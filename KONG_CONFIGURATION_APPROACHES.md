# Kong Configuration Approaches

This project demonstrates two different ways to configure Kong API Gateway with HTTPBin service.

## 🗄️ Database-backed Kong (Default Approach)

### How it works:
1. Kong uses PostgreSQL database to store configuration
2. Services, routes, and plugins are added via Kong Admin API
3. Configuration is dynamic and can be modified at runtime

### Setup Process:
1. Start PostgreSQL database
2. Run Kong migrations to set up database schema
3. Start Kong with database connection
4. Use Admin API to configure services, routes, and plugins

### Scripts:
- `setup-kong-httpbin.sh` - Setup only
- `setup-and-test-kong-httpbin.sh` - Setup + comprehensive testing

### Configuration Files:
- `docker-compose.yml` - Defines all services including PostgreSQL
- Configuration added via API calls in setup scripts

### Advantages:
- ✅ Dynamic configuration changes
- ✅ Runtime plugin management
- ✅ Suitable for production environments
- ✅ Kong Manager UI available
- ✅ Configuration persistence across restarts

### Use Cases:
- Production deployments
- Environments requiring runtime configuration changes
- Teams using Kong Manager UI for administration

---

## 📄 Declarative Kong (DB-less Approach)

### How it works:
1. Kong reads configuration from YAML file at startup
2. All services, routes, and plugins defined in `config/kong.yaml`
3. Configuration is static - changes require restart

### Setup Process:
1. Start HTTPBin service
2. Start Kong with declarative configuration file
3. Kong automatically loads all configuration from YAML

### Scripts:
- `setup-kong-httpbin-declarative.sh` - Declarative setup and testing

### Configuration Files:
- `kong.yaml` - Docker compose for DB-less Kong
- `config/kong.yaml` - Declarative configuration with services, routes, and plugins

### Advantages:
- ✅ **Routes available immediately** - No API calls needed!
- ✅ Configuration as code (GitOps friendly)
- ✅ No database required
- ✅ Faster startup time
- ✅ Version control friendly
- ✅ Immutable infrastructure pattern

### Use Cases:
- Containerized deployments
- GitOps workflows
- Development environments
- Microservices with static routing

---

## 🔍 Configuration Comparison

| Feature | Database-backed | Declarative |
|---------|----------------|-------------|
| **Startup Time** | Slower (DB + migrations) | Faster (file only) |
| **Route Availability** | After API configuration | **Immediate** |
| **Runtime Changes** | ✅ Yes | ❌ Requires restart |
| **Database Required** | ✅ PostgreSQL | ❌ None |
| **Kong Manager UI** | ✅ Available | ❌ Limited |
| **GitOps Friendly** | ❌ API-based | ✅ File-based |
| **Configuration Drift** | Possible | ❌ Prevented |

---

## 📋 Current Configuration (Both Approaches)

### Services:
- **httpbin-service**: Routes to HTTPBin container

### Routes:
- `/httpbin/*` → HTTPBin (with path stripping)
- `/get` → HTTPBin GET endpoint
- `/post` → HTTPBin POST endpoint

### Plugins:
- **CORS**: Allow all origins, multiple HTTP methods
- **Rate Limiting**: 5 requests/minute, 100/hour
- **IP Restriction**: Docker network allowed
- **Request Size Limiting**: 10KB maximum

---

## 🚀 Quick Start Commands

### Database-backed (Dynamic):
```bash
./setup-and-test-kong-httpbin.sh
```

### Declarative (Static):
```bash
./setup-kong-httpbin-declarative.sh
```

### Test Either Approach:
```bash
curl http://localhost:8000/get
curl -X POST http://localhost:8000/post -d '{"test": "data"}' -H "Content-Type: application/json"
```

---

## 💡 Recommendation

- **Use Declarative** for: Development, containerized deployments, GitOps workflows
- **Use Database-backed** for: Production environments requiring runtime configuration changes

**Key Benefit of Declarative**: Routes and services are configured automatically when Kong starts - perfect for your use case of having routes available immediately! 🎯
