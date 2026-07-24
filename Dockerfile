FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm install --production

FROM node:20-alpine

WORKDIR /app

COPY --from=builder /app/node_modules ./node_modules
COPY . .

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

RUN mkdir -p /etc/todos && chown -R appuser:appgroup /etc/todos

USER appuser

EXPOSE 3000

CMD ["node", "src/index.js"]