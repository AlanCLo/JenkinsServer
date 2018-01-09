#!/bin/sh

USER=postgres
HOST=postgres
PSQL="psql -h ${HOST} -U ${USER}"

$PSQL <<EOF
CREATE DATABASE demo_prod TEMPLATE template0;
CREATE TABLE demo_table (id integer);
INSERT INTO demo_table VALUES(1);
EOF

