# ADR-0005: Usar só hooks locais no pre-commit

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
O repositório quer barrar erros antes do commit: arquivo do Vault em texto puro, segredo vazado, YAML fora do padrão e violação do `ansible-lint`. O pre-commit permite isso, e cada hook pode vir de um repositório remoto ou ser um comando local.

O repositório já fixa todas as versões das ferramentas no `uv.lock` ([ADR-0002](0002-versoes-fixadas.md)).

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Hooks locais, que rodam a ferramenta do `uv.lock` (escolhida) | Uma só lista de versões; nenhum código de hook é baixado | Quem clona precisa instalar o `gitleaks` à parte e rodar `make hooks` |
| Repositórios remotos de hooks (`repo:` com `rev`) | Configuração curta e hooks prontos | Código de terceiros fora do `uv.lock` e uma segunda lista de versões para manter |
| Sem pre-commit | Nada para instalar | O erro só aparece depois do push, e o gitleaks precisa barrar antes do commit |

## Decisão
Vamos usar só hooks locais (`repo: local`). Os hooks de YAML e de Ansible chamam `uv run --frozen yamllint --strict` e `uv run --frozen ansible-lint`, que usam as versões do `uv.lock`. O hook `vault-encrypted` chama `scripts/check-vault-encrypted.sh`. O hook `gitleaks` chama o executável instalado na máquina. A instalação é por clone, com `make hooks`.

## Consequências
- Positivas:
  - As versões das ferramentas vêm de um lugar só (`uv.lock`).
  - Nenhum código de hook de terceiros é baixado.
- Negativas e o que aceitamos perder:
  - O pre-commit só protege quem rodou `make hooks`.
  - **O gitleaks roda só localmente.** A CI não o executa, e o `make lint` também não. Quem não instalou os hooks não tem a varredura de segredos. É uma lacuna conhecida, registrada como risco na [arquitetura](../arquitetura/arquitetura.md#11-riscos-e-débitos-técnicos). Adicionar o gitleaks à CI fica como melhoria futura; a CI não muda por este ADR.
  - O `gitleaks` precisa ser instalado à mão (é requisito do desenvolvedor no `README.md`).
- Como verificamos que a decisão continua sendo seguida:
  - A CI repete `yamllint`, `ansible-lint` e a conferência do Vault (job `Lint`, `make lint`). Para o gitleaks não há verificação automática.

## Referências
- `.pre-commit-config.yaml`, linhas 2 a 4 e 6 a 28.
- `Makefile`, linhas 25 e 26 (`make hooks`) e 28 a 31 (`make lint`).
- `README.md`, seção "Quick start" (requisitos: pre-commit e gitleaks).
