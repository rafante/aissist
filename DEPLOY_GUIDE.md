# AIssist Deploy Guide - PostgreSQL Externo no Coolify

Este guia mostra como migrar o AIssist do armazenamento em memória para PostgreSQL persistente no Coolify.

## 🎯 Objetivo

Separar o banco de dados em um serviço independente para que os dados dos usuários não se percam a cada redeploy.

## 📋 Passo a Passo

### 1. Deploy do Serviço de Banco (PRIMEIRO)

1. **No Coolify Dashboard:**
   - Clique em "New Resource"
   - Escolha "Docker Compose"
   - Nome: `aissist-database`
   - Git Repository: `https://github.com/rafante/aissist.git`
   - Branch: `main`
   - Docker Compose Path: `/database-service/docker-compose.yml`

2. **Configurar Environment Variables:**
   ```env
   POSTGRES_PASSWORD=AiSsIsT2024!SecurePassword
   REDIS_PASSWORD=AiSsIsT2024!RedisPassword
   ```

3. **Deploy e aguardar**
   - Clique em "Deploy"
   - Aguarde até ficar "Running"
   - **IMPORTANTE:** Anote os Container IDs gerados (ex: `abc123def456`)

### 2. Configurar AIssist para usar o Banco Externo

1. **No Coolify, vá para o AIssist existente**
   
2. **Atualize as Environment Variables:**
   ```env
   # Database configuration (SUBSTITUA pelos IDs reais do passo 1)
   SERVERPOD_DATABASE_HOST=<POSTGRES_CONTAINER_ID>
   SERVERPOD_DATABASE_PORT=5432
   SERVERPOD_DATABASE_NAME=aissist
   SERVERPOD_DATABASE_USER=postgres
   SERVERPOD_DATABASE_REQUIRE_SSL=false
   SERVERPOD_PASSWORD_database=AiSsIsT2024!SecurePassword
   
   # Redis configuration (SUBSTITUA pelos IDs reais do passo 1)
   SERVERPOD_REDIS_ENABLED=true
   SERVERPOD_REDIS_HOST=<REDIS_CONTAINER_ID>
   SERVERPOD_REDIS_PORT=6379
   SERVERPOD_PASSWORD_redis=AiSsIsT2024!RedisPassword
   
   # JWT Secret for authentication
   SERVERPOD_PASSWORD_JWT_SECRET=AiSsIsT2024!JwtSuperSecretKey
   
   # TMDB API Key
   TMDB_API_KEY=466fd9ba21e369cd51e7743d32b7833f
   ```

3. **Redeploy o AIssist**

### 3. Executar Migração do Banco

1. **Connect no container do banco:**
   ```bash
   # No Coolify terminal do postgres container
   psql -U postgres -d aissist
   ```

2. **Ou execute a migração via Serverpod:**
   ```bash
   # No AIssist container
   dart run serverpod:serverpod generate
   dart run serverpod:serverpod create-migration
   ```

### 4. Teste do Sistema

1. **Acesse:** https://aissist.rafante-tec.online
2. **Crie uma conta de teste**
3. **Faça redeploy do AIssist**
4. **Verifique se a conta ainda existe** ✅

## 🏗️ Estrutura Final

```
AIssist Ecosystem:
├── aissist-database (Serviço separado)
│   ├── PostgreSQL (porta 5432)
│   └── Redis (porta 6379)
└── aissist (Aplicação principal)
    ├── API Server (porta 8080)
    ├── Insights Server (porta 8081)
    └── Web Server (porta 8082)
```

## 🔐 Usuário Admin Inicial

Após a migração, haverá um usuário admin:
- **Email:** admin@aissist.com
- **Senha:** admin123
- **Plano:** Pro

## 🚨 Container IDs no Coolify

Os Container IDs seguem o padrão do Coolify:
- Formato: `abc123def456` (hash de 12 caracteres)
- Visível no dashboard após deploy
- Usado para comunicação interna entre serviços

## ✅ Checklist de Deploy

- [ ] Deploy do aissist-database realizado
- [ ] Container IDs anotados (postgres + redis)
- [ ] Environment variables do AIssist atualizadas
- [ ] Redeploy do AIssist realizado  
- [ ] Teste de cadastro funcionando
- [ ] Teste de persistência pós-redeploy
- [ ] Login admin funcionando

## 🔄 Rollback (se necessário)

Se algo der errado:
1. Remova as env vars de database do AIssist
2. Redeploy
3. Voltará para armazenamento em memória

---

**Status:** Pronto para execução
**Tempo estimado:** 15-20 minutos
**Risco:** Baixo (rollback disponível)