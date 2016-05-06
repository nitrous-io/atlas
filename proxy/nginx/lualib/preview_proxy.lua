local cjson = require "cjson"
local common = require "common"
local redis_client = require "redis_client"
local settings = require "settings"
local resolver = require "resolver"

local containers_key = "n2o:containers"

-- get container slug from uri
local uri = ngx.var.host
local slug = common.get_slug_from_uri(uri, settings.container_base_domain)

if not slug then
  r, err = resolver.get()
  if not r then
    ngx.log(ngx.ERR, "failed to instantiate the resolver: ", err)
    return ngx.exit(500)
  end

  local answers, err = r:query(uri, {qtype = r.TYPE_CNAME})
  if not answers or not answers[1] or err ~= nil then
    ngx.log(ngx.ERR, "failed to query the DNS server: ", err)
    return ngx.exit(404)
  end

  if answers.errcode then
    ngx.log(ngx.ERR, "server returned error code: ", answers.errcode, ": ", answers.errstr)
    return ngx.exit(404)
  end

  ngx.log(ngx.INFO, "proxy to: ", answers[1].cname)
  slug = common.get_slug_from_uri(answers[1].cname, settings.container_base_domain)
  if not slug then
    ngx.log(ngx.ERR, "failed to get container slug from: ", uri)
  end
end

-- get redis client
local red, err = redis_client.get_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

-- get container information from redis
local container_json, err = red:hget(containers_key, slug)
if not container_json then
  redis_client.close_client(red)
  ngx.log(ngx.ERR, "failed to get the container: ", slug, err)
  return ngx.exit(404)
end

redis_client.close_client(red)

if container_json == ngx.null then
  ngx.log(ngx.ERR, "the container not found: ", slug)
  return ngx.exit(404)
end

local container = cjson.decode(container_json)

-- get host ip
local host_ip = container["ip_address"]
if not host_ip then
  ngx.log(ngx.ERR, "failed to get host ip from container: ", slug)
  return ngx.exit(500)
end

-- get freighter port
local freighterd_port = container["freighterd_port"]
if not freighterd_port then
  freighterd_port = 65333
end

-- get container port
local container_port = ngx.var.server_port
if container_port == '80' or container_port == '443' then
  container_port = '3000'
end

-- proxy to host's freighter
ngx.req.set_header("X-NITROUS-PROXY-CONTAINER-PROTO", ngx.var.scheme)
ngx.req.set_header("X-NITROUS-PROXY-CONTAINER-SLUG", slug)
ngx.req.set_header("X-NITROUS-PROXY-CONTAINER-PORT", container_port)
local url = host_ip..":"..freighterd_port
ngx.log(ngx.INFO, "proxying to: ", url)
ngx.var.target = url
