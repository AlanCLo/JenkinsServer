#!/bin/bash

set +x

echo "Attempting to stop any running postgres instances without generating cmd error"
docker stop postgres || true && docker rm postgres || true

echo "Attempting to create data volume. No effect if named volume already exists"
docker volume create --name pgdata

docker run -d --name postgres -P -v pgdata:/var/lib/postgresql/data -e POSTGRES_PASSWORD=admin123 postgres

docker ps
