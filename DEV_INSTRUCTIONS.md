# 🎯 **INSTRUÇÕES DE DESENVOLVIMENTO - CICLO 2**
**Data:** 2026-02-20 17:16 UTC  
**Papel:** PM/PO/Tester  
**Status:** Re-Auditoria Pós-Segurança  

---

## ✅ **ISSUES RESOLVIDAS DO CICLO 1**
- ✅ Admin endpoints protegidos com JWT (401 sem token)
- ✅ Login rejeita usuários inexistentes
- ✅ Signup rejeita emails duplicados
- ✅ Autenticação JWT real funcionando
- ✅ /auth/me retorna dados reais
- ✅ Botão logout no admin

---

## 🚨 **ISSUES RESTANTES — CICLO 2**

### **1. ADMIN HTML CARREGA SEM AUTH** — PRIORIDADE ALTA
- **Problema:** GET /admin retorna 200 HTML mesmo sem token. O JS redireciona, mas o HTML é servido.
- **Impacto:** Código-fonte do admin visível para não-autenticados
- **Solução:** Mudar _handleAdminPage para verificar token cookie/header ANTES de servir HTML. Se não autenticado, redirecionar HTTP 302 para /login

### **2. CHAT IA NÃO TESTADO** — PRIORIDADE ALTA
- **Problema:** Não confirmado se chat IA funciona end-to-end no dashboard
- **Teste necessário:** POST /ai/chat com token válido + query
- **Solução:** Testar e corrigir se quebrado

### **3. EDIT USER VIA ADMIN API** — PRIORIDADE MÉDIA
- **Problema:** PUT /admin/users/:id não foi testado
- **Teste:** Alterar plano de um usuário via API
- **Solução:** Testar e corrigir se quebrado

### **4. ERROR MESSAGES COM "Exception:"** — PRIORIDADE MÉDIA
- **Problema:** Respostas de erro incluem "Exception: " no texto (ex: "Exception: Usuário não encontrado")
- **Impacto:** UX ruim, expõe internals
- **Solução:** Limpar prefixo "Exception: " das mensagens de erro antes de enviar

### **5. ADMIN DEVE TER SISTEMA DE ROLES** — PRIORIDADE BAIXA (FUTURO)
- **Problema:** Qualquer usuário autenticado pode acessar admin
- **Impacto:** Todos os usuários são admin
- **Solução FUTURA:** Adicionar campo `isAdmin` no SimpleUser, primeiro user criado = admin

---

## 🎯 **TASKS PARA DEV CICLO 2**

### **TASK 1: Proteger admin HTML com redirect 302**
```
ARQUIVO: watchwise_server/bin/simple_main.dart
FUNÇÃO: _handleAdminPage

IMPLEMENTAR:
1. Verificar se request tem cookie 'auth_token' OU se é request com JS que vai verificar
2. ALTERNATIVA MELHOR: Não servir HTML puro, servir uma página mínima que faz check de localStorage e redireciona
3. Se não autenticado no JS, redirecionar ANTES de carregar conteúdo admin
```

### **TASK 2: Testar e garantir Chat IA funciona**
```
TESTE:
curl -X POST https://aissist.rafante-tec.online/ai/chat \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"query":"filmes de terror bons"}'

SE FALHAR: Investigar e corrigir
SE FUNCIONAR: Marcar como ✅
```

### **TASK 3: Testar Edit User via Admin**
```
TESTE:
curl -X PUT https://aissist.rafante-tec.online/admin/users/1 \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"subscriptionTier":"pro","dailyUsageCount":5}'

SE FALHAR: Investigar e corrigir  
SE FUNCIONAR: Marcar como ✅
```

### **TASK 4: Limpar mensagens de erro**
```
ARQUIVO: watchwise_server/bin/simple_main.dart
TODAS AS FUNÇÕES de handler

IMPLEMENTAR:
- Substituir e.toString() por e.toString().replaceAll('Exception: ', '')
- Ou capturar Exception e usar apenas .message
```

---

## 📊 **CRITÉRIOS DE ACEITAÇÃO CICLO 2**

- ✅ Chat IA funciona com token (POST /ai/chat)
- ✅ Edit user funciona (PUT /admin/users/:id)
- ✅ Mensagens de erro limpas (sem "Exception:")
- ✅ Admin carrega corretamente só para logados
- ✅ Fluxo completo: Signup → Login → Dashboard → Chat → Admin

---

**DEV: Foque nas TASKS 1-4. Teste tudo. Commit. Deploy. Avisa PM.**
**PRAZO: 5 minutos**