# 🎬 AIssist - Plataforma IA de Recomendações de Filmes

> **A única IA conversacional em português especializada em filmes e séries**

Uma plataforma revolucionária que usa inteligência artificial para recomendar filmes e séries baseado em conversas naturais, com sistema anti-spoiler e gamificação RPG única no mercado.

## 🚀 **Status Atual - FUNCIONANDO!**

### ✅ **DEMO AO VIVO:** 
**https://aissist.rafante-tec.online/demo.html**

### 🤖 **IA REAL FUNCIONANDO:**
- **Backend:** Conectado ao `llm.rafante-tec.online` 
- **Model:** `reviva:latest` com autenticação Basic Auth
- **Fallbacks:** Sistema inteligente com 15+ categorias
- **API:** `POST /ai/chat` com resposta em tempo real

---

## 🎯 **Funcionalidades Únicas**

### 🗣️ **IA Conversacional em Português**
```
👤 "Filmes como Inception mas menos confuso"
🤖 "Entendi! Você quer sci-fi inteligente mas mais direta. 
    Recomendo 'Source Code' e 'Minority Report'..."
```

### 🔒 **Sistema Anti-Spoiler**
- IA treinada para dar apenas informações seguras
- Nunca revela plot twists ou finais
- Foca em gênero, diretor, ano, premissa geral

### 🎮 **Gamificação RPG** *(Em desenvolvimento)*
- XP por avaliações e descobertas
- Badges por tipos de filme assistidos  
- Níveis de "Cinéfilo" com benefícios
- Sistema único no mercado brasileiro

### 🎬 **Base de Dados Completa**
- Integração com **TMDB API**
- Milhões de filmes e séries atualizados
- Metadados em português brasileiro
- Imagens, trailers, ratings, elenco

---

## 🏗️ **Arquitetura Técnica**

### **Backend (Dart + HTTP Server)**
```
📁 watchwise_server/
├── bin/simple_main.dart       # HTTP Server principal
├── lib/src/services/
│   ├── tmdb_service.dart      # API TMDB integration  
│   └── reviva_llm_service.dart # AI LLM integration
└── web/static/demo.html       # Landing page demo
```

### **Endpoints API**
- `GET /health` - Status + endpoints disponíveis
- `GET /movies/popular` - Filmes populares
- `GET /movies/search?query=Matrix` - Busca filmes
- `GET /tv/search?query=Friends` - Busca séries
- `POST /ai/chat` - **Conversa com IA** 🤖
- `GET /demo.html` - Landing page interativa

### **Integração IA**
- **Servidor:** `llm.rafante-tec.online`  
- **Modelo:** `reviva:latest` (Ollama custom)
- **Auth:** Basic Auth (rafante2@gmail.com)
- **Timeout:** 30 segundos máximo
- **Fallback:** Sistema inteligente por keywords

---

## 🌟 **Diferencial Competitivo**

| Recurso | AIssist | Netflix | Letterboxd | IMDb |
|---------|---------|---------|------------|------|
| **IA Conversacional PT-BR** | ✅ | ❌ | ❌ | ❌ |
| **Sistema Anti-Spoiler** | ✅ | ❌ | ❌ | ❌ |
| **Gamificação RPG** | ✅ | ❌ | 📍 | ❌ |
| **Contexto Brasileiro** | ✅ | 📍 | ❌ | ❌ |
| **Gratuito com IA** | ✅ | ❌ | ❌ | ❌ |

**📍 = Limitado**

---

## 🚀 **Como Executar**

### **1. Clone o repositório**
```bash
git clone https://github.com/rafante/aissist.git
cd aissist
```

### **2. Execute o servidor**
```bash
cd watchwise_server
dart bin/simple_main.dart
```

### **3. Acesse o demo**
```
http://localhost:8081/demo.html
```

### **4. Teste a IA**
```bash
# Via curl
curl -X POST http://localhost:8081/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"Filmes como Matrix"}'

# Via script de teste
dart test_ai_direct.dart
```

