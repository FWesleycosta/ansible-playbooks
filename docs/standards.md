# Ansible standards

These are the rules followed in this repository, each with the reason behind it.
`ansible-lint` (production profile) and `yamllint` enforce most of them; the rest is checked in review.
The [base](../roles/base) role is the reference implementation.

## Layout

| Path | Content |
| --- | --- |
| `inventories/<environment>/` | `hosts.yml`, `group_vars/`, `host_vars/` of one environment |
| `playbooks/` | `site.yml` imports one playbook per layer (`base.yml`, ...) |
| `roles/<role>/` | `defaults/`, `meta/` (`main.yml` and `argument_specs.yml`), `tasks/`, `templates/`, `files/`, `handlers/`, `README.md` |
| `molecule/<role>/` | Molecule scenario of the role, named after it |
| `tests/images/` | Images used as test hosts |
| `lab/` | Local lab used by the `lab` inventory |

- `handlers/` exists only when the role restarts or reloads something.
- `vars/main.yml` holds only internal constants (for example, values per OS family). It has high precedence, so anything a user may override goes to `defaults/main.yml`.
- Molecule runs from the repository root, which is its project directory: its prerun installs `requirements.yml` from there, without symlinks in the home directory. Molecule runs Ansible with an `ansible.cfg` it generates, so each `molecule.yml` repeats `roles_path` and `collections_path` under `ansible.cfg.defaults`.
- The Molecule `dependency` step is disabled, and that step is the only one that installs the collections required by the Molecule Docker driver. `requirements.yml` therefore pins them too (`community.docker` and `ansible.posix`); a collection missing there fails in CI even when it exists in a local `.ansible/collections` or `~/.ansible/collections`.

## Naming

| Item | Rule | Example | Why |
| --- | --- | --- | --- |
| Role | `snake_case` noun of what it configures, no `_role` suffix | `base`, `ssh` | The name becomes the variable prefix and the tag |
| Role variable | Prefix with the role name | `base_timezone` | No collisions between roles; enforced by `var-naming` |
| Internal or registered variable in a role | Prefix with `__` and the role name | `__base_zoneinfo` | Shows that it is not part of the public interface |
| Registered variable in a playbook or test | Prefix with the purpose | `verify_motd` | Readable without opening the task |
| Vault variable | `vault_` plus the name of the plain variable | `vault_lab_demo_api_token` | `grep` finds where a secret is used |
| Task | Imperative, starts with a capital letter, English, unique in the play | `Write the MOTD` | The run output reads like a log |
| File | `.yml` extension and `---` on the first line | `tasks/install.yml` | One style everywhere; files named by a tool (`.pre-commit-config.yaml`) keep the tool's name |
| Tag | One per role, same name as the role, set in the playbook | `--tags base` | Runs one layer without guessing tag names |
| Inventory group | Function, never environment | `web`, `db` | The environment is the inventory folder |

## Writing tasks

- Use the fully qualified module name: `ansible.builtin.copy`, not `copy`.
- Booleans are `true` and `false` only.
- `become` is declared per play or per task, never globally in `ansible.cfg`.
- Prefer a module to `shell` or `command`. When there is no module, set `changed_when` (and `creates` or `removes` when it applies) so the task stays idempotent.
- Files and templates set `owner`, `group` and a quoted `mode` (`"0644"`), because an unquoted mode can be read as a decimal number.
- Templates of critical configuration use `validate` (`sshd -t -f %s`, `visudo -cf %s`), so a broken file never replaces a working one.
- Services are restarted or reloaded only by handlers.
- Facts are read through `ansible_facts['...']`, which works even when facts are not injected as variables.
- Inputs that can break a host are checked with `ansible.builtin.assert` before any change.
- Each role declares its inputs in `meta/argument_specs.yml`, so a wrong type fails before the first task.
- No `apt_key` (deprecated): keys go to `/etc/apt/keyrings` and repositories use `ansible.builtin.deb822_repository`.

## Variables and inventories

- `defaults/main.yml` is the public interface of a role. Every variable in it is documented in `argument_specs.yml`.
- Roles hold no environment data. Hosts, addresses and environment values come from the inventory.
- Inventories are YAML. Each group with secrets uses a folder: `group_vars/<group>/main.yml` and `group_vars/<group>/vault.yml`.
- `host_vars` is only for what is really specific to one host.
- This repository is public: no real host names or IP addresses. Examples use `192.0.2.0/24` (RFC 5737) and the `.example` domain (RFC 2606).

## Secrets

- Two-part Vault: `main.yml` holds the reference (`app_token: "{{ vault_app_token }}"`) and `vault.yml` holds the encrypted value. The variable stays easy to find while its value stays protected.
- The Vault password never enters the repository: use `--ask-vault-pass` or `ANSIBLE_VAULT_PASSWORD_FILE` pointing to a file outside the repository.
- Tasks that handle secrets use `no_log: true`.
- Molecule and CI do not depend on the Vault: test values live in the scenario.
- pre-commit blocks a plaintext `vault.yml` (`scripts/check-vault-encrypted.sh`) and leaked credentials (`gitleaks`).
- A secret that reaches Git history is rotated first; cleaning the history comes after.

## ansible.cfg

- Host key checking stays on (Ansible default), because turning it off opens the door to man-in-the-middle attacks.
- Deprecation warnings stay visible: they announce what will break in the next upgrade.
- Collections are installed inside the project (`.ansible/collections`) from `requirements.yml`, so every run uses the same versions.

## Tests

- `make lint` and the pre-commit hooks run `yamllint`, `ansible-lint` and the Vault check.
- CI (`.github/workflows/ci.yml`) runs `make lint` and `make test` on every pull request and push to `main` and `develop`, plus a security scan of the Dockerfile and the workflows. The `CI result` job is the single check the branch rulesets can require.
- Each role has a Molecule scenario: create, converge, idempotence, verify, destroy.
- `verify.yml` checks the end state of the host (package installed, file content), not the tasks that produced it.
- The scenario overrides some defaults, which proves that the role honours its interface.
- `prepare.yml` puts the host in the state of a freshly built image (no apt package lists, with a recent `/var/lib/apt/lists` mtime), so the local run and CI exercise the same path whatever the Docker storage driver.
- Containers cannot test kernel parameters, firewalls, auditd or the system clock. Roles that need them get a virtual machine scenario.

## Toolchain and versions

- `pyproject.toml` and `uv.lock` pin Python and every tool; `requirements.yml` pins every collection; test images are pinned by digest.
- GitHub Actions are pinned by full commit SHA, with the version in a comment, and Dependabot proposes updates. Tool images in the workflows are pinned by digest, and the uv and zizmor versions are pinned in the workflow; these are updated by hand.
- Updates are deliberate: change the version, run `make lint test`, then record it in the changelog.

## Commits and releases

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/) (`feat:`, `fix:`, `docs:`, `ci:`, `refactor:`).
- Releases use [Semantic Versioning](https://semver.org/) tags and are recorded in [CHANGELOG.md](../CHANGELOG.md).
