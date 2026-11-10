# ADR-0004: Usar um laboratório de contêineres com systemd, acessado pela conexão `community.docker`

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
O repositório precisa de hosts para aplicar os playbooks e para rodar os testes do Molecule, sem guardar IP, chave nem host real (o repositório é público). O host de teste precisa se comportar como uma máquina virtual, com o systemd como PID 1, para que as roles possam gerenciar serviços como num host real (é o que o comentário do `Dockerfile` da imagem de teste diz).

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Contêineres Ubuntu com systemd e conexão `community.docker.docker` (escolhida) | Rápidos, leves, funcionam na CI; sem SSH, sem IP e sem chave | Precisam de `privileged` e do cgroup do host; não testam tudo o que uma máquina virtual testa |
| Máquinas virtuais | Comportamento mais próximo de um host real | Lentas, pesadas e difíceis de rodar na CI |
| Contêineres com SSH | Mesmo caminho de conexão de um host real | Chaves, portas e IPs num repositório público |
| Contêineres sem systemd | Mais simples de rodar | Não testam `service` nem o systemd |

## Decisão
Vamos usar três contêineres Ubuntu com systemd (`web-01`, `web-02`, `db-01`), definidos em `lab/compose.yml` e criados a partir da imagem de teste `tests/images/ubuntu/Dockerfile`. O inventário `lab` os alcança pelo plugin de conexão `community.docker.docker`, então ele não tem IP, SSH nem host real. O `ansible.cfg` aponta o inventário `lab` como padrão: o alvo padrão é sempre local.

## Consequências
- Positivas:
  - Nenhum IP, chave ou host real no repositório.
  - O mesmo tipo de host serve ao laboratório e ao Molecule.
- Negativas e o que aceitamos perder:
  - `privileged: true` e `cgroup: host` (e, no Molecule, `cgroupns_mode: host`) dão ao contêiner privilégios altos. São aceitáveis só para uso local, e a imagem nunca é implantada (`.trivyignore` aceita DS-0002 e DS-0026 por isso; ver [ADR-0001](0001-imagem-oficial-do-trivy.md)).
  - Contêineres não testam parâmetros de kernel, firewall, auditd nem o relógio do sistema. As roles que precisam disso (`chrony` e `firewall`, no roadmap) vão exigir um cenário com máquina virtual.
- Como verificamos que a decisão continua sendo seguida:
  - O inventário `lab` é o padrão no `ansible.cfg`.
  - O job `Security` roda o hadolint e o Trivy sobre o Dockerfile da imagem de teste.

## Referências
- `lab/compose.yml`, linhas 1 a 5 e 8 a 19.
- `inventories/lab/hosts.yml`, linhas 2 a 4 e 7.
- `ansible.cfg`, linhas 2 e 3.
- `tests/images/ubuntu/Dockerfile`, linhas 1 a 4, 15 e 16, 31 a 34.
- `docs/standards.md`, linha 82 (limites dos contêineres); `README.md`, seção "Roadmap".
