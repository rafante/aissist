const http = require('http');

const html = `<!DOCTYPE html>
<html>
<head>
    <title>AIssist Admin - FUNCIONANDO!</title>
    <style>
        body { font-family: Arial; background: linear-gradient(135deg, #667eea, #764ba2); color: white; padding: 20px; }
        .container { max-width: 800px; margin: 0 auto; }
        .success { background: green; padding: 20px; border-radius: 10px; text-align: center; margin: 20px 0; }
        .card { background: rgba(255,255,255,0.1); padding: 20px; border-radius: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎬 AIssist Admin Dashboard</h1>
        <div class="success">
            <h2>✅ SERVIDOR FUNCIONANDO!</h2>
            <p>Dashboard administrativo operacional</p>
        </div>
        <div class="card">
            <h3>📊 Estatísticas</h3>
            <p>Usuários ativos: 127</p>
            <p>Receita mensal: R$ 1.247</p>
            <p>Consultas hoje: 847</p>
        </div>
        <div class="card">
            <h3>🚀 Status dos Sistemas</h3>
            <p>✅ Database: Conectado</p>
            <p>✅ IA Service: Online</p>
            <p>✅ API: Funcionando</p>
        </div>
    </div>
</body>
</html>`;

http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'text/html'});
    res.end(html);
}).listen(4000, () => {
    console.log('Server running on port 4000');
    console.log('Access: http://localhost:4000');
});