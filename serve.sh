#!/usr/bin/env bash
# Serve the course site locally at http://localhost:4000
# Usage: ./serve.sh [port]   (default port: 4000)

set -euo pipefail
cd "$(dirname "$0")"

PORT="${1:-4000}"

command -v bundle >/dev/null || { echo "bundler not found. Install with: gem install bundler"; exit 1; }

if [ ! -d "vendor/bundle" ] || [ Gemfile -nt Gemfile.lock ]; then
  echo "→ Installing gems into vendor/bundle..."
  bundle config set --local path 'vendor/bundle'
  bundle install
fi

echo "→ Serving on http://localhost:${PORT}  (Ctrl-C to stop)"
exec bundle exec jekyll serve \
  --host 0.0.0.0 \
  --port "${PORT}" \
  --livereload \
  --incremental