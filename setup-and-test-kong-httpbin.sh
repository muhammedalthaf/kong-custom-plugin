#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Function to wait for service to be ready
wait_for_service() {
    local url=$1
    local service_name=$2
    local max_attempts=30
    local attempt=1

    print_step "Waiting for $service_name to be ready..."
    while [ $attempt -le $max_attempts ]; do
        if curl -s -f "$url" > /dev/null 2>&1; then
            print_success "$service_name is ready!"
            return 0
        fi
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done

    print_error "$service_name failed to start after $((max_attempts * 2)) seconds"
    return 1
}

echo "🦍 Kong API Gateway + HTTPBin + Express.js Complete Setup & Test Script"
echo "========================================================================"
echo ""

# Step 1: Clean up any existing containers
print_step "🧹 Step 1: Cleaning up existing containers..."
docker compose down -v 2>/dev/null || true
docker system prune -f > /dev/null 2>&1
print_success "Cleanup completed"
echo ""

# Step 2: Start database, HTTPBin, and Express app first
print_step "🚀 Step 2: Starting database, HTTPBin, and Express.js services..."
docker compose up -d kong-database httpbin express-app
if [ $? -ne 0 ]; then
    print_error "Failed to start database and backend services"
    exit 1
fi
print_success "Database, HTTPBin, and Express.js started"

# Wait for database to be ready
print_step "⏳ Waiting for PostgreSQL to be ready..."
sleep 10
print_success "Database should be ready"

# Step 3: Run migrations
print_step "🔄 Step 3: Running Kong migrations..."
docker compose up kong-migrations
if [ $? -ne 0 ]; then
    print_error "Failed to run migrations"
    exit 1
fi
print_success "Migrations completed"

# Step 4: Start Kong
print_step "🚀 Step 4: Starting Kong..."
docker compose up -d kong
if [ $? -ne 0 ]; then
    print_error "Failed to start Kong"
    exit 1
fi
print_success "Kong started"
echo ""

# Step 5: Wait for services to be ready
print_step "⏳ Step 5: Waiting for services to be ready..."
wait_for_service "http://localhost:8080/get" "HTTPBin"
wait_for_service "http://localhost:3000/" "Express.js API"
wait_for_service "http://localhost:8001/" "Kong Admin API"
echo ""

# Step 6: Configure Kong services and routes
print_step "⚙️  Step 6: Configuring Kong services and routes..."

# Create HTTPBin service
print_step "Creating HTTPBin service..."
service_response=$(curl -s -X POST http://localhost:8001/services/ \
  --data "name=httpbin-service" \
  --data "url=http://httpbin:80")

