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

ngx.log(ngx.INFO, "redirecting..... ")

local request_headers = ngx.req.get_headers()
-- check if it is websocket request
local port = 3000
if request_headers["Upgrade"] == 'websocket' or request_headers["Connection"] == 'websocket' then
  port = 28080
end

local host = "127.0.0.1"
local url = host..":"..port

ngx.var.target = url

