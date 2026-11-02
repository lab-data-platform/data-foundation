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

output "contract_parameters" {
  description = "Parâmetros SSM publicados como contrato."
  value       = sort([for p in aws_ssm_parameter.contract : p.name])
}
