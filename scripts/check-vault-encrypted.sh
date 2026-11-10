#!/usr/bin/env bash
# check-vault-encrypted.sh - fails when a Vault file is not encrypted with ansible-vault.
#
# Usage:
#   scripts/check-vault-encrypted.sh [file ...]
#   With no arguments, checks every vault.yml/vault.yaml that Git tracks or would track.
#
# Called by pre-commit (with the staged Vault files) and by `make lint`.
# Runs on macOS (bash 3.2) and Linux. Exit codes: 0 all encrypted, 1 plaintext file found.
set -euo pipefail
IFS=$'\n\t'

readonly HEADER="\$ANSIBLE_VAULT;"

erro() { printf 'ERROR: %s\n' "$*" >&2; }

list_vault_files() {
  git ls-files --cached --others --exclude-standard -- '*vault.yml' '*vault.yaml'
}

main() {
  local files=() f first failed=0

  if [[ $# -gt 0 ]]; then
    files=("$@")
  else
    command -v git >/dev/null 2>&1 || {
      erro "git not found"
      exit 1
    }
    while IFS= read -r f; do
      files+=("$f")
    done < <(list_vault_files)
  fi

  if [[ ${#files[@]} -eq 0 ]]; then
    printf 'No Vault files found.\n'
    exit 0
  fi

  for f in "${files[@]}"; do
    [[ -f "$f" ]] || continue
    first=""
    IFS= read -r first <"$f" || true
    if [[ "$first" != "$HEADER"* ]]; then
      erro "$f is not encrypted. Run: uv run ansible-vault encrypt $f"
      failed=1
    fi
  done

  if [[ $failed -ne 0 ]]; then
    exit 1
  fi
  printf 'Vault files encrypted: %s\n' "${#files[@]}"
}

main "$@"
