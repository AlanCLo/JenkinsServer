# Makefile for easy docker commands

IMAGE=backupapps
NAME=backupapps
VOLUMES=-v `pwd`:/backupapps
LINKS=--link postgres:postgres
RESTART=--restart unless-stopped
DOCKER_ARGS= 


.PHONY: run stop rm clean


# Builds image
build: Dockerfile install_dependencies.sh
	docker build -t ${IMAGE} .

# Run with docker
run: 
	docker run -d -it --name ${NAME} ${VOLUMES} ${LINKS} ${RESTART} ${DOCKER_ARGS} ${IMAGE}

enter:
	docker exec -it ${NAME} /bin/bash

stop:
	docker stop ${NAME} 2> /dev/null || true

rm: stop
	docker rm ${NAME} 2> /dev/null || true

clean: rm
	docker rmi -f ${IMAGE} 2> /dev/null || true


defualt: build
