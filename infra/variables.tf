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
