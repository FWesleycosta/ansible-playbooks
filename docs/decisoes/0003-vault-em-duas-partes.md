# ADR-0003: Guardar segredos no Ansible Vault em duas partes

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
O repositório é público e serve de portfólio: nenhum segredo real, host real ou IP pode entrar nele. Mesmo assim, ele precisa mostrar como um segredo é tratado de forma correta: fácil de achar no código, protegido no repositório e fora do alcance dos testes.

O laboratório tem um segredo de demonstração (`lab_demo_api_token`), de valor falso, só para exercitar o padrão.

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Vault em duas partes: `main.yml` com a referência e `vault.yml` cifrado (escolhida) | O nome da variável fica visível e o valor fica protegido; `grep` acha onde o segredo é usado | Os linters não leem o `vault.yml` cifrado; exige um check próprio |
| Cifrar o `main.yml` inteiro | Um arquivo só | Os nomes das variáveis ficam invisíveis e o diff vira ilegível |
| `encrypt_string` dentro do `main.yml` | Um arquivo só, com o valor cifrado | Mistura texto puro e valor cifrado no mesmo arquivo, e a conferência do pre-commit deixa de valer (ela confere arquivos `vault.yml` inteiros) |
| Cofre externo (AWS Secrets Manager, HashiCorp Vault) | Rotação e auditoria de segredos | Este é um laboratório de portfólio, sem serviço de segredos nem conta de nuvem |

## Decisão
Vamos guardar cada segredo em duas partes, na mesma pasta de `group_vars`:
- `main.yml` declara a variável como referência: `lab_demo_api_token: "{{ vault_lab_demo_api_token }}"`.
- `vault.yml` guarda o valor, cifrado com `ansible-vault`, numa variável com o prefixo `vault_`.

A senha do Vault nunca entra no repositório: `make converge` e `make check` pedem a senha (`--ask-vault-pass`), a menos que `ANSIBLE_VAULT_PASSWORD_FILE` aponte para um arquivo fora do repositório. O hook `vault-encrypted`, o `.gitignore` (padrões de arquivos de senha, chaves e `.env`) e o gitleaks protegem contra erro humano. Os testes do Molecule não dependem do Vault.

## Consequências
- Positivas:
  - O nome do segredo continua visível no código e o valor continua protegido.
  - A CI e o Molecule rodam sem senha e sem segredo.
- Negativas e o que aceitamos perder:
  - O `yamllint` e o `ansible-lint` excluem `**/vault.yml`, porque o arquivo cifrado é ilegível para eles. Quem confere o arquivo é o `scripts/check-vault-encrypted.sh`, que só olha o cabeçalho `$ANSIBLE_VAULT;`: ele prova que o arquivo está cifrado, não que o conteúdo está certo.
  - A senha precisa chegar ao colega por um canal fora do repositório (ver o [runbook do Vault](../runbooks/vault.md)).
  - O gitleaks roda só no computador de quem instalou os hooks (ver [ADR-0005](0005-hooks-pre-commit-locais.md)).
- Como verificamos que a decisão continua sendo seguida:
  - `scripts/check-vault-encrypted.sh` roda no hook `vault-encrypted` e no `make lint`, que a CI executa (job `Lint`); um `vault.yml` em texto puro faz o comando sair com código 1.

## Referências
- `inventories/lab/group_vars/all/main.yml`, linhas 5 a 7; `inventories/lab/group_vars/all/vault.yml` (só o cabeçalho foi conferido).
- `Makefile`, linhas 13 e 14; `scripts/check-vault-encrypted.sh`.
- `.pre-commit-config.yaml`, linhas 7 a 11; `.gitignore`, linhas 19 a 29.
- `.yamllint.yml`, linha 11; `.ansible-lint.yml`, linhas 11 e 12.
- `docs/standards.md`, seção "Secrets"; `README.md`, seção "Secrets".
