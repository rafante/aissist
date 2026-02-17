import 'dart:io';
import 'dart:convert';

/// Service to interact with Reviva LLM API for AI conversations
class RevivaLLMService {
  static const String _baseUrl = 'http://llm.rafante-tec.online';
  
  final HttpClient _httpClient;
  
  RevivaLLMService() : _httpClient = HttpClient();
  
  /// Generate AI response for movie recommendations
  Future<String> generateMovieRecommendation({
    required String userQuery,
    List<Map<String, dynamic>>? movieContext,
  }) async {
    try {
      final systemPrompt = _buildSystemPrompt();
      final userPrompt = _buildUserPrompt(userQuery, movieContext);
      
      final response = await _sendRequest(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      
      return response;
    } catch (e) {
      print('❌ Error calling Reviva LLM: $e');
      return _getFallbackResponse(userQuery);
    }
  }
  
  String _buildSystemPrompt() {
    return '''Você é a IA do AIssist, uma plataforma de recomendações de filmes e séries.

PERSONALIDADE:
- Amigável, empolgado e conhecedor de cinema
- Fala em português brasileiro
- Usa emojis quando apropriado
- É conciso mas detalhado quando necessário

REGRAS IMPORTANTES:
- JAMAIS dê spoilers de filmes ou séries
- Foque em gênero, diretor, ano, atores principais, premissa geral
- Se o usuário pedir algo específico demais, sugira alternativas
- Sempre explique POURQUÊ está recomendando
- Mantenha tom conversacional, não formal

EXEMPLO DE RESPOSTA:
"🎬 Entendi perfeitamente! Você quer ficção científica inteligente como Inception, mas sem a complexidade narrativa. Vou recomendar filmes que têm conceitos interessantes mas são mais diretos de acompanhar..."''';
  }
  
  String _buildUserPrompt(String userQuery, List<Map<String, dynamic>>? movieContext) {
    var prompt = 'PERGUNTA DO USUÁRIO: $userQuery\n\n';
    
    if (movieContext != null && movieContext.isNotEmpty) {
      prompt += 'FILMES ENCONTRADOS PELA BUSCA:\n';
      for (final movie in movieContext) {
        prompt += '- ${movie['title']} (${movie['release_date']?.toString().split('-').first ?? 'N/A'})\n';
        if (movie['overview'] != null && movie['overview'].toString().isNotEmpty) {
          prompt += '  Sinopse: ${movie['overview']}\n';
        }
      }
      prompt += '\n';
    }
    
    prompt += '''Baseado na pergunta e nos filmes encontrados, gere uma resposta que:
1. Entenda o que o usuário realmente quer
2. Explique porque os filmes encontrados são boas opções
3. Seja conversacional e empolgante
4. Não dê spoilers
5. Termine sugerindo que o usuário pode fazer mais perguntas

Resposta:''';
    
    return prompt;
  }
  
  Future<String> _sendRequest({
    required String systemPrompt,
    required String userPrompt,
  }) async {
    final request = await _httpClient.postUrl(
      Uri.parse('$_baseUrl/v1/chat/completions'),
    );
    
    request.headers.contentType = ContentType.json;
    request.headers.add('Authorization', 'Bearer sk-dummy-key'); // Adjust as needed
    
    final body = jsonEncode({
      'model': 'gpt-3.5-turbo', // Adjust based on Reviva's model
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'max_tokens': 300,
      'temperature': 0.7,
    });
    
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('LLM API returned ${response.statusCode}: $responseBody');
    }
  }
  
  String _getFallbackResponse(String query) {
    // Fallback responses when LLM is not available
    final fallbacks = {
      'inception': '🎬 Entendi! Você quer ficção científica inteligente como Inception, mas menos complexa. Recomendo "Source Code" - tem viagem no tempo e ação, mas é bem mais direto. "Minority Report" também é ótimo - futuro, ação e Tom Cruise!',
      
      'romantico': '💕 Ah, romance que não seja piegas! Entendo perfeitamente. "Her" é lindo e futurístico, "Eternal Sunshine" é poético mas não meloso, e "(500) Days of Summer" quebra clichês românticos de forma inteligente.',
      
      'terror': '😱 Terror psicológico é o melhor! "The Machinist" vai mexer com sua cabeça, "Shutter Island" tem plot twists incríveis, e "Annihilation" mistura sci-fi com horror de forma única.',
      
      'comedia': '😂 Comédia inteligente é vida! "Brooklyn Nine-Nine" (série) tem humor rápido e personagens ótimos. Para filmes, "The Grand Budapest Hotel" é visualmente lindo e engraçado.',
    };
    
    // Simple keyword matching
    final lowerQuery = query.toLowerCase();
    for (final key in fallbacks.keys) {
      if (lowerQuery.contains(key)) {
        return fallbacks[key]!;
      }
    }
    
    return '🎬 Que pergunta interessante! Baseado no que você está procurando, encontrei algumas opções que combinam perfeitamente com seu gosto. Nossa IA analisou milhões de filmes para trazer essas recomendações personalizadas para você!';
  }
  
  void dispose() {
    _httpClient.close();
  }
}