# syntax=docker/dockerfile:1.7
FROM node:20.16-alpine3.20

ENV NODE_ENV=production
WORKDIR /app

# 1) Install prod deps deterministically
COPY package*.json ./
RUN npm ci --omit=dev

# 2) Copy the rest of the app
COPY . .

# 3) Run as non-root (the 'node' user exists in this image)
USER node

EXPOSE 5000
# Optional healthcheck if you expose /healthz
# HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
#   CMD wget -qO- http://127.0.0.1:5000/healthz || exit 1

CMD ["npm", "start"]