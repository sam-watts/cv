#!/bin/sh
# Builds the site and prints it to sam-watts-cv.pdf using the print styles.
# Re-run after editing the CV, then commit the PDF alongside your changes:
#   ./_scripts/build-pdf.sh
# Needs Docker and Google Chrome. (Lives in _scripts so Jekyll doesn't publish it.)
# Also run by .github/workflows/build-pdf.yml, which sets CHROME and CHROME_FLAGS.
set -e

ROOT=$(cd "$(dirname "$0")/.." && pwd)
OUT="$ROOT/sam-watts-cv.pdf"
SITE=$(mktemp -d)
PORT=4567
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

echo "Building site..."
# on Linux (e.g. CI), make the container write files as the current user
USER_ENV=""
if [ "$(uname)" = "Linux" ]; then USER_ENV="-e JEKYLL_UID=$(id -u) -e JEKYLL_GID=$(id -g)"; fi
docker run --rm --platform linux/amd64 $USER_ENV \
  -v "$ROOT":/srv/jekyll -v "$SITE":/out jekyll/jekyll:3.8 \
  sh -c "bundle install >/dev/null && jekyll build -d /out" >/dev/null

python3 -m http.server "$PORT" --directory "$SITE" >/dev/null 2>&1 &
SERVER=$!
trap 'kill $SERVER; wait $SERVER 2>/dev/null || true; rm -rf "$SITE"' EXIT
sleep 1

echo "Printing PDF..."
"$CHROME" --headless=new --disable-gpu --no-pdf-header-footer --virtual-time-budget=5000 $CHROME_FLAGS \
  --print-to-pdf="$OUT" "http://localhost:$PORT/index.html" 2>/dev/null

echo "Wrote $OUT"
