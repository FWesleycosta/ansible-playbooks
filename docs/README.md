# Documentação do ansible-playbooks

Esta pasta explica como o repositório funciona, como operá-lo e por que ele é assim. Quem chega agora deve ler, nesta ordem: a arquitetura (visão geral), o pipeline de CI e o runbook do laboratório. Os padrões de escrita de código ficam em `standards.md`, em inglês.

## Arquitetura
- [Arquitetura](arquitetura/arquitetura.md): o que o repositório é, o que roda onde, os riscos conhecidos e os diagramas C4 (contexto e contêineres).

## Pipeline
- [CI do ansible-playbooks](pipelines/ci.md): o que a CI roda em cada pull request e push, e por que o workflow é assim.

## Runbooks
- [Laboratório](runbooks/laboratorio.md): subir, usar e remover o laboratório local (`make lab-up`, `check`, `converge`, `lab-down`).
- [Vault](runbooks/vault.md): criar e editar arquivos do Ansible Vault, usar o arquivo de senha e tratar o hook `vault-encrypted`.
- [Molecule](runbooks/molecule.md): rodar os testes e resolver falhas de imagem, de systemd, de coleção e de idempotência.
- [Atualizar as versões fixadas](runbooks/atualizar-versoes-fixadas.md): Dependabot (semanal) e revisão mensal manual.
- [Falha na CI](runbooks/falha-na-ci.md): diagnóstico por job (`Lint`, `Molecule`, `Security` e `CI result`).

## Decisões de arquitetura
- [ADR-0001](decisoes/0001-imagem-oficial-do-trivy.md): imagem oficial do Trivy em vez do `trivy-action`.
- [ADR-0002](decisoes/0002-versoes-fixadas.md): política de versões fixadas.
- [ADR-0003](decisoes/0003-vault-em-duas-partes.md): segredos no Vault em duas partes.
- [ADR-0004](decisoes/0004-laboratorio-conteineres-systemd.md): laboratório de contêineres com systemd e conexão `community.docker`.
- [ADR-0005](decisoes/0005-hooks-pre-commit-locais.md): hooks do pre-commit só locais.
- [ADR-0006](decisoes/0006-check-obrigatorio-ci-result.md): check único, o `CI result`, feito para o ruleset exigir (hoje não exige).
- [ADR-0007](decisoes/0007-molecule-ubuntu-2404-2604-idempotencia.md): Molecule em Ubuntu 24.04 e 26.04, com segunda execução sem mudanças.

## Padrões de código
- [Padrões do repositório](standards.md) (em inglês): nomes, tarefas, variáveis, segredos e testes, cada um com o motivo.

## Arquivos derivados
Dois conjuntos de arquivos desta pasta são gerados a partir de outra fonte. **Não os edite à mão: altere a fonte e gere de novo.**

| Arquivo | Fonte | Como gerar |
| --- | --- | --- |
| `portal.html` | Os arquivos Markdown do `README.md` e desta pasta. É uma página única com tudo e com a lista das pendências em aberto | Da raiz do repositório, `gerar-portal.sh` da skill `documentacao-tecnica` |
| `diagramas/*.drawio.png` | `diagramas/modelo.json` | Da raiz do repositório, `gerar-drawio-modelo.py docs/diagramas/modelo.json --repo . --exportar`, da mesma skill |

Os diagramas Mermaid ficam dentro dos próprios Markdown e são revisados pelo diff.

## Pendências
Nenhuma pendência aberta.

## Risco conhecido
- O ruleset `protege-main-develop` não exige o check `CI result`: uma CI vermelha não impede o merge. Verificado em 10/11/2026 na configuração de rulesets do repositório no GitHub, que não está no código. Detalhes em [Arquitetura](arquitetura/arquitetura.md) (seção 11), [Pipeline de CI](pipelines/ci.md), [ADR-0006](decisoes/0006-check-obrigatorio-ci-result.md) e no [runbook de falha na CI](runbooks/falha-na-ci.md).
