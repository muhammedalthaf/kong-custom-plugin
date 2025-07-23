const express = require('express');
const fs = require('fs');
const path = require('path');
const app = express();
const port = 3000;

// Middleware to parse JSON
app.use(express.json());

// Path to logs file
const logsFilePath = path.join(__dirname, 'logs.json');

// Helper function to read logs from file
function readLogs() {
  try {
    if (fs.existsSync(logsFilePath)) {
      const data = fs.readFileSync(logsFilePath, 'utf8');
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error reading logs:', error);
    return [];
  }
}

// Helper function to write logs to file
function writeLogs(logs) {
  try {
    fs.writeFileSync(logsFilePath, JSON.stringify(logs, null, 2));
    return true;
  } catch (error) {
    console.error('Error writing logs:', error);
    return false;
  }
}

// Basic endpoints
app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Express API!',
    service: 'express-app',
    timestamp: new Date().toISOString(),
    endpoints: [
      'GET /',
      'GET /health',
      'GET /users',
      'POST /users',
      'GET /data',
      'POST /logs',
      'GET /logs?limit=N'
    ]
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    service: 'express-app',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/users', (req, res) => {
  res.json({
    users: [
      { id: 1, name: 'John Doe', email: 'john@example.com' },
      { id: 2, name: 'Jane Smith', email: 'jane@example.com' },
      { id: 3, name: 'Bob Johnson', email: 'bob@example.com' }
    ],
    total: 3,
    service: 'express-app'
  });
});

app.post('/users', (req, res) => {
  const { name, email } = req.body;
  res.status(201).json({
    message: 'User created successfully',
    user: {
      id: Math.floor(Math.random() * 1000),
      name: name || 'Unknown',
      email: email || 'unknown@example.com',
      created: new Date().toISOString()
    },
    service: 'express-app'
  });
});

app.get('/data', (req, res) => {
  res.json({
    data: {
      random: Math.random(),
      timestamp: Date.now(),
      message: 'Sample data from Express API'
    },
    service: 'express-app',
    headers: req.headers
  });
});

// Logs API - POST endpoint to add logs
app.post('/logs', (req, res) => {
  try {
    const body = req.body;
    let logEntry;

    // Check if it's a Kong plugin request (has request/response structure)
    if (body.request && body.response) {
      // Kong plugin format
      logEntry = {
        id: Date.now() + Math.random(),
        type: 'kong_request_response',
        timestamp: new Date().toISOString(),
        request: {
          url: body.request.url || '',
          method: body.request.method || '',
          headers: body.request.headers || {},
          body: body.request.body || ''
        },
        response: {
          status_code: body.response.status_code || 0,
          headers: body.response.headers || {},
          body: body.response.body || ''
        }
      };
    } else {
      // Invalid format
      return res.status(400).json({
        error: 'Invalid log format. Either provide "message" field or "request"/"response" fields',
        service: 'express-app'
      });
    }

    // Read existing logs
    const logs = readLogs();

    // Add to beginning of array (most recent first)
    logs.unshift(logEntry);

    // Write back to file
    if (writeLogs(logs)) {
      res.status(201).json({
        success: true,
        message: 'Log entry added successfully',
        logEntry,
        totalLogs: logs.length,
        service: 'express-app'
      });
    } else {
      res.status(500).json({
        error: 'Failed to save log entry',
        service: 'express-app'
      });
    }
  } catch (error) {
    res.status(500).json({
      error: 'Internal server error',
      details: error.message,
      service: 'express-app'
    });
  }
});

// Logs API - GET endpoint to fetch logs
app.get('/logs', (req, res) => {
  try {
    const { limit = 10 } = req.query;
    const limitNum = parseInt(limit, 10);

    if (isNaN(limitNum) || limitNum < 1) {
      return res.status(400).json({
        error: 'Limit must be a positive number',
        service: 'express-app'
      });
    }

    // Read logs from file
    const allLogs = readLogs();

    // Get the requested number of logs (most recent first)
    const logs = allLogs.slice(0, limitNum);

    res.json({
      logs,
      totalLogs: allLogs.length,
      returnedLogs: logs.length,
      limit: limitNum,
      service: 'express-app'
    });
  } catch (error) {
    res.status(500).json({
      error: 'Internal server error',
      details: error.message,
      service: 'express-app'
    });
  }
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Endpoint not found',
    service: 'express-app',
    path: req.originalUrl,
    method: req.method
  });
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Express app listening at http://0.0.0.0:${port}`);
});
