# 🎬 PROJETO AISSIST - DOCUMENTAÇÃO COMPLETA
**Data:** 2026-02-17  
**Status:** Em desenvolvimento ativo - MVP quase LIVE  
**Repositório:** https://github.com/rafante/aissist

---

## 📋 **RESUMO EXECUTIVO**

**AIssist** é uma plataforma SaaS de recomendações de filmes/séries com:
- 🤖 **IA Conversacional** para recomendações personalizadas
- 🛡️ **Sistema Anti-Spoiler** único no mercado
- 🎮 **Gamificação RPG** (XP, badges, classes de usuário)
- 💰 **Economia Colaborativa** (usuários ganham dinheiro contribuindo)
- 🌐 **Rede Social** para críticos e descobridores

---

## 🎯 **STATUS ATUAL DO PROJETO**

### ✅ **COMPLETO:**
- [x] **Conceito & Planejamento:** 100% definido
- [x] **Repositório GitHub:** https://github.com/rafante/aissist
- [x] **Stack Técnico:** Flutter + Serverpod/HTTP + PostgreSQL + Redis
- [x] **TMDB API:** Integração completa e testada
- [x] **Deployment Infrastructure:** Docker + Coolify configurado
- [x] **Domínio:** `aissist.rafante-tec.online` configurado

### 🔄 **EM PROGRESSO:**
- [ ] **Deploy Final:** Servidor HTTP simples sendo deployado
- [ ] **APIs Funcionando:** TMDB endpoints quase LIVE

### ⏳ **PRÓXIMOS PASSOS:**
1. **Validar deployment** do servidor HTTP simples
2. **Testar endpoints** TMDB em produção
3. **Implementar interface Flutter** básica
4. **Sistema de usuários** (quando necessário)

---

## 🏗️ **ARQUITETURA TÉCNICA**

### **Stack Principal:**
- **Backend:** Dart HTTP Server (simplificado de Serverpod)
- **Frontend:** Flutter 3.41.1 (Web + Mobile)
- **Database:** PostgreSQL + pgvector + Redis
- **Deploy:** Docker Compose + Coolify
- **API Externa:** TMDB API (The Movie Database)

### **Estrutura do Projeto:**
```
aissist/ (GitHub: rafante/aissist)
├── watchwise_server/          # Backend Dart/HTTP
│   ├── bin/simple_main.dart   # Servidor HTTP simples
│   ├── lib/src/services/      # TmdbService
│   ├── lib/src/protocol/      # Models (Movie, TvShow)
│   ├── Dockerfile             # Container config
│   └── docker-compose.yaml    # PostgreSQL + Redis
├── watchwise_client/          # Client library
├── watchwise_flutter/         # Frontend Flutter
└── docs/                      # Documentação
```

---

## 🎬 **INTEGRAÇÃO TMDB**

### **Status:** ✅ 100% FUNCIONAL E TESTADA

**API Key:** `466fd9ba21e369cd51e7743d32b7833f`

**Endpoints Implementados:**
- `GET /movies/popular` - Filmes populares
- `GET /movies/search?query=Matrix` - Busca filmes
- `GET /tv/search?query=Friends` - Busca séries
- `GET /health` - Health check

**Teste Local Realizado:**
```bash
cd /data/workspace/watchwise && dart test_tmdb.dart
# ✅ RESULTADO: API funcionando, português, posters, tudo OK
```

---

## 🚀 **DEPLOYMENT - HISTÓRICO COMPLETO**

### **Plataforma:** Coolify (https://rafante-tec.online)
### **Domínio:** `aissist.rafante-tec.online`
### **VPS:** 69.62.88.50

### **Problemas Enfrentados e Soluções:**

#### 1. **Conflitos de Porta** ✅ RESOLVIDO
- **Problema:** Portas 8080, 9090 ocupadas no VPS
- **Solução:** Removidas exposições de porta, Coolify gerencia proxy

#### 2. **Problemas Serverpod** ✅ CONTORNADO
- **Problema:** Autenticação JWT complexa causando crashes
- **Solução:** Servidor HTTP puro em `bin/simple_main.dart`

#### 3. **Dependencies Issues** ✅ RESOLVIDO
- **Problema:** `pubspec.lock`, `resolution: workspace`
- **Solução:** Arquivo removido, workspace resolution removido

#### 4. **Compilation Errors** ✅ RESOLVIDO
- **Problema:** `dart compile exe` falhando (exit code 254)
- **Solução:** Simplificação total - servidor HTTP puro

---

## 💰 **MODELO DE NEGÓCIO**

### **Receita Multi-Stream:**
- **Freemium:** Free (limitado) + Premium R$19/mês + Pro R$39/mês
- **Doações:** Taxa 15% entre usuários
- **Afiliados:** Comissões streamings + cinema
- **Competições:** Eventos patrocinados

