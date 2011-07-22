/* ******************************************************************** 
 
	BinaryDownloaderPlugin.js
	PhoneGap plugin JS interface.
 
 
 ********************************************************************/

function BinaryDownloaderPlugin()
{
}

BinaryDownloaderPlugin.prototype.cancel = function(uri, win, fail)
{
	PhoneGap.exec(win, fail, "com.phonegap.hydra.BinaryDownloaderPlugin", "cancel", [uri]);
}

BinaryDownloaderPlugin.prototype.download = function(uri, filepath, win, fail)
{
	PhoneGap.exec(win, fail, "com.phonegap.hydra.BinaryDownloaderPlugin", "download", [uri, filepath]);
}

BinaryDownloaderPlugin.install = function()
{
	if ( !window.plugins ) {
		window.plugins = {};
    } 
	if ( !window.plugins.binaryDownloader ) {
		window.plugins.binaryDownloader = new BinaryDownloaderPlugin();
    }
}

PhoneGap.addConstructor(BinaryDownloaderPlugin.install);

