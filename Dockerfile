FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install || echo "No package.json, skipping npm install"

# Copy server and HTML files
COPY server.js .
COPY watchwise_server/web/static/ ./watchwise_server/web/static/

EXPOSE 8080

CMD ["node", "server.js"]