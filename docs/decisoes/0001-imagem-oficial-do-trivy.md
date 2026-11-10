# ADR-0001: Usar a imagem oficial do Trivy em vez do `trivy-action`

- **Status:** aceito
- **Data:** 10/11/2026
- **Responsáveis:** Wesley Costa

## Contexto
A CI varre os arquivos de configuração do repositório com o Trivy (`trivy config --exit-code 1 .`, no job `Security`). O passo mais comum para isso no GitHub Actions é o `trivy-action`, uma action de terceiros mantida pela Aqua Security.

Em março de 2026, o aviso GHSA-69fq-xp46-6x23 (CVE-2026-33634) relatou que o ecossistema do Trivy sofreu um ataque à cadeia de suprimentos. Segundo o aviso, as tags do `trivy-action` foram reescritas com código que roubava credenciais, e as imagens Docker v0.69.5 e v0.69.6 foram publicadas com código malicioso. O `trivy-action` ficou corrigido na versão 0.35.0.

O repositório fixa tudo o que a CI executa (ver [ADR-0002](0002-versoes-fixadas.md)) e não usa segredos na CI. Ainda assim, o passo de segurança não podia depender de uma action cujo histórico de tags já se mostrou reescrevível.

## Alternativas consideradas
| Alternativa | Prós | Contras |
| --- | --- | --- |
| Imagem oficial `aquasec/trivy`, fixada por tag e digest, chamada com `docker://` (escolhida) | Nenhuma action de terceiros no passo; a versão é controlada pelo digest | Atualização manual: o Dependabot não cobre referências `docker://` |
| Manter o `trivy-action`, fixado por SHA | Integração pronta com o GitHub Actions | Descartada por causa do aviso GHSA-69fq-xp46-6x23: a action faz parte do ecossistema que foi comprometido |
| Instalar o binário do Trivy no runner | Não depende de imagem nem de action | A versão do binário fica fora do controle do digest |

## Decisão
Vamos usar a imagem oficial `aquasec/trivy`, fixada por tag e digest, diretamente no passo (`uses: docker://aquasec/trivy:0.76.2@sha256:...`, em `.github/workflows/ci.yml`, linhas 107 a 110). O Trivy lê `trivy.yaml` e `.trivyignore` da raiz do repositório.

## Consequências
- Positivas:
  - O passo não depende de uma action de terceiros.
  - A versão exata do Trivy é a do digest e só muda por commit.
- Negativas e o que aceitamos perder:
  - A atualização da imagem é manual. O Dependabot cobre só as ações (`.github/dependabot.yml`). O procedimento está no [runbook de atualização das versões fixadas](../runbooks/atualizar-versoes-fixadas.md).
  - O `.trivyignore` aceita DS-0002 (imagem roda como root) e DS-0026 (sem `HEALTHCHECK`). Os comentários do arquivo dizem que valem "for tests/images/ubuntu/Dockerfile only", mas o arquivo não limita por caminho: as duas exceções valem para o repositório inteiro. Um Dockerfile novo que rode como root passaria pelo Trivy. A regra "todo outro Dockerfile roda sem root" só é garantida pela revisão do pull request.
- Como verificamos que a decisão continua sendo seguida:
  - O job `Security` roda o Trivy na CI e falha com qualquer achado (`--exit-code 1`).
  - Mudanças no `.trivyignore` aparecem no diff do pull request e passam pela revisão.

## Referências
- `.github/workflows/ci.yml`, linhas 107 a 110; `trivy.yaml`; `.trivyignore`.
- Comentário removido no commit `d5b908e`: "The official image is used instead of trivy-action (see GHSA-69fq-xp46-6x23)". O motivo agora está registrado neste ADR e em [Pipeline de CI](../pipelines/ci.md).
- Aviso GHSA-69fq-xp46-6x23, publicado em 21/03/2026 e atualizado em 30/03/2026: <https://github.com/advisories/GHSA-69fq-xp46-6x23> (consultado em 10/11/2026).
