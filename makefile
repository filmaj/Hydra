VERSION = `cat ./VERSION`
HYDRA = $(CURDIR)
CALLBACK_ANDROID = /Users/filmaj/src/callback-android

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
	mkdir -p ./dist/android/src/com/phonegap/remote
	mv ./dist/android/assets/www/ext/android/AppLoader.java ./dist/android/src/com/phonegap/remote
	mkdir -p ./dist/android/src/com/byarger/exchangeit
	mv ./dist/android/assets/www/ext/android/Easy* ./dist/android/src/com/byarger/exchangeit
	rm -rf ./dist/android/assets/www/ext

android: android_create clean

ios:

blackberry:

.PHONY: clean
