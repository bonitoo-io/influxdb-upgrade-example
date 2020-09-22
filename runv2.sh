#!/bin/bash

docker run \
	--rm \
	--name influxdb_v2_upgraded \
	-p 8086:8086 \
	-e "INFLUXD_CONFIG_PATH=/etc/influxdb.toml" \
	-v $PWD/data-v2:/root/.influxdbv2 \
	-v $PWD/influxdb.toml:/etc/influxdb.toml \
	influxdb:dev
	
	
	