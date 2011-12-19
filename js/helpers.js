// constants
var BUILD_URL = 'https://build.phonegap.com';

// Dom helpers
function $(s) { return document.getElementById(s); }

// Extend the String object for simple templating
String.prototype.format = function(){
	var args = arguments;
	obj = (args.length == 1 && (typeof args[0] == 'object')) ? args[0] : args;
	return this.replace(/\{(\w+)\}/g, function(m, i){
		return obj[i];
	});
}

	// helper for XHR
function xhr(url, options) {
	var xhr = new XMLHttpRequest();

	if (options && options.username && typeof options.password != 'undefined') {
		var schemeSeparator = "://";
		var extractToIndex = url.indexOf(schemeSeparator) + schemeSeparator.length;
		var scheme = url.substring(0, extractToIndex);
		var rhs = url.substring(extractToIndex);
		url = scheme + encodeURIComponent(options.username) + ':' + encodeURIComponent(options.password) + '@' + rhs;
	}

	xhr.open('GET', url, (options && typeof options.async != 'undefined'?options.async:true));

	if (options && options.headers) {
		// Lifted from xui source; github.com/xui/xui/blob/master/src/js/xhr.js
		for (var key in options.headers) {
			if (options.headers.hasOwnProperty(key)) {
				xhr.setRequestHeader(key, options.headers[key]);
			}
		}
	}

	xhr.setRequestHeader("Accept", "application/json");

	xhr.onreadystatechange = function(){
		if ( xhr.readyState == 4 ) {
			if ( xhr.status == 200 || xhr.status == 0) {
				options.callback.call(xhr);
			} else {
				alert('XHR error, status: ' + xhr.status);
			}
		}
	};
	xhr.send((options && options.data? options.data : null));
}
