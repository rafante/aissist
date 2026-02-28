# Use official Dart runtime as base image
FROM dart:3.11.0

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec file first
COPY pubspec.yaml ./

# Get dependencies with verbose output for debugging
RUN dart pub get --verbose

# Copy all source code
COPY . .

# Compile the simple application (avoiding Serverpod complexity for now)
RUN dart compile exe bin/simple_main.dart -o bin/server

# Expose port
EXPOSE 8081

# Set environment variables with defaults
ENV POSTGRES_HOST=${POSTGRES_HOST:-rwk0o4osos80sgccso4g00co}
ENV POSTGRES_PORT=${POSTGRES_PORT:-5432}
ENV POSTGRES_DB=${POSTGRES_DB:-postgres}
ENV POSTGRES_USER=${POSTGRES_USER:-postgres}
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-AiSsIsT2024!SecurePassword}
ENV REDIS_HOST=${REDIS_HOST:-redis}
ENV REDIS_PORT=${REDIS_PORT:-6379}
ENV REDIS_PASSWORD=${REDIS_PASSWORD:-password}
ENV TMDB_API_KEY=${TMDB_API_KEY}

# Run the application
CMD ["./bin/server"]