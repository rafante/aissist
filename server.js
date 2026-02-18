const express = require('express');
const cors = require('cors');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3030;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Logging middleware
app.use((req, res, next) => {
  console.log(`📡 ${req.method} ${req.path}`);
  next();
});

// Auth endpoints
app.post('/auth/signup', (req, res) => {
  const { email, password, planType } = req.body;
  
  console.log('✅ Signup:', { email, planType });
  
  res.json({
    success: true,
    user: {
      id: Math.floor(Math.random() * 1000),
      email: email,
      subscriptionTier: planType || 'free',
      remainingQueries: planType === 'pro' ? 500 : planType === 'premium' ? 100 : 5,
      createdAt: new Date().toISOString()
    },
    token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6MTIzLCJlbWFpbCI6InRlc3RAdGVzdC5jb20ifQ.mock_token_' + Date.now(),
    message: 'Conta criada com sucesso! Bem-vindo ao AIssist.'
  });
});

app.post('/auth/login', (req, res) => {
  const { email, password } = req.body;
  
  console.log('🔑 Login:', { email });
  
  res.json({
    success: true,
    user: {
      id: 1,
      email: email,
      subscriptionTier: 'premium',
      remainingQueries: 95,
      lastLoginAt: new Date().toISOString()
    },
    token: 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJpZCI6MSwiZW1haWwiOiJ0ZXN0QHRlc3QuY29tIn0.login_token_' + Date.now(),
    message: 'Login realizado com sucesso!'
  });
});

app.get('/auth/me', (req, res) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ success: false, message: 'Token não fornecido' });
  }
  
  res.json({
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
  });
});

app.get('/auth/usage', (req, res) => {
  res.json({
    success: true,
    usage: {
      todayQueries: 3,
      dailyLimit: 100,
      remainingQueries: 97,
      resetTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
      subscriptionTier: 'premium'
    }
  });
});

// AI endpoints
app.post('/ai/chat', async (req, res) => {
  const { message, context } = req.body;
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ success: false, message: 'Autenticação necessária' });
  }
  
  console.log('🤖 AI Chat:', { message });
  
  // Simular resposta da IA
  const responses = [
    `Baseado na sua pergunta sobre "${message}", posso sugerir alguns filmes interessantes...`,
    `Interessante! Sobre "${message}", aqui estão algumas recomendações...`,
    `Entendi sua busca por "${message}". Vou analisar e sugerir...`,
    `Sobre "${message}" - deixe-me buscar as melhores opções para você...`
  ];
  
  setTimeout(() => {
    res.json({
      success: true,
      response: responses[Math.floor(Math.random() * responses.length)],
      recommendations: [
        { title: 'Filme Exemplo 1', rating: 8.5, year: 2023 },
        { title: 'Série Exemplo 2', rating: 9.1, year: 2024 },
        { title: 'Documentário 3', rating: 7.8, year: 2022 }
      ],
      queriesRemaining: 96,
      processingTime: Math.floor(Math.random() * 2000) + 500
    });
  }, 1000); // Simular delay de processamento
});

app.get('/ai/status', (req, res) => {
  res.json({
    success: true,
    service: 'AIssist LLM',
    healthy: true,
    endpoint: 'aissist.rafante-tec.online',
    model: 'aissist-v1.0',
    uptime: Math.floor(Math.random() * 86400),
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Content endpoints (legacy compatibility)
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK',
    service: 'AIssist',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    auth: 'enabled',
    ai: 'enabled'
  });
});

app.get('/movies/popular', (req, res) => {
  res.json({
    success: true,
    movies: [
      { id: 1, title: 'Demo Movie 1', rating: 8.5 },
      { id: 2, title: 'Demo Movie 2', rating: 7.8 }
    ]
  });
});

app.get('/movies/search', (req, res) => {
  const { query } = req.query;
  res.json({
    success: true,
    query: query,
    results: [
      { id: 1, title: `Resultado para: ${query}`, rating: 8.0 }
    ]
  });
});

// Serve static files
app.get('/demo', (req, res) => {
  res.sendFile(path.join(__dirname, 'watchwise_server/web/static/demo.html'));
});

app.get('/admin', (req, res) => {
  res.sendFile(path.join(__dirname, 'admin-corrigido.html'));
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not found',
    path: req.path,
    available_endpoints: [
      '/auth/signup [POST]',
      '/auth/login [POST]', 
      '/auth/me [GET]',
      '/auth/usage [GET]',
      '/ai/chat [POST]',
      '/ai/status [GET]',
      '/health [GET]',
      '/demo [GET]',
      '/admin [GET]'
    ]
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log('🚀 AIssist Server FUNCIONANDO na porta', PORT);
  console.log('🔐 Endpoints de Auth: /auth/signup, /auth/login, /auth/me');
  console.log('🤖 Endpoints de AI: /ai/chat, /ai/status');
  console.log('🎬 Frontend: /demo, /admin');
  console.log('💾 Modo: Mock/Demo (banco simulado)');
});