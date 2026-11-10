# base

Baseline for Debian-family hosts: installs essential packages, sets the timezone and writes the MOTD.

## Requirements

- Debian-family host (tested on Ubuntu 24.04 and 26.04).
- Facts gathered (`gather_facts: true`, the default).
- Privilege escalation: run the role with `become: true`.

## Role variables

Defaults are in [defaults/main.yml](defaults/main.yml); types are validated by [meta/argument_specs.yml](meta/argument_specs.yml).

| Variable | Default | Description |
| --- | --- | --- |
| `base_packages` | `ca-certificates`, `curl`, `htop`, `tzdata` | Packages installed on every host. Overriding it replaces the whole list |
| `base_packages_extra` | `[]` | Extra packages added to `base_packages`, usually set per group or host |
| `base_apt_cache_valid_time` | `3600` | Age of the apt cache, in seconds, before it is refreshed. Ignored when the host has no package lists: the cache is refreshed anyway |
| `base_timezone` | `Etc/UTC` | IANA timezone name, for example `America/Sao_Paulo` |
| `base_motd_enabled` | `true` | Write `/etc/motd` |
| `base_motd_message` | `This host is managed by Ansible...` | Message written to `/etc/motd` |

The timezone is applied by linking `/etc/localtime` and writing `/etc/timezone`, which is what `timedatectl` does on Debian-family hosts, without depending on D-Bus. The role fails before any change if the timezone does not exist in `/usr/share/zoneinfo`.

## Dependencies

None.

## Example playbook

```yaml
- name: Apply the baseline
  hosts: all
  become: true
  roles:
    - role: base
      tags:
        - base
      vars:
        base_timezone: America/Sao_Paulo
        base_packages_extra:
          - jq
```

## Testing

From the repository root:

```bash
make test-role ROLE=base
```

The [Molecule scenario](../../molecule/base) runs the role on Ubuntu 24.04 and 26.04, checks idempotence and verifies the packages, the timezone and the MOTD.

## License

MIT

## Author

Wesley Costa
