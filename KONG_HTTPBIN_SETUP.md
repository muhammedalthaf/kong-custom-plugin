# Kong API Gateway + HTTPBin Setup

## 🎯 Overview
Successfully set up Kong API Gateway with HTTPBin service to demonstrate API gateway functionality.

## 🏗️ Architecture
```
Client → Kong API Gateway (Port 8000) → HTTPBin Service (Port 8080)
```

## 📦 Services Running
- **HTTPBin**: `http://localhost:8080` - HTTP testing service
- **Kong Proxy**: `http://localhost:8000` - API Gateway proxy
- **Kong Admin API**: `http://localhost:8001` - Kong management API
- **Kong Manager UI**: `http://localhost:8002` - Web-based management interface
- **PostgreSQL**: `localhost:5432` - Kong database

## 🛣️ Routes Configured

### 1. HTTPBin Route (`/httpbin/*`)
- **Path**: `/httpbin/*`
- **Target**: HTTPBin service
- **Strip Path**: `true` (removes `/httpbin` prefix)
- **Example**: `GET http://localhost:8000/httpbin/get` → `httpbin/get`

### 2. Direct GET Route (`/get`)
- **Path**: `/get`
- **Target**: HTTPBin service
- **Strip Path**: `false` (preserves path)
- **Example**: `GET http://localhost:8000/get` → `httpbin/get`

### 3. Direct POST Route (`/post`)
- **Path**: `/post`
- **Target**: HTTPBin service
- **Strip Path**: `false` (preserves path)
- **Example**: `POST http://localhost:8000/post` → `httpbin/post`

## 🔧 Plugins Enabled

### 1. Rate Limiting Plugin
- **Limit**: 5 requests per minute, 100 requests per hour
- **Policy**: Local (in-memory)
- **Response**: HTTP 429 when limit exceeded
- **Headers**: Adds rate limit headers to responses

### 2. CORS Plugin
- **Origins**: `*` (all origins allowed)
- **Methods**: `GET`, `POST`, `PUT`, `DELETE`
- **Headers**: Standard headers allowed
- **Credentials**: Enabled

## 🧪 Testing Results

### ✅ Successful Tests
1. **Direct HTTPBin Access**: ✅ Working on port 8080
2. **Kong Proxy Routes**: ✅ All routes working correctly
3. **Rate Limiting**: ✅ Blocks requests after 5/minute
4. **CORS Headers**: ✅ Proper CORS headers added
5. **POST Requests**: ✅ JSON data passed through correctly
6. **Kong Manager UI**: ✅ Accessible at port 8002

### 📊 Rate Limiting Demonstration
- Requests 1-2: ✅ Success (200)
- Requests 3-6: ❌ Rate Limited (429)

## 🚀 How to Use

### 🎯 Quick Start (Recommended)
```bash
# Complete setup from scratch (includes cleanup, setup, and testing)
./setup-and-test-kong-httpbin.sh
```

### 🔧 Setup Only
```bash
# Setup services and configuration only (no testing)
./setup-kong-httpbin.sh
```

### 🧪 Manual Testing
```bash
# Test individual endpoints
curl http://localhost:8000/get
curl -X POST http://localhost:8000/post -d '{"test": "data"}' -H "Content-Type: application/json"
curl http://localhost:8000/httpbin/get

# Test rate limiting (make multiple requests quickly)
for i in {1..6}; do curl -w "Status: %{http_code}\n" -o /dev/null -s http://localhost:8000/get; done
```

### 🌐 Access Management Interfaces
- **Kong Manager UI**: http://localhost:8002
- **Kong Admin API**: http://localhost:8001
- **HTTPBin Direct**: http://localhost:8080

### 🛑 Stop Services
```bash
docker compose down
```

### 📋 Check Status
```bash
# View running containers
docker compose ps

# View Kong services
curl http://localhost:8001/services

# View Kong routes
curl http://localhost:8001/routes

# View Kong plugins
curl http://localhost:8001/plugins
```

## 📁 Files Modified/Created
- `docker-compose.yml` - Added HTTPBin service and networking
- `config/kong.yaml` - Updated for HTTPBin (declarative config)
- `kong.yaml` - Updated for HTTPBin (DB-less config)
- `setup-kong-httpbin.sh` - **Setup script (setup only)**
- `setup-and-test-kong-httpbin.sh` - **Complete setup and testing script**
- `KONG_HTTPBIN_SETUP.md` - This documentation

## 📜 Script Descriptions

### `setup-kong-httpbin.sh`
- **Purpose**: Sets up Kong + HTTPBin from scratch
- **Features**:
  - Cleans up existing containers
  - Starts services in correct order (DB → Migrations → Kong)
  - Configures services, routes, and plugins
  - Provides setup summary
- **Use when**: You want to setup the environment without running tests

### `setup-and-test-kong-httpbin.sh`
- **Purpose**: Complete setup + comprehensive testing
- **Features**:
  - Everything from setup script
  - Comprehensive testing of all functionality
  - Rate limiting demonstration
  - CORS testing
  - Detailed test results and summaries
- **Use when**: You want to verify everything is working correctly

## 🎉 Success!
Kong API Gateway is successfully serving HTTPBin as a backend service, demonstrating:
- ✅ Service proxying
- ✅ Route management
- ✅ Plugin functionality (rate limiting, CORS)
- ✅ Request/response transformation
- ✅ API management capabilities
