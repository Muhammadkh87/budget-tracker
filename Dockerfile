# ================================
# Stage 1 — Builder
# ================================

FROM node:20-alpine AS builder

WORKDIR /app

# Install build tools needed for native modules like better-sqlite3
# better-sqlite3 compiles C++ code during npm install
# Alpine doesn't have these tools by default so we install them:
# python3  → needed by node-gyp to compile native addons
# make     → build tool
# g++      → C++ compiler
RUN apk add --no-cache python3 make g++

COPY package*.json ./

RUN npm install

COPY . .

# ================================
# Stage 2 — Production
# ================================

# Also update production stage to Node 20
FROM node:20-alpine AS production

WORKDIR /app

# Copy node_modules from builder (already compiled, no build tools needed)
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/server.js .
COPY --from=builder /app/database.js .
COPY --from=builder /app/public ./public

EXPOSE 3000

CMD ["node", "server.js"]