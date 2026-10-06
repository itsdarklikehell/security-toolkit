#!/usr/bin/env bash
set -euo pipefail

# Security Audit — uitgebreide security checks
# Gebruik: bash scripts/security-audit.sh [DIRECTORY]

SCAN_DIR="${1:-.}"
EXIT_CODE=0
ISSUES=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Security Audit ==="
echo "Scanning directory: $SCAN_DIR"
echo ""

# Check 1: World-writable bestanden
echo "--- World-writable files ---"
WW_COUNT=0
while IFS= read -r -d '' file; do
  perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null || echo "000")
  if [ "$perms" = "777" ]; then
    echo -e "  ${RED}[HIGH]${NC} World-writable: $file"
    WW_COUNT=$((WW_COUNT + 1))
    ISSUES=$((ISSUES + 1))
  fi
done < <(find "$SCAN_DIR" -type f -not -path '*/.git/*' -print0 2>/dev/null)
if [ "$WW_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}None found${NC}"
fi
echo ""

# Check 2: SUID/SGID bestanden
echo "--- SUID/SGID files ---"
SUID_COUNT=0
while IFS= read -r -d '' file; do
  perms=$(stat -c '%a' "$file" 2>/dev/null || stat -f '%Lp' "$file" 2>/dev/null || echo "000")
  # SUID/SGID: 4-cijferige perms waar eerste cijfer >= 4 (SUID=4, SGID=2, beide=6)
  if [ "${#perms}" -ge 4 ]; then
    suid_bit="${perms:0:1}"
    if [ "$suid_bit" -ge 4 ] 2>/dev/null; then
      echo -e "  ${RED}[CRITICAL]${NC} SUID/SGID: $file (perms: $perms)"
      SUID_COUNT=$((SUID_COUNT + 1))
      ISSUES=$((ISSUES + 1))
    fi
  fi
done < <(find "$SCAN_DIR" -type f -not -path '*/.git/*' -print0 2>/dev/null)
if [ "$SUID_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}None found${NC}"
fi
echo ""

# Check 3: Hardcoded credentials in config files
echo "--- Hardcoded credentials in configs ---"
CRED_PATTERNS=(
  "password\s*=\s*['\"][^'\"]\{8,\}['\"]"
  "secret\s*=\s*['\"][^'\"]\{8,\}['\"]"
  "api[_-]?key\s*=\s*['\"][^'\"]\{16,\}['\"]"
  "token\s*=\s*['\"][^'\"]\{16,\}['\"]"
  "BEGIN.*PRIVATE KEY"
)
CRED_COUNT=0
CONFIG_FILES=(
  "*.env"
  "*.env.*"
  ".env"
  ".env.*"
  "config.json"
  "config.yaml"
  "config.yml"
  "*.config.js"
  "*.config.ts"
  "settings.json"
  "settings.yaml"
  "settings.yml"
  "*.ini"
  "*.cfg"
  "*.conf"
)
for pattern in "${CONFIG_FILES[@]}"; do
  while IFS= read -r -d '' file; do
    for cred_pat in "${CRED_PATTERNS[@]}"; do
      if grep -qEi "$cred_pat" "$file" 2>/dev/null; then
        echo -e "  ${YELLOW}[MEDIUM]${NC} Possible credential in: $file"
        CRED_COUNT=$((CRED_COUNT + 1))
        ISSUES=$((ISSUES + 1))
        break
      fi
    done
  done < <(find "$SCAN_DIR" -name "$pattern" -not -path '*/.git/*' -not -path '*/node_modules/*' -print0 2>/dev/null)
done
if [ "$CRED_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}None found${NC}"
fi
echo ""

# Check 4: Security headers in web configs
echo "--- Security headers (web configs) ---"
WEB_CONFIG_FILES=(
  "nginx.conf"
  "*.nginx.conf"
  ".htaccess"
  "web.config"
  "Caddyfile"
)
SECURITY_HEADERS=(
  "Strict-Transport-Security"
  "X-Content-Type-Options"
  "X-Frame-Options"
  "Content-Security-Policy"
  "X-XSS-Protection"
  "Referrer-Policy"
  "Permissions-Policy"
)
HEADER_COUNT=0
for pattern in "${WEB_CONFIG_FILES[@]}"; do
  while IFS= read -r -d '' file; do
    echo "  Checking: $file"
    for header in "${SECURITY_HEADERS[@]}"; do
      if ! grep -qi "$header" "$file" 2>/dev/null; then
        echo -e "    ${YELLOW}[LOW]${NC} Missing header: $header"
        HEADER_COUNT=$((HEADER_COUNT + 1))
      fi
    done
  done < <(find "$SCAN_DIR" -name "$pattern" -not -path '*/.git/*' -print0 2>/dev/null)
done
if [ "$HEADER_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}All security headers present${NC}"
fi
echo ""

# Check 5: Outdated dependencies in package.json
echo "--- Outdated npm dependencies ---"
if command -v npm &>/dev/null; then
  for pkg_json in $(find "$SCAN_DIR" -name "package.json" -not -path "*/node_modules/*" 2>/dev/null); do
    dir=$(dirname "$pkg_json")
    echo "  Checking: $dir"
    outdated=$(cd "$dir" && npm outdated --json 2>/dev/null || true)
    if [ -n "$outdated" ] && [ "$outdated" != "{}" ]; then
      echo "$outdated" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for pkg, info in data.items():
        current = info.get('current', '?')
        latest = info.get('latest', '?')
        if current != latest:
            print(f'    {pkg}: {current} -> {latest}')
except:
    pass
" 2>/dev/null || echo "    (npm outdated failed)"
      echo ""
    fi
  done
else
  echo "  npm not installed"
fi
echo ""

# Check 6: File permissions summary
echo "--- File permissions summary ---"
TOTAL_FILES=0
EXEC_FILES=0
while IFS= read -r -d '' file; do
  TOTAL_FILES=$((TOTAL_FILES + 1))
  if [ -x "$file" ]; then
    EXEC_FILES=$((EXEC_FILES + 1))
  fi
done < <(find "$SCAN_DIR" -type f -not -path '*/.git/*' -print0 2>/dev/null)
echo "  Total files: $TOTAL_FILES"
echo "  Executable files: $EXEC_FILES"
echo ""

# Check 7: .gitignore check
echo "--- .gitignore check ---"
if [ -f "$SCAN_DIR/.gitignore" ]; then
  echo -e "  ${GREEN}.gitignore found${NC}"
  GI_PATTERNS=(
    "node_modules/"
    ".env"
    "__pycache__/"
    "*.pyc"
    "*.log"
    ".DS_Store"
    "dist/"
    "build/"
    "*.egg-info/"
    ".venv/"
    "venv/"
  )
  for gi in "${GI_PATTERNS[@]}"; do
    if ! grep -qF "$gi" "$SCAN_DIR/.gitignore" 2>/dev/null; then
      # Also check for character-class variants (e.g. *.py[cod] covers *.pyc)
      if [ "$gi" = "*.pyc" ] && grep -qF "*.py[cod]" "$SCAN_DIR/.gitignore" 2>/dev/null; then
        continue
      fi
      echo -e "  ${YELLOW}[LOW]${NC} Missing in .gitignore: $gi"
    fi
  done
else
  echo -e "  ${YELLOW}[MEDIUM]${NC} No .gitignore found"
  ISSUES=$((ISSUES + 1))
fi
echo ""

# Samenvatting
echo "=== Summary ==="
if [ "$ISSUES" -gt 0 ]; then
  echo -e "${RED}Found $ISSUES security issue(s)${NC}"
  EXIT_CODE=1
else
  echo -e "${GREEN}No security issues found${NC}"
fi

exit $EXIT_CODE
