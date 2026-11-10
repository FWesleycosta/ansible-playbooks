# Changelog

All notable changes to this project are documented in this file.
The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and the project uses [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- Repository layout, written standards (`docs/standards.md`) and pinned toolchain: Python 3.14, ansible-core 2.21.6, ansible-lint 26.10.1, Molecule 26.11.0, community.docker 5.4.0 and ansible.posix 2.2.2.
- `base` role: essential packages, timezone and MOTD, with argument validation. It refreshes the apt cache when the host has no package lists, even if the cache looks recent.
- Molecule scenario for `base` on Ubuntu 24.04 and 26.04 containers with systemd.
- Local lab with three systemd containers and the `lab` inventory.
- Ansible Vault pattern and pre-commit hooks: yamllint, ansible-lint, gitleaks and the Vault encryption check.
- CI with GitHub Actions on pull requests and pushes to `main` and `develop`: `make lint` (plus actionlint), `make test` (Molecule) and a security scan (hadolint, Trivy config and zizmor). Actions pinned by commit SHA and kept up to date by Dependabot.
- Technical documentation in `docs/` (architecture, CI pipeline, runbooks and decision records, in Brazilian Portuguese), with C4 diagrams and a generated `docs/portal.html`.
