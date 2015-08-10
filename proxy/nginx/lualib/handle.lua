local base_domain = ".nitrousapp.com"
local containers_key = "n2o:containers"
local preview_forwared_ports = { ["80"] = true, ["433"] = true }

local cjson = require "cjson"

-- To get redis client
function get_redis_client()
  local redis = require "resty.redis"
  local red = redis:new()

  red:set_timeout(1000)

  local ok, err = red:connect("127.0.0.1", 6379)
  if not ok then
    return nil, err
  end

  return red, nil
end

-- To parse container slug from url
function get_container_slug_from_uri(uri, base_domain)
  local last, _ = string.find(uri, base_domain)
  if not last then
    return nil
  end

  local first
  last = last - 1

  for i = last, 1, -1  do
    local c = uri:sub(i,i)
    if c == "." then break end
    first = i
  end

  return string.sub(uri, first, last)
end

function print_table(hash)
  for key,value in pairs(hash) do
    ngx.log(ngx.INFO, "key: ", key, " value: ", value)
  end
end

function split(value, delimiter)
  local words = {}
  local index = 1
  for word in string.gmatch(value, delimiter) do
    words[index] = word
    index = index + 1
  end

  return words
end

function isWebsocket()
  local request_headers = ngx.req.get_headers()
  if request_headers["Upgrade"] == 'websocket' and request_headers["Connection"] == 'upgrade' then
    return true
  end
  return false
end

-- get container slug from uri
local uri = ngx.var.host
local slug = get_container_slug_from_uri(uri, base_domain)

if not slug then
  ngx.log(ngx.ERR, "failed to get slug from: ", uri)
  return ngx.exit(400)
end

-- get redis client to test
local red, err = get_redis_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

-- get container information from redis
local container_json, err = red:hget(containers_key, slug)
if not container_json then
  ngx.log(ngx.ERR, "the container does not exist: ", slug, err)
  return ngx.exit(404)
end
local container = cjson.decode(container_json)

-- get host ip
local host_ip = container["ip_address"]
if not host_ip then
  ngx.log(ngx.ERR, "failed to get host ip from container: ", container["slug"])
  return ngx.exit(403)
end

-- get port mappings
if container["port_mappings"] == nil then
  ngx.log(ngx.ERR, "the container does not have port mappings: ", container["slug"])
  return ngx.exit(403)
end

-- 1. Incoming port is 80 or 443, uses preview
-- 2. If there is no preview port or incoming port 80 nor 443, use incomning port
ngx.log(ngx.INFO, "server port: ", ngx.var.server_port)
local port_mappings = cjson.decode(container["port_mappings"])
local port
if preview_forwared_ports[ngx.var.server_port] ~= nil then
  port = port_mappings["preview"]
end

if port == nil then
  port = port_mappings[ngx.var.server_port]
end

if port == nil then
  ngx.log(ngx.ERR, "failed to find a port mapping for : ", ngx.var.server_port)
  return ngx.exit(404)
end

local url = host_ip..":"..port
ngx.var.target = url

