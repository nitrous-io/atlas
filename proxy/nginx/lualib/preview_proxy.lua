local cjson = require "cjson"
local common = require "common"
local redis_client = require "redis_client"
local settings = require "settings"
local resolver = require "resolver"

local containers_key = "n2o:containers"
local preview_forwared_ports = { ["80"] = true, ["443"] = true }

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
  if not answers or err ~= nil then
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
    ngx.log(ngx.ERR, "failed to get slug from: ", uri)
  end
end

-- get redis client to test
local red, err = redis_client.get_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

-- get container information from redis
local container_json, err = red:hget(containers_key, slug)
if not container_json then
  ngx.log(ngx.ERR, "failed to get the container: ", slug, err)
  return ngx.exit(404)
end

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

-- get port mappings
if container["port_mappings"] == nil then
  ngx.log(ngx.ERR, "the container's port mapping is empty: ", slug)
  return ngx.exit(500)
end

-- 1. Incoming port is 80 or 443, uses preview
-- 2. If there is no preview port or incoming port 80 nor 443, use incomning port
local port_mappings = cjson.decode(container["port_mappings"])
local port
if preview_forwared_ports[ngx.var.server_port] ~= nil then
  port = port_mappings["preview"]
end

if port == nil then
  port = port_mappings[ngx.var.server_port]
end

if port == nil then
  ngx.log(ngx.ERR, "failed to find a port mapping for: ", ngx.var.server_port)
  return ngx.exit(502)
end

local url = host_ip..":"..port
ngx.log(ngx.INFO, "redirecting to: ", url)
ngx.var.target = url

