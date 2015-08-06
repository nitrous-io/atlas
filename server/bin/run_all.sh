#!/bin/bash

set -e
set -x
set -o pipefail

service redis_6379 start

cd /opt/server && ./bin/cable &
cd /opt/server && rails server --binding=0.0.0.0 --port=3000