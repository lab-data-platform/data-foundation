# Tópico de alertas compartilhado pela plataforma.
# Os outros repositórios publicam nele as falhas (Lambda, Step Functions, Airflow),
# encontrando o ARN pelo parâmetro SSM <ssm_prefix>/alerts_topic_arn.

resource "aws_sns_topic" "alerts" {
  name = "${local.name_prefix}-alerts"

  # Criptografia com a chave gerenciada pela AWS (sem custo de KMS).
  kms_master_key_id = "alias/aws/sns"
}

# A AWS envia um e-mail de confirmação para cada endereço; o alerta só chega depois de confirmado.
resource "aws_sns_topic_subscription" "alerts_email" {
  for_each = toset(var.alert_emails)

  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = each.value
}
