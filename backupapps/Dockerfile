FROM ubuntu:16.04

RUN mkdir -p /backupapps
ADD . /backupapps
WORKDIR /backupapps
RUN sh install_dependencies.sh
# Reduce resulting image size
RUN rm -rf /var/lib/app/lists/*

# Assumes the volume you mount is a clone of the repo with your stuff which will override the default
VOLUME /backupapps


CMD ["/bin/bash", "/backupapps/entry_point.sh"]
