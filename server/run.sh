#!/bin/bash

set -e
set -x
set -o pipefail

docker run -d --name server \
  -p 3000:3000 server