terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # Configuração parcial: bucket, key e região são passados no `make init`
  # (ver Makefile), para nenhum dado da conta ficar fixo no código.
  # use_lockfile = lock nativo do S3, dispensa tabela DynamoDB (Terraform >= 1.10).
  backend "s3" {
    encrypt      = true
    use_lockfile = true
  }
}
