# ADR-0006: Exigir um único check, o `CI result`

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
A CI tem três jobs de verificação (`Lint`, `Molecule` e `Security`). Para que uma branch protegida só aceite um pull request com a CI verde, o ruleset do GitHub precisa exigir checks. Exigir cada job separadamente amarra o ruleset aos nomes dos jobs e deixa a lista de checks para manter à mão. O comentário do workflow descreve a regra que se quer: um único check, que falha quando qualquer job falhou, foi cancelado ou foi pulado.

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Um job final, `CI result`, que consolida os outros e é o único check exigido (escolhida) | O ruleset tem um nome estável para exigir; o job reprova se algum outro falhou, foi cancelado ou foi pulado | O `needs` do `CI result` é uma lista manual |
| Exigir cada job no ruleset | Não precisa de job extra | Os nomes dos checks mudam (por exemplo, com uma matriz), e a lista do ruleset é manual |
| Nenhum check obrigatório | Nada para configurar | Um pull request com a CI quebrada poderia ser mesclado |

## Decisão
Vamos manter o job `ci-result` (nome exibido: `CI result`), que roda sempre (`if: always()`), depende de `lint`, `molecule` e `security` e falha se qualquer um deles terminar com resultado diferente de `success` (falha, cancelado ou pulado). Esse é o check que o ruleset exige.

Situação verificada em 10/11/2026 na configuração de rulesets do repositório no GitHub, que não está no código: o ruleset `protege-main-develop` não exige o check `CI result` (não tem `required_status_checks`), e a `main` não tem proteção clássica. Hoje, portanto, uma CI vermelha não impede o merge.

## Consequências
- Positivas:
  - Um único nome para exigir, que não muda quando um job é renomeado ou ganha matriz.
  - Job pulado ou cancelado reprova o `CI result`.
- Negativas e o que aceitamos perder:
  - O `needs` do `ci-result` é manual: quem cria um job novo precisa incluí-lo na lista, senão a falha dele não derruba o `CI result`. Nada verifica isso automaticamente.
  - Se um novo push cancela a execução de um pull request, o `CI result` dessa execução reprova (cancelado). Vale a execução mais recente.
- Como verificamos que a decisão continua sendo seguida:
  - Revisão: todo pull request que cria ou renomeia um job do `ci.yml` precisa atualizar o `needs` do `ci-result`.
  - Pendente: a configuração do ruleset (ver acima).

## Referências
- `.github/workflows/ci.yml`, linhas 123 a 142 (comentário da linha 130: "Single required check for the rulesets").
- `docs/standards.md`, seção "Tests".
- [Pipeline de CI](../pipelines/ci.md).
