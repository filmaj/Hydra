VERSION = `cat ./VERSION`
HYDRA = $(CURDIR)
CALLBACK_ANDROID = /Users/filmaj/src/callback-android
CALLBACK_VERSION = `cat ${CALLBACK_ANDROID}/VERSION`

default: prepare build archive clean

prepare:
	rm -rf ./dist
	mkdir ./dist

build:
	sed -i -e "s/__VERSION__/${VERSION}/g" ./config.xml

archive:
	zip -r ./dist/hydra.zip .

clean:
	sed -i -e "s/${VERSION}/__VERSION__/g" ./config.xml

android_create: prepare
	mkdir ./dist/android
	cd ${CALLBACK_ANDROID} && ./bin/create ${HYDRA}/dist/android com.phonegap.hydra Hydra
	
	mv ./dist/android/assets/www/phonegap-${CALLBACK_VERSION}.js ./dist/android/assets/
	rm -f ./dist/android/assets/www/*
	cp -f index.html master.css ./dist/android/assets/www
	cp -rf ./img ./dist/android/assets/www
	cp -rf ./js ./dist/android/assets/www
	mv ./dist/android/assets/phonegap-${CALLBACK_VERSION}.js ./dist/android/assets/www/phonegap.js
	
	mkdir -p ./dist/android/src/com/phonegap/remote
	cp -f ./ext/android/AppLoader.java ./dist/android/src/com/phonegap/remote
	mkdir -p ./dist/android/src/com/byarger/exchangeit
	cp -f ./ext/android/Easy* ./dist/android/src/com/byarger/exchangeit

android: android_create clean

ios:

blackberry:

.PHONY: clean
