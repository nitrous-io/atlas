local cjson = require "cjson"
local common = require "common"
local redis_client = require "redis_client"
local hosts_key = "n2o:hosts"
local settings = require "settings"

-- get host slug from uri
local uri = ngx.var.host
local slug = common.get_slug_from_uri(uri, settings.host_base_domain)

if not slug then
  ngx.log(ngx.ERR, "failed to get slug from: ", uri)
  return ngx.exit(404)
end

-- get redis client to test
local red, err = redis_client.get_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

-- get host information from redis
local host_json, err = red:hget(hosts_key, slug)
if not host_json then
  ngx.log(ngx.ERR, "failed to get host: ", slug, err)
  redis_client.close_client(red)
  return ngx.exit(404)
end

redis_client.close_client(red)

if host_json == ngx.null then
  ngx.log(ngx.ERR, "the host not found: ", slug)
  return ngx.exit(404)
end

local host = cjson.decode(host_json)

-- get host ip
local host_ip = host["ip_address"]
if not host_ip then
  ngx.log(ngx.ERR, "failed to get host ip: ", slug)
  return ngx.exit(404)
end

-- get freighter port
local port = host["freighterd_port"]
if not port then
  ngx.log(ngx.ERR, "the host does not have freighterd_port: ", slug)
  return ngx.exit(404)
end

ngx.header["X-FORWARDED-PORT"] = port
local url = host_ip..":"..port
ngx.log(ngx.INFO, "redirecting to: ", url)
ngx.var.target = url

