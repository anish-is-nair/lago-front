# Stage 1: Build Lago Front
FROM node:22-alpine AS build

WORKDIR /app

# Install core utilities and pnpm
RUN apk add --no-cache python3 build-base && \
    corepack enable && \
    corepack prepare pnpm@latest --activate

# Copy dependency manifests first (for better caching)
COPY package.json pnpm-lock.yaml pnpmfile.docker.cjs ./

# Install dependencies (only root first for caching)
RUN pnpm install --frozen-lockfile

# Copy the rest of the project
COPY . .

# Re-link workspaces (important for packages like design-system)
RUN pnpm install --recursive --prefer-offline

# Build project
RUN pnpm build && ls -l dist

# Stage 2: Serve via Nginx
FROM nginx:1.27-alpine

WORKDIR /usr/share/nginx/html

# Install basic tools (optional but safe)
RUN apk add --no-cache bash curl && \
    apk update && apk upgrade libx11 nghttp2 openssl tiff busybox

# Copy built files from build stage
COPY --from=build /app/dist ./

# Copy nginx configs
COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf
COPY ./nginx/gzip.conf /etc/nginx/conf.d/gzip.conf

# Expose web port
EXPOSE 80

# Launch nginx
CMD ["nginx", "-g", "daemon off;"]

# FROM node:22-alpine AS build

# WORKDIR /app

# RUN apk add python3 build-base && corepack enable && corepack prepare pnpm@latest --activate

# COPY package.json pnpm-lock.yaml pnpmfile.docker.cjs ./
# RUN pnpm install --pnpmfile=./pnpmfile.docker.cjs
# COPY . .
# RUN pnpm install && pnpm build

# FROM nginx:1.27-alpine

# WORKDIR /usr/share/nginx/html

# RUN apk add --no-cache bash
# RUN apk update && apk upgrade libx11 nghttp2 openssl tiff curl busybox

# COPY --from=build /app/dist .
# COPY ./nginx/nginx.conf /etc/nginx/conf.d/default.conf
# COPY ./nginx/gzip.conf /etc/nginx/conf.d/gzip.conf
# COPY ./.env.sh ./.env.sh

# EXPOSE 80

# ENTRYPOINT ["/bin/bash", "-c", "./.env.sh && nginx -g \"daemon off;\""]
