# Use official Dart runtime as base image
FROM dart:3.11.0

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec file first
COPY pubspec.yaml ./

# Remove workspace resolution for standalone Docker build
RUN sed -i '/^resolution: workspace/d' pubspec.yaml

# Get dependencies with verbose output for debugging
RUN dart pub get --verbose

# Copy all source code
COPY . .

# Compile the simple application (avoiding Serverpod complexity for now)
RUN dart compile exe bin/simple_main.dart -o bin/server

# Expose port
EXPOSE 8081

# Set environment variables (Values provided by Coolify at runtime)
ENV POSTGRES_HOST=${POSTGRES_HOST}
ENV POSTGRES_PORT=${POSTGRES_PORT}
ENV POSTGRES_DB=${POSTGRES_DB}
ENV POSTGRES_USER=${POSTGRES_USER}
ENV POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
ENV REDIS_HOST=${REDIS_HOST}
ENV REDIS_PORT=${REDIS_PORT}
ENV REDIS_PASSWORD=${REDIS_PASSWORD}
ENV TMDB_API_KEY=${TMDB_API_KEY}

RUN echo "Build version: $(date)" > /app/build_date.txt

# Run the application
CMD ["./bin/server"]