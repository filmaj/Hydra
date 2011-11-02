VERSION = `cat ./VERSION`

default: prepare build archive clean

prepare:
	rm -rf ./dist

build:
	sed -i -e "s/__VERSION__/${VERSION}/g" ./config.xml

archive:
	mkdir dist
	zip -r ./dist/hydra.zip .

clean:
	sed -i -e "s/${VERSION}/__VERSION__/g" ./config.xml

android:

ios:

blackberry:

.PHONY: clean
