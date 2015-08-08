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

function print_table(hash)
  for key,value in pairs(hash) do
    ngx.log(ngx.INFO, "key: ", key, " value: ", value)
  end
end

-- get redis client to test
local red, err = get_redis_client()
if err ~= nil then
  ngx.log(ngx.ERR, "failed to connect to redis: ", err)
  return ngx.exit(500)
end

ngx.log(ngx.INFO, "http_host: ", ngx.var.http_host)
ngx.log(ngx.INFO, "host: ", ngx.var.host)

ngx.log(ngx.INFO, "redirecting.....")

local request_headers = ngx.req.get_headers()
-- check if it is websocket request
if request_headers["Upgrade"] == 'websocket' or request_headers["Connection"] == 'websocket' then
  -- redirect
  local port = 28080
  local host = "127.0.0.1"
  local url = host..":"..port

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

  ngx.var.target = url
else
  -- redirect
  local port = 3000
  local host = "127.0.0.1"

  local url = host..":"..port
  ngx.var.target = url
end

