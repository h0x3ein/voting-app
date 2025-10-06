# syntax=docker/dockerfile:1.7
FROM node:20-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install all dependencies (prod + dev)
RUN npm ci

# Copy source files
COPY . .

# ========== Production stage ==========
FROM node:20-alpine AS prod

WORKDIR /app

# Copy only production dependencies
COPY package*.json ./
RUN npm ci --omit=dev

# Copy source files
COPY . .

USER node
EXPOSE 5000

CMD ["npm", "start"]
