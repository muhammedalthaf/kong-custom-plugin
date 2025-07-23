local http = require "resty.http"
local cjson = require "cjson"

local RequestResponseLoggerHandler = {}

RequestResponseLoggerHandler.PRIORITY = 1000
RequestResponseLoggerHandler.VERSION = "1.0.0"

-- Helper function to truncate body if too large
local function truncate_body(body, max_size)
  if not body then
    return ""
  end
  
  local body_str = tostring(body)
  if #body_str > max_size then
    return body_str:sub(1, max_size) .. "... [truncated]"
  end
  return body_str
end

-- Helper function to safely convert headers to table
local function headers_to_table(headers)
  local result = {}
  if headers then
    for name, value in pairs(headers) do
      result[name] = value
    end
  end
  return result
end

-- Helper function to send log asynchronously
local function send_log_async(log_endpoint, log_data, timeout, keepalive)
  local httpc = http.new()
  httpc:set_timeout(timeout)
  
  local ok, err = httpc:request_uri(log_endpoint, {
    method = "POST",
    body = cjson.encode(log_data),
    headers = {
      ["Content-Type"] = "application/json",
      ["User-Agent"] = "Kong-Request-Response-Logger/1.0.0"
    },
    keepalive_timeout = keepalive,
    keepalive_pool = 10
  })
  
  if not ok then
    kong.log.err("Failed to send log to ", log_endpoint, ": ", err)
  else
    kong.log.debug("Successfully sent log to ", log_endpoint)
  end
  
  httpc:close()
end

function RequestResponseLoggerHandler:access(conf)
  -- Store request data in context for later use
  local ctx = kong.ctx.plugin
  
  -- Capture request data
  ctx.request_data = {
    url = kong.request.get_scheme() .. "://" .. kong.request.get_host() .. 
          (kong.request.get_port() ~= 80 and kong.request.get_port() ~= 443 
           and ":" .. kong.request.get_port() or "") .. 
          kong.request.get_path_with_query(),
    method = kong.request.get_method(),
    headers = headers_to_table(kong.request.get_headers())
  }
  
  -- Capture request body if enabled
  if conf.log_request_body then
    local body = kong.request.get_raw_body()
    ctx.request_data.body = truncate_body(body, conf.max_body_size)
  else
    ctx.request_data.body = "[body logging disabled]"
  end
  
  -- Store config for later use
  ctx.config = conf
end

function RequestResponseLoggerHandler:header_filter(conf)
  -- Store response headers in context
  local ctx = kong.ctx.plugin
  if not ctx.response_data then
    ctx.response_data = {}
  end
  
  ctx.response_data.status_code = kong.response.get_status()
  ctx.response_data.headers = headers_to_table(kong.response.get_headers())
end

function RequestResponseLoggerHandler:body_filter(conf)
  -- Capture response body
  local ctx = kong.ctx.plugin
  if not ctx.response_data then
    ctx.response_data = {}
  end
  
  if conf.log_response_body then
    local chunk = kong.response.get_raw_body()
    if chunk then
      if not ctx.response_data.body then
        ctx.response_data.body = ""
      end
      ctx.response_data.body = ctx.response_data.body .. chunk
    end
  else
    ctx.response_data.body = "[body logging disabled]"
  end
end

function RequestResponseLoggerHandler:log(conf)
  local ctx = kong.ctx.plugin
  
  -- Ensure we have both request and response data
  if not ctx.request_data or not ctx.response_data then
    kong.log.warn("Missing request or response data for logging")
    return
  end
  
  -- Truncate response body if needed
  if conf.log_response_body and ctx.response_data.body then
    ctx.response_data.body = truncate_body(ctx.response_data.body, conf.max_body_size)
  end
  
  -- Prepare log data in the required format
  local log_data = {
    request = ctx.request_data,
    response = ctx.response_data
  }
  
  -- Send log asynchronously using ngx.timer
  local ok, err = ngx.timer.at(0, function()
    send_log_async(conf.log_endpoint, log_data, conf.timeout, conf.keepalive)
  end)
  
  if not ok then
    kong.log.err("Failed to create timer for async logging: ", err)
  end
end

return RequestResponseLoggerHandler
