terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  # O bootstrap cria o bucket que guarda o state de todos os repositórios da plataforma,
  # por isso o state dele próprio fica local (bootstrap/terraform.tfstate, ignorado pelo Git).
  # Se esse arquivo se perder, recupere com: terraform import aws_s3_bucket.tfstate <nome-do-bucket>
}
