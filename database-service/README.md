# AIssist Database Service

Serviço separado PostgreSQL + Redis para o AIssist deployado no Coolify.

## Deploy no Coolify

1. **Criar novo Resource no Coolify:**
   - Tipo: Docker Compose
   - Nome: `aissist-database`
   - Git Repository: Este mesmo repo (branch: main)
   - Docker Compose Path: `/database-service/docker-compose.yml`

2. **Configurar Environment Variables:**
   ```
   POSTGRES_PASSWORD=AiSsIsT2024!SecurePassword
   REDIS_PASSWORD=AiSsIsT2024!RedisPassword
   ```

3. **Portas expostas:**
   - PostgreSQL: 5432
   - Redis: 6379

4. **Volumes persistentes:**
   - `postgres_data` → Dados PostgreSQL
   - `redis_data` → Dados Redis

## Conexão do AIssist

Após deploy, o AIssist deve conectar usando os hostnames internos do Coolify:
- PostgreSQL: `<container-id-postgres>`
- Redis: `<container-id-redis>`

Os hostnames reais serão visíveis no dashboard do Coolify após o deploy.

## Estrutura do Banco

- **users** → Usuários cadastrados
- **subscriptions** → Assinaturas/planos
- **usage_logs** → Logs de uso da IA

## Usuário Inicial

- Email: `admin@aissist.com`
- Senha: `admin123`
- Plano: `Pro`