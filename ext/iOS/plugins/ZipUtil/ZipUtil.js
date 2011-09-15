/* ******************************************************************** 
 
	ZipUtil.js
	PhoneGap plugin JS interface.
 
 
 ********************************************************************/

function ZipUtil()
{
}

ZipUtil.prototype.unzip = function(sourcePath, targetFolder, win, fail)
{
	PhoneGap.exec(win, fail, "com.nitobi.ZipUtil", "unzip", sourcePath, targetFolder);
}

ZipUtil.install = function()
{
	if ( !window.plugins ) {
		window.plugins = {};
    } 
	if ( !window.plugins.zipUtil ) {
		window.plugins.zipUtil = new ZipUtil();
    }
}

PhoneGap.addConstructor(ZipUtil.install);

