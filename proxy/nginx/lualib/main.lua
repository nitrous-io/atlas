local rocks = require "luarocks.loader"
local cjson = require "cjson"
local ltn12 = require("ltn12")

function get_redis_client()
  local redis = require "resty.redis"
  local red = redis:new()

  red:set_timeout(1000)

  local ok, err = red:connect("redisserver", 6379)
  if not ok then
    return nil, err
  end

  return red, nil
end

function get_container_slug_from_uri(uri, base_domain)
  local last, _ = string.find(uri, base_domain)
  if not last then
    return nil
  end

  local first = nil
  last = last - 1

  for i = last, 1, -1  do
    local c = uri:sub(i,i)
    if c == "." then break end
    first = i
  end

  return string.sub(uri, first, last)
end

function https_request(cafile, ip, port, path, secret)
  local https = require("ssl.https")
  local full_url = "https://"..ip..":"..port..path
  local response_body = {}
  local params = {
    url = full_url,
    protocol = "tlsv1",
    sink = ltn12.sink.table(response_body),
    options = "all",
    verify = "peer",
    cafile = cafile,
    headers = {
      ["X-Freighter-Secret"] = secret,
    },
  }
  local one, code, headers, status = https.request(params)
  ngx.log(ngx.INFO, code, ", ", status)

  return table.concat(response_body)
end

function send_with_websocket()
  local client = require "resty.websocket.client"
  local wb, err = client:new()
  if err ~= nil then
    ngx.log(ngx.INFO, "failed to create websocket client : ", err)
    return ngx.exit(500)
  end

  local uri = "ws://" .. url .. ngx.var.request_uri

  ngx.log(ngx.INFO, "Websocket. conneting to ", uri)

  local ok, err = wb:connect(uri)
  if not ok then
    ngx.log(ngx.INFO, "failed to connect: " .. err)
    return ngx.exit(500)
  end

  local data, typ, err = wb:recv_frame()
  if not data then
    ngx.log(ngx.INFO, "failed to receive the frame: ", err)
    return ngx.exit(500)
  end

  ngx.log(ngx.INFO, "received: ", data, " (", typ, "): ", err)

  local bytes, err = wb:send_text("copy: " .. data)
  if not bytes then
    ngx.log(ngx.INFO, "failed to send frame: ", err)
    return ngx.exit(500)
  end

  local bytes, err = wb:send_close()
  if not bytes then
    ngx.log(ngx.INFO, "failed to send frame: ", err)
    return ngx.exit(500)
  end

  local ok, err = wb:close()
  if err ~= nil then
    ngx.log(ngx.INFO, "failed to close websocket client : ", err)
    return ngx.exit(500)
  end
end

local base_domain = ".nitrousapp.com"
local containers_key = "n2o:containers"
local tls_domain = ".nitrouspro.com"

-- get container slug from uri
local uri = ngx.var.host
local slug = get_container_slug_from_uri(uri, base_domain)

if not slug then
  ngx.log(ngx.ERR, "failed to get slug from ", uri)
  return ngx.exit(400)
end

-- get redis client
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

-- get container info from freighter to get exposed port
local container = cjson.decode(container_json)
local host_ip = container["ip_address"]
local host_port = container["freighterd_port"]
local secret = container["secret"]
local host_uri = slug..tls_domain
local ca_path = "certs/priv.nitrouspro.crt"
local info_path = "/containers/"..container["cid"]

local response_body = https_request(ca_path, host_ip, host_port, info_path, secret)
local container_info = cjson.decode(response_body)

-- force to use 3000 for now
local port = container_info["container"]["ports"]["3000"][1]
ngx.header["X-FORWARDED-PORT"] = port
local dest_addr = host_ip..":"..port

ngx.var.target = dest_addr
