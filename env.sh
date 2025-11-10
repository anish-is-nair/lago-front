#!/bin/bash
set -e

echo "Generating env-config.js from environment variables..."

cat <<EOF > /usr/share/nginx/html/env-config.js
window.env = {
  LAGO_API_URL: "${LAGO_API_URL}",
  NEXT_PUBLIC_API_URL: "${NEXT_PUBLIC_API_URL}",
  API_URL: "${API_URL:-${LAGO_API_URL}}"
};
EOF

echo "✅ env-config.js created with:"
cat /usr/share/nginx/html/env-config.js
