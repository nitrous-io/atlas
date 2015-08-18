#!/bin/bash

docker-compose -f docker-compose-test.yml stop
docker-compose -f docker-compose-test.yml up -d proxy redis server0 server1

function register_server {
  server_name=$1
  server_port=$2
  cid=$(docker ps | grep luaproxyexperiment_${server_name} | awk '{print $1}')
  server_ip=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' $cid`
  json="{\"container_slug\":\"${server_name}\",\"cid\":123,\"ip_address\":\"$server_ip\",\"port_mappings\":\"{\\\"preview\\\":${server_port}}\"}"
  redis-cli -h "192.168.59.103" -n 1 hset n2o:containers ${server_name} $json
}

register_server "server0" 3000
register_server "server1" 4000

docker-compose -f docker-compose-test.yml run test "rspec"
#docker-compose -f docker-compose-test.yml stop