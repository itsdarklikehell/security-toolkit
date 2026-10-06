# Security Toolkit

Security scanning en auditing tools voor de GitHub Fleet Manager.

## Features

- **Secret scanning** - Detecteer AWS keys, GitHub tokens, private keys, wachtwoorden en meer
- **Dependency vulnerability scanning** - Scan op bekende kwetsbaarheden in dependencies
- **SAST (Static Application Security Testing)** - Statische code analyse voor security issues
- **Security audits** - Uitgebreide security audits
- **Compliance checks** - Controle op security compliance

## Installatie

```bash
git clone https://github.com/itsdarklikehell/security-toolkit.git
cd security-toolkit
chmod +x scripts/*.sh
```

## Gebruik

### Secret Scanning

```bash
bash scripts/secret-scan.sh
```

Dit script scant de repository op:
- AWS access keys (AKIA, ASIA)
- GitHub tokens (ghp_, gho_, ghu_, ghs_, ghr_)
- Private keys (RSA, EC, DSA, OpenSSH)
- Wachtwoorden in configuratiebestanden
- API keys
- Slack tokens
- JWT tokens

### CI/CD

De repository bevat GitHub Actions workflows voor:
- **CI** - Bash syntax check, ShellCheck, secret scanning, Trivy vulnerability scanning, linting
- **Gource** - Automatische development visualisatie

## Project Structuur

```
security-toolkit/
├── .github/
│   └── workflows/
│       ├── ci.yml          # CI pipeline
│       └── gource.yml      # Gource visualisatie
├── scripts/
│   └── secret-scan.sh      # Secret scanning script
├── CONTRIBUTING.md         # Bijdrage richtlijnen
├── SECURITY.md             # Security policy
├── LICENSE                 # MIT License
└── README.md               # Dit bestand
```

## Development

Zie [CONTRIBUTING.md](CONTRIBUTING.md) voor richtlijnen over hoe bij te dragen.

## Security

Zie [SECURITY.md](SECURITY.md) voor de security policy en het rapporteren van vulnerabilities.

## :film_projector: Development visualization

Bekijk de [Gource development video](https://github.com/itsdarklikehell/security-toolkit/releases) voor een visuele tijdlijn van de projectgeschiedenis.

Om de video lokaal te genereren:
```bash
gource -1920x1080 --auto-skip-seconds 1 -o gource.ppm
ffmpeg -y -r 60 -i gource.ppm -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p gource.mp4
```

De GitHub Actions workflow (`.github/workflows/gource.yml`) genereert de video automatisch bij elke release.

## Licentie

MIT
