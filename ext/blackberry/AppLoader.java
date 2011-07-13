package com.phonegap.remote;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;

import javax.microedition.io.Connector;
import javax.microedition.io.HttpsConnection;
import javax.microedition.io.file.FileConnection;

import net.rim.device.api.io.FileNotFoundException;
import net.rim.device.api.crypto.*;
import net.sf.zipme.ZipArchive;
import net.sf.zipme.ZipEntry;

import com.phonegap.PhoneGapExtension;
import com.phonegap.file.FileUtils;
import com.phonegap.json4j.JSONArray;

import com.phonegap.api.Plugin;
import com.phonegap.api.PluginResult;

public class AppLoader extends Plugin {

  private String callback;
  private String local_path;
  private TripleDESKey key = null;
  private TripleDESEncryptorEngine encryptionEngine = null;
  private PKCS5FormatterEngine formatterEngine = null;

  public PluginResult execute(String action, JSONArray args, String callbackId) {
    this.callback = callbackId;

    // Generate key based off key returned from build API
    try {
      if (this.key == null) {
        byte[] keyBase = args.getString(0).getBytes();
        this.key = new TripleDESKey(keyBase);
        this.encryptionEngine = new TripleDESEncryptionEngine(this.key);
        this.formatterEngine = new PKCS5FormatterEngine(this.encryptionEngine);
      }
    } catch (Exception e) {
      return new PluginResult(PluginResult.Status.ERROR, "Problem during encryption key generation, aborting.");
    }

    if (action.equals("load")) {
      load(args);
    } else if (action.equals("fetch")) {
      fetch(args);
    } else if (action.equals("remove")) {
      remove(args);
    } else {
      return new PluginResult(PluginResult.Status.INVALIDACTION);
    }

    PluginResult r = new PluginResult(PluginResult.Status.NO_RESULT);
    r.setKeepCallback(true);
    return r;
  }

  // Loads a locally-saved app into the WebView.
  private void load(JSONArray args) {
    try {
      local_path = getAppRootDirectory() + args.getString(1) + "/";
      this.success(new PluginResult(PluginResult.Status.OK, local_path + "index.html"), this.callback);
    } catch (com.phonegap.json4j.JSONException e) {
      this.error(new PluginResult(PluginResult.Status.ERROR, "JSON exception during argument parsing; make sure the app ID was passed as an argument."), this.callback);
    }
  }

  // Grabs assets off the intarwebz and saves them to a local store/jail for hydration.
  private void fetch(JSONArray args) {
    String url;
    String username;
    String password;
    String id;
    try {
      id = args.getString(1);
      url = args.getString(2);
      username = args.getString(3);
      password = args.getString(4);

      // Create directory for app.
      local_path = getAppRootDirectory() + id + "/";
      FileUtils.mkdir(local_path); // will not overwrite if exists.

      if (fetchApp(url, username, password)) {
        this.success(new PluginResult(PluginResult.Status.OK, local_path + "index.html"), this.callback);
      } else {
        this.error(new PluginResult(PluginResult.Status.ERROR, "Error during app saving or fetching; protocol or IO error likely."), this.callback);
      }
      /*
      if (!rootFile.equals("")){
        byte[] buf=FileUtils.readFile(rootFile+"/index.html", Connector.READ_WRITE);
        PhoneGapExtension.getBrowserField().displayContent(buf, "text/html", rootFile);
      }
      */
    } catch (com.phonegap.json4j.JSONException e) {
      this.error(new PluginResult(PluginResult.Status.ERROR, "Error during app saving or fetching: JSON exception, make sure right arguments were passed."), this.callback);
    } catch (FileNotFoundException e) {
      this.error(new PluginResult(PluginResult.Status.ERROR, "Error during app saving or fetching: FileNotFoundException was thrown."), this.callback);
    } catch (IOException e) {
      this.error(new PluginResult(PluginResult.Status.ERROR, "Error during app saving or fetching: IOException was thrown."), this.callback);
    }
  }

  // Removes locally-stored app(s).
  private void remove(JSONArray args) {
    // TODO: this whole thing. but we dont need removing so whatevs.
  }

  // Returns the directory to use as the app's home directory.
  private String getAppRootDirectory() {
    return FileUtils.getFileSystemRoot() + "remote_app/";
  }

  private boolean fetchApp(String url, String username, String password) throws IOException {
    HttpsConnection httpsConnection = null;
    boolean returnValue = false;
    try {
      if (username == "null") {
        username = null;
      }
      if (password == "null") {
        password = null;
      }
      httpsConnection = (HttpsConnection)Connector.open(url, Connector.READ);
      httpsConnection.setRequestMethod(HttpsConnection.GET);
      int statusCode = httpsConnection.getResponseCode();
      if (statusCode == HttpsConnection.HTTP_OK) {
        ZipInputStream data = new ZipInputStream(httpsConnection.openDataInputStream());
        // TODO: keep going from here.
        returnValue = saveAndVerify(data);
      } else {
        returnValue = false;
      }
    } catch(Exception e) {
      e.printStackTrace();
      returnValue = false;
    } finally {
      if (inputStream!=null) inputStream.close();
      if (httpConnection!=null) httpConnection.close();
    }
    return returnValue;
  }
  private boolean saveAndVerify(ZipInputStream data) throws IOExeption {
    try {
      ZipEntry ze;
      while ((ze = data.getNextEntry()) != null) {
        // Filename + reference to file.
        String filename = ze.getName();
        File output = new File(local_path + filename);
        
        if(filename.endsWith("/")) {
          output.mkdirs();
        } else {
          if (output.exists()) {
        	  // Delete the file if it already exists.
        	  if (!output.delete()) {
        		  return false;
        	  }
          }
          if (output.createNewFile()) {
            FileOutputStream out = new FileOutputStream(output);
            byte[] buffer = new byte[1024];
            int count;
            while ((count = data.read(buffer)) != -1) {
              out.write(buffer, 0, count);
            }
          } else {
            return false;
          }
        }
      }

    } catch(Exception e) {
      e.printStrackTrace();
    } finally {
      data.close();
    }
  }
}
