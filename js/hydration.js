var Hydration = function() {}

Hydration.prototype = {
	load:function(win, fail, key, id){
	    return PhoneGap.exec(win, fail, 'AppLoader', 'load', [ id ]);
	},
	fetch:function(win, fail, key, id, url, username, password){
	    return PhoneGap.exec(win, fail, 'AppLoader', 'fetch', [ id, url, username, password ]);
	},
	remove:function(win, fail, key, id){
	    return PhoneGap.exec(win, fail, 'AppLoader', 'remove', [ id ]);
	}
}

PhoneGap.addConstructor(function() {
    PhoneGap.addPlugin('remoteApp', new Hydration());
    navigator.app.addService('AppLoader', 'com.phonegap.remote.AppLoader');
});
