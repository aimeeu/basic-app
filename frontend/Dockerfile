# ── Build stage ───────────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

COPY package.json ./
RUN npm ci

COPY public/ public/
COPY src/ src/

# Build-time fallback; the real value is injected at runtime via env-config.js
ARG REACT_APP_BACKEND_API_URL=http://localhost:8080
ENV REACT_APP_BACKEND_API_URL=${REACT_APP_BACKEND_API_URL}

RUN npm run build

# ── Production stage ───────────────────────────────────────────────────────────
FROM nginx:1.27-alpine

# Install gettext for envsubst
RUN apk add --no-cache gettext

# Replace the default Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the React build output
COPY --from=builder /app/build /usr/share/nginx/html

# Copy the runtime env template (env-config.js is also present as a fallback
# from the build but will be overwritten by the entrypoint)
COPY public/env-config.js.template /usr/share/nginx/html/env-config.js.template

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# BACKEND_API_URL is the runtime environment variable consumed by the app
ENV BACKEND_API_URL=http://localhost:8080

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
