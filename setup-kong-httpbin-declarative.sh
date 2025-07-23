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

echo "🦍 Kong API Gateway + HTTPBin + Express.js Declarative Setup Script"
echo "===================================================================="
echo ""
echo "🔧 Using declarative configuration (DB-less mode)"
echo "📁 Configuration file: config/kong.yaml"
echo "🚀 Services: HTTPBin + Express.js API"
echo ""

# Step 1: Clean up any existing containers
print_step "🧹 Step 1: Cleaning up existing containers..."
docker compose down -v 2>/dev/null || true
print_success "Cleanup completed"
echo ""

# Step 2: Start HTTPBin and Express app first
print_step "🚀 Step 2: Starting HTTPBin and Express.js services..."
docker compose up -d httpbin express-app
if [ $? -ne 0 ]; then
    print_error "Failed to start backend services"
    exit 1
fi
print_success "HTTPBin and Express.js started"
echo ""

# Step 3: Start Kong with declarative configuration
print_step "🚀 Step 3: Starting Kong with declarative configuration..."
docker compose -f kong.yaml up -d kong
if [ $? -ne 0 ]; then
    print_error "Failed to start Kong"
    exit 1
fi
print_success "Kong started with declarative config"
echo ""

# Step 4: Wait for services to be ready
print_step "⏳ Step 4: Waiting for services to be ready..."
wait_for_service "http://localhost:8080/get" "HTTPBin"
wait_for_service "http://localhost:3000/" "Express.js API"
wait_for_service "http://localhost:8001/" "Kong Admin API"
echo ""

# Step 5: Verify configuration loaded
print_step "🔍 Step 5: Verifying declarative configuration..."

# Check services
services_count=$(curl -s http://localhost:8001/services | jq '.data | length')
if [ "$services_count" -gt 0 ]; then
    print_success "Services loaded: $services_count service(s)"
else
    print_error "No services found"
fi

# Check routes
routes_count=$(curl -s http://localhost:8001/routes | jq '.data | length')
if [ "$routes_count" -gt 0 ]; then
    print_success "Routes loaded: $routes_count route(s)"
else
    print_error "No routes found"
fi

# Check plugins
plugins_count=$(curl -s http://localhost:8001/plugins | jq '.data | length')
if [ "$plugins_count" -gt 0 ]; then
    print_success "Plugins loaded: $plugins_count plugin(s)"
else
    print_error "No plugins found"
fi
echo ""

# Step 6: Test the setup
print_step "🧪 Step 6: Testing the declarative setup..."

echo "Testing HTTPBin route:"
if curl -s http://localhost:8000/httpbin/get | jq .url > /dev/null 2>&1; then
    print_success "HTTPBin route working (/httpbin/get)"
else
    print_error "HTTPBin route failed"
fi

echo "Testing HTTPBin POST route:"
if curl -s -X POST http://localhost:8000/httpbin/post -d '{"test": "declarative"}' -H "Content-Type: application/json" | jq .json > /dev/null 2>&1; then
    print_success "HTTPBin POST route working (/httpbin/post)"
else
    print_error "HTTPBin POST route failed"
fi

echo "Testing Express.js API route:"
if curl -s http://localhost:8000/express/ | jq .service > /dev/null 2>&1; then
    print_success "Express.js API route working (/express/)"
else
    print_error "Express.js API route failed"
fi

echo "Testing Express.js users route:"
if curl -s http://localhost:8000/express/users | jq .users > /dev/null 2>&1; then
    print_success "Express.js users route working (/express/users)"
else
    print_error "Express.js users route failed"
fi

echo "Testing Express.js health route:"
if curl -s http://localhost:8000/express/health | jq .status > /dev/null 2>&1; then
    print_success "Express.js health route working (/express/health)"
else
    print_error "Express.js health route failed"
fi
echo ""

# Final summary
print_success "🎉 Declarative setup completed successfully!"
echo ""
echo "🎯 Services Running:"
echo "   - HTTPBin service: http://localhost:8080"
echo "   - Express.js API: http://localhost:3000"
echo "   - Kong Proxy: http://localhost:8000"
echo "   - Kong Admin API: http://localhost:8001"
echo ""
echo "🛣️  Routes Available (from config/kong.yaml):"
echo "   HTTPBin routes (prefix: /httpbin/*):"
echo "   - GET  http://localhost:8000/httpbin/get"
echo "   - POST http://localhost:8000/httpbin/post"
echo "   - Any  http://localhost:8000/httpbin/*"
echo ""
echo "   Express.js routes (prefix: /express/*):"
echo "   - GET  http://localhost:8000/express/"
echo "   - GET  http://localhost:8000/express/users"
echo "   - POST http://localhost:8000/express/users"
echo "   - GET  http://localhost:8000/express/health"
echo "   - Any  http://localhost:8000/express/*"
echo ""
echo "🔧 Plugins Enabled (from config/kong.yaml):"
echo "   - CORS: Cross-origin resource sharing (both services)"
echo "   - Rate Limiting: HTTPBin (5/min), Express.js (10/min)"
echo "   - IP Restriction: Docker network allowed"
echo "   - Request Size Limiting: 10KB max"
echo ""
echo "📋 Configuration Details:"
echo "   - Mode: DB-less (declarative)"
echo "   - Config file: config/kong.yaml"
echo "   - No database required"
echo "   - Routes and services loaded at startup"
echo ""
echo "🛑 Stop services:"
echo "   docker compose -f kong.yaml down"
echo "   docker compose down  # to stop httpbin"
