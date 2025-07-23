local typedefs = require "kong.db.schema.typedefs"

return {
  name = "request-response-logger",
  fields = {
    { consumer = typedefs.no_consumer },
    { protocols = typedefs.protocols_http },
    { config = {
        type = "record",
        fields = {
          { log_endpoint = {
              type = "string",
              required = true,
              default = "http://express-app:3000/logs"
          }},
          { timeout = {
              type = "number",
              default = 10000
          }},
          { keepalive = {
              type = "number",
              default = 60000
          }},
          { log_request_body = {
              type = "boolean",
              default = true
          }},
          { log_response_body = {
              type = "boolean",
              default = true
          }},
          { max_body_size = {
              type = "number",
              default = 1024
          }}
        }
    }}
  }
}
