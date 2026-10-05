# Security Toolkit

Security scanning en auditing tools voor de GitHub Fleet Manager.

## Features

- Secret scanning
- Dependency vulnerability scanning
- SAST (Static Application Security Testing)
- Security audits
- Compliance checks

## Installatie

```bash
git clone https://github.com/itsdarklikehell/security-toolkit.git
cd security-toolkit
```

## Gebruik

```bash
bash scripts/secret-scan.sh
bash scripts/dependency-audit.sh
bash scripts/security-audit.sh
```

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
