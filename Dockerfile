# rebuild trigger

# --- Stage 1: Build Lago Front ---
FROM node:22-alpine AS build

WORKDIR /app

# Install core utilities and pnpm
RUN apk add --no-cache python3 build-base && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

# Copy dependency manifests first (for better caching)
COPY package.json pnpm-lock.yaml pnpmfile.docker.cjs ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy the rest of the project
COPY . .

# Re-link workspaces and build
RUN pnpm install --recursive --prefer-offline
RUN pnpm build && echo "--- DIST CONTENTS ---" && ls -la dist


# --- Stage 2: Serve via Nginx ---
FROM nginx:1.27-alpine

WORKDIR /usr/share/nginx/html

# Install minimal utilities
RUN apk add --no-cache bash curl && \
    apk update && apk upgrade libx11 nghttp2 openssl tiff busybox

# Copy built files and nginx config
COPY --from=build /app/dist ./
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./nginx/gzip.conf /etc/nginx/conf.d/gzip.conf

# ✅ Add a startup script to generate env-config.js dynamically
COPY ./.env.sh /docker-entrypoint.d/99-generate-env.sh
RUN chmod +x /docker-entrypoint.d/99-generate-env.sh

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
