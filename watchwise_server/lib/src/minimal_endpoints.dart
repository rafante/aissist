import 'package:serverpod/serverpod.dart';
import 'content/content_endpoint.dart';

/// Minimal endpoint dispatcher for AIssist
class MinimalEndpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {
    var endpoints = <String, Endpoint>{
      'content': ContentEndpoint()
        ..initialize(
          server,
          'content',
          null,
        ),
      'greeting': GreetingEndpoint()
        ..initialize(
          server,
          'greeting',
          null,
        ),
    };

    // Register the endpoints
    endpoints.forEach((name, endpoint) {
      connectors[name] = EndpointConnector(
        name: name,
        endpoint: endpoint,
        methodConnectors: _createMethodConnectors(name, endpoint),
      );
    });
  }

  Map<String, MethodConnector> _createMethodConnectors(String name, Endpoint endpoint) {
    if (name == 'content') {
      return {
        'searchMovies': MethodConnector(
          name: 'searchMovies',
          params: {
            'query': ParameterDescription(
              name: 'query',
              type: getType<String>(),
              nullable: false,
            ),
            'page': ParameterDescription(
              name: 'page',
              type: getType<int>(),
              nullable: true,
            ),
            'language': ParameterDescription(
              name: 'language',
              type: getType<String>(),
              nullable: true,
            ),
          },
          call: (session, params) async => 
            (endpoint as ContentEndpoint).searchMovies(
              session,
              query: params['query'],
              page: params['page'] ?? 1,
              language: params['language'] ?? 'pt-BR',
            ),
        ),
        'getPopularMovies': MethodConnector(
          name: 'getPopularMovies',
          params: {},
          call: (session, params) async => 
            (endpoint as ContentEndpoint).getPopularMovies(session),
        ),
      };
    }
    return {};
  }
}

/// Simple greeting endpoint for testing
class GreetingEndpoint extends Endpoint {
  Future<String> hello(Session session, String name) async {
    return 'Hello $name from AIssist API!';
  }
}