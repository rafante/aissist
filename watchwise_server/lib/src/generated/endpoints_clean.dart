import 'package:serverpod/serverpod.dart' as _i1;
import '../greetings/greeting_endpoint.dart' as _i2;
import '../content/content_endpoint.dart' as _i3;

/// Clean endpoints without auth dependencies
class CleanEndpoints extends _i1.EndpointDispatch {
  @override
  void initializeEndpoints(_i1.Server server) {
    var endpoints = <String, _i1.Endpoint>{
      'greeting': _i2.GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
      'content': _i3.ContentEndpoint()
        ..initialize(
          server,
          'content',
          null,
        ),
    };
    
    // Greeting endpoint connectors
    connectors['greeting'] = _i1.EndpointConnector(
      name: 'greeting',
      endpoint: endpoints['greeting']!,
      methodConnectors: {
        'hello': _i1.MethodConnector(
          name: 'hello',
          params: {
            'name': _i1.ParameterDescription(
              name: 'name',
              type: _i1.getType<String>(),
              nullable: false,
            ),
          },
          call: (session, params) async => 
            (endpoints['greeting'] as _i2.GreetingEndpoint).hello(
              session,
              params['name'],
            ),
        ),
      },
    );

    // Content endpoint connectors  
    connectors['content'] = _i1.EndpointConnector(
      name: 'content',
      endpoint: endpoints['content']!,
      methodConnectors: {
        'searchMovies': _i1.MethodConnector(
          name: 'searchMovies',
          params: {
            'query': _i1.ParameterDescription(
              name: 'query',
              type: _i1.getType<String>(),
              nullable: false,
            ),
            'page': _i1.ParameterDescription(
              name: 'page',
              type: _i1.getType<int>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String>(),
              nullable: true,
            ),
          },
          call: (session, params) async => 
            (endpoints['content'] as _i3.ContentEndpoint).searchMovies(
              session,
              query: params['query'],
              page: params['page'] ?? 1,
              language: params['language'] ?? 'pt-BR',
            ),
        ),
        'getPopularMovies': _i1.MethodConnector(
          name: 'getPopularMovies',
          params: {
            'page': _i1.ParameterDescription(
              name: 'page',
              type: _i1.getType<int>(),
              nullable: true,
            ),
            'language': _i1.ParameterDescription(
              name: 'language',
              type: _i1.getType<String>(),
              nullable: true,
            ),
          },
          call: (session, params) async => 
            (endpoints['content'] as _i3.ContentEndpoint).getPopularMovies(
              session,
              page: params['page'] ?? 1,
              language: params['language'] ?? 'pt-BR',
            ),
        ),
      },
    );
  }
}