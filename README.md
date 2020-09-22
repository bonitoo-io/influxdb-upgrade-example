### InfluxDB V1 Upgrade process

Let's assume that we have running InfluxDB 1.X in Docker.
Configration `influxdb.conf` and `data-v1` are stored in the local directory. 
```
docker run -p 8086:8086 \
      -v $PWD/data-v1:/var/lib/influxdb \
      -v $PWD/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
      influxdb -config /etc/influxdb/influxdb.conf
```


First we need to build docker image `influxdb:dev` with latest InfluxDB `feat/upgrade` branch
```
git clone git@github.com:vlastahajek/influxdb.git
git checkout feat/upgrade
make docker-image-influx
```

Following commands will execute InfluxDB 2.0 upgrade. We need to mount volumes with v1 datafiles and config files in 
order to 
```
# create empty first, this files will be generated 
touch upgrade.log
touch influxd-upgrade-security.sh
touch influxdb.toml
mkdir data-v2

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
```
The script will perform following steps:

- creates new v2 config `$PWD/influxdb.toml` based on v1 `$PWD/influxdb.conf`
- setup InfluxDB 2.0, user `my-user` with password `my-password` and organization `my-org` and default bucket `my-bucket`
- creates `influxd-upgrade-security.sh` that will be used for migration of user privileges 
- copies and upgrades datafiles from `$PWD/data-v1` into `$PWD/data-v2` directory
- upgrade process is logged into `$PWD/upgrade.log`

Next step is to start InfluxDB v2, mount `data-v2` directory and `influxdb.toml` configuration.
```
docker run \
	--rm -d \
	--name influxdb_v2_upgraded \
	-p 8086:8086 \
	-e "INFLUXD_CONFIG_PATH=/etc/influxdb.toml" \
	-v $PWD/data-v2:/root/.influxdbv2 \
	-v $PWD/influxd-upgrade-security.sh:/root/influxd-upgrade-security.sh \
	-v $PWD/influxdb.toml:/etc/influxdb.toml \
	influxdb:dev
```
Now we have V2 instance with upgraded database.

Last optional step is apply security script that will create additional users and permissions.
```
docker exec influxdb_v2_upgraded sh /root/influxd-upgrade-security.sh
```




 
