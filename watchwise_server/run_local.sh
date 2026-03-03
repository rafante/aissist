#!/bin/bash

# Get dependencies
dart pub get

# Generate serverpod code
serverpod generate --force

# Run the server in development mode
dart bin/main.dart --mode development