---

## 📊 **Modelo de Negócio**

### **Tiers de Preços**
- 🆓 **Free:** 10 consultas IA/dia + busca básica
- 💎 **Premium (R$ 19/mês):** 100 consultas + IA avançada + sem anúncios
- 🚀 **Pro (R$ 39/mês):** Ilimitado + API + relatórios + beta features

### **Monetização Adicional**
- 🎬 **Afiliados:** Parcerias com streaming (15% comissão)
- 📱 **White-label:** Licenciamento para cinemas/produtoras
- 🎮 **NFTs:** Badges únicos e colecionáveis  
- 📊 **Analytics:** Insights de tendências para estúdios

---

## 🛠️ **Roadmap Técnico**

### **v0.3.0 - Sistema de Usuários** *(Próximo)*
- [ ] Autenticação Firebase + JWT
- [ ] Perfis com preferências 
- [ ] Histórico de conversas
- [ ] Favoritos e watchlists

### **v0.4.0 - Gamificação RPG**
- [ ] Sistema de XP e níveis
- [ ] Badges por gêneros/diretores
- [ ] Ranking de usuários
- [ ] Achievements especiais

### **v0.5.0 - Social Features**
- [ ] Compartilhar recomendações
- [ ] Seguir outros usuários
- [ ] Reviews colaborativas
- [ ] Grupos temáticos

### **v1.0.0 - Launch**
- [ ] App mobile (Flutter)
- [ ] PWA completo
- [ ] Sistema de pagamentos
- [ ] Analytics avançados

---

## 📈 **Métricas de Sucesso**

### **KPIs Principais**
- 🎯 **Precisão IA:** >85% satisfação nas recomendações
- ⏱️ **Tempo Resposta:** <5s para consultas IA
- 👤 **Retenção:** >60% usuários voltam em 7 dias
- 💰 **Conversão:** >15% Free → Premium

### **Metas 2026**
- 📱 **10k usuários** até junho
- 💎 **1k assinantes** Premium até setembro  
- 🚀 **100k consultas IA** processadas
- 💰 **R$ 50k MRR** até dezembro

---

## 🎬 **Demonstração**

### **Landing Page Cinematográfica**
- ✨ Animações de partículas em tempo real
- 🤖 Chat IA interativo funcionando
- 🎨 Design inspirado em cinema (gradientes azul→roxo)
- 📱 100% responsivo (mobile-first)

### **Chat IA Real**
```
👤 "Terror psicológico tipo Black Mirror"
🤖 "Entendi o vibe Black Mirror! Quer algo que mexe com 
    tecnologia e sociedade. 'Ex Machina' questiona IA, 
    'Her' explora amor digital, 'Minority Report' mostra 
    vigilância futurística. Que aspecto te interessa mais?"
```

---

## 🏷️ **Tags e Versões**

- `v0.1.0-landing` - Landing page cinematográfica completa
- `v0.2.0-ai` - Integração IA com Reviva LLM  
- `v0.2.1-fix` - **Atual** - Basic Auth + fallbacks inteligentes

---

## 🤝 **Contribuindo**

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-feature`)
3. Commit suas mudanças (`git commit -m 'Add: nova feature incrível'`)
4. Push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

---

## 📄 **Licença**

Este projeto está sob licença privada. Todos os direitos reservados.

**© 2026 AIssist - A revolução das recomendações de filmes chegou!** 🎬✨

---

## 🔗 **Links Importantes**

- 🌐 **Demo:** https://aissist.rafante-tec.online/demo.html
- 🐙 **GitHub:** https://github.com/rafante/aissist
- 🤖 **LLM Server:** llm.rafante-tec.online  
- 📊 **Coolify:** https://rafante-tec.online
- 💬 **Contato:** rafante2@gmail.com

**🚀 Pronto para revolucionar como as pessoas descobrem filmes!**