#!/bin/sh
set -e

# Substitute BACKEND_API_URL (and any other variables that exist in the
# template) into the runtime config that the browser loads.
export BACKEND_API_URL="${BACKEND_API_URL:-http://localhost:8080}"

envsubst '${BACKEND_API_URL}' \
  < /usr/share/nginx/html/env-config.js.template \
  > /usr/share/nginx/html/env-config.js

exec "$@"
