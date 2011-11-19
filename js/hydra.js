(function() {
  if (!('localStorage' in window && window['localStorage'] !== null)) alert("No support for localStorage.");

	// constants
	var BUILD_URL = 'https://build.phonegap.com';

  // Dom helpers
  function $(s) { return document.getElementById(s); }

  function showModal(txt) {
    var wrap = $('modal-wrap');
    var msg = $('modal-msg');
    var prog_msg = $('progress-msg');
    msg.innerHTML = txt || 'Loading';
    prog_msg.innerHTML = txt || 'Loading';
    document.body.style.height = window.innerHeight + 'px';
    document.body.style.overflow = 'hidden';
    wrap.style.display = '';
  }

  function hideModal() {
    document.body.style.height = '';
    document.body.style.overflow = '';
    $('modal-wrap').style.display = 'none';
  }

	function error(txt) {
		alert('PhoneGap Build error: ' + txt);
		hideModal();
	}

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

  // plugin error handler
  function pluginError(msg) {
    alert('Hydration plugin error!' + msg);
    hideModal();
  }

	function getLocalApps() {
		var apps = window.localStorage.getItem('apps');
		if (apps == null) {
			apps= {};
		} else {
			apps = JSON.parse(apps);
		}
		return apps;
	}

  // saves app information to localstorage
  function saveApps(apps, username, password) {
		var local = getLocalApps();
		for (var i = 0, l = apps.length; i < l; i++) {
			var app = apps[i];
			app.username = username;
			app.password = password;
			local['' + app.id] = app;
		}
    window.localStorage.setItem('apps', JSON.stringify(local));

    //window.plugins.remoteApp.load(function(loc) {
    //  window.location = loc;
    //},  pluginError, key, id);
  }

	function retrieveApps(username, password) {
		var url = BUILD_URL + '/api/v1/apps';
    console.log('retrieving apps from ' + url);
		xhr(url, {
			callback:function() {
        console.log('evaling response');
				eval('var json = ' + this.responseText + ';');
				if (json.error) {
          console.log('error!');
					error(json.error);
				} else {
          console.log('were ok, apps:');
					saveApps(json.apps, username, password);
					if (renderApps()) {
            $('home').style.display = 'none';
            $('existing').style.display = '';
          } else {
            alert('Your account has no applications!');
          }
					hideModal();
				}
			},
			async:true,
			username:username,
			password:password
		});
	}

  // loads an app
  loadApp = function(id, username, password) {
    var url = BUILD_URL + '/api/v1/apps/' + id + '/hydrate';
    var apps = window.localStorage.getItem('apps');

    // Check the last updated timestamp on build.
    xhr(url, {
      callback:function() {
        console.log('xhr callback');
        console.log(this);
        console.log(this.responseText);
        eval('var json = ' + this.responseText + ';');
        if (json.error) {
          error(json.error);
        } else {
          // We get an S3 url, updated_at time stamp and app title.
          var sthree = json['s3_url'].replace(/&amp;/gi, '&'),
              updatedAt = json['updated_at'],
              title = json['title'],
              key = json['key'];

          console.log('S3 URL: ' + sthree);

          // Weird JSON.parse error in Android browser: can't parse null, it'll throw an exception.
          if (apps != null) apps = JSON.parse(apps);

          // Check if we've already stored this app.
          if (apps && typeof apps['app' + id] != 'undefined') {
            var app = apps['app' + id];

            // Update its data.
            app.title = title;
            app.username = username;
            app.password = password;
            app.id = id;

            // Check if the app was updated on build.phonegap.com
            if (app.updatedAt != updatedAt) {
              console.log('new version of app, update this shit!');
              app.updatedAt = updatedAt;
              showModal('Downloading application update...');
              window.plugins.remoteApp.fetch(function(loc) {
                console.log('new version app fetch plugin success!');
                app.location = loc;
                saveAppInfoAndLoad(key, id, app);
              }, pluginError, key, id, sthree, null, null);
            } else {
              console.log('same version of app, dont update, just load it');
              showModal('Loading application...');
              window.plugins.remoteApp.load(function(loc) {
                window.location = loc;
              },  pluginError, key, id);
            }
          } else {
            // Couldn't find the app in local storage, fetch it yo.
            showModal('Downloading application...');
            console.log('fresh app, fetching it for first time');
            window.plugins.remoteApp.fetch(function(loc) {
              var app = {
                title:title,
                location:loc,
                username:username,
                password:password,
                updatedAt:updatedAt,
                key:key
              };
              console.log('fresh app fetch plugin success!');
              saveAppInfoAndLoad(key, id, app);
            }, pluginError, key, id, sthree, null, null);
          }
        }
      },
      async:true,
      username:username,
      password:password
    });
  }

  function saveCredentials(username, password) {
    window.localStorage.setItem('username', username);
    window.localStorage.setItem('password', password);
  }

  function loadCredentials() {
    if (typeof window.localStorage == 'undefined') {
      return;
    }
    
    var username = window.localStorage.getItem('username');
    if (username) $('username').value = username;
    var password = window.localStorage.getItem('password');
    if (password) $('password').value = password;
  }

	function renderApps() {
		var local = getLocalApps(),
				template = '<li><a href="#" onclick="loadApp(\'{id}\', \'{username}\', \'{password}\');"><img src="" class="icon"><h1>{title} v{version}</h1><small>Built {build_count} times</small></a></li>',
				html = [];
		for (var app_id in local) {
			if (local.hasOwnProperty(app_id)) {
				var app = local[app_id];
				html.push(template.format(app));
			}
		}
    
		if (html.length > 0) {
			var list = $('app_list');
			list.innerHTML = html.join('');
			list.style.display = '';
      return true;
		} else return false;
	}

  // Hydrate action
  hydra = function() {
    var username = $('username').value;
    var password = $('password').value;
    if (confirm('Would you like to save your build.phonegap.com credentials?')) {
      saveCredentials(username, password);
    }
    showModal('Talking to build.phonegap.com...');
		retrieveApps(username, password);
  }

  document.addEventListener('deviceready', function() {
    console.log('deviceready');
    loadCredentials();

    // Load existing apps.
    if (window.localStorage && window.localStorage.getItem('apps')) {
      if (renderApps()) {
        // We have apps, switch the view.
        $('home').style.display = 'none';
        $('existing').style.display = '';
      } else {
        // Do nothing; show the login form.
      }
    }
    
    hideModal();
  }, false);
})();
