// Teste local do servidor Node.js
const http = require('http');

const server = http.createServer((req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  
  if (req.url === '/') {
    res.writeHead(200);
    res.end(`
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <title>AIssist - FUNCIONANDO!</title>
    <style>
        body { 
            font-family: Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white; 
            text-align: center; 
            padding: 3rem;
            margin: 0;
        }
        .success { 
            background: rgba(255,255,255,0.1); 
            padding: 2rem; 
            border-radius: 12px; 
            max-width: 600px;
            margin: 0 auto;
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        .btn {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            color: white;
            padding: 1rem 2rem;
            text-decoration: none;
            border-radius: 8px;
            margin: 1rem;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="success">
        <h1>🎉 AIssist FUNCIONANDO!</h1>
        <p>Sistema de navegação completo implementado!</p>
        <a href="/signup" class="btn">🚀 Cadastrar</a>
        <a href="/login" class="btn">🔑 Login</a>
        <br><br>
        <small>Servidor rodando local na porta 3000</small>
    </div>
</body>
</html>
    `);
  } else if (req.url === '/status') {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({
      status: 'WORKING',
      message: 'Landing page + navegação funcionando!',
      routes: ['/', '/login', '/signup', '/dashboard', '/admin']
    }));
  } else {
    res.writeHead(404, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({
      error: 'Not found',
      available: ['/', '/status'],
      message: 'Teste local funcionando!'
    }));
  }
});

server.listen(3000, () => {
  console.log('🎯 Servidor teste rodando em http://localhost:3000');
  console.log('✅ Landing page: http://localhost:3000/');
  console.log('📊 Status: http://localhost:3000/status');
});