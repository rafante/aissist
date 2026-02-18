const http = require('http');
const fs = require('fs');
const path = require('path');
const url = require('url');

const port = process.env.PORT || 8080;

// Serve static files
function serveFile(res, filePath, contentType = 'text/html') {
    fs.readFile(filePath, (err, content) => {
        if (err) {
            res.writeHead(404, {'Content-Type': 'text/plain'});
            res.end('File not found');
            return;
        }
        res.writeHead(200, {'Content-Type': contentType, 'Access-Control-Allow-Origin': '*'});
        res.end(content);
    });
}

// Mock AI service
async function callAI(query) {
    // Simulate API call to LLM
    return `Baseado na sua consulta "${query}", aqui estão minhas recomendações:

🎬 Filmes Recomendados:
• Film 1 - Excelente para o gênero que você busca
• Film 2 - Altamente avaliado pela crítica  
• Film 3 - Popular entre usuários

✨ Por que essas escolhas:
Analisei seu perfil e estas opções combinam perfeitamente com suas preferências. Cada filme foi selecionado considerando qualidade, relevância e avaliações.

📊 Confiança da recomendação: 95%
🎯 Personalização aplicada: Sim
⭐ Nota média dos filmes: 8.5/10`;
}

const server = http.createServer(async (req, res) => {
    const parsedUrl = url.parse(req.url, true);
    const pathname = parsedUrl.pathname;
    
    console.log(`${new Date().toISOString()} - ${req.method} ${pathname}`);
    
    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    try {
        switch (pathname) {
            case '/':
            case '/admin':
                serveFile(res, 'watchwise_server/web/static/admin.html');
                break;
                
            case '/demo':
            case '/demo.html':
                serveFile(res, 'watchwise_server/web/static/demo-visual.html');
                break;
                
            case '/health':
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                    status: 'healthy',
                    service: 'AIssist',
                    timestamp: new Date().toISOString(),
                    endpoints: ['/admin', '/demo', '/ai/chat', '/auth/login']
                }));
                break;
                
            case '/ai/status':
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                    success: true,
                    service: 'ReVivaLLM', 
                    healthy: true,
                    endpoint: 'llm.rafante-tec.online',
                    model: 'reviva:latest',
                    timestamp: new Date().toISOString()
                }));
                break;
                
            case '/ai/chat':
                if (req.method === 'POST') {
                    let body = '';
                    req.on('data', chunk => body += chunk);
                    req.on('end', async () => {
                        try {
                            const data = JSON.parse(body);
                            const response = await callAI(data.query);
                            
                            res.writeHead(200, {'Content-Type': 'application/json'});
                            res.end(JSON.stringify({
                                success: true,
                                response: response,
                                query: data.query,
                                processingTime: Math.random() * 2000 + 500,
                                timestamp: new Date().toISOString()
                            }));
                        } catch (error) {
                            res.writeHead(400, {'Content-Type': 'application/json'});
                            res.end(JSON.stringify({success: false, error: 'Invalid JSON'}));
                        }
                    });
                } else {
                    res.writeHead(405, {'Content-Type': 'application/json'});
                    res.end(JSON.stringify({error: 'Method not allowed'}));
                }
                break;
                
            case '/auth/login':
                if (req.method === 'POST') {
                    res.writeHead(200, {'Content-Type': 'application/json'});
                    res.end(JSON.stringify({
                        success: true,
                        user: {
                            id: 1,
                            email: 'admin@aissist.com',
                            subscriptionTier: 'pro',
                            remainingQueries: 500
                        },
                        token: 'mock_admin_jwt_' + Date.now()
                    }));
                } else {
                    res.writeHead(405);
                    res.end('Method not allowed');
                }
                break;
                
            case '/auth/signup':
                if (req.method === 'POST') {
                    res.writeHead(200, {'Content-Type': 'application/json'});
                    res.end(JSON.stringify({
                        success: true,
                        user: {
                            id: Date.now(),
                            email: 'user@aissist.com',
                            subscriptionTier: 'free',
                            remainingQueries: 5
                        },
                        token: 'mock_jwt_' + Date.now()
                    }));
                } else {
                    res.writeHead(405);
                    res.end('Method not allowed');
                }
                break;
                
            case '/movies/search':
                const query = parsedUrl.query.query || 'action';
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                    query: query,
                    results: [
                        {title: 'Movie 1', year: 2024, rating: 8.5},
                        {title: 'Movie 2', year: 2023, rating: 7.8}
                    ]
                }));
                break;
                
            case '/movies/popular':
                res.writeHead(200, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                    results: [
                        {title: 'Popular Movie 1', rating: 9.1},
                        {title: 'Popular Movie 2', rating: 8.7}
                    ]
                }));
                break;
                
            default:
                res.writeHead(404, {'Content-Type': 'application/json'});
                res.end(JSON.stringify({
                    error: 'Not found',
                    available_endpoints: ['/admin', '/demo', '/ai/chat', '/auth/login', '/health']
                }));
        }
    } catch (error) {
        console.error('Server error:', error);
        res.writeHead(500, {'Content-Type': 'application/json'});
        res.end(JSON.stringify({error: 'Internal server error'}));
    }
});

server.listen(port, () => {
    console.log(`🚀 AIssist Server running on port ${port}`);
    console.log(`📊 Admin Dashboard: /admin`);
    console.log(`🎬 Demo Page: /demo`);
    console.log(`🤖 AI Chat: /ai/chat`);
    console.log(`🔐 Auth: /auth/login, /auth/signup`);
});