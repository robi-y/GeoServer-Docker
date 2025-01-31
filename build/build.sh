#!/bin/bash

# Create plugins folder if does not exist
if [ ! -d ./resources ]
then
    mkdir ./resources
fi

if [ ! -d ./resources/plugins ]
then
    mkdir ./resources/plugins
fi

GS_VERSION=2.20.1
BUILD_GS_VERSION=${GS_VERSION:0:-2}

# Add in selected plugins.  Comment out or modify as required
plugins=(control-flow inspire monitor css ysld web-resource sldservice imagemosaic-jdbc )

for p in "${plugins[@]}"
do 
	if [ ! -f resources/plugins/geoserver-${p}-plugin.zip ]
	then
		wget -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-${p}-plugin.zip -O resources/plugins/geoserver-${p}-plugin.zip
	fi
done

# Community plugins are not available from sourgeforge
# therefore source from https://build.geoserver.org/
community_plugins=(mbtiles mbtiles-store s3-geotiff )
for c in "${community_plugins[@]}"
do
	if [ ! -f resources/plugins/geoserver-${c}-plugin.zip ]
	then
		wget -c https://build.geoserver.org/geoserver/${BUILD_GS_VERSION}.x/community-latest/geoserver-${BUILD_GS_VERSION}-SNAPSHOT-${c}-plugin.zip -O resources/plugins/geoserver-${c}-plugin.zip
	fi
done

## build options include:
#    TOMCAT_EXTRAS  [true | false]
#    GDAL_NATIVE    [true | false]  - default false; build with GDAL support
#    GS_VERSION              - specifies which version of geoserver is to be built

docker build --build-arg GS_VERSION=${GS_VERSION} --build-arg TOMCAT_EXTRAS=false --build-arg GDAL_NATIVE=true -t thinkwhere/geoserver:${GS_VERSION} .
