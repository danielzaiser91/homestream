#!/usr/bin/env bash
# Cut a new HomeFlix release: stamp a fresh version into docs/version.json and
# docs/index.html (BUILD_VERSION), commit, and push. Open browser tabs pick up
# the change within 15s (auto-reload if just loaded, else an update banner).
#
# Usage:  bash scripts/release.sh "short note about what changed"
set -euo pipefail
cd "$(dirname "$0")/.."

STAMP="$(date +%Y%m%d-%H%M)"
NOTE="${1:-release $STAMP}"

cat > docs/version.json <<EOF
{
  "version": "$STAMP",
  "app": "HomeFlix",
  "notes": "$NOTE"
}
EOF

# Bump the baked BUILD_VERSION constant in the app (keeps the trailing comment).
sed -i -E 's/const BUILD_VERSION="[^"]*";/const BUILD_VERSION="'"$STAMP"'";/' docs/index.html

echo "Stamped version $STAMP"
git add docs/version.json docs/index.html
git commit -m "Release $STAMP: $NOTE"
git push
echo "Pushed. Live in ~1-2 min; open pages update within 15s."
