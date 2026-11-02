# data-foundation

Base da plataforma `lab-data`: tudo o que os outros repositórios precisam antes de existir. Visão geral da plataforma em [data-platform](../data-platform/README.md).

## Recursos na AWS

O que este repositório cria na conta. **Região:** `us-east-2` (Ohio), exceto os serviços globais. No console, confira se o seletor de região (canto superior direito) está em **Ohio**; senão, os recursos regionais parecem não existir.

| Serviço AWS | Recurso | Para que serve | Região | Custo | Código | Onde ver no console |
|---|---|---|---|---|---|---|
| **Amazon S3** | Bucket `lab-data-tfstate-<account_id>` | Guarda o state do Terraform de **todos** os repositórios. Versionamento, criptografia, bloqueio público, lifecycle e TLS ficam nas abas *Properties* e *Permissions* do bucket | `us-east-2` | centavos | `bootstrap/main.tf` | [S3 → Buckets](https://us-east-2.console.aws.amazon.com/s3/buckets?region=us-east-2) |
| **AWS Budgets** | Budget `lab-data-dev-mensal` | Alerta de **custo** por e-mail: 50%, 80% e 100% de US$ 10, mais previsão do mês | global | grátis (2 primeiros budgets) | `infra/budget.tf` | [Billing → Budgets](https://us-east-1.console.aws.amazon.com/billing/home#/budgets) |
| **Amazon SNS** | Tópico `lab-data-dev-alerts` + assinatura de e-mail | Canal de alertas **técnicos** da plataforma: as próximas camadas publicam falhas nele | `us-east-2` | grátis no volume do lab | `infra/alerts.tf` | [SNS → Topics](https://us-east-2.console.aws.amazon.com/sns/v3/home?region=us-east-2#/topics) |
| **AWS Systems Manager** (Parameter Store) | 4 parâmetros em `/lab-data/dev/foundation/` | Contrato lido pelos outros repositórios ([detalhe abaixo](#contrato-publicado)) | `us-east-2` | grátis (parâmetros *Standard*) | `infra/contract.tf` | [Parameter Store](https://us-east-2.console.aws.amazon.com/systems-manager/parameters?region=us-east-2) |

**Previsto (camada 6):** rede e segurança base (VPC, security groups, roles IAM).

**Fora do Terraform:** o usuário IAM `lab-admin` foi criado à mão no console ([setup](../data-platform/docs/setup/ambiente-local.md)).

Para listar pelo terminal tudo o que este repositório criou:

```bash
aws resourcegroupstaggingapi get-resources --region us-east-2 \
  --tag-filters Key=Repository,Values=data-foundation \
  --query 'ResourceTagMappingList[].ResourceARN' --output text
```

O budget não aparece nesse comando, porque ele é global e a busca por tag é regional. Para vê-lo: `aws budgets describe-budgets --account-id <account_id>`.

## Estrutura

```
data-foundation/
├── bootstrap/            # bucket do state (state local, roda uma vez)
│   └── tests/
├── infra/                # stack principal (state remoto: foundation/<env>/terraform.tfstate)
│   └── tests/
├── Makefile
├── CLAUDE.md
└── README.md
```

## Uso

```bash
make help            # lista os comandos
make test            # testes unitários, sem AWS
make whoami          # confirma a identidade (esperado: user/lab-admin)
pre-commit install   # uma vez por clone: ativa os hooks (gitleaks, terraform fmt...)

# Uma única vez: bucket do state
make bootstrap-plan
make bootstrap-apply

# Stack principal
cp -n infra/terraform.tfvars.example infra/terraform.tfvars   # -n: não sobrescreve; depois coloque o seu e-mail
make init
make plan
make apply
```

Depois do `apply`, a AWS manda um e-mail para **confirmar a assinatura do tópico de alertas**. Os alertas só chegam depois de você clicar no link. O budget manda e-mail direto, sem confirmação.

## Testes

| Nível | Comando | O que cobre |
|---|---|---|
| Pré-commit | `pre-commit run --all-files` | Segredos (gitleaks, credenciais AWS, chaves privadas), YAML, formatação do Terraform e commit direto na `main`; roda sozinho a cada `git commit` |
| CI | GitHub Actions ([ci.yml](.github/workflows/ci.yml)) | `terraform fmt -check`, `make validate` e `make test` em todo PR e push na `main`; obrigatório para o merge |
| Unitário | `make test` | Nomes, tags, budget, assinaturas, contrato SSM e validação das variáveis, com provider simulado |
| Real | `make plan` | Plano contra a conta `dev` |

Este repositório não tem emulador local: os serviços dele (Budgets e as tags do S3 via S3 Control) não são emulados de forma confiável pelo moto. Ver [ADR-0012](../data-platform/docs/decisoes/0012-testes-locais.md).

## Contrato publicado

| Parâmetro SSM | Valor |
|---|---|
| `/lab-data/<env>/foundation/name_prefix` | `lab-data-<env>` |
| `/lab-data/<env>/foundation/account_id` | ID da conta |
| `/lab-data/<env>/foundation/region` | `us-east-2` |
| `/lab-data/<env>/foundation/alerts_topic_arn` | ARN do tópico SNS de alertas |

Mudar um nome aqui quebra quem consome: atualize também o [catálogo de contratos](../data-platform/docs/contratos.md).
