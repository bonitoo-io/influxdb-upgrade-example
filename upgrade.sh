#!/bin/bash

set -e

#delete v2 data directory
rm -rf $PWD/data-v2

# create empty files
touch upgrade.log
touch influxd-upgrade-security.sh
touch influxdb.toml

# run influxd upgrade
docker run \
	-v $PWD/data-v1:/var/lib/influxdb \
	-v $PWD/data-v2:/root/.influxdbv2 \
	-v $PWD/influxdb.conf:/root/influxdb.conf \
	-v $PWD/influxdb.toml:/root/influxdb.toml \
	-v $PWD/upgrade.log:/root/upgrade.log \
	-v $PWD/influxd-upgrade-security.sh:/root/influxd-upgrade-security.sh \
	influxdb:dev upgrade -u my-user -p my-password -o my-org -b my-bucket \
		--config-file /root/influxdb.conf

docker kill influxdb_v2_upgraded || true
docker rm influxdb_v2_upgraded || true

docker run \
	--rm \
	-d \
	--name influxdb_v2_upgraded \
	-p 8086:8086 \
	-e "INFLUXD_CONFIG_PATH=/etc/influxdb.toml" \
	-v $PWD/data-v2:/root/.influxdbv2 \
	-v $PWD/influxd-upgrade-security.sh:/root/influxd-upgrade-security.sh \
	-v $PWD/influxdb.toml:/etc/influxdb.toml \
	influxdb:dev

#wait to startup
wget -S --spider --tries=20 --retry-connrefused --waitretry=5 http://localhost:8086/ping

#add v1 users, execute generated security script
docker exec influxdb_v2_upgraded sh /root/influxd-upgrade-security.sh

echo InfluxDB 2.0 is running on http://localhost:8086

