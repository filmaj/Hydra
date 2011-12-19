Hydra
====

![Hydra!](http://github.com/filmaj/hydra/raw/master/img/icon-big.png)

A beast with many heads. Keep one or more [PhoneGap](http://www.phonegap.com) app assets "in the cloud" on [build.phonegap.com](http://build.phonegap.com), and use this shell to store different apps and keep each app up-to-date with the latest assets.

# Getting Started

1. Edit the `CALLBACK_ANDROID` and other platform paths at the top of
     the `makefile`.
2. Run `make <platform>` to generate the PhoneGap/Callback/Cordova
	 project under `dist/<platform>`.
3. `cd dist/<platform>` and then run the platform-specific tools to
	 debug/test/deploy/sign/etc.

## iOS' Special Needs

1. Include libz.dylib in your project
    - Xcode 4
        1. Select your target
        2. Select _Build Phases_ tab
        3. Expand _Link Binary with Libraries_
        4. Press _+_ at the bottom
        5. Search and add _libz.dylib_ (expand collapsed directories)
        6. (Optional) Move into the "Frameworks" group

2. In PhoneGap.plist, under "Plugins", add these new entries: 
    1. For the key, add "AppLoader", and for the value, add "AppLoader"
    2. For the key, add "com.nitobi.BinaryDownloader", and for the value, add "BinaryDownloader"
    3. For the key, add "com.nitobi.ZipUtil", and for the value, add "ZipUtil"

3. For PhoneGap 1.1, In PhoneGap.plist, under "ExternalHosts", add these new entries:
     * build.phonegap.com
     * s3.amazonaws.com
     * (any other hosts that your downloaded app needs to connect to - of course you need to know this in advance - or you can use "*" to allow everything)

# Why?

* Easier to manage application updates; a poor man's TestFlight.
* Theoretically more secure. However: be warned I don't know shit about
  security.

# Contributors

* [Fil Maj](http://www.github.com/filmaj)
* [Michael Brooks](http://www.github.com/mwbrooks)
* [Ryan Betts](http://www.github.com/ryanbetts)
* [Joe Bowser](http://www.github.com/infil00p)
* [Shazron Abdullah](http://www.github.com/shazron)
* [Brett Rudd](http://www.github.com/goya)

