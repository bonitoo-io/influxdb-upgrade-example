#!/bin/bash
docker run -p 8086:8086 \
      -v $PWD/data-v1:/var/lib/influxdb \
      -v $PWD/influxdb.conf:/etc/influxdb/influxdb.conf:ro \
      influxdb -config /etc/influxdb/influxdb.conf
