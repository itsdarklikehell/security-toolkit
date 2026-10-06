#!/usr/bin/env bash
set -euo pipefail

# Secret Scanner — detecteert hardcoded secrets in code
# Gebruik: bash scripts/secret-scan.sh [DIRECTORY]

SCAN_DIR="${1:-.}"
EXIT_CODE=0
FOUND_SECRETS=0

# Kleuren
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "=== Secret Scanning ==="
echo "Scanning directory: $SCAN_DIR"
echo ""

# Secret patterns: naam|regex|beschrijving
SECRET_PATTERNS=(
  "AWS Access Key|AKIA[0-9A-Z]{16}|AWS access key"
  "AWS Secret Key|['\"][0-9a-zA-Z\/+]{40}['\"]|AWS secret key"
  "GitHub Token|ghp_[0-9a-zA-Z]{36}|GitHub personal access token"
  "GitHub OAuth|gho_[0-9a-zA-Z]{36}|GitHub OAuth token"
  "GitHub App|ghs_[0-9a-zA-Z]{36}|GitHub app token"
  "GitLab Token|glpat-[0-9a-zA-Z\-]{20}|GitLab personal access token"
  "Slack Token|xox[baprs]-[0-9a-zA-Z\-]{10,}|Slack token"
  "Stripe Key|sk_live_[0-9a-zA-Z]{24}|Stripe live secret key"
  "Stripe Test|sk_test_[0-9a-zA-Z]{24}|Stripe test secret key"
  "Google API Key|AIza[0-9A-Za-z\-_]{35}|Google API key"
  "JWT Token|eyJ[A-Za-z0-9\-_]+\.eyJ[A-Za-z0-9\-_]+\.[A-Za-z0-9\-_]+|JWT token"
  "Private Key|-----BEGIN [A-Z ]*PRIVATE KEY-----|Private key"
  "Password in URL|https?://[^:]+:[^@]+@|Password in URL"
  "API Key generic|['\"]?api[_-]?key['\"]?\s*[:=]\s*['\"][^'\"]{16,}['\"]|Generic API key"
  "Secret generic|['\"]?secret['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]|Generic secret"
  "Token generic|['\"]?token['\"]?\s*[:=]\s*['\"][^'\"]{16,}['\"]|Generic token"
  "DB Password|['\"]?password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]|Database password"
  "npm Token|npm_[0-9a-zA-Z]{36}|npm access token"
  "Datadog Key|['\"][0-9a-f]{32}['\"]|Datadog API key"
  "SendGrid Key|SG\.[0-9A-Za-z\-_]{22}\.[0-9A-Za-z\-_]{43}|SendGrid API key"
  "Twilio Key|SK[0-9a-fA-F]{32}|Twilio API key"
  "Heroku Key|['\"][0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}['\"]|Heroku API key"
)

# Bestanden om te skippen
SKIP_PATTERNS=(
  '\.git/'
  'node_modules/'
  'vendor/'
  '\.lock$'
  '\.min\.js$'
  '\.min\.css$'
  'package-lock\.json$'
  'yarn\.lock$'
  'pnpm-lock\.yaml$'
  'Cargo\.lock$'
  'poetry\.lock$'
  'Pipfile\.lock$'
  '\.sum$'
  '\.test\.'
  '_test\.'
  'test_'
  '\.md$'
  '\.svg$'
  '\.png$'
  '\.jpg$'
  '\.ico$'
  '\.woff'
  '\.ttf$'
  '\.eot$'
)

should_skip() {
  local file="$1"
  for pattern in "${SKIP_PATTERNS[@]}"; do
    if echo "$file" | grep -qE "$pattern"; then
      return 0
    fi
  done
  return 1
}

# Scan elk bestand
while IFS= read -r -d '' file; do
  if should_skip "$file"; then
    continue
  fi

  for secret_def in "${SECRET_PATTERNS[@]}"; do
    IFS='|' read -r name pattern description <<< "$secret_def"

    matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
    if [ -n "$matches" ]; then
      echo -e "${RED}[SECRET]${NC} $file: $name"
      echo "$matches" | while IFS= read -r line; do
        echo "  $line"
      done
      echo ""
      FOUND_SECRETS=$((FOUND_SECRETS + 1))
      EXIT_CODE=1
    fi
  done
done < <(find "$SCAN_DIR" -type f -print0 2>/dev/null)

echo ""
if [ "$FOUND_SECRETS" -gt 0 ]; then
  echo -e "${RED}Found $FOUND_SECRETS potential secret(s)${NC}"
else
  echo -e "${GREEN}No secrets found${NC}"
fi

exit $EXIT_CODE