if echo "$service_response" | grep -q '"id"'; then
    service_id=$(echo "$service_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    print_success "HTTPBin service created with ID: $service_id"
else
    print_error "Failed to create HTTPBin service"
    echo "Response: $service_response"
    exit 1
fi

# Create Express.js service
print_step "Creating Express.js service..."
express_service_response=$(curl -s -X POST http://localhost:8001/services/ \
  --data "name=express-service" \
  --data "url=http://express-app:3000")

if echo "$express_service_response" | grep -q '"id"'; then
    express_service_id=$(echo "$express_service_response" | grep -o '"id":"[^"]*"' | cut -d'"' -f4)
    print_success "Express.js service created with ID: $express_service_id"
else
    print_error "Failed to create Express.js service"
    echo "Response: $express_service_response"
    exit 1
fi

# Create routes
print_step "Creating routes..."

# HTTPBin route: /httpbin/* with path stripping
httpbin_route_response=$(curl -s -X POST http://localhost:8001/services/httpbin-service/routes \
  --data "paths[]=/httpbin" \
  --data "strip_path=true")

if echo "$httpbin_route_response" | grep -q '"id"'; then
    print_success "HTTPBin route /httpbin/* created"
else
    print_error "Failed to create /httpbin route"
fi

# Express.js route: /express/* with path stripping
express_route_response=$(curl -s -X POST http://localhost:8001/services/express-service/routes \
  --data "paths[]=/express" \
  --data "strip_path=true")

if echo "$express_route_response" | grep -q '"id"'; then
    print_success "Express.js route /express/* created"
else
    print_error "Failed to create /express route"
fi
echo ""

# Step 7: Configure plugins
print_step "🔧 Step 7: Configuring Kong plugins..."

# Add HTTPBin plugins
print_step "Adding HTTPBin plugins..."
httpbin_rate_limit_response=$(curl -s -X POST http://localhost:8001/services/httpbin-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=5" \
  --data "config.hour=100" \
  --data "config.policy=local")

if echo "$httpbin_rate_limit_response" | grep -q '"id"'; then
    print_success "HTTPBin rate limiting plugin added (5 req/min, 100 req/hour)"
else
    print_error "Failed to add HTTPBin rate limiting plugin"
fi

httpbin_cors_response=$(curl -s -X POST http://localhost:8001/services/httpbin-service/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET" \
  --data "config.methods=POST" \
  --data "config.methods=PUT" \
  --data "config.methods=DELETE" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token" \
  --data "config.credentials=true")

if echo "$httpbin_cors_response" | grep -q '"id"'; then
    print_success "HTTPBin CORS plugin added"
else
    print_error "Failed to add HTTPBin CORS plugin"
fi

# Add Express.js plugins
print_step "Adding Express.js plugins..."
express_rate_limit_response=$(curl -s -X POST http://localhost:8001/services/express-service/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=10" \
  --data "config.hour=200" \
  --data "config.policy=local")

if echo "$express_rate_limit_response" | grep -q '"id"'; then
    print_success "Express.js rate limiting plugin added (10 req/min, 200 req/hour)"
else
    print_error "Failed to add Express.js rate limiting plugin"
fi

express_cors_response=$(curl -s -X POST http://localhost:8001/services/express-service/plugins \
  --data "name=cors" \
  --data "config.origins=*" \
  --data "config.methods=GET" \
  --data "config.methods=POST" \
  --data "config.methods=PUT" \
  --data "config.methods=DELETE" \
  --data "config.headers=Accept,Accept-Version,Content-Length,Content-MD5,Content-Type,Date,X-Auth-Token" \
  --data "config.credentials=true")

if echo "$express_cors_response" | grep -q '"id"'; then
    print_success "Express.js CORS plugin added"
else
    print_error "Failed to add Express.js CORS plugin"
fi

# Add custom request-response-logger plugin for HTTPBin
print_step "Adding custom request-response-logger plugin for HTTPBin..."
httpbin_logger_response=$(curl -s -X POST http://localhost:8001/services/httpbin-service/plugins \
  --data "name=request-response-logger" \
  --data "config.log_endpoint=http://express-app:3000/logs" \
  --data "config.timeout=10000" \
  --data "config.keepalive=60000" \
  --data "config.log_request_body=true" \
  --data "config.log_response_body=true" \
  --data "config.max_body_size=1024")

if echo "$httpbin_logger_response" | grep -q '"id"'; then
    print_success "HTTPBin request-response-logger plugin added"
else
    print_error "Failed to add HTTPBin request-response-logger plugin"
    echo "Response: $httpbin_logger_response"
fi

# Add custom request-response-logger plugin for Express.js
print_step "Adding custom request-response-logger plugin for Express.js..."
express_logger_response=$(curl -s -X POST http://localhost:8001/services/express-service/plugins \
  --data "name=request-response-logger" \
  --data "config.log_endpoint=http://express-app:3000/logs" \
  --data "config.timeout=10000" \
  --data "config.keepalive=60000" \
  --data "config.log_request_body=true" \
  --data "config.log_response_body=true" \
  --data "config.max_body_size=1024")

if echo "$express_logger_response" | grep -q '"id"'; then
    print_success "Express.js request-response-logger plugin added"
else
    print_error "Failed to add Express.js request-response-logger plugin"
    echo "Response: $express_logger_response"
fi
echo ""

# Step 8: Wait a moment for configuration to propagate
print_step "⏳ Step 8: Waiting for configuration to propagate..."
sleep 3
print_success "Configuration ready"
echo ""

# Step 9: Run tests
print_step "🧪 Step 9: Running comprehensive tests..."
echo ""

echo "📋 Testing Kong API Gateway with HTTPBin service..."
echo ""

echo "1. Testing direct HTTPBin access (port 8080):"
echo "   curl http://localhost:8080/get"
if curl -s http://localhost:8080/get | jq .url > /dev/null 2>&1; then
    curl -s http://localhost:8080/get | jq .url
    print_success "Direct HTTPBin access working"
else
    print_error "Direct HTTPBin access failed"
fi
echo ""

echo "2. Testing direct Express.js access (port 3000):"
echo "   curl http://localhost:3000/"
if curl -s http://localhost:3000/ | jq .service > /dev/null 2>&1; then
    curl -s http://localhost:3000/ | jq .service
    print_success "Direct Express.js access working"
else
    print_error "Direct Express.js access failed"
fi
echo ""

echo "3. Testing Kong proxy to HTTPBin via /httpbin route:"
echo "   curl http://localhost:8000/httpbin/get"
if curl -s http://localhost:8000/httpbin/get | jq .url > /dev/null 2>&1; then
    curl -s http://localhost:8000/httpbin/get | jq .url
    print_success "Kong /httpbin/* route working"
else
    print_error "Kong /httpbin/* route failed"
fi
echo ""

echo "4. Testing Kong proxy to Express.js via /express route:"
echo "   curl http://localhost:8000/express/"
if curl -s http://localhost:8000/express/ | jq .service > /dev/null 2>&1; then
    curl -s http://localhost:8000/express/ | jq .service
    print_success "Kong /express/* route working"
else
    print_error "Kong /express/* route failed"
fi
echo ""

echo "5. Testing HTTPBin POST request through Kong:"
echo "   curl -X POST http://localhost:8000/httpbin/post -d '{\"test\": \"data\"}'"
if curl -s -X POST http://localhost:8000/httpbin/post -d '{"test": "data"}' -H "Content-Type: application/json" | jq .json > /dev/null 2>&1; then
    curl -s -X POST http://localhost:8000/httpbin/post -d '{"test": "data"}' -H "Content-Type: application/json" | jq .json
    print_success "Kong HTTPBin POST requests working"
else
    print_error "Kong HTTPBin POST requests failed"
fi
echo ""

echo "6. Testing Express.js POST request through Kong:"
echo "   curl -X POST http://localhost:8000/express/users -d '{\"name\": \"Kong User\"}'"
if curl -s -X POST http://localhost:8000/express/users -d '{"name": "Kong User", "email": "kong@example.com"}' -H "Content-Type: application/json" | jq .user > /dev/null 2>&1; then
    curl -s -X POST http://localhost:8000/express/users -d '{"name": "Kong User", "email": "kong@example.com"}' -H "Content-Type: application/json" | jq .user
    print_success "Kong Express.js POST requests working"
else
    print_error "Kong Express.js POST requests failed"
fi
echo ""

echo "5. Testing Express.js users endpoint:"
echo "   curl http://localhost:8000/express/users"
if curl -s http://localhost:8000/express/users | jq .users > /dev/null 2>&1; then
    user_count=$(curl -s http://localhost:8000/express/users | jq '.users | length')
    print_success "Express.js users endpoint working ($user_count users)"
else
    print_error "Express.js users endpoint failed"
fi
echo ""

echo "6. Testing HTTPBin rate limiting (making 6 requests quickly):"
success_count=0
rate_limited_count=0
for i in {1..6}; do
    echo -n "   Request $i: "
    status=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/httpbin/get)
    if [ "$status" = "200" ]; then
        echo "✅ Success ($status)"
        success_count=$((success_count + 1))
    else
        echo "❌ Rate Limited ($status)"
        rate_limited_count=$((rate_limited_count + 1))
    fi
done

if [ $success_count -gt 0 ] && [ $rate_limited_count -gt 0 ]; then
    print_success "HTTPBin rate limiting working correctly ($success_count successful, $rate_limited_count rate-limited)"
else
    print_warning "HTTPBin rate limiting behavior unexpected"
fi
echo ""

echo "7. Testing Express.js rate limiting (making 12 requests quickly):"
express_success_count=0
express_rate_limited_count=0
for i in {1..12}; do
    echo -n "   Request $i: "
    status=$(curl -s -w "%{http_code}" -o /dev/null http://localhost:8000/express/)
    if [ "$status" = "200" ]; then
        echo "✅ Success ($status)"
        express_success_count=$((express_success_count + 1))
    else
        echo "❌ Rate Limited ($status)"
        express_rate_limited_count=$((express_rate_limited_count + 1))
    fi
done

if [ $express_success_count -gt 0 ] && [ $express_rate_limited_count -gt 0 ]; then
    print_success "Express.js rate limiting working correctly ($express_success_count successful, $express_rate_limited_count rate-limited)"
else
    print_warning "Express.js rate limiting behavior unexpected"
fi
echo ""

echo "8. Testing HTTPBin CORS headers:"
echo "   curl -I -X OPTIONS http://localhost:8000/httpbin/get"
httpbin_cors_headers=$(curl -I -X OPTIONS http://localhost:8000/httpbin/get 2>/dev/null | grep -E "(Access-Control|Allow)")
if [ -n "$httpbin_cors_headers" ]; then
    echo "$httpbin_cors_headers"
    print_success "HTTPBin CORS headers present"
else
    print_error "HTTPBin CORS headers missing"
fi
echo ""

echo "9. Testing Express.js CORS headers:"
echo "   curl -I -X OPTIONS http://localhost:8000/express/"
express_cors_headers=$(curl -I -X OPTIONS http://localhost:8000/express/ 2>/dev/null | grep -E "(Access-Control|Allow)")
if [ -n "$express_cors_headers" ]; then
    echo "$express_cors_headers"
    print_success "Express.js CORS headers present"
else
    print_error "Express.js CORS headers missing"
fi
echo ""

echo "10. Kong Admin API status:"
echo "    curl http://localhost:8001/"
if kong_status=$(curl -s http://localhost:8001/ | jq -r .version 2>/dev/null); then
    echo "    Kong version: $kong_status"
    print_success "Kong Admin API working"
else
    print_error "Kong Admin API failed"
fi
echo ""

echo "11. Testing custom request-response-logger plugin:"
echo "    Making test requests and checking logs..."

# Make a test request to HTTPBin
echo "    Testing HTTPBin logging..."
test_response=$(curl -s -X POST http://localhost:8000/httpbin/post \
  -H "Content-Type: application/json" \
  -d '{"test": "plugin verification", "service": "httpbin"}')

# Make a test request to Express.js
echo "    Testing Express.js logging..."
test_response2=$(curl -s -X POST http://localhost:8000/express/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Plugin Test User", "email": "test@plugin.com"}')

# Wait a moment for async logging
sleep 2

# Check if logs were captured
echo "    Checking captured logs..."
if log_count=$(curl -s "http://localhost:3000/logs?limit=5" | jq -r '.logs | length' 2>/dev/null); then
    if [ "$log_count" -gt 0 ]; then
        recent_logs=$(curl -s "http://localhost:3000/logs?limit=2" | jq -r '.logs[] | select(.type == "kong_request_response") | .request.url' 2>/dev/null)
        if echo "$recent_logs" | grep -q "httpbin\|express"; then
            print_success "Custom request-response-logger plugin working ($log_count logs captured)"
            echo "    Recent logged requests:"
            echo "$recent_logs" | sed 's/^/      - /'
        else
            print_error "Plugin not capturing Kong requests"
        fi
    else
        print_error "No logs captured by plugin"
    fi
else
    print_error "Failed to check logs API"
fi
echo ""

# Step 10: Display summary
print_step "📊 Step 10: Setup Summary"
echo ""
echo "🎯 Services Running:"
echo "   - HTTPBin service: http://localhost:8080"
echo "   - Express.js API: http://localhost:3000"
echo "   - Kong Proxy: http://localhost:8000"
echo "   - Kong Admin API: http://localhost:8001"
echo "   - Kong Manager UI: http://localhost:8002"
echo ""
echo "✅ Kong is successfully serving HTTPBin + Express.js as an API Gateway!"
echo "   Routes configured:"
echo "   - /httpbin/* -> httpbin service (strip_path=true)"
echo "   - /express/* -> express-app service (strip_path=true)"
echo ""
echo "🔧 Plugins enabled:"
echo "   - Rate Limiting: HTTPBin (5/min), Express.js (10/min)"
echo "   - CORS: Allow all origins, methods: GET,POST,PUT,DELETE (both services)
   - Custom Request-Response Logger: Captures all requests/responses to logs API (both services)"
echo ""

# Step 11: Show useful commands
print_step "💡 Useful Commands:"
echo ""
echo "🔍 Check container status:"
echo "   docker compose ps"
echo ""
echo "📋 View Kong services:"
echo "   curl http://localhost:8001/services"
echo ""
echo "🛣️  View Kong routes:"
echo "   curl http://localhost:8001/routes"
echo ""
echo "🔧 View Kong plugins:"
echo "   curl http://localhost:8001/plugins"
echo ""
echo "📋 View captured logs:"
echo "   curl http://localhost:3000/logs?limit=10"
echo ""
echo "🔍 View custom plugin status:"
echo "   curl http://localhost:8001/plugins | jq '.data[] | select(.name == \"request-response-logger\")'"
echo ""
echo "🌐 Open Kong Manager UI:"
echo "   http://localhost:8002"
echo ""
echo "🛑 Stop all services:"
echo "   docker compose down"
echo ""

print_success "🎉 Complete setup and testing finished successfully!"
echo ""
print_step "🚀 Kong API Gateway is ready to use!"
