# Contributing to Security Toolkit

Bedankt voor je interesse om bij te dragen aan het Security Toolkit project!

## Development Setup

1. Fork de repository
2. Clone je fork: `git clone https://github.com/<username>/security-toolkit.git`
3. Maak een feature branch: `git checkout -b feature/my-feature`
4. Maak je wijzigingen
5. Test je wijzigingen: `bash scripts/secret-scan.sh`
6. Commit: `git commit -m "feat: description"`
7. Push: `git push origin feature/my-feature`
8. Maak een Pull Request aan

## Code Standaarden

- Gebruik 4 spaces voor indentatie (geen tabs)
- Eindig alle bestanden met een newline
- Gebruik LF line endings (geen CRLF)
- Voeg comments toe aan complexe logica
- Houd scripts POSIX-compatibel waar mogelijk

## Commit Berichten

Gebruik [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` nieuwe functionaliteit
- `fix:` bug fix
- `docs:` documentatie wijzigingen
- `test:` test toevoegen of wijzigen
- `refactor:` code refactoring
- `chore:` build process, dependencies, etc.

## Security

- Voeg NOOIT secrets of credentials toe aan de repository
- Gebruik de secret-scan.sh script om te controleren voordat je commit
- Rapporteer security issues via GitHub Security Advisories
