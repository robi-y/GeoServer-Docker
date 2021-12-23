GS_PORT=8000

docker run --rm --name=geoserver_${GS_PORT} -p ${GS_PORT}:8080 -d -v $HOME/geoserver_data:/opt/geoserver/data_dir -e "HTTP_MAX_HEADER_SIZE=524288" -t thinkwhere/geoserver:2.20.1 /bin/sh -c conf/update_tomcat_settings.sh
