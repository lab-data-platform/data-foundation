output "account_id" {
  description = "Conta AWS da plataforma."
  value       = local.account_id
}

output "name_prefix" {
  description = "Prefixo padrão dos recursos."
  value       = local.name_prefix
}

output "budget_name" {
  description = "Nome do budget mensal."
  value       = aws_budgets_budget.monthly.name
}

output "alerts_topic_arn" {
  description = "Tópico SNS de alertas da plataforma."
  value       = aws_sns_topic.alerts.arn
}

output "assets_event_bus_name" {
  description = "Barramento de eventos dos assets."
  value       = aws_cloudwatch_event_bus.assets.name
}

output "audit_trail" {
  description = "Trilha de auditoria do CloudTrail e bucket dos logs."
  value       = { trail = aws_cloudtrail.audit.name, bucket = aws_s3_bucket.audit.bucket }
}

output "contract_parameters" {
  description = "Parâmetros SSM publicados como contrato."
  value       = sort([for p in aws_ssm_parameter.contract : p.name])
}
