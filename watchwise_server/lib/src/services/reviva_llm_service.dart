import 'dart:io';
import 'dart:convert';

/// Service to interact with Reviva LLM API for AI conversations
class RevivaLLMService {
  static const String _baseUrl = 'https://llm.rafante-tec.online';
  
  final HttpClient _httpClient;
  
  RevivaLLMService() : _httpClient = HttpClient();
  
  /// Generate AI response for movie recommendations
  Future<String> generateMovieRecommendation({
    required String userQuery,
    List<Map<String, dynamic>>? movieContext,
  }) async {
    try {
      print('🤖 Calling Reviva LLM for query: $userQuery');
      
      final systemPrompt = _buildSystemPrompt();
      final userPrompt = _buildUserPrompt(userQuery, movieContext);
      
      final response = await _sendRequest(
        systemPrompt: systemPrompt,
        userPrompt: userPrompt,
      );
      
      print('✅ LLM Response received: ${response.length} chars');
      return response;
    } catch (e) {
      print('❌ Error calling Reviva LLM: $e');
      print('🔄 Using enhanced fallback response');
      return _getFallbackResponse(userQuery);
    }
  }
  
  String _buildSystemPrompt() {
    return '''Você é a IA especialista em filmes do AIssist. Seu trabalho é recomendar filmes e séries baseado no que o usuário descreve.

COMO RESPONDER:
1. Entenda o que o usuário quer (gênero, humor, estilo)
2. Recomende 2-3 filmes específicos com ano
3. Explique brevemente PORQUE cada um é uma boa escolha
4. Use português brasileiro e seja empolgado
5. NUNCA dê spoilers - apenas premissa, gênero, diretor, atores

EXEMPLO:
"🎬 Entendi! Ficção científica inteligente mas acessível. Recomendo:
- Source Code (2011) - Viagem no tempo mais direta que Inception
- Ex Machina (2014) - IA e filosofia, visualmente lindo
- Arrival (2016) - Aliens e linguística, emociona sem confundir"

Seja conciso, específico e útil.''';
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
    // Set timeout for LLM requests (25 seconds max - Ollama is slow)
    _httpClient.connectionTimeout = const Duration(seconds: 25);
    
    final request = await _httpClient.postUrl(
      Uri.parse('$_baseUrl/api/generate'), // Correct Ollama endpoint
    );
    
    request.headers.contentType = ContentType.json;
    
    // Add Basic Auth credentials for Reviva LLM
    final credentials = 'rafante2@gmail.com:RevivaTester123';
    final encoded = base64Encode(utf8.encode(credentials));
    request.headers.add('Authorization', 'Basic $encoded');
    
    print('🔗 Sending request to Ollama /api/generate...');
    
    // Combine system prompt and user prompt for Ollama generate API
    final combinedPrompt = '''$systemPrompt

USUÁRIO: $userPrompt

ASSISTENTE:''';
    
    final body = jsonEncode({
      'model': 'reviva:latest',
      'prompt': combinedPrompt,
      'stream': false, // Important: get complete response
      'options': {
        'temperature': 0.7,
        'top_p': 0.9,
        'num_predict': 300, // Ollama uses num_predict instead of max_tokens
        'stop': ['\nUSUÁRIO:', '\nHUMAN:', '\nUSER:'], // Stop at new user input
      }
    });
    
    request.write(body);
    
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    print('📥 Ollama Response Status: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      
      // Ollama uses 'response' field, not 'choices'
      if (data['response'] != null) {
        final content = data['response'] as String;
        print('✅ Ollama Response: ${content.length > 100 ? content.substring(0, 100) + '...' : content}');
        return content.trim();
      } else {
        throw Exception('No response field in Ollama response');
      }
    } else {
      print('❌ Ollama Error Response: $responseBody');
      throw Exception('Ollama API returned ${response.statusCode}: $responseBody');
    }
  }
  
  String _getFallbackResponse(String query) {
    // Enhanced fallback responses with much better keyword coverage
    final lowerQuery = query.toLowerCase();
    
    // Action/Adventure
    if (lowerQuery.contains('acao') || lowerQuery.contains('ação') || 
        lowerQuery.contains('aventura') || lowerQuery.contains('john wick') ||
        lowerQuery.contains('fast') || lowerQuery.contains('mission')) {
      return '💥 Ação na veia! Se curte adrenalina, recomendo "Mad Max: Fury Road" (ação pura), "John Wick" (coreografias incríveis) e "Mission Impossible" (stunts insanos). Que tipo de ação você prefere - mais realista ou mais fantasia?';
    }
    
    // Sci-Fi
    if (lowerQuery.contains('inception') || lowerQuery.contains('matrix') || 
        lowerQuery.contains('ficção') || lowerQuery.contains('sci-fi') ||
        lowerQuery.contains('futuro') || lowerQuery.contains('aliens')) {
      return '🚀 Ficção científica é vida! "Blade Runner 2049" é visualmente deslumbrante, "Arrival" mexe com a mente, e "Ex Machina" questiona nossa relação com IA. Quer algo mais cerebral ou com mais ação?';
    }
    
    // Romance
    if (lowerQuery.contains('romantico') || lowerQuery.contains('romântico') || 
        lowerQuery.contains('romance') || lowerQuery.contains('amor') ||
        lowerQuery.contains('piegas') || lowerQuery.contains('casal')) {
      return '💕 Romance inteligente chegando! "Her" é poético e futurístico, "Eternal Sunshine" brinca com memórias do amor, "(500) Days of Summer" quebra clichês. Prefere mais drama ou comédia romântica?';
    }
    
    // Horror/Terror
    if (lowerQuery.contains('terror') || lowerQuery.contains('horror') || 
        lowerQuery.contains('medo') || lowerQuery.contains('assombra') ||
        lowerQuery.contains('suspense') || lowerQuery.contains('psicológico')) {
      return '😱 Terror de qualidade! "Hereditary" é perturbador, "Get Out" mistura terror com crítica social, "The Witch" é atmosférico. Curte mais gore ou terror psicológico?';
    }
    
    // Comedy
    if (lowerQuery.contains('comedia') || lowerQuery.contains('comédia') || 
        lowerQuery.contains('engracado') || lowerQuery.contains('rir') ||
        lowerQuery.contains('humor') || lowerQuery.contains('funny')) {
      return '😂 Comédia boa é remédio! "The Grand Budapest Hotel" é visualmente lindo e hilário, "Knives Out" mistura comédia com mistério, "What We Do in the Shadows" é comédia vampiresca genial!';
    }
    
    // Drama
    if (lowerQuery.contains('drama') || lowerQuery.contains('emociona') || 
        lowerQuery.contains('chora') || lowerQuery.contains('profundo') ||
        lowerQuery.contains('tocante') || lowerQuery.contains('história')) {
      return '🎭 Drama que emociona! "Moonlight" é uma obra-prima sobre identidade, "Parasite" critica social brilhante, "Manchester by the Sea" vai te deixar pensativo. Quer algo mais pesado ou esperançoso?';
    }
    
    // Animation
    if (lowerQuery.contains('anima') || lowerQuery.contains('pixar') || 
        lowerQuery.contains('disney') || lowerQuery.contains('desenho') ||
        lowerQuery.contains('família') || lowerQuery.contains('criança')) {
      return '🎨 Animação que emociona adultos! "Spider-Verse" revolucionou a animação, "Soul" da Pixar é profundo, "Your Name" é lindo demais. Para toda família ou mais adulto?';
    }
    
    // Specific movies mentioned
    if (lowerQuery.contains('black mirror')) {
      return '📱 Entendi o vibe Black Mirror! Quer algo que mexe com tecnologia e sociedade. "Ex Machina" questiona IA, "Her" explora amor digital, "Minority Report" mostra vigilância futurística. Que aspecto te interessa mais?';
    }
    
    // Netflix/Streaming
    if (lowerQuery.contains('netflix') || lowerQuery.contains('prime') || 
        lowerQuery.contains('streaming') || lowerQuery.contains('plataforma')) {
      return '📺 Olha só! Não consigo verificar disponibilidade em tempo real, mas posso recomendar ótimos títulos. Me conta que gênero ou humor você está buscando que eu indico os melhores!';
    }
    
    // Generic but much better than before
    return '🎬 Interessante! Para dar a recomendação perfeita, me conta: que gênero te anima mais agora? Ação, drama, comédia, terror? Ou tem algum filme que você curtiu recentemente que eu posso usar de referência?';
  }
  
  void dispose() {
    _httpClient.close();
  }
}