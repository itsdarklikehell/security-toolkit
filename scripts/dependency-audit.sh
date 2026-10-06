#!/usr/bin/env bash
set -euo pipefail

# Dependency Audit — controleert dependencies op bekende kwetsbaarheden
# Gebruik: bash scripts/dependency-audit.sh [DIRECTORY]

SCAN_DIR="${1:-.}"
EXIT_CODE=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "=== Dependency Audit ==="
echo "Scanning directory: $SCAN_DIR"
echo ""

# Detecteer package managers en audit
audit_npm() {
  local dir="$1"
  echo "--- npm audit ---"
  if command -v npm &>/dev/null; then
    (cd "$dir" && npm audit --json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    vulns = data.get('vulnerabilities', {})
    if not vulns:
        print('  No vulnerabilities found')
    else:
        for name, v in vulns.items():
            severity = v.get('severity', 'unknown')
            title = v.get('title', 'Unknown')
            print(f'  [{severity}] {name}: {title}')
except:
    print('  npm audit failed')
" 2>/dev/null || echo "  npm audit not available")
  else
    echo "  npm not installed"
  fi
}

audit_pip() {
  local dir="$1"
  echo "--- pip audit ---"
  if command -v pip-audit &>/dev/null; then
    (cd "$dir" && pip-audit --format=json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    deps = data.get('dependencies', [])
    vulns = [d for d in deps if d.get('vulns')]
    if not vulns:
        print('  No vulnerabilities found')
    else:
        for d in vulns:
            for v in d.get('vulns', []):
                print(f'  [{v.get(\"severity\",\"?\")}] {d[\"name\"]}: {v.get(\"description\",\"?\")}')
except:
    print('  pip-audit failed')
" 2>/dev/null || echo "  pip-audit not available")
  else
    echo "  pip-audit not installed (pip install pip-audit)"
  fi
}

audit_cargo() {
  local dir="$1"
  echo "--- cargo audit ---"
  if command -v cargo-audit &>/dev/null; then
    (cd "$dir" && cargo audit --json 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    vulns = data.get('vulnerabilities', {}).get('list', [])
    if not vulns:
        print('  No vulnerabilities found')
    else:
        for v in vulns:
            print(f'  [{v.get(\"severity\",\"?\")}] {v.get(\"package\",\"?\")}: {v.get(\"title\",\"?\")}')
except:
    print('  cargo audit failed')
" 2>/dev/null || echo "  cargo-audit not available")
  else
    echo "  cargo-audit not installed (cargo install cargo-audit)"
  fi
}

audit_go() {
  local dir="$1"
  echo "--- go audit ---"
  if command -v govulncheck &>/dev/null; then
    (cd "$dir" && govulncheck -json ./... 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    vulns = data.get('Vulns', [])
    if not vulns:
        print('  No vulnerabilities found')
    else:
        for v in vulns:
            print(f'  {v.get(\"OSV\",{}).get(\"id\",\"?\")}: {v.get(\"OSV\",{}).get(\"summary\",\"?\")}')
except:
    print('  govulncheck failed')
" 2>/dev/null || echo "  govulncheck not available")
  else
    echo "  govulncheck not installed (go install golang.org/x/vuln/cmd/govulncheck@latest)"
  fi
}

# Detecteer welke package managers gebruikt worden
found_pm=false

if find "$SCAN_DIR" -name "package.json" -not -path "*/node_modules/*" | grep -q .; then
  found_pm=true
  for pkg_json in $(find "$SCAN_DIR" -name "package.json" -not -path "*/node_modules/*"); do
    dir=$(dirname "$pkg_json")
    echo "Found package.json in: $dir"
    audit_npm "$dir"
    echo ""
  done
fi

if find "$SCAN_DIR" -name "requirements.txt" -o -name "Pipfile" -o -name "pyproject.toml" | grep -q .; then
  found_pm=true
  for req in $(find "$SCAN_DIR" -name "requirements.txt" -o -name "Pipfile" -o -name "pyproject.toml"); do
    dir=$(dirname "$req")
    echo "Found Python dependencies in: $dir"
    audit_pip "$dir"
    echo ""
  done
fi

if find "$SCAN_DIR" -name "Cargo.toml" | grep -q .; then
  found_pm=true
  for cargo in $(find "$SCAN_DIR" -name "Cargo.toml"); do
    dir=$(dirname "$cargo")
    echo "Found Cargo.toml in: $dir"
    audit_cargo "$dir"
    echo ""
  done
fi

if find "$SCAN_DIR" -name "go.mod" | grep -q .; then
  found_pm=true
  for gomod in $(find "$SCAN_DIR" -name "go.mod"); do
    dir=$(dirname "$gomod")
    echo "Found go.mod in: $dir"
    audit_go "$dir"
    echo ""
  done
fi

if [ "$found_pm" = false ]; then
  echo -e "${YELLOW}No package manager files found${NC}"
fi

echo ""
echo -e "${GREEN}Dependency audit complete${NC}"
