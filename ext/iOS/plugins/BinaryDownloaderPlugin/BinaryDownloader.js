/* ******************************************************************** 
 
	BinaryDownloaderPlugin.js
	PhoneGap plugin JS interface.
 
 
 ********************************************************************/

function BinaryDownloader()
{
}

BinaryDownloader.prototype.cancel = function(uri, win, fail)
{
	PhoneGap.exec(win, fail, "com.nitobi.BinaryDownloader", "cancel", [uri]);
}

BinaryDownloader.prototype.download = function(uri, filepath, win, fail)
{
	PhoneGap.exec(win, fail, "com.nitobi.BinaryDownloader", "download", [uri, filepath]);
}

BinaryDownloader.install = function()
{
	if ( !window.plugins ) {
		window.plugins = {};
    } 
	if ( !window.plugins.binaryDownloader ) {
		window.plugins.binaryDownloader = new BinaryDownloader();
    }
}

PhoneGap.addConstructor(BinaryDownloader.install);

