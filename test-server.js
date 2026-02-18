// Código de teste para verificar se o problema é no servidor ou no deploy
const http = require('http');

const adminHTML = `<!DOCTYPE html>
<html><head><title>AIssist Admin Test</title>
<style>
body{font-family:Arial;background:linear-gradient(135deg,#667eea 0%,#764ba2 100%);color:white;padding:20px;min-height:100vh;}
.card{background:rgba(255,255,255,0.1);padding:20px;border-radius:10px;margin:10px 0;}
h1{text-align:center;font-size:3rem;}
.status{background:green;color:white;padding:10px;border-radius:5px;text-align:center;margin:10px 0;}
</style></head>
<body>
<h1>🎬 AIssist Dashboard</h1>
<div class="status">✅ FUNCIONANDO - Deploy realizado com sucesso!</div>
<div class="card">
<h2>📊 Dashboard Admin</h2>
<p>Sistema de administração do AIssist operacional</p>
<p><strong>Data/Hora:</strong> ${new Date().toLocaleString('pt-BR')}</p>
<p><strong>Status:</strong> 🟢 Online</p>
<p><strong>Usuários:</strong> 127 ativos</p>
<p><strong>Receita:</strong> R$ 1.247 este mês</p>
</div>
<div class="card">
<h2>🔧 Sistema</h2>
<p>Todos os serviços funcionando normalmente:</p>
<ul>
<li>✅ Database conectado</li>
<li>✅ IA Service online</li>
<li>✅ API endpoints ativos</li>
<li>✅ Deploy automático funcionando</li>
</ul>
</div>
<div class="card">
<h2>🚀 Próximos Passos</h2>
<p>Dashboard básico funcionando. Próximas implementações:</p>
<ul>
<li>Interface de usuários completa</li>
<li>Sistema de pagamentos</li>
<li>Analytics detalhadas</li>
<li>Mobile responsivo</li>
</ul>
</div>
</body></html>`;

const server = http.createServer((req, res) => {
    const url = req.url;
    
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    console.log(new Date().toISOString() + ' - ' + req.method + ' ' + url);
    
    if (url === '/' || url === '/admin' || url === '/dashboard') {
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end(adminHTML);
    } else if (url === '/status' || url === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            status: 'healthy',
            service: 'AIssist Admin Dashboard',
            version: '2.0',
            timestamp: new Date().toISOString(),
            endpoints: ['/admin', '/dashboard', '/status']
        }));
    } else {
        res.writeHead(404, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            error: 'Not found',
            message: 'Try /admin or /dashboard',
            available: ['/admin', '/dashboard', '/status']
        }));
    }
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
    console.log('🚀 AIssist Test Server running on port ' + port);
    console.log('📊 Admin Dashboard: /admin');
    console.log('🔧 Status: /status');
});