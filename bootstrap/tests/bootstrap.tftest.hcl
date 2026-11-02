# Testes unitários do bootstrap, com provider simulado: não acessam a AWS.
# Rodar: make test

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  # O provider real devolve um JSON válido; o mock precisa fazer o mesmo para o bucket policy.
  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

run "bucket_de_state_segue_a_convencao" {
  command = plan

  assert {
    condition     = aws_s3_bucket.tfstate.bucket == "lab-data-tfstate-123456789012"
    error_message = "O bucket de state deve se chamar <platform>-tfstate-<account_id>."
  }
}

run "bucket_de_state_e_protegido" {
  command = plan

  assert {
    condition     = aws_s3_bucket_versioning.tfstate.versioning_configuration[0].status == "Enabled"
    error_message = "O bucket de state deve ser versionado."
  }

  assert {
    condition = alltrue([
      aws_s3_bucket_public_access_block.tfstate.block_public_acls,
      aws_s3_bucket_public_access_block.tfstate.block_public_policy,
      aws_s3_bucket_public_access_block.tfstate.ignore_public_acls,
      aws_s3_bucket_public_access_block.tfstate.restrict_public_buckets,
    ])
    error_message = "Todo acesso público ao bucket de state deve ser bloqueado."
  }

  assert {
    condition     = one(one(aws_s3_bucket_server_side_encryption_configuration.tfstate.rule).apply_server_side_encryption_by_default).sse_algorithm == "AES256"
    error_message = "O bucket de state deve ser criptografado."
  }
}
