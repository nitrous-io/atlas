local cjson = require "cjson"
local common = require "common"
local redis_client = require "redis_client"
local settings = require "settings"
local resolver = require "resolver"

local custom_domains_key = "n2o:custom_domains"

local host = ngx.var.host
local original_port = ngx.var.server_port

-- get redis client
local red, err = redis_client.get_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

-- get container information from redis
local custom_domain_json, err = red:hget(custom_domains_key, host..":"..original_port)
if not custom_domain_json then
  redis_client.close_client(red)
  ngx.log(ngx.ERR, "failed to get the custom domain information: ", host, err)
  return ngx.exit(404)
end

redis_client.close_client(red)

if custom_domain_json == ngx.null then
  ngx.log(ngx.ERR, "the custom domain not found: ", slug)
  return ngx.exit(404)
end

local custom_domain = cjson.decode(custom_domain_json)

-- get host ip
local host_ip = custom_domain["host_ip"]
if not host_ip then
  ngx.log(ngx.ERR, "failed to get host ip from custom_domain: ", host_ip)
  return ngx.exit(500)
end

-- get freighterd port
local freighterd_port = custom_domain["freighterd_port"]
if not freighterd_port then
  freighterd_port = 65333
end

-- get container slug
local container_slug = custom_domain["container_slug"]
if not container_slug then
  ngx.log(ngx.ERR, "failed to get container slug from custom_domain: ", container_slug)
  return ngx.exit(500)
end

-- get container port
local container_port = custom_domain["container_port"]
if not container_port then
  container_port = 3000
end

-- proxy to host's freighter
ngx.req.set_header("X-NITROUS-PROXY-CONTAINER-SLUG", container_slug)
ngx.req.set_header("X-NITROUS-PROXY-CONTAINER-PORT", container_port)
local url = host_ip..":"..freighterd_port
ngx.log(ngx.INFO, "proxying to: ", url)
ngx.var.target = url
