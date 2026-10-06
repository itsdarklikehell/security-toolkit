#!/usr/bin/env bash
set -euo pipefail

# Compliance Check — controleert op compliance met security best practices
# Gebruik: bash scripts/compliance-check.sh [DIRECTORY]

SCAN_DIR="${1:-.}"
EXIT_CODE=0
VIOLATIONS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "=== Compliance Check ==="
echo "Scanning directory: $SCAN_DIR"
echo ""

# Check 1: License bestand
echo "--- License file ---"
if [ -f "$SCAN_DIR/LICENSE" ] || [ -f "$SCAN_DIR/LICENSE.md" ] || [ -f "$SCAN_DIR/LICENSE.txt" ]; then
  echo -e "  ${GREEN}License file found${NC}"
else
  echo -e "  ${RED}[VIOLATION]${NC} No license file found"
  VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# Check 2: README bestand
echo "--- README file ---"
if [ -f "$SCAN_DIR/README.md" ]; then
  echo -e "  ${GREEN}README found${NC}"
  # Check of README minimaal 500 tekens bevat
  README_SIZE=$(wc -c < "$SCAN_DIR/README.md")
  if [ "$README_SIZE" -lt 500 ]; then
    echo -e "  ${YELLOW}[WARNING]${NC} README is very small ($README_SIZE bytes)"
  fi
else
  echo -e "  ${RED}[VIOLATION]${NC} No README.md found"
  VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# Check 3: .gitignore bestand
echo "--- .gitignore file ---"
if [ -f "$SCAN_DIR/.gitignore" ]; then
  echo -e "  ${GREEN}.gitignore found${NC}"
  GI_PATTERNS=(
    "node_modules/"
    ".env"
    "__pycache__/"
    "*.pyc"
    "*.py[cod]"
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
      if [ "$gi" = "*.pyc" ] && grep -qF "*.py[cod]" "$SCAN_DIR/.gitignore" 2>/dev/null; then
        continue
      fi
      echo -e "  ${YELLOW}[LOW]${NC} Missing in .gitignore: $gi"
    fi
  done
else
  echo -e "  ${RED}[VIOLATION]${NC} No .gitignore found"
  VIOLATIONS=$((VIOLATIONS + 1))
fi
echo ""

# Check 4: Geen grote bestanden (>10MB)
echo "--- Large files (>10MB) ---"
LARGE_COUNT=0
while IFS= read -r -d '' file; do
  size=$(stat -c '%s' "$file" 2>/dev/null || stat -f '%z' "$file" 2>/dev/null || echo "0")
  if [ "$size" -gt 10485760 ]; then
    size_mb=$((size / 1048576))
    echo -e "  ${YELLOW}[WARNING]${NC} Large file: $file (${size_mb}MB)"
    LARGE_COUNT=$((LARGE_COUNT + 1))
  fi
done < <(find "$SCAN_DIR" -type f -not -path '*/.git/*' -print0 2>/dev/null)
if [ "$LARGE_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}No large files${NC}"
fi
echo ""

# Check 5: Geen binary bestanden in repo (behalve .git)
echo "--- Binary files ---"
BINARY_COUNT=0
while IFS= read -r -d '' file; do
  # Skip scripts met shebang
  if head -1 "$file" 2>/dev/null | grep -q '^#!'; then
    continue
  fi
  if file "$file" 2>/dev/null | grep -q "executable\|binary"; then
    rel="${file#$SCAN_DIR/}"
    # Skip .git directory
    if [[ "$rel" != .git/* ]]; then
      echo -e "  ${YELLOW}[WARNING]${NC} Binary file: $rel"
      BINARY_COUNT=$((BINARY_COUNT + 1))
    fi
  fi
done < <(find "$SCAN_DIR" -type f -not -path '*/.git/*' -print0 2>/dev/null)
if [ "$BINARY_COUNT" -eq 0 ]; then
  echo -e "  ${GREEN}No unexpected binary files${NC}"
fi
echo ""

# Check 6: Security policy
echo "--- Security policy ---"
if [ -f "$SCAN_DIR/SECURITY.md" ]; then
  echo -e "  ${GREEN}SECURITY.md found${NC}"
else
  echo -e "  ${YELLOW}[WARNING]${NC} No SECURITY.md found"
fi
echo ""

# Check 7: Contributing guide
echo "--- Contributing guide ---"
if [ -f "$SCAN_DIR/CONTRIBUTING.md" ]; then
  echo -e "  ${GREEN}CONTRIBUTING.md found${NC}"
else
  echo -e "  ${YELLOW}[WARNING]${NC} No CONTRIBUTING.md found"
fi
echo ""

# Check 8: Code of Conduct
echo "--- Code of Conduct ---"
if [ -f "$SCAN_DIR/CODE_OF_CONDUCT.md" ]; then
  echo -e "  ${GREEN}CODE_OF_CONDUCT.md found${NC}"
else
  echo -e "  ${YELLOW}[WARNING]${NC} No CODE_OF_CONDUCT.md found"
fi
echo ""

# Check 9: CI/CD workflow
echo "--- CI/CD workflow ---"
if [ -d "$SCAN_DIR/.github/workflows" ]; then
  WF_COUNT=$(find "$SCAN_DIR/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
  echo -e "  ${GREEN}Found $WF_COUNT workflow(s)${NC}"
else
  echo -e "  ${YELLOW}[WARNING]${NC} No GitHub Actions workflows found"
fi
echo ""

# Check 10: Dependencies pinned
echo "--- Dependency pinning ---"
if find "$SCAN_DIR" -name "package.json" -not -path "*/node_modules/*" | grep -q .; then
  for pkg_json in $(find "$SCAN_DIR" -name "package.json" -not -path "*/node_modules/*" 2>/dev/null); do
    dir=$(dirname "$pkg_json")
    echo "  Checking: $dir"
    # Check of dependencies gepind zijn (geen ^ of ~)
    unpinned=$(python3 -c "
import json, sys
try:
    with open('$pkg_json') as f:
        data = json.load(f)
    deps = data.get('dependencies', {})
    dev_deps = data.get('devDependencies', {})
    all_deps = {**deps, **dev_deps}
    unpinned = []
    for name, version in all_deps.items():
        if version.startswith('^') or version.startswith('~') or version == '*' or version == 'latest':
            unpinned.append(f'{name}: {version}')
    if unpinned:
        for u in unpinned:
            print(f'    {u}')
    else:
        print('    All pinned')
except Exception as e:
    print(f'    Error: {e}')
" 2>/dev/null || echo "    (check failed)")
    echo "$unpinned"
  done
else
  echo "  No package.json found"
fi
echo ""

# Samenvatting
echo "=== Summary ==="
if [ "$VIOLATIONS" -gt 0 ]; then
  echo -e "${RED}Found $VIOLATIONS compliance violation(s)${NC}"
  EXIT_CODE=1
else
  echo -e "${GREEN}All compliance checks passed${NC}"
fi

exit $EXIT_CODE
