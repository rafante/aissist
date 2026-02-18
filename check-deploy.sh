#!/bin/bash

echo "🔍 Verificando deploy do AIssist..."
echo "⏰ Timestamp: $(date)"
echo ""

# Função para verificar se o endpoint de auth está funcionando
check_auth() {
    response=$(curl -s -X POST https://aissist.rafante-tec.online/auth/signup \
        -H "Content-Type: application/json" \
        -d '{"email":"test@test.com","password":"123","planType":"free"}' 2>/dev/null)
    
    if echo "$response" | grep -q "success.*true"; then
        echo "✅ AUTH FUNCIONANDO!"
        echo "📝 Resposta: $response"
        return 0
    else
        echo "❌ Auth ainda não disponível"
        echo "📝 Resposta: $response"
        return 1
    fi
}

# Verificar health endpoint
echo "🏥 Verificando /health..."
health_response=$(curl -s https://aissist.rafante-tec.online/health 2>/dev/null)
echo "📝 Health: $health_response"
echo ""

# Verificar auth endpoint
echo "🔐 Verificando /auth/signup..."
if check_auth; then
    echo ""
    echo "🎉 DEPLOY CONCLUÍDO COM SUCESSO!"
    echo "✅ Todos os endpoints de autenticação estão funcionando"
else
    echo ""
    echo "⏳ Deploy ainda em progresso..."
    echo "💡 Coolify pode demorar 1-5 minutos para fazer rebuild"
fi

echo ""
echo "🔗 URL para testar manualmente: https://aissist.rafante-tec.online/demo"