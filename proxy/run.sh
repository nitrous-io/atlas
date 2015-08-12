#!/bin/bash
# exit if any command in this script fails
set -e

# enable bash debugging
set -x

set -o pipefail

# prepare Lua config file
cat << EOF > /opt/openresty/nginx/lualib/settings.lua
  return {
    redis_database = $REDIS_DATABASE
  }
EOF

nginx -g "daemon off; error_log /dev/stderr info;"