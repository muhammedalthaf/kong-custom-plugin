# 🦍 Kong API Gateway + HTTPBin Playground

Welcome to the **Kong API Gateway** testing repo with **HTTPBin** integration!
This is your **sandbox** for exploring Kong's API gateway capabilities with a real backend service. 🧪🚀

---

## 🎯 Quick Start

**Start from scratch with one command:**

```bash
./setup-and-test-kong-httpbin.sh
```

This will:
- ✅ Clean up any existing containers
- ✅ Start Kong + HTTPBin + PostgreSQL
- ✅ Configure services, routes, and plugins
- ✅ Run comprehensive tests
- ✅ Show you everything working!

---

## 🔌 What's Included

- **Kong API Gateway** - Industry-leading API gateway
- **HTTPBin Service** - HTTP testing service for realistic API testing
- **Rate Limiting Plugin** - 5 requests/minute limit
- **CORS Plugin** - Cross-origin resource sharing
- **PostgreSQL Database** - Kong's data store
- **Kong Manager UI** - Web-based management interface

---

## 🛣️ Available Routes & Examples

Once setup is complete, you can test these endpoints:

### 🔗 HTTPBin Service Routes (Prefix: `/httpbin/*`)

#### 📥 GET Requests
```bash
# HTTPBin GET endpoint via Kong
curl http://localhost:8000/httpbin/get

# HTTPBin IP endpoint via Kong
curl http://localhost:8000/httpbin/ip

# Direct HTTPBin access (bypasses Kong)
curl http://localhost:8080/get
```

#### 📤 POST Requests
```bash
# Send JSON data via Kong
curl -X POST http://localhost:8000/httpbin/post \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello Kong!", "user": "developer"}'

# Send form data via Kong
curl -X POST http://localhost:8000/httpbin/post \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "name=Kong&type=API Gateway"
```

### 🚀 Express.js API Routes (Prefix: `/express/*`)

#### 📥 GET Requests
```bash
# API root - shows available endpoints
curl http://localhost:8000/express/

# Get all users
curl http://localhost:8000/express/users

# Health check
curl http://localhost:8000/express/health

# Get sample data
curl http://localhost:8000/express/data

# Direct Express.js access (bypasses Kong)
curl http://localhost:3000/
```

#### 📤 POST Requests
```bash
# Create a new user
curl -X POST http://localhost:8000/express/users \
  -H "Content-Type: application/json" \
  -d '{"name": "Alice Kong", "email": "alice@kong.com"}'
```

### 🚦 Rate Limiting Test
```bash
# Test rate limiting (5 requests/minute limit)
for i in {1..7}; do
  echo "Request $i:"
  curl -w "Status: %{http_code}\n" -o /dev/null -s http://localhost:8000/get
done
```

### 🌐 CORS Testing
```bash
# Test CORS preflight request
curl -I -X OPTIONS http://localhost:8000/get

# Test CORS headers in response
curl -I http://localhost:8000/get | grep -i "access-control"
```

### 📊 Kong Management
```bash
# View all services
curl http://localhost:8001/services | jq .

# View all routes
curl http://localhost:8001/routes | jq .

# View all plugins
curl http://localhost:8001/plugins | jq .

# Check Kong status
curl http://localhost:8001/ | jq .version
```

### 🔍 Expected Responses

**HTTPBin GET request:**
```json
{
  "args": {},
  "headers": {
    "Accept": "*/*",
    "Host": "httpbin",
    "User-Agent": "curl/8.5.0",
    "X-Forwarded-Host": "localhost",
    "X-Kong-Request-Id": "abc123..."
  },
  "origin": "172.18.0.1",
  "url": "http://localhost/get"
}
```

**Express.js API root:**
```json
{
  "message": "Hello from Express API!",
  "service": "express-app",
  "timestamp": "2025-07-23T18:03:53.688Z",
  "endpoints": [
    "GET /",
    "GET /health",
    "GET /users",
    "POST /users",
    "GET /data"
  ]
}
```

**Express.js users list:**
```json
{
  "users": [
    {
      "id": 1,
      "name": "John Doe",
      "email": "john@example.com"
    }
  ],
  "total": 3,
  "service": "express-app"
}
```

**Rate limited response (HTTP 429):**
```json
{
  "message": "API rate limit exceeded"
}
```

**CORS headers in response:**
```
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
Access-Control-Allow-Methods: GET, POST, PUT, DELETE, PATCH, OPTIONS
```

---

## 🔧 Kong Configuration Approaches

### 🗄️ Database-backed Kong (Default)
- **Configuration**: Dynamic via Admin API
- **Persistence**: PostgreSQL database
- **Flexibility**: Add/modify routes and plugins at runtime
- **Use case**: Production environments, dynamic configuration
- **Scripts**: `setup-kong-httpbin.sh`, `setup-and-test-kong-httpbin.sh`

### 📄 Declarative Kong (DB-less)
- **Configuration**: Static via `config/kong.yaml` file
- **Persistence**: Configuration file only
- **Flexibility**: Routes and plugins defined at startup
- **Use case**: Containerized deployments, GitOps workflows
- **Scripts**: `setup-kong-httpbin-declarative.sh`

**Key Advantage of Declarative**: Routes and services are configured automatically when Kong starts - no need to add them via API calls!

---

## 🌐 Management Interfaces

- **Kong Proxy**: [http://localhost:8000](http://localhost:8000) - Main API gateway endpoint
- **Kong Manager UI**: [http://localhost:8002](http://localhost:8002) - Visual management interface
- **Kong Admin API**: [http://localhost:8001](http://localhost:8001) - REST API for configuration
- **HTTPBin Direct**: [http://localhost:8080](http://localhost:8080) - Direct HTTPBin access
- **Express.js Direct**: [http://localhost:3000](http://localhost:3000) - Direct Express.js access

---

## 🚀 Available Scripts

### Database-backed Kong (Recommended)
```bash
# Complete setup and testing (recommended for first-time users)
./setup-and-test-kong-httpbin.sh

# Setup only (no testing)
./setup-kong-httpbin.sh
```

### Declarative Kong (DB-less)
```bash
# Uses config/kong.yaml for configuration
./setup-kong-httpbin-declarative.sh
```

### Manual Docker Commands
```bash
# Database-backed Kong
docker compose up -d

# Declarative Kong (DB-less)
docker compose -f kong.yaml up -d

# Stop services
docker compose down
```

### 🚀 Quick Verification
```bash
# Test that everything is working
curl http://localhost:8000/get && echo "✅ Kong is working!"
```

---

## � Troubleshooting

### Check Service Status
```bash
# View running containers
docker compose ps

# Check Kong logs
docker compose logs kong

# Check HTTPBin logs
docker compose logs httpbin
```

### Common Issues

**Kong returns 404:**
- Wait a few seconds for configuration to propagate
- Check if routes are configured: `curl http://localhost:8001/routes`

**Rate limiting not working:**
- Make requests quickly within the same minute
- Check plugin configuration: `curl http://localhost:8001/plugins`

**Services won't start:**
- Ensure no other services are using ports 8000-8002, 8080, 5432
- Run `docker compose down` and try again

### Reset Everything
```bash
# Complete cleanup and restart
docker compose down -v
./setup-and-test-kong-httpbin.sh
```

---

## �📚 Documentation

For detailed information, see [KONG_HTTPBIN_SETUP.md](KONG_HTTPBIN_SETUP.md)