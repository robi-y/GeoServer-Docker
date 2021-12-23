#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM tomcat:9.0-jre11-slim
MAINTAINER thinkWhere<info@thinkwhere.com>
# Credit: Tim Sutton<tim@linfiniti.com>
#llow-unauthenticatedi kartoza/docker-geoserver

RUN apt-get -y update; apt-get -y --allow-unauthenticated install libapr1-dev \
    libssl-dev wget zip curl xsltproc certbot cabextract \
    make g++ ant swig openjdk-11-jdk

RUN set -e \
    export DEBIAN_FRONTEND=noninteractive \
    dpkg-divert --local --rename --add /sbin/initctl \
	# Set JAVA_HOME to /usr/lib/jvm/default-java and link it to OpenJDK installation
    && ln -s /usr/lib/jvm/java-11-openjdk-amd64 /usr/lib/jvm/default-java \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*


#-------------Application Specific Stuff ----------------------------------------------------

ENV JAVA_HOME=/usr/lib/jvm/default-java \
	DEBIAN_FRONTEND=noninteractive \
    GEOSERVER_DATA_DIR=/opt/geoserver/data_dir \
	GDAL_DATA=/usr/local/gdal-data \
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib:/usr/local/apr/lib:/usr/lib:/usr/lib/x86_64-linux-gnu"

#	GDAL_SKIP="ECW JP2ECW" \

RUN mkdir -p ${GEOSERVER_DATA_DIR}

ADD resources /tmp/resources

# Optionally remove Tomcat manager, docs, and examples
ARG TOMCAT_EXTRAS=false
RUN if [ "$TOMCAT_EXTRAS" = false ]; then \
    rm -rf $CATALINA_HOME/webapps/ROOT && \
    rm -rf $CATALINA_HOME/webapps/docs && \
    rm -rf $CATALINA_HOME/webapps/examples && \
    rm -rf $CATALINA_HOME/webapps/host-manager && \
    rm -rf $CATALINA_HOME/webapps/manager; \
  fi;

# ---------- GS_Version can be passed in as a parameter ------------
ARG GS_VERSION=2.20.1

# Add GDAL native libraries if the build-arg GDAL_NATIVE = true
# EWC and JP2ECW are subjected to licence restrictions
ARG GDAL_NATIVE=false
RUN if [ "$GDAL_NATIVE" = true ]; then \
    wget --progress=bar http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.16/native/gdal/gdal-data.zip \
	-O /tmp/resources/gdal-data.zip && \
    wget --progress=bar http://demo.geo-solutions.it/share/github/imageio-ext/releases/1.1.X/1.1.29/native/gdal/linux/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz \
	-O /tmp/resources/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz && \
    unzip /tmp/resources/gdal-data.zip -d /usr/local && \
    mkdir /usr/local/gdal_native_libs && \
    tar -xvf /tmp/resources/gdal192-Ubuntu12-gcc4.6.3-x86_64.tar.gz -C /usr/local/gdal_native_libs; \
    apt-get update; \
	apt-get install -y gdal-bin libgdal-java --fix-missing; \
fi;


# If using GDAL make sure extension is downloaded
RUN if [ "$GDAL_NATIVE" = true ] && [ ! -f /tmp/resources/plugins/geoserver-gdal-plugin.zip ]; then \
	wget --progress=bar -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/extensions/geoserver-${GS_VERSION}-gdal-plugin.zip \
	-O /tmp/resources/plugins/geoserver-gdal-plugin.zip; \
fi;

WORKDIR $CATALINA_HOME


# Fetch the geoserver war file if it
# is not available locally in the resources dir and
RUN if [ ! -f /tmp/resources/geoserver.zip ]; then \
    wget --progress=bar -c http://downloads.sourceforge.net/project/geoserver/GeoServer/${GS_VERSION}/geoserver-${GS_VERSION}-war.zip \
      -O /tmp/resources/geoserver.zip; \
    fi; \
    unzip /tmp/resources/geoserver.zip -d /tmp/geoserver \
    && unzip /tmp/geoserver/geoserver.war -d $CATALINA_HOME/webapps/geoserver \
    && rm -rf $CATALINA_HOME/webapps/geoserver/data \
    && rm -rf /tmp/geoserver

# Install any plugin zip files in resources/plugins
RUN if ls /tmp/resources/plugins/*.zip > /dev/null 2>&1; then \
      for p in /tmp/resources/plugins/*.zip; do \
        unzip $p -d /tmp/gs_plugin \
        && mv /tmp/gs_plugin/*.jar $CATALINA_HOME/webapps/geoserver/WEB-INF/lib/ \
        && rm -rf /tmp/gs_plugin; \
      done; \
    fi;

# Install Font files in resources/fonts if they exist
RUN if ls /tmp/resources/fonts/*.ttf > /dev/null 2>&1; then \
      cp -rf /tmp/resources/fonts/*.ttf /usr/share/fonts/truetype/; \
	fi;

# Copy across script and XML stylesheet which will allow the Tomcat server.xml to be parameterised
RUN cp /tmp/resources/tomcat/* $CATALINA_HOME/conf/

# Copy ECW libs
RUN cp /tmp/resources/ecw-release/* /usr/local/lib
RUN mkdir -p /usr/local/hexagon && cp -r /tmp/resources/ecw5.4.0/* /usr/local/hexagon/
RUN ldconfig /usr/local/lib && ldconfig /usr/local/hexagon

# install gdal source
RUN cd /tmp/resources/gdal-2.4.4 \
	&& ./configure --with-ecw=/usr/local/hexagon --with-java=/usr/lib/jvm/default-java \
        && make \
        && make install \
	&& cd swig/java \
	&& make \
	&& make install 

RUN gdalinfo --formats | grep ECW


# Delete resources after installation
RUN rm -rf /tmp/resources

# CMD "/opt/geoserver/bin/startup.sh"
EXPOSE 8080
