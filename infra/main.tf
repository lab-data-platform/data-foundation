provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile

  # Tags aplicadas automaticamente em todo recurso (ver convenções no data-platform).
  default_tags {
    tags = {
      Platform    = var.platform
      Environment = var.environment
      Component   = "foundation"
      ManagedBy   = "terraform"
      Repository  = "data-foundation"
    }
  }
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id

  # Prefixo padrão dos recursos: <platform>-<environment>, ex.: lab-data-dev
  name_prefix = "${var.platform}-${var.environment}"

  # Raiz dos parâmetros SSM publicados por este repositório (contrato entre repositórios).
  ssm_prefix = "/${var.platform}/${var.environment}/foundation"
}
