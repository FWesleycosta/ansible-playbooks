# ADR-0002: Fixar todas as versões que o repositório usa

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
O repositório quer builds reprodutíveis: o mesmo commit deve produzir o mesmo resultado hoje e daqui a seis meses, no computador do mantenedor e na CI. Quer também proteger a cadeia de suprimentos: uma versão nova e comprometida de uma ferramenta, de uma action ou de uma imagem não pode entrar sem que alguém a veja (o caso que motivou o [ADR-0001](0001-imagem-oficial-do-trivy.md)).

Há cinco grupos de versões em jogo: as ferramentas Python, as coleções Ansible, as actions da CI, as imagens (de ferramenta e de teste) e as ferramentas que a CI baixa na hora (uv e zizmor).

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Fixar tudo com versão exata, SHA ou digest, e atualizar com revisão (escolhida) | A CI só muda por commit; o laboratório e o Molecule se comportam igual em qualquer máquina | Alguém precisa fazer as atualizações |
| Tags flutuantes e intervalos (`@v4`, `latest`, `>=`) | Nenhuma manutenção | A CI mudaria sem commit: o mesmo código passaria hoje e falharia amanhã |
| Fixar só as actions da CI | A parte mais exposta da CI fica protegida | O laboratório e o Molecule perdem a reprodutibilidade |
| Atualização automática de tudo, sem revisão | Sempre atualizado | Uma versão nova entra sem ninguém olhar; por isso o que não é ação passa pela revisão mensal |

## Decisão
Vamos fixar toda versão que o repositório usa:
- **Python e ferramentas:** `pyproject.toml` com `==` e `uv.lock`, instalados com `uv sync --frozen`; `ansible-core` e as demais ferramentas em versão exata.
- **Coleções Ansible:** `requirements.yml` com versão exata.
- **Actions da CI:** commit SHA completo, com a versão em comentário.
- **Imagens:** digest, tanto as de ferramenta na CI quanto as bases Ubuntu do `tests/images/ubuntu/Dockerfile` e do `Makefile`.
- **uv e zizmor:** versão exata no workflow.

O Dependabot cuida só das actions: pull request semanal para `develop`, agrupado, com `cooldown` de 7 dias (espera uma semana antes de propor uma versão nova, para que uma versão comprometida tenha tempo de ser descoberta). O restante passa pela [revisão mensal](../runbooks/atualizar-versoes-fixadas.md).

## Consequências
- Positivas:
  - Builds reprodutíveis, na máquina local e na CI.
  - Versão nova nenhuma entra sem revisão.
- Negativas e o que aceitamos perder:
  - O trabalho de atualizar fica com o mantenedor (revisão mensal).
  - O Dependabot não cobre imagens, uv, zizmor, dependências Python nem coleções.
  - O zizmor roda com `uvx` e só a versão dele é fixa: as dependências transitivas dele não passam pelo `uv.lock`.
- Como verificamos que a decisão continua sendo seguida:
  - O `make setup` usa `uv sync --frozen`, que instala o que está no `uv.lock` sem recalcular versões.
  - A regra "toda action por SHA" e "toda imagem por digest" não tem uma verificação automática dedicada no código: ela é mantida pela revisão do pull request e, no caso das actions, pelas atualizações do Dependabot.

## Referências
- `.github/workflows/ci.yml` (SHAs nas linhas 33, 43, 50, 68, 73, 80, 97 e 115; digests nas linhas 38, 102 e 108; uv na 45, 75 e 117; zizmor na 121).
- `pyproject.toml`, linhas 8 a 14; `uv.lock`; `requirements.yml`, linhas 5 a 9.
- `tests/images/ubuntu/Dockerfile`, linha 7; `Makefile`, linha 10 e linha 7 (`uv run --frozen`).
- `.github/dependabot.yml` (semanal, `target-branch: develop`, `cooldown`).
- `.pre-commit-config.yaml`, linha 2: os hooks rodam a ferramenta do `uv.lock`.
- `docs/standards.md`, seção "Toolchain and versions".
