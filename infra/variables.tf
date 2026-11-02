variable "platform" {
  description = "Nome da plataforma, usado como prefixo dos recursos."
  type        = string
  default     = "lab-data"
}

variable "environment" {
  description = "Ambiente da plataforma."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "prd"], var.environment)
    error_message = "environment deve ser dev ou prd."
  }
}

variable "aws_region" {
  description = "Região AWS da plataforma."
  type        = string
  default     = "us-east-2"
}

variable "aws_profile" {
  description = "Profile do AWS CLI usado pelo Terraform."
  type        = string
  default     = "lab-data"
}


variable "budget_limit_usd" {
  description = "Limite mensal de custo da conta, em USD, para os alertas do AWS Budgets."
  type        = number
  default     = 10
}

variable "alert_emails" {
  description = "E-mails que recebem os alertas de custo e de falha da plataforma."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "Informe pelo menos um e-mail em alert_emails."
  }

  validation {
    condition     = alltrue([for e in var.alert_emails : !endswith(lower(e), "@exemplo.com")])
    error_message = "alert_emails ainda tem o e-mail de exemplo: coloque o seu e-mail em infra/terraform.tfvars."
  }
}

variable "assets_events_retention_days" {
  description = "Dias que o archive do barramento de assets guarda os eventos (auditoria e replay)."
  type        = number
  default     = 90
}

variable "audit_retention_days" {
  description = "Dias que os logs de auditoria do CloudTrail ficam no S3."
  type        = number
  default     = 365
}

variable "audit_multi_region" {
  description = <<-EOT
    Trilha de auditoria em todas as regiões. No plano gratuito só us-east-2 está liberada (ADR-0013);
    se a SCP impedir a trilha multirregião no apply, use false.
  EOT
  type        = bool
  default     = true
}
