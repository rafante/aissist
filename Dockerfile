# Multi-stage build for Dart application
FROM dart:stable AS build

# Copy the entire project
WORKDIR /app
COPY . .

# Get dependencies and compile
WORKDIR /app/watchwise_server
RUN dart pub get
RUN dart compile exe bin/simple_main.dart -o main

# Runtime stage  
FROM debian:bullseye-slim
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/watchwise_server/main .

# Expose port
EXPOSE 8081

# Environment variables
ENV PORT=8081
ENV TMDB_API_KEY=466fd9ba21e369cd51e7743d32b7833f

# Start the server
CMD ["./main"]