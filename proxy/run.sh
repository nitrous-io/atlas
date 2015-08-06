#!/bin/bash

set -e
set -x
set -o pipefail

docker run -d --name lua-nginx \
  -v /Users/sunjinlee/workspace/lua-proxy-experiment/proxy/nginx/conf:/opt/openresty/nginx/conf \
  -v /Users/sunjinlee/workspace/lua-proxy-experiment/proxy/nginx/lualib:/opt/openresty/nginx/lualib \
  -v /Users/sunjinlee/workspace/lua-proxy-experiment/proxy/nginx/sites-enabled:/opt/openresty/nginx/sites-enabled \
  -v /Users/sunjinlee/workspace/lua-proxy-experiment/proxy/nginx/sites-available:/opt/openresty/nginx/sites-available \
  -p 4000:4000 --link=server:original.co proxy