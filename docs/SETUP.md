# 🔧 Setup Guide - WatchWise

## Ambiente de Desenvolvimento

### ✅ Instalado e Configurado

- **Dart SDK**: 3.11.0 ✅
- **Flutter**: 3.41.1 ✅  
- **Serverpod CLI**: 3.3.1 ✅
- **Projeto Base**: Criado ✅

### ⚠️ Dependências Externas (Para Deploy)

**Docker** (PostgreSQL + Redis):
```bash
# No ambiente de produção/desenvolvimento local:
cd watchwise_server
docker compose up --build --detach
```

**Configuração Database:**
- PostgreSQL: localhost:8090
- Redis: localhost:8091
- Passwords: ver `watchwise_server/docker-compose.yaml`

## 🚀 Próximos Passos MVP

### 1. **TMDB Integration** (Priority 1)
- [ ] Adicionar package `http` para API calls
- [ ] Criar models para Movie, TV, Person
- [ ] Implementar TMDB service class  
- [ ] Endpoints para busca e detalhes

### 2. **Sistema de Usuários** (Priority 1)  
- [ ] Extend Serverpod User model
- [ ] Authentication endpoints
- [ ] User preferences (valores, gêneros, etc)
- [ ] Profile management

### 3. **Chat Conversacional** (Priority 2)
- [ ] WebSocket endpoints para chat
- [ ] Integração OpenAI/Anthropic
- [ ] Sistema de contexto (memory)
- [ ] Response streaming

### 4. **Anti-Spoiler System** (Priority 2)
- [ ] Spoiler detection model
- [ ] Review moderation pipeline  
- [ ] 3-tier validation system
- [ ] Appeal process

## 📝 Arquitetura Planejada

### Backend Structure
```
watchwise_server/lib/src/
├── auth/           # Authentication & users
├── content/        # Movies, TV, reviews
├── gamification/   # XP, badges, competitions  
├── social/         # Following, profiles
├── ai/            # Chat, recommendations
├── payments/      # Donations, subscriptions
└── integrations/  # TMDB, social media APIs
```

### Database Schema (PostgreSQL + pgvector)
```sql
-- Core entities
users, movies, tv_shows, reviews, ratings

-- Gamification  
user_xp, badges, user_badges, competitions

-- Social
follows, user_profiles, critic_pages

-- AI/ML
embeddings, similarity_cache, chat_sessions

-- Economy
donations, subscriptions, affiliate_commissions
```

### Flutter App Structure  
```
watchwise_flutter/lib/
├── screens/        # Main app screens
├── widgets/        # Reusable components
├── services/       # API clients
├── models/         # Data models  
├── providers/      # State management
└── utils/          # Helpers
```

## 🎯 MVP Features Checklist

### Core MVP (Semana 3-4)
- [ ] **User Registration/Login**
- [ ] **TMDB Movie/TV Search** 
- [ ] **Basic Recommendations**
- [ ] **Simple Chat Interface**
- [ ] **Review System (no spoiler detection yet)**

### Gamification MVP (Semana 5-6)
- [ ] **XP System** (points for reviews)
- [ ] **Basic Badges** (5-10 types)
- [ ] **User Levels** (1-10)
- [ ] **Simple Leaderboard**

### Social MVP (Semana 7-8)  
- [ ] **User Profiles**
- [ ] **Follow System**
- [ ] **Public Reviews Feed**  
- [ ] **Basic Donation System**

## 🔑 API Keys Necessárias

Para desenvolvimento completo:
- **TMDB API Key** (gratuita) ✅ Planejada
- **OpenAI API Key** (paga) ✅ Planejada  
- **Stripe** (donations/subscriptions) ⏳ Futuro
- **Social Media APIs** ⏳ Futuro

## 📊 Performance Targets MVP

- **Response Time**: < 500ms para recomendações básicas
- **Database**: < 100ms queries  
- **AI Chat**: < 2s response time
- **Concurrent Users**: 100+ sem degradação

---

**Status**: 📋 Planejamento completo - Ready para desenvolvimento
**Próximo**: Implementar TMDB integration + User system