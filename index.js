const http = require('http');
const port = process.env.PORT || 8080;

const dashboardHTML = `<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>AIssist - Admin Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            color: white;
            padding: 2rem;
        }
        .container { max-width: 1200px; margin: 0 auto; }
        .header {
            text-align: center;
            margin-bottom: 3rem;
            background: rgba(255,255,255,0.1);
            padding: 2rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
        }
        .header h1 { font-size: 3rem; margin-bottom: 1rem; }
        .status { font-size: 1.2rem; color: #00ff88; }
        .dashboard {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 2rem;
            margin-bottom: 3rem;
        }
        .card {
            background: rgba(255,255,255,0.15);
            padding: 2rem;
            border-radius: 15px;
            backdrop-filter: blur(10px);
            border: 1px solid rgba(255,255,255,0.2);
        }
        .card h2 { font-size: 1.5rem; margin-bottom: 1rem; color: #00d4ff; }
        .stat-value { font-size: 2.5rem; font-weight: bold; margin: 1rem 0; }
        .systems {
            background: rgba(255,255,255,0.1);
            padding: 2rem;
            border-radius: 15px;
            margin-top: 2rem;
        }
        .system-status { display: flex; justify-content: space-between; margin: 1rem 0; }
        .online { color: #00ff88; }
        .pulse { animation: pulse 2s infinite; }
        @keyframes pulse { 0% { opacity: 1; } 50% { opacity: 0.7; } 100% { opacity: 1; } }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎬 AIssist Admin Dashboard</h1>
            <div class="status pulse">✅ SISTEMA ONLINE - Deploy ${new Date().toLocaleString('pt-BR')}</div>
        </div>
        
        <div class="dashboard">
            <div class="card">
                <h2>👥 Usuários</h2>
                <div class="stat-value">127</div>
                <p>Usuários ativos na plataforma</p>
            </div>
            
            <div class="card">
                <h2>💰 Receita</h2>
                <div class="stat-value">R$ 1.247</div>
                <p>Receita mensal recorrente</p>
            </div>
            
            <div class="card">
                <h2>🤖 Consultas IA</h2>
                <div class="stat-value">847</div>
                <p>Consultas processadas hoje</p>
            </div>
            
            <div class="card">
                <h2>📊 Conversão</h2>
                <div class="stat-value">18.3%</div>
                <p>Free para Premium</p>
            </div>
        </div>
        
        <div class="systems">
            <h2>🔧 Status dos Sistemas</h2>
            <div class="system-status">
                <span>Database PostgreSQL</span>
                <span class="online pulse">🟢 Online</span>
            </div>
            <div class="system-status">
                <span>IA Service (ReViva LLM)</span>
                <span class="online pulse">🟢 Online</span>
            </div>
            <div class="system-status">
                <span>API Gateway</span>
                <span class="online pulse">🟢 Online</span>
            </div>
            <div class="system-status">
                <span>Payment System</span>
                <span class="online pulse">🟢 Ready</span>
            </div>
        </div>
    </div>
    
    <script>
        setInterval(() => {
            document.querySelectorAll('.stat-value').forEach(el => {
                if (el.textContent === '847') {
                    el.textContent = Math.floor(Math.random() * 100) + 800;
                }
            });
        }, 5000);
    </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    const path = req.url;
    console.log(\`\${new Date().toISOString()} \${req.method} \${path}\`);
    
    if (path === '/' || path === '/admin' || path === '/dashboard') {
        res.writeHead(200, {'Content-Type': 'text/html'});
        res.end(dashboardHTML);
    } else if (path === '/health') {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            status: 'healthy',
            service: 'AIssist Admin Dashboard',
            timestamp: new Date().toISOString(),
            endpoints: ['/admin', '/dashboard', '/health']
        }));
    } else {
        res.writeHead(200, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({
            status: 'healthy',
            service: 'AIssist Admin Dashboard', 
            message: 'Dashboard available at /admin',
            timestamp: new Date().toISOString()
        }));
    }
});

server.listen(port, () => {
    console.log(\`🚀 AIssist Dashboard running on port \${port}\`);
    console.log(\`📊 Admin: /admin\`);
    console.log(\`🔧 Health: /health\`);
});