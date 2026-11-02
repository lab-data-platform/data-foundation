# Contrato publicado por este repositório no SSM Parameter Store.
# Os outros repositórios leem esses valores com data "aws_ssm_parameter",
# sem depender do state deste repositório. O catálogo de parâmetros fica em
# data-platform/docs/contratos.md: mudar um nome aqui é mudança de contrato.

locals {
  contract = {
    name_prefix      = local.name_prefix
    account_id       = local.account_id
    region           = var.aws_region
    alerts_topic_arn = aws_sns_topic.alerts.arn
  }
}

resource "aws_ssm_parameter" "contract" {
  for_each = local.contract

  name  = "${local.ssm_prefix}/${each.key}"
  type  = "String"
  value = each.value
}
