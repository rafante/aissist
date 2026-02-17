# 🎬 WatchWise - Plataforma Inteligente de Recomendações

> Sistema de recomendação de entretenimento com IA conversacional, gamificação e economia colaborativa

## 🚀 Features Principais

- **IA Conversacional**: Chat natural para recomendações personalizadas
- **Anti-Spoiler**: Sistema inteligente de detecção de spoilers em 3 camadas  
- **Gamificação RPG**: Sistema de XP, badges, classes e competições
- **Economia Colaborativa**: Usuários ganham dinheiro contribuindo conteúdo
- **Rede Social**: Críticos, influencers e descobridores de gemas escondidas
- **Integrações**: Twitch, Instagram, X, streamings

## 🛠️ Stack Tecnológico

- **Backend**: Serverpod 3.3.1 (Dart)
- **Frontend**: Flutter 3.41.1 (Web + Mobile)
- **Database**: PostgreSQL + pgvector (embeddings)
- **Cache**: Redis
- **IA**: OpenAI/Anthropic + Sentence Transformers
- **APIs**: TMDB, JustWatch, Social Media APIs

## 🏗️ Estrutura do Projeto

```
watchwise/
├── watchwise_server/     # Backend Serverpod
│   ├── lib/             # Endpoints e lógica
│   ├── migrations/      # Database migrations
│   └── docker-compose.yaml # PostgreSQL + Redis
├── watchwise_client/     # Client library (Dart)
├── watchwise_flutter/    # Frontend Flutter
└── docs/                # Documentação
```

## ⚡ Quick Start

### 1. Setup Ambiente

```bash
# Adicionar ao PATH (já configurado)
export PATH="/data/workspace/dart-sdk/bin:/data/workspace/flutter/bin:$HOME/.pub-cache/bin:$PATH"
```

### 2. Iniciar Database

```bash
cd watchwise_server
docker compose up --build --detach
```

### 3. Executar Backend

```bash
cd watchwise_server  
dart bin/main.dart
```

### 4. Executar Frontend

```bash
cd watchwise_flutter
flutter run -d web-server --web-port 8080
```

## 📋 MVP Roadmap (8 semanas)

### ✅ **Semana 1-2: Fundação (ATUAL)**
- [x] ✅ Setup Serverpod + PostgreSQL + Redis
- [x] ✅ Integração TMDB API base 
- [x] ✅ Estrutura de projeto criada
- [ ] 🔄 Sistema básico de usuários
- [ ] 🔄 Interface Flutter base

### ⏳ **Semana 3-4: Core Features**
- [ ] Chat conversacional básico (OpenAI integration)
- [ ] Sistema de recomendações v1
- [ ] Anti-spoiler detector (IA)
- [ ] Sistema XP/Badges básico

### ⏳ **Semana 5-6: Gamificação**
- [ ] Classes de usuário (Descobridor/Analista/Curador/Influencer)
- [ ] Sistema de contestação colaborativa
- [ ] Leaderboards e competições
- [ ] Economia básica (WatchCoins)

### ⏳ **Semana 7-8: Social + Deploy**
- [ ] Profiles públicos de críticos
- [ ] Sistema de seguidores
- [ ] Doações entre usuários (taxa 15%)
- [ ] Deploy produção

## 💰 Modelo de Receita

- **Free**: 10 recomendações/dia, IA básica
- **Premium (R$19/mês)**: Ilimitado, IA avançada  
- **Pro (R$39/mês)**: Analytics, ferramentas de curador
- **Doações**: Taxa 15% entre usuários
- **Afiliados**: Comissões streamings + cinema

## 🎮 Sistema de Gamificação

### Classes de Usuário
- 🔍 **Descobridor** - Especialista em gemas escondidas
- 📝 **Analista** - Reviews detalhados e precisos  
- 🏛️ **Curador** - Organiza e valida catálogo
- ⭐ **Influencer** - Grandes seguidores e engajamento

### Sistema de Badges
- 🏆 Garimpeiro de Ouro (10 gemas descobertas)
- 🎯 Preciso (95% acurácia cadastros)
- ⚡ Primeiro (primeiro a recomendar hit)
- 👑 Influencer (1000+ seguidores)

### Economia WatchCoins
- Ganhe coins por: reviews aceitas, cadastros corretos, descobertas
- Gaste coins em: recomendações premium, badges especiais
- Converta coins em: dinheiro real (taxa 15%)

## 🔗 Integrações Planejadas

### APIs de Dados
- ✅ TMDB (filmes/séries/pessoas)
- ⏳ JustWatch (onde assistir)
- ⏳ OMDb (dados extras)

### Redes Sociais
- ⏳ Instagram API (cross-post reviews)
- ⏳ Twitch API (streams de reviews) 
- ⏳ X/Twitter API (compartilhamento)
- ⏳ YouTube API (trailers embedados)

## 📊 Métricas de Sucesso

- **Engagement**: DAU/MAU > 20%, Tempo sessão > 15min
- **Receita**: MRR +20%/mês, LTV/CAC > 3:1
- **Qualidade**: Recomendações 80%+, Anti-spoiler 95%+

## 🛡️ Competitive Moats

1. **Anti-spoiler único** - Primeiro no mercado
2. **Personalização granular** - Valores pessoais + contexto
3. **Gamificação RPG** - Engajamento diferenciado  
4. **Economia colaborativa** - Usuários trabalham para plataforma

## 🔧 Comandos de Desenvolvimento

```bash
# Database
docker compose -f watchwise_server/docker-compose.yaml up -d

# Backend
cd watchwise_server && dart bin/main.dart

# Frontend  
cd watchwise_flutter && flutter run -d web

# Generate code
cd watchwise_server && serverpod generate

# Migrations
cd watchwise_server && serverpod create-migration

# Tests
cd watchwise_server && dart test
```

## 📝 Configuração Database

- **PostgreSQL**: porta 8090, user: postgres, db: watchwise
- **Redis**: porta 8091  
- **pgvector**: Habilitado para embeddings de similaridade

---

**Status Atual**: 🔧 Fundação completa - Iniciando desenvolvimento MVP  
**Team**: Bruno Rafante (PO) + Maia (CTO/Dev/PM)  
**Timeline**: MVP em 6 semanas restantes  
**Próximo**: Implementar sistema de usuários + TMDB integration