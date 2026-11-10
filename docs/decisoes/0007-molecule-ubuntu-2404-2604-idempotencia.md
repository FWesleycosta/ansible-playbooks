# ADR-0007: Testar as roles no Ubuntu 24.04 e no 26.04, com a segunda execução sem mudanças

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
A role `base` declara suporte ao Ubuntu 24.04 (`noble`) e ao 26.04 (`resolute`) em `meta/main.yml`. O repositório quer provar duas coisas com testes: que a role funciona nas duas versões e que ela é idempotente, isto é, que aplicá-la de novo não muda nada.

O commit `b109523` mostra por que testar o ambiente da CI importa: o estado de uma imagem em um runner Linux era diferente do estado no Docker Desktop local, e um erro só aparecia na CI.

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Duas plataformas (24.04 e 26.04), com checagem de idempotência (escolhida) | Cobre tudo o que a role declara; a idempotência é verificada | Duas imagens para construir e manter |
| Testar só o 24.04 | Uma imagem só | A role declara as duas versões, e a 26.04 já mostrou diferença |
| Sem teste de idempotência | Teste mais curto | Uma role que muda algo a cada execução passaria despercebida |
| Matriz com mais distribuições | Mais cobertura | A role só declara Ubuntu e usa `apt` |

## Decisão
Vamos rodar cada cenário do Molecule em dois contêineres com systemd, `base-ubuntu-2404` e `base-ubuntu-2604`, construídos de imagens com digest fixo. Cada cenário passa pelos passos `destroy`, `create`, `prepare`, `converge`, `idempotence`, `verify` e `destroy`. No passo `idempotence`, o Molecule aplica a role uma segunda vez e reprova se qualquer tarefa mudar algo.

O cenário também sobrescreve alguns valores padrão (fuso, pacote extra e mensagem do MOTD), para provar que a interface da role funciona, e o `prepare.yml` coloca o host no estado de uma imagem recém-construída em um runner Linux (listas do `apt` vazias com data recente).

## Consequências
- Positivas:
  - A role é testada nas duas versões do Ubuntu que declara.
  - Uma tarefa não idempotente reprova a CI.
- Negativas e o que aceitamos perder:
  - Os testes só provam o que o contêiner alcança: kernel, firewall e relógio ficam fora (ver [ADR-0004](0004-laboratorio-conteineres-systemd.md)).
  - Cada nova versão de Ubuntu exige uma imagem e um digest novos, atualizados à mão (ver [ADR-0002](0002-versoes-fixadas.md)).
- Como verificamos que a decisão continua sendo seguida:
  - O job `Molecule` da CI roda `make test` (`molecule test --all`), que inclui o passo `idempotence`.

## Referências
- `molecule/base/molecule.yml`, linhas 25 a 49 (plataformas) e 56 a 60 (valores sobrescritos).
- `roles/base/meta/main.yml`, linhas 7 a 11.
- `molecule/base/prepare.yml` e commit `b109523`.
- `Makefile`, linhas 8 a 10 e 33 a 41; `tests/images/ubuntu/Dockerfile`, linhas 5 a 8.
- `README.md`, seção "What this repository demonstrates"; `docs/standards.md`, seção "Tests".
