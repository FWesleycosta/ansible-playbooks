# Common tasks. Run `make` to list them.
# Everything runs locally: the default inventory is the container lab, never a real host.
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c
.DEFAULT_GOAL := help

UV_RUN := uv run --frozen
IMAGE := localhost/ansible-playbooks/test-ubuntu
# Ubuntu 24.04 uses the digest pinned in tests/images/ubuntu/Dockerfile.
UBUNTU_2604_BASE := ubuntu:26.04@sha256:6a06111c3b0a8600feadb270aec771dc239bf407b25625f93f44ab00e11f4d3c
ROLE ?= base
PLAYBOOK ?= playbooks/site.yml
# Prompts for the Vault password unless ANSIBLE_VAULT_PASSWORD_FILE points to a file outside the repository.
VAULT_ARGS := $(if $(ANSIBLE_VAULT_PASSWORD_FILE),,--ask-vault-pass)

.PHONY: help setup hooks lint image test test-role lab-up lab-down converge check

help: ## List the available targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "}; {printf "  %-10s %s\n", $$1, $$2}'

setup: ## Create the Python environment and install the pinned collections
	uv sync --frozen
	$(UV_RUN) ansible-galaxy collection install -r requirements.yml

hooks: ## Install the pre-commit hooks in this clone
	pre-commit install

lint: ## Run yamllint, ansible-lint and the Vault encryption check
	$(UV_RUN) yamllint --strict .
	$(UV_RUN) ansible-lint
	scripts/check-vault-encrypted.sh

image: ## Build the local test images (Ubuntu 24.04 and 26.04)
	docker build --tag $(IMAGE):24.04 tests/images/ubuntu
	docker build --build-arg BASE_IMAGE=$(UBUNTU_2604_BASE) --tag $(IMAGE):26.04 tests/images/ubuntu

test: image ## Run every Molecule scenario
	$(UV_RUN) molecule test --all

test-role: image ## Run one Molecule scenario: make test-role ROLE=base
	$(UV_RUN) molecule test --scenario-name $(ROLE)

lab-up: ## Start the lab containers
	docker compose --file lab/compose.yml up --detach --wait

lab-down: ## Stop and remove the lab containers
	docker compose --file lab/compose.yml down

converge: ## Apply PLAYBOOK (default playbooks/site.yml) to the lab
	$(UV_RUN) ansible-playbook $(PLAYBOOK) --diff $(VAULT_ARGS)

check: ## Dry run of PLAYBOOK against the lab, showing the diff
	$(UV_RUN) ansible-playbook $(PLAYBOOK) --check --diff $(VAULT_ARGS)
