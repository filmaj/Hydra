(function() {
  if (!('localStorage' in window && window['localStorage'] !== null)) alert("No support for localStorage.");

  // Dom helpers
  function $(s) { return document.getElementById(s); }
  function showModal(msg) {
    $('modal').innerHTML = msg || 'Loading';
    var h = window.innerHeight;
    var topOffset = Math.floor(h/2) - 50; // 50 = half the height of modal dialog
    var leftOffset = Math.floor(window.innerWidth/2) - 100; // 100 = half the width of the modal dialog
    document.body.style.height = h + 'px';
    document.body.style.overflow = 'hidden';
    var m = $('modal');
    m.style.top = topOffset + 'px';
    m.style.left = leftOffset + 'px';
    m.style.display = '';
    $('backdrop').style.display = '';
  }
  function hideModal() { 
    document.body.style.height = '';
    document.body.style.overflow = '';
    $('backdrop').style.display = 'none'; 
    $('modal').style.display = 'none';
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
    var xhr = new XMLHttpRequest(),
        async = (options && options.async ? options.async : true);

    xhr.open("GET", url, async);
    
    if (options && options.headers) {
      // Lifted from xui source; github.com/xui/xui/blob/master/src/js/xhr.js
      for (key in options.headers) {
          if (options.headers.hasOwnProperty(key)) {
            xhr.setRequestHeader(key, options.headers[key]);
          }
      }
    }

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

  // saves app information to localstorage and loads app into current webview
  function saveAppInfoAndLoad(id, timestamp, location) {
    var apps = window.localStorage.getItem('apps');
    console.log('save app, apps is: ' + apps);
    console.log('type of apps: ' + typeof apps);
    if (apps == null) {
      console.log('apps is null');
      apps = {};
    } else {
      console.log('parsing apps');
      apps = JSON.parse(apps);
    }
    apps['app' + id] = {
      updatedAt:timestamp,
      location:location
    };
    window.localStorage.setItem('apps', JSON.stringify(apps));
    console.log('loading ' + location);
    window.location = location;
  }

  // Hydrate action
  hydra = function() {
    var id = $('app_id').value;
    var url = 'https://build.phonegap.com/api/v0/apps/' + id + '/hydrate';
    var username = $('username').value;
    var password = $('password').value;
    var auth = 'Basic ' + Base64.encode(username + ':' + password);

    showModal('Talking to build.phonegap.com...');
    xhr(url, {
      callback:function() {
        eval('var json = ' + this.responseText + ';');
        console.log(JSON.stringify(json));
        if (json.error) {
          alert("build.phonegap.com error: " + json.error);
        } else {
          // We get an S3 url + an updated_at time stamp.
          var sthree = json['s3_url'].replace(/&amp;/gi, '&');
          var updatedAt = json['updated_at'];
          // compare application(s) stored in offline storage before updating.
          var apps = window.localStorage.getItem('apps');
          if (apps) {
            console.log('xhr callback: we have apps');
            if (typeof apps['app' + id] != 'undefined') {
              console.log('xhr callback: app already exists');
              var app = apps['app' + id];
              if (app.updatedAt != updatedAt) {
                console.log('new version of app, update this shit!');
                window.plugins.remoteApp.fetch(function(location) {
                  console.log('new version app fetch plugin success!');
                  saveAppInfoAndLoad(id, updatedAt, location);
                }, pluginError, id, sthree, null, null);
              } else {
                console.log('same version of app, dont update, just load it');
                window.plugins.remoteApp.load(function(location) {
                  console.log('same version app load plugin success!');
                  saveAppInfoAndLoad(id, updatedAt, location);
                }, pluginError, id);
              }
            } else {
              console.log('havent saved this app yet');
              window.plugins.remoteApp.fetch(function(location) {
                console.log('new app fetch plugin success!');
                saveAppInfoAndLoad(id, updatedAt, location);
              }, pluginError, id, sthree, null, null);
            }
          } else {
            console.log('no existing apps, fetching!');
            window.plugins.remoteApp.fetch(function(location) {
              console.log('fresh app fetch plugin success!');
              saveAppInfoAndLoad(id, updatedAt, location);
            }, pluginError, id, sthree, null, null);
          }
        }
        hideModal();
      },
      async:true,
      headers:{'Authorization':auth}
    });
  }
  document.addEventListener('deviceready', function() {
    console.log('deviceready');
    document.getElementById('action').style.display = 'block';

    // Load existing apps.
    if (window.localStorage && window.localStorage.getItem('apps')) {
      console.log('loading existing apps into dom');
      var apps = JSON.parse(window.localStorage.getItem('apps')),
          template = '<li><a href="#" onclick="window.location = \'{location}\';">{appId}</a><span>(Last updated at {updatedAt})</span></li>',
          html = [];
      for (var app_id in apps) {
        if (apps.hasOwnProperty(app_id)) {
          console.log('dealing with ' + app_id);
          var app = apps[app_id];
          if (app.updatedAt && app.location) {
            console.log('has the right properties');
            html.push(template.format({
              appId:app_id,
              updatedAt:app.updatedAt,
              location:app.location
            }));
          }
        }
      }
      if (html.length > 0) {
        var list = $('existing');
        list.innerHTML = html.join('');
        list.style.display = '';
      }
    }
  }, false);
})();
