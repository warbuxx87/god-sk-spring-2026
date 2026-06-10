#!/usr/bin/env bash
set -euo pipefail

# Manual release helper when you need to cut a version outside Release Please.
# Usage: ./scripts/release.sh [patch|minor|major]

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

bump="${1:-patch}"
current="$(jq -r '.version' package.json)"

IFS='.' read -r major minor patch <<< "${current//v/}"
case "$bump" in
  major) major=$((major + 1)); minor=0; patch=0 ;;
  minor) minor=$((minor + 1)); patch=0 ;;
  patch) patch=$((patch + 1)) ;;
  *)
    echo "Usage: $0 [patch|minor|major]" >&2
    exit 1
    ;;
esac

next="${major}.${minor}.${patch}"
today="$(date +%Y-%m-%d)"
tag="v${next}"

jq --arg v "$next" '.version = $v' package.json > package.json.tmp && mv package.json.tmp package.json

perl -pi -e "s/content=\"[^\"]+\"<!-- x-release-please-version -->/content=\"${next}\"<!-- x-release-please-version -->/" index.html
perl -pi -e "s/>v[^<]+<\\/span><!-- x-release-please-version -->/>v${next}<\\/span><!-- x-release-please-version -->/" index.html
perl -pi -e "s/version: '[^']+', \\/\\/ x-release-please-version/version: '${next}', \\/\\/ x-release-please-version/" index.html

if ! grep -q "## \\[${next}\\]" CHANGELOG.md; then
  tmp="$(mktemp)"
  {
    head -n 7 CHANGELOG.md
    echo
    echo "## [${next}] - ${today}"
    echo
    echo "### Changed"
    echo
    echo "- Describe changes here"
    echo
    tail -n +8 CHANGELOG.md
  } > "$tmp"
  mv "$tmp" CHANGELOG.md
fi

echo "Bumped version to ${next}"
echo "Review CHANGELOG.md, then commit and tag:"
echo "  git add package.json CHANGELOG.md index.html"
echo "  git commit -m \"chore: release ${next}\""
echo "  git tag ${tag}"
echo "  git push && git push origin ${tag}"
echo "  gh release create ${tag} --generate-notes index.html"
