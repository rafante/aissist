#!/bin/bash

echo "🧪 Testing Ollama API Integration..."
echo "=================================="

echo ""
echo "1️⃣  Testing /api/tags endpoint..."
curl -u "rafante2@gmail.com:RevivaTester123" \
     https://llm.rafante-tec.online/api/tags | jq '.models[] | .name'

echo ""
echo "2️⃣  Testing live AIssist /ai/chat endpoint..."
echo "Query: 'Filmes como Matrix mas mais recentes'"

curl -X POST http://localhost:8081/ai/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"Filmes como Matrix mas mais recentes"}' \
  --max-time 30 | jq -r '.ai_response // .error'

echo ""
echo "✅ Test completed. Check responses above."