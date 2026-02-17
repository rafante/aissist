import 'dart:io';
import 'dart:convert';

/// Quick test script to verify AI integration is working
Future<void> main() async {
  print('🤖 Testing AIssist AI Integration...\n');
  
  final testQueries = [
    'Filmes como Inception mas menos confuso',
    'Terror psicológico tipo Black Mirror', 
    'Comédia romântica que não seja piegas',
    'Ação com protagonista feminino forte',
    'Drama que me faça chorar',
  ];
  
  for (final query in testQueries) {
    print('🎬 Testing: "$query"');
    await testAIQuery(query);
    print('${'='*60}\n');
  }
}

Future<void> testAIQuery(String query) async {
  try {
    final client = HttpClient();
    final request = await client.postUrl(
      Uri.parse('http://localhost:8081/ai/chat'),
    );
    
    request.headers.contentType = ContentType.json;
    
    final body = jsonEncode({'query': query});
    request.write(body);
    
    print('📤 Sending request...');
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    
    if (response.statusCode == 200) {
      final data = jsonDecode(responseBody);
      
      if (data['success'] == true) {
        print('✅ Status: SUCCESS');
        print('🤖 AI Response: ${data['ai_response']}');
        
        if (data['movie_suggestions'] != null && data['movie_suggestions'].isNotEmpty) {
          print('🎬 Movie Suggestions:');
          for (final movie in data['movie_suggestions']) {
            print('   - ${movie['title']} (${movie['release_date']?.split('-')[0] ?? 'N/A'})');
          }
        }
      } else {
        print('❌ Status: FAILED');
        print('Error: ${data['error'] ?? 'Unknown error'}');
      }
    } else {
      print('❌ HTTP Error ${response.statusCode}');
      print('Response: $responseBody');
    }
    
    client.close();
  } catch (e) {
    print('❌ Exception: $e');
  }
}