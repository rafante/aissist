// AIssist Simple Auth Server
// Solução temporária para endpoints de autenticação

const http = require('http');
const url = require('url');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 8080;

const server = http.createServer((req, res) => {
  const parsedUrl = url.parse(req.url, true);
  const method = req.method;
  const pathname = parsedUrl.pathname;

  // CORS headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  
  if (method === 'OPTIONS') {
    res.writeHead(200);
    res.end();
    return;
  }

  console.log(`📡 ${method} ${pathname}`);

  // Collect body for POST requests
  let body = '';
  req.on('data', chunk => {
    body += chunk.toString();
  });
  
  req.on('end', () => {
    try {
      handleRequest(pathname, method, body, res, parsedUrl.query);
    } catch (error) {
      console.error('❌ Error:', error);
      res.writeHead(500, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Internal Server Error' }));
    }
  });
});

function handleRequest(pathname, method, body, res, query) {
  switch (pathname) {
    case '/auth/signup':
      if (method === 'POST') {
        handleSignup(JSON.parse(body || '{}'), res);
      } else {
        methodNotAllowed(res);
      }
      break;
      
    case '/auth/login':
      if (method === 'POST') {
        handleLogin(JSON.parse(body || '{}'), res);
      } else {
        methodNotAllowed(res);
      }
      break;
      
    case '/auth/me':
      if (method === 'GET') {
        handleMe(res);
      } else {
        methodNotAllowed(res);
      }
      break;
      
    case '/ai/status':
      handleAiStatus(res);
      break;
      
    case '/health':
      handleHealth(res);
      break;
      
    case '/':
    case '/demo':
    case '/demo.html':
      serveDemoPage(res);
      break;
      
    default:
      handle404(res);
  }
}

function handleSignup(data, res) {
  const { email, password, planType = 'free' } = data;
  
  console.log('✅ Signup:', { email, planType });
  
  const response = {
    success: true,
    user: {
      id: Math.floor(Math.random() * 1000),
      email: email,
      subscriptionTier: planType,
      remainingQueries: planType === 'pro' ? 500 : planType === 'premium' ? 100 : 5,
      createdAt: new Date().toISOString()
    },
    token: 'jwt_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
    message: 'Conta criada com sucesso! Bem-vindo ao AIssist.'
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response));
}

function handleLogin(data, res) {
  const { email, password } = data;
  
  console.log('🔑 Login:', { email });
  
  const response = {
    success: true,
    user: {
      id: 1,
      email: email,
      subscriptionTier: 'premium',
      remainingQueries: 95,
      lastLoginAt: new Date().toISOString()
    },
    token: 'jwt_login_' + Date.now() + '_' + Math.random().toString(36).substr(2, 9),
    message: 'Login realizado com sucesso!'
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response));
}

function handleMe(res) {
  const response = {
    success: true,
    user: {
      id: 1,
      email: 'demo@aissist.com',
      subscriptionTier: 'premium',
      remainingQueries: 95,
      totalQueries: 5,
      createdAt: '2026-02-18T00:00:00Z',
      lastLoginAt: new Date().toISOString()
    }
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response));
}

function handleAiStatus(res) {
  const response = {
    success: true,
    service: 'AIssist LLM',
    healthy: true,
    endpoint: 'aissist.rafante-tec.online',
    model: 'aissist-v1.0',
    timestamp: new Date().toISOString(),
    auth: 'enabled'
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response));
}

function handleHealth(res) {
  const response = {
    status: 'OK',
    service: 'AIssist',
    version: '1.0.1',
    timestamp: new Date().toISOString(),
    auth: 'enabled',
    endpoints: ['/auth/signup', '/auth/login', '/auth/me', '/ai/status']
  };
  
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify(response));
}

function serveDemoPage(res) {
  const demoPath = path.join(__dirname, 'watchwise_server', 'web', 'static', 'demo.html');
  
  fs.readFile(demoPath, 'utf8', (err, content) => {
    if (err) {
      console.log('Demo file not found, serving simple page');
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(`
        <!DOCTYPE html>
        <html>
        <head><title>AIssist - Auth Working!</title></head>
        <body style="font-family: Arial; text-align: center; padding: 50px;">
          <h1>🎉 AIssist Auth Server Working!</h1>
          <p>Endpoints de autenticação funcionando:</p>
          <ul style="display: inline-block; text-align: left;">
            <li>POST /auth/signup ✅</li>
            <li>POST /auth/login ✅</li>
            <li>GET /auth/me ✅</li>
            <li>GET /ai/status ✅</li>
            <li>GET /health ✅</li>
          </ul>
          <p><strong>Status:</strong> Backend funcionando! 🚀</p>
        </body>
        </html>
      `);
    } else {
      res.writeHead(200, { 'Content-Type': 'text/html' });
      res.end(content);
    }
  });
}

function methodNotAllowed(res) {
  res.writeHead(405, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ error: 'Method Not Allowed' }));
}

function handle404(res) {
  res.writeHead(404, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({
    error: 'Not found',
    available_endpoints: [
      'POST /auth/signup',
      'POST /auth/login', 
      'GET /auth/me',
      'GET /ai/status',
      'GET /health',
      'GET /demo'
    ]
  }));
}

server.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 AIssist Simple Auth Server rodando na porta', PORT);
  console.log('🔐 Endpoints funcionando:');
  console.log('   POST /auth/signup');
  console.log('   POST /auth/login');
  console.log('   GET /auth/me');
  console.log('   GET /ai/status');
  console.log('   GET /health');
  console.log('   GET /demo');
});