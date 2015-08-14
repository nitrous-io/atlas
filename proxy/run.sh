#!/bin/bash
# exit if any command in this script fails
set -e

# enable bash debugging
set -x

set -o pipefail

# prepare Lua config file
cat << EOF > /opt/openresty/nginx/lualib/settings.lua
return {
  redis_host              = "$REDIS_HOST",
  redis_port              = "$REDIS_PORT",
  redis_timeout           = "$REDIS_TIMEOUT",
  redis_database          = $REDIS_DATABASE,
  container_base_domain   = "$CONTAINER_BASE_DOMAIN",
  host_base_domain        = "$HOST_BASE_DOMAIN"
}
EOF

nginx -g "daemon off; error_log /dev/stderr info;"