# Security Toolkit

![CI](https://img.shields.io/github/actions/workflow/status/itsdarklikehell/security-toolkit/ci.yml?branch=master) ![License](https://img.shields.io/github/license/itsdarklikehell/security-toolkit) ![Last Commit](https://img.shields.io/github/last-commit/itsdarklikehell/security-toolkit)

Security scanning en auditing tools voor de GitHub Fleet Manager.

## Features

- **Secret scanning** — detecteert hardcoded secrets (API keys, tokens, passwords, private keys)
- **Dependency vulnerability scanning** — controleert npm, pip, cargo en go dependencies
- **Security audits** — world-writable bestanden, SUID/SGID, hardcoded credentials, security headers
- **Compliance checks** — license, README, .gitignore, binary bestanden, dependency pinning

## Installatie

```bash
git clone https://github.com/itsdarklikehell/security-toolkit.git
cd security-toolkit
chmod +x scripts/*.sh
```

## Gebruik

### Secret Scanning

Detecteert hardcoded secrets in code:

```bash
bash scripts/secret-scan.sh [DIRECTORY]
```

Ondersteunde secret types:
- AWS Access/Secret Keys
- GitHub Tokens (PAT, OAuth, App)
- GitLab Tokens
- Slack Tokens
- Stripe Keys
- Google API Keys
- JWT Tokens
- Private Keys
- Generic API keys, secrets, tokens
- Database passwords
- npm, Datadog, SendGrid, Twilio, Heroku tokens

### Dependency Audit

Controleert dependencies op bekende kwetsbaarheden:

```bash
bash scripts/dependency-audit.sh [DIRECTORY]
```

Ondersteunde package managers:
- npm (via `npm audit`)
- pip (via `pip-audit`)
- Cargo (via `cargo audit`)
- Go (via `govulncheck`)

### Security Audit

Uitgebreide security checks:

```bash
bash scripts/security-audit.sh [DIRECTORY]
```

Checks:
- World-writable bestanden
- SUID/SGID bestanden
- Hardcoded credentials in config bestanden
- Security headers in web configs
- Outdated npm dependencies
- File permissions summary
- .gitignore aanwezigheid en inhoud

### Compliance Check

Controleert op compliance met best practices:

```bash
bash scripts/compliance-check.sh [DIRECTORY]
```

Checks:
- License bestand
- README bestand
- .gitignore bestand
- Grote bestanden (>10MB)
- Binary bestanden
- Security policy (SECURITY.md)
- Contributing guide
- Code of Conduct
- CI/CD workflows
- Dependency pinning

## CI/CD

De GitHub Actions workflow (`.github/workflows/ci.yml`) voert automatisch uit:
- Bash syntax check
- ShellCheck linting
- Alle vier scripts uitvoeren op de repo zelf en op testdata

## :film_projector: Development visualization

Bekijk de [Gource development video](https://github.com/itsdarklikehell/security-toolkit/releases) voor een visuele tijdlijn van de projectgeschiedenis.

Om de video lokaal te genereren:
```bash
gource -1920x1080 --auto-skip-seconds 1 -o gource.ppm
ffmpeg -y -r 60 -i gource.ppm -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p gource.mp4
```

De GitHub Actions workflow (`.github/workflows/gource.yml`) genereert de video automatisch bij elke release.

## Testing

```bash
# Voer alle scripts uit op de repo zelf
for script in scripts/*.sh; do
  echo "=== Testing $script ==="
  bash "$script" . || true
  echo ""
done
```

## Licentie

MIT
