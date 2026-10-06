# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 1.x.x   | :white_check_mark: |

## Reporting a Vulnerability

Als je een security vulnerability vindt in het Security Toolkit project, volg dan deze stappen:

1. **Maak GEEN openbaar issue aan** voor de vulnerability
2. Stuur een email naar de maintainers met:
   - Een beschrijving van de vulnerability
   - Stappen om te reproduceren
   - Mogelijke impact
   - Suggestie voor fix (indien aanwezig)
3. Je ontvangt binnen 48 uur een reactie
4. Na bevestiging werken we samen aan een fix
5. Na publicatie van de fix wordt je naam vermeld in de release notes (tenzij je anoniem wilt blijven)

## Security Best Practices voor Contributors

- Voeg nooit secrets of credentials toe aan de repository
- Gebruik de `scripts/secret-scan.sh` script voordat je commit
- Houd dependencies up-to-date
- Gebruik sterke authenticatie voor alle accounts
- Volg het principe van least privilege
