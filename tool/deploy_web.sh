#!/usr/bin/env bash
# Builds the web app without any Turso token and deploys it, with the proxy in
# web_proxy/, to Cloudflare Pages.
#
#   tool/deploy_web.sh            # production
#   tool/deploy_web.sh preview    # a preview URL, production untouched
#
# One-time setup is described in web_proxy/README.md.
set -euo pipefail

PROJECT="${PAGES_PROJECT:-petsa}"
BRANCH="main"
[[ "${1:-}" == "preview" ]] && BRANCH="preview"

cd "$(dirname "$0")/.."

echo "› Tests"
flutter test
(cd web_proxy && npm test --silent)

echo "› Building (no token; the app talks to /v3/pipeline on its own site)"
flutter build web --release --dart-define=TURSO_URL=/

# Safety net: refuse to publish a bundle that contains a Turso token.
for f in .env.local .env.test.local; do
  [[ -f "$f" ]] || continue
  for token in $(grep -o '"TURSO[A-Z_]*TOKEN": *"[^"]*"' "$f" | sed 's/.*: *"\(.*\)"/\1/'); do
    if grep -rqF "$token" build/web; then
      echo "✗ A Turso token from $f ended up in build/web; not deploying." >&2
      exit 1
    fi
  done
done
if grep -rqE 'eyJhbGciOiJFZERTQSIsInR5cCI6IkpXVCJ9\.' build/web; then
  echo "✗ build/web contains something that looks like a Turso token." >&2
  exit 1
fi

echo "› Deploying to Cloudflare Pages ($PROJECT, branch $BRANCH)"
cd web_proxy
npx --yes wrangler@4 pages deploy ../build/web \
  --project-name "$PROJECT" --branch "$BRANCH" --commit-dirty=true
