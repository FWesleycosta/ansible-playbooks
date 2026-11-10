# ansible-playbooks

[![ansible-core](https://img.shields.io/badge/ansible--core-2.21.6-blue)](https://docs.ansible.com/)
[![ansible-lint](https://img.shields.io/badge/ansible--lint-production%20profile-blue)](https://ansible.readthedocs.io/projects/lint/profiles/)
[![Molecule](https://img.shields.io/badge/tested%20with-Molecule-blue)](https://ansible.readthedocs.io/projects/molecule/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Ansible playbooks and roles that I use to practice infrastructure automation and to show how I structure, test and secure Ansible code.

## What this repository demonstrates

- **Standards that are written down and enforced.** Naming, variables, tasks and secrets follow [docs/standards.md](docs/standards.md). `ansible-lint` (production profile) and `yamllint` check them on every commit.
- **Idempotence proven by tests.** Every role has a Molecule scenario that applies it twice on Ubuntu 24.04 and 26.04 containers and fails if the second run changes anything.
- **Secrets handled properly.** Ansible Vault in two parts (a plain reference and an encrypted value), the Vault password kept outside the repository, and pre-commit hooks that block plaintext Vault files and leaked credentials.
- **A reproducible toolchain.** Python, ansible-core, ansible-lint, Molecule and the collections are pinned to exact versions (`uv.lock`, `requirements.yml`). Test images are pinned by digest.
- **A safe place to practice.** A local lab of systemd containers. No real host, IP address or credential is stored here.

## Repository layout

```text
.
├── ansible.cfg                 # project settings (lab inventory by default)
├── requirements.yml            # collections, pinned
├── pyproject.toml / uv.lock    # Python toolchain, pinned
├── Makefile                    # setup, lint, test, lab and converge targets
├── docs/standards.md           # the standards, with the reason behind each one
├── inventories/
│   └── lab/                    # one folder per environment
│       ├── hosts.yml
│       └── group_vars/
├── playbooks/
│   ├── site.yml                # entry point
│   └── base.yml
├── roles/
│   └── base/                   # reference role for the standards
├── molecule/
│   └── base/                   # Molecule scenario of the base role
├── lab/compose.yml             # local lab: web-01, web-02, db-01
├── tests/images/ubuntu/        # test image: Ubuntu with systemd
└── scripts/                    # helper scripts used by the hooks
```

## Quick start

Requirements: macOS or Linux, [uv](https://docs.astral.sh/uv/), Docker, `make`, [pre-commit](https://pre-commit.com/) and [gitleaks](https://github.com/gitleaks/gitleaks).

```bash
make setup      # Python environment and pinned collections
make hooks      # pre-commit hooks for this clone
make lint       # yamllint, ansible-lint and the Vault encryption check
make test       # Molecule: every role on Ubuntu 24.04 and 26.04
make lab-up     # start the lab hosts
make converge   # apply playbooks/site.yml to the lab (prompts for the Vault password)
make lab-down   # remove the lab
```

Run `make` to list every target.

## Roles

| Role | What it does | Platforms | Tests |
| --- | --- | --- | --- |
| [base](roles/base) | Essential packages, timezone and MOTD | Ubuntu 24.04, 26.04 | Molecule |

## Inventories and variables

- Each environment is a folder under `inventories/`. The `lab` environment points to local containers through the `community.docker.docker` connection plugin, so it has no IP addresses and no SSH.
- Inventory groups describe a function (`web`, `db`), never an environment.
- Variable precedence, from lowest to highest: role defaults, `group_vars/all`, `group_vars/<group>`, `host_vars/<host>`. For example, the web hosts get their own MOTD in [inventories/lab/group_vars/web.yml](inventories/lab/group_vars/web.yml).

## Secrets

- A variable that holds a secret is declared in `group_vars/<group>/main.yml` as a reference: `lab_demo_api_token: "{{ vault_lab_demo_api_token }}"`.
- The value lives in `vault.yml`, in the same folder, encrypted with `ansible-vault`. The lab Vault holds fake values only.
- The Vault password never enters the repository. `make converge` prompts for it, unless `ANSIBLE_VAULT_PASSWORD_FILE` points to a file outside the repository.
- Molecule tests do not depend on the Vault.

## Roadmap

- [x] `base`: packages, timezone and MOTD
- [ ] `users`: users and sudo rules validated with `visudo`
- [ ] `ssh`: `sshd_config` validated with `sshd -t`
- [ ] `docker`: official repository in deb822 format
- [ ] `chrony` and `firewall` (they need a virtual machine target)
- [ ] CI with GitHub Actions running lint and Molecule

## License

[MIT](LICENSE)

## Author

Wesley Costa - [GitHub](https://github.com/FWesleycosta)
