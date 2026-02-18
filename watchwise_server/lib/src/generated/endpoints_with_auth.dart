// Generated endpoints with authentication support
// This includes all endpoints: auth, AI, content, etc.

import 'package:serverpod/serverpod.dart';

// Import all endpoints
import '../auth/auth_endpoint.dart';
import '../ai/ai_endpoint.dart';
import '../content/content_endpoint.dart';
import '../greetings/greeting_endpoint.dart';

/// Endpoints with authentication support
class AuthenticatedEndpoints extends EndpointDispatch {
  @override
  void initializeEndpoints(Server server) {
    // Authentication endpoints (public)
    server.addEndpoint('auth', AuthEndpoint());
    
    // AI endpoints (mixed: public + authenticated)
    server.addEndpoint('ai', AiEndpoint());
    
    // Content endpoints (public)
    server.addEndpoint('content', ContentEndpoint());
    
    // Greeting endpoints (public)
    server.addEndpoint('greeting', GreetingEndpoint());
  }

  @override
  EndpointConnector? getConnector(String endpointName) {
    switch (endpointName) {
      case 'auth':
        return EndpointConnector(
          name: 'auth',
          endpoint: AuthEndpoint(),
          methodConnectors: {
            'signup': MethodConnector(
              name: 'signup',
              params: {
                'email': ParameterDescription(name: 'email', type: String, nullable: false),
                'password': ParameterDescription(name: 'password', type: String, nullable: false),
              },
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).signup(
                session,
                params['email'],
                params['password'],
              ),
            ),
            'login': MethodConnector(
              name: 'login',
              params: {
                'email': ParameterDescription(name: 'email', type: String, nullable: false),
                'password': ParameterDescription(name: 'password', type: String, nullable: false),
              },
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).login(
                session,
                params['email'],
                params['password'],
              ),
            ),
            'me': MethodConnector(
              name: 'me',
              params: {},
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).me(session),
            ),
            'usage': MethodConnector(
              name: 'usage',
              params: {},
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).usage(session),
            ),
            'checkLimit': MethodConnector(
              name: 'checkLimit',
              params: {},
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).checkLimit(session),
            ),
            'logout': MethodConnector(
              name: 'logout',
              params: {},
              call: (endpoint, session, params) => (endpoint as AuthEndpoint).logout(session),
            ),
          },
        );
      case 'ai':
        return EndpointConnector(
          name: 'ai',
          endpoint: AiEndpoint(),
          methodConnectors: {
            'chat': MethodConnector(
              name: 'chat',
              params: {
                'query': ParameterDescription(name: 'query', type: String, nullable: false),
                'language': ParameterDescription(name: 'language', type: String, nullable: true),
              },
              call: (endpoint, session, params) => (endpoint as AiEndpoint).chat(
                session,
                query: params['query'],
                language: params['language'] ?? 'pt-BR',
              ),
            ),
            'chatPublic': MethodConnector(
              name: 'chatPublic',
              params: {
                'query': ParameterDescription(name: 'query', type: String, nullable: false),
                'language': ParameterDescription(name: 'language', type: String, nullable: true),
              },
              call: (endpoint, session, params) => (endpoint as AiEndpoint).chatPublic(
                session,
                query: params['query'],
                language: params['language'] ?? 'pt-BR',
              ),
            ),
            'status': MethodConnector(
              name: 'status',
              params: {},
              call: (endpoint, session, params) => (endpoint as AiEndpoint).status(session),
            ),
          },
        );
      case 'content':
        return EndpointConnector(
          name: 'content',
          endpoint: ContentEndpoint(),
          methodConnectors: {
            'searchMovies': MethodConnector(
              name: 'searchMovies',
              params: {
                'query': ParameterDescription(name: 'query', type: String, nullable: false),
                'page': ParameterDescription(name: 'page', type: int, nullable: true),
                'language': ParameterDescription(name: 'language', type: String, nullable: true),
              },
              call: (endpoint, session, params) => (endpoint as ContentEndpoint).searchMovies(
                session,
                query: params['query'],
                page: params['page'] ?? 1,
                language: params['language'] ?? 'pt-BR',
              ),
            ),
            // Add other content methods as needed...
          },
        );
      case 'greeting':
        return EndpointConnector(
          name: 'greeting',
          endpoint: GreetingEndpoint(),
          methodConnectors: {
            'hello': MethodConnector(
              name: 'hello',
              params: {
                'name': ParameterDescription(name: 'name', type: String, nullable: false),
              },
              call: (endpoint, session, params) => (endpoint as GreetingEndpoint).hello(
                session,
                params['name'],
              ),
            ),
          },
        );
      default:
        return null;
    }
  }
}

/// Parameter description for endpoint methods
class ParameterDescription {
  final String name;
  final Type type;
  final bool nullable;

  const ParameterDescription({
    required this.name,
    required this.type,
    required this.nullable,
  });
}

/// Method connector for endpoint methods
class MethodConnector {
  final String name;
  final Map<String, ParameterDescription> params;
  final Function call;

  const MethodConnector({
    required this.name,
    required this.params,
    required this.call,
  });
}

/// Endpoint connector
class EndpointConnector {
  final String name;
  final Endpoint endpoint;
  final Map<String, MethodConnector> methodConnectors;

  const EndpointConnector({
    required this.name,
    required this.endpoint,
    required this.methodConnectors,
  });
}