#!/bin/bash

docker-compose -f docker-compose-test.yml stop
docker-compose -f docker-compose-test.yml up -d proxy redis server0

for cid in $(docker ps | grep luaproxyexperiment_server | awk '{print $1}')
do
  server_ip=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $cid`
  json="{\"container_slug\":\"server0\",\"cid\":123,\"ip_address\":\"$server_ip\",\"port_mappings\":\"{\\\"preview\\\":3000}\"}"
  redis-cli -h "192.168.59.103" -n 1 hset n2o:containers server0 $json
done

docker-compose -f docker-compose-test.yml run test "rspec"