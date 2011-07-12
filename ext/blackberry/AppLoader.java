package com.phonegap.remote;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;

import javax.microedition.io.Connector;
import javax.microedition.io.HttpConnection;
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

  public PluginResult execute(String action, JSONArray args, String callbackId) {
    this.callback = callbackId;

    // Generate key based off key returned from build API
    try {
      if (this.key == null) {
        byte[] keyBase = args.getString(0).getBytes();
        this.key = new TripleDESKey(keyBase);
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
      local_path = "";
    } catch (JSONException e) {
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
      id = args.getString(0);
      url = args.getString(1);
      username = args.getString(2);
      password = args.getString(3);
      String rootFile = fetchApp(url);
      if (!rootFile.equals("")){
        byte[] buf=FileUtils.readFile(rootFile+"/index.html", Connector.READ_WRITE);
        PhoneGapExtension.getBrowserField().displayContent(buf, "text/html", rootFile);
      }
    } catch (com.phonegap.json4j.JSONException e) {
      e.printStackTrace();
    } catch (FileNotFoundException e) {
      e.printStackTrace();
    } catch (IOException e) {
      e.printStackTrace();
    }
  }

  // Removes locally-stored app(s).
  private void remove(JSONArray args) {
  }

  private String fetchApp(String url, String username, String password) throws IOException {
    HttpConnection httpConnection = null;
    InputStream inputStream = null;
    try {
      httpConnection = (HttpConnection)Connector.open(url, Connector.READ);
      httpConnection.setRequestMethod(HttpConnection.GET);
      int statusCode = httpConnection.getResponseCode();
      if (statusCode == HttpConnection.HTTP_OK) {
        inputStream = httpConnection.openDataInputStream();
        String tempDir = FileUtils.createApplicationTempDirectory();
        String filePath = tempDir+"app.zip";
        FileUtils.delete(filePath);
        FileUtils.delete(tempDir+"app/");
        writeFile(filePath, inputStream);
        inputStream.close();
        httpConnection.close();
        if (saveAndUnzip(filePath, tempDir+"app/"))
          return tempDir+"app/";
      }
    } finally{
      if (inputStream!=null) inputStream.close();
      if (httpConnection!=null) httpConnection.close();
    }
    return "";
  }

  private static boolean writeFile(String filePath, InputStream stream) throws SecurityException, IOException {
    FileConnection fconn = null;
    OutputStream os = null;
    try {
      fconn = (FileConnection)Connector.open(filePath, Connector.READ_WRITE);
      if (!fconn.exists()) {
          fconn.create();
      }
      os = fconn.openOutputStream();
      byte[] buffer = new byte[1024];
      int count;
      while ((count = stream.read(buffer)) > 0) {
          os.write(buffer, 0, count);
      }
      return true;
    } finally {
      try {
        if (os != null)
            os.close();
        if (fconn != null)
            fconn.close();
      } catch (IOException ignored) {
      }
    }
  }

  private boolean saveAndUnzip(String savedZipFilePath, String targetPath) throws IOException {
    FileConnection fconn = (FileConnection)Connector.open(targetPath);
    try {
      if (!fconn.exists()) {
        fconn.mkdir();
      }
    } finally {
      if (fconn!=null) fconn.close();
    }
    fconn = (FileConnection)Connector.open(savedZipFilePath, Connector.READ_WRITE);
    InputStream stream = fconn.openDataInputStream();
    try {
      ZipArchive archive = new ZipArchive(stream);
      Enumeration ze = archive.entries();
      while (ze.hasMoreElements()) {
        ZipEntry entry = (ZipEntry) ze.nextElement();
        System.out.println("Attempting write: "+targetPath+entry.getName());
        writeZipEntry(archive.getInputStream(entry), targetPath,entry.getName());
      }
    } finally {
      if (stream!=null) stream.close();
      if (fconn!=null) fconn.close();
    }
    return true;
  }
  
  private static void writeZipEntry(InputStream stream, String rootPath, String relativePath) throws IOException {
    boolean isDirectory=relativePath.endsWith("/");
    String[] paths=split(relativePath, "/");
    int pathItems=(isDirectory)?paths.length:paths.length-1;
    
    String directories="";
    for(int i=0;i<pathItems;i++){
      String dir=rootPath+directories+paths[i]+"/";
      FileConnection fconn = (FileConnection)Connector.open(dir);
      try {
        if (!fconn.exists()) {
          fconn.mkdir();
        }
        directories+=paths[i]+"/";
      } finally {
        fconn.close();
      }
    }
    if (!isDirectory){
      AppLoader.writeFile(rootPath+relativePath, stream);
    }
  }
  
  private static String[] split(String strString, String strDelimiter)
  {
    int iOccurrences = 0;
    int iIndexOfInnerString = 0;
    int iIndexOfDelimiter = 0;
    int iCounter = 0;

    if (strString == null) {
      throw new NullPointerException("Input string cannot be null.");
    }

    if (strDelimiter.length() <= 0 || strDelimiter == null) {
      throw new NullPointerException("Delimeter cannot be null or empty.");
    }

    if (strString.startsWith(strDelimiter)) {
      strString = strString.substring(strDelimiter.length());
    }

    if (!strString.endsWith(strDelimiter)) {
      strString += strDelimiter;
    }

    while((iIndexOfDelimiter= strString.indexOf(strDelimiter,iIndexOfInnerString))!=-1) {
      iOccurrences += 1;
      iIndexOfInnerString = iIndexOfDelimiter + strDelimiter.length();
    }

    String[] strArray = new String[iOccurrences];
    iIndexOfInnerString = 0;
    iIndexOfDelimiter = 0;

    while((iIndexOfDelimiter= strString.indexOf(strDelimiter,iIndexOfInnerString))!=-1) {
      strArray[iCounter] = strString.substring(iIndexOfInnerString, iIndexOfDelimiter);
      iIndexOfInnerString = iIndexOfDelimiter + strDelimiter.length();
      iCounter += 1;
    }
    return strArray;
  }
}
