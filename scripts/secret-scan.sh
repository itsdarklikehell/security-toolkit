#!/usr/bin/env bash
set -euo pipefail

# Secret scanning script for security toolkit
# Scans for common secrets and credentials in the repository

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Counters
TOTAL_FILES=0
FILES_WITH_SECRETS=0
TOTAL_FINDINGS=0

# Secret patterns to detect
declare -a SECRET_PATTERNS=(
    # AWS
    "AKIA[0-9A-Z]{16}"
    "ASIA[0-9A-Z]{16}"
    # GitHub tokens
    "ghp_[a-zA-Z0-9]{36}"
    "gho_[a-zA-Z0-9]{36}"
    "ghu_[a-zA-Z0-9]{36}"
    "ghs_[a-zA-Z0-9]{36}"
    "ghr_[a-zA-Z0-9]{36}"
    # Generic API keys
    "api[_-]?key['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{32,}['\"]"
    # Private keys
    "-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
    # Passwords in config
    "password['\"]?\s*[:=]\s*['\"][^'\"]{8,}['\"]"
    # Tokens
    "token['\"]?\s*[:=]\s*['\"][a-zA-Z0-9]{20,}['\"]"
    # Slack tokens
    "xox[baprs]-[0-9a-zA-Z]{10,}"
    # JWT
    "eyJ[a-zA-Z0-9_-]{10,}\.eyJ[a-zA-Z0-9_-]{10,}\.[a-zA-Z0-9_-]{10,}"
)

# Files to exclude
declare -a EXCLUDE_PATTERNS=(
    ".git/"
    "node_modules/"
    "__pycache__/"
    "*.pyc"
    ".venv/"
    "venv/"
    "*.log"
    ".env.example"
    "test_*"
    "*_test.sh"
)

log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

should_exclude() {
    local file="$1"
    for pattern in "${EXCLUDE_PATTERNS[@]}"; do
        if [[ "$file" == *"$pattern"* ]]; then
            return 0
        fi
    done
    return 1
}

scan_file() {
    local file="$1"
    local findings=0

    for pattern in "${SECRET_PATTERNS[@]}"; do
        local matches
        matches=$(grep -nE "$pattern" "$file" 2>/dev/null || true)
        if [[ -n "$matches" ]]; then
            log_error "Potential secret found in $file:"
            echo "$matches" | while read -r line; do
                echo "  $line"
            done
            ((findings++)) || true
        fi
    done

    return $findings
}

main() {
    log_info "=== Secret Scanning ==="
    log_info "Scanning repository: $REPO_ROOT"
    echo ""

    # Find all text files
    while IFS= read -r -d '' file; do
        if should_exclude "$file"; then
            continue
        fi

        ((TOTAL_FILES++)) || true

        local file_findings=0
        scan_file "$file" || file_findings=$?

        if [[ $file_findings -gt 0 ]]; then
            ((FILES_WITH_SECRETS++)) || true
            ((TOTAL_FINDINGS += file_findings)) || true
        fi
    done < <(find "$REPO_ROOT" -type f \( -name "*.sh" -o -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.json" -o -name "*.yml" -o -name "*.yaml" -o -name "*.env" -o -name "*.conf" -o -name "*.cfg" -o -name "*.ini" -o -name "*.md" \) -print0 2>/dev/null)

    echo ""
    log_info "=== Scan Summary ==="
    echo "Files scanned: $TOTAL_FILES"
    echo "Files with potential secrets: $FILES_WITH_SECRETS"
    echo "Total findings: $TOTAL_FINDINGS"

    if [[ $TOTAL_FINDINGS -gt 0 ]]; then
        log_error "Potential secrets detected! Please review and remove them."
        exit 1
    else
        log_info "No secrets detected."
        exit 0
    fi
}

main "$@"