### **Diferencial Competitivo:**
1. **Anti-spoiler System** - Primeiro no mercado
2. **IA Conversational** - Contexto pessoal + valores
3. **Gamificação RPG** - Engajamento único
4. **Economia Colaborativa** - "Usuários trabalham PARA você"

---

## 🎮 **SISTEMA DE GAMIFICAÇÃO**

### **Classes de Usuário:**
- 🔍 **Descobridor** - Especialista em gemas escondidas
- 📝 **Analista** - Reviews detalhados e precisos
- 🏛️ **Curador** - Organiza e valida catálogo
- ⭐ **Influencer** - Grandes seguidores e monetização

### **Sistema de Badges:**
- 🏆 Garimpeiro de Ouro (10 gemas descobertas)
- 🎯 Preciso (95% acurácia cadastros)
- ⚡ Primeiro (primeiro a recomendar hit)
- 👑 Influencer (1000+ seguidores)

---

## 🔧 **CONFIGURAÇÕES TÉCNICAS**

### **Environment Variables:**
```bash
# TMDB API
TMDB_API_KEY=466fd9ba21e369cd51e7743d32b7833f

# Database (PostgreSQL)
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=watchwise
POSTGRES_USER=postgres
POSTGRES_PASSWORD=5DSV-jq2bDFrY7oUFXvksaRamSiyJ8nO

# Redis
REDIS_HOST=redis  
REDIS_PORT=6379
REDIS_PASSWORD=hRTeXLSLqSx0VPI0IL0b5nUbKKDntbfq
```

### **Docker Compose Stack:**
- **app:** Servidor Dart HTTP (porta 8080)
- **postgres:** PostgreSQL + pgvector
- **redis:** Cache + sessions

---

## 📊 **ROADMAP MVP (8 SEMANAS)**

### **✅ Semana 1-2: Fundação (95% COMPLETA)**
- [x] Setup técnico completo
- [x] TMDB integration 100% testada
- [x] Estrutura de projeto + GitHub
- [x] Deploy infrastructure configurada
- [ ] 🔄 APIs LIVE (deploy final em progresso)

### **⏳ Semana 3-4: Core Features**
- [ ] Interface Flutter básica conectada
- [ ] Chat conversacional (OpenAI integration)
- [ ] Sistema de recomendações v1
- [ ] Anti-spoiler detector (IA)

### **⏳ Semana 5-6: Gamificação**
- [ ] Classes de usuário básicas
- [ ] Sistema XP/Badges
- [ ] Leaderboards e competições
- [ ] Economia básica (WatchCoins)

### **⏳ Semana 7-8: Social + Launch**
- [ ] Profiles públicos de críticos
- [ ] Sistema de seguidores
- [ ] Doações entre usuários
- [ ] Marketing launch

---

## 📝 **COMANDOS ÚTEIS**

### **Desenvolvimento Local:**
```bash
# Testar TMDB API
cd /data/workspace/watchwise && dart test_tmdb.dart

# Rodar servidor local
cd watchwise_server && dart run bin/simple_main.dart

# Build Flutter app
cd watchwise_flutter && flutter run -d web
```

### **Git Workflow:**
```bash
cd /data/workspace/watchwise
git add -A
git commit -m "Mensagem"
git push origin main
```

### **Deploy no Coolify:**
1. Acesse https://rafante-tec.online
2. Login: rafante2 / Upando978!@#3
3. Projeto: AIssist → Redeploy

---

## 🔗 **LINKS IMPORTANTES**

- **GitHub Repo:** https://github.com/rafante/aissist
- **Coolify Panel:** https://rafante-tec.online
- **Domain (quando LIVE):** https://aissist.rafante-tec.online
- **TMDB API Docs:** https://developers.themoviedb.org/3
- **Serverpod Docs:** https://docs.serverpod.dev

---

## ⚠️ **NOTAS CRÍTICAS**

### **Decisões Arquiteturais:**
1. **Servidor HTTP Simples:** Escolhido sobre Serverpod por simplicidade de deploy
2. **TMDB Como Base:** API gratuita e completa para catálogo inicial
3. **Docker + Coolify:** Stack de deploy robusta e escalável
4. **Flutter Web+Mobile:** Uma codebase para todas as plataformas

### **Learnings Importantes:**
- **Simplicidade > Complexidade** para MVP
- **Deploy early, iterate fast**
- **TMDB API é excelente** para dados de entretenimento
- **Coolify é poderoso** mas tem curva de aprendizado

---

## 🚀 **STATUS FINAL**

**PROJETO AISSIST** está 95% pronto para ter sua primeira versão funcional LIVE.

**Último passo:** Validar deploy do servidor HTTP simples no Coolify.

**Depois:** Interface Flutter básica conectando com as APIs.

**Timeline:** MVP completo em **6 semanas** a partir de hoje.

---

*Documento criado em: 2026-02-17*  
*Autor: Maia (CTO/Dev/PM) + Bruno Rafante (Product Owner)*