#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter build web --release
mkdir -p .vercel/output/static
rsync -a --delete build/web/ .vercel/output/static/
cat > .vercel/output/config.json <<'JSON'
{"version":3,"routes":[{"src":"/.*","headers":{"X-Content-Type-Options":"nosniff","Referrer-Policy":"strict-origin-when-cross-origin"},"continue":true},{"handle":"filesystem"},{"src":"/.*","dest":"/index.html"}]}
JSON
