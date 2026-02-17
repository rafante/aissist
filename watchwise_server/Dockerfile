# Use official Dart runtime as base image
FROM dart:3.11.0

# Install curl for healthcheck
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml ./
COPY pubspec.lock ./

# Install dependencies
RUN dart pub get

# Copy source code
COPY . .

# Compile the application
RUN dart compile exe bin/main.dart -o bin/server

# Expose port
EXPOSE 8080

# Set environment variables
ENV POSTGRES_HOST=postgres
ENV POSTGRES_PORT=5432
ENV POSTGRES_DB=watchwise
ENV POSTGRES_USER=postgres
ENV POSTGRES_PASSWORD=5DSV-jq2bDFrY7oUFXvksaRamSiyJ8nO
ENV REDIS_HOST=redis
ENV REDIS_PORT=6379
ENV REDIS_PASSWORD=hRTeXLSLqSx0VPI0IL0b5nUbKKDntbfq
ENV TMDB_API_KEY=466fd9ba21e369cd51e7743d32b7833f

# Run the application
CMD ["./bin/server"]