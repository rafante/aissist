FROM node:18-alpine

WORKDIR /app

# Copy all files first
COPY . .

# Install dependencies if package.json exists
RUN npm install || echo "No package.json, skipping npm install"

# Make sure static files are accessible
RUN ls -la watchwise_server/web/static/ || echo "Static files not found"

EXPOSE 8080

CMD ["node", "server.js"]