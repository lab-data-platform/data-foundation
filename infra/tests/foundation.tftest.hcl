# Testes unitários do stack foundation, com provider simulado: não acessam a AWS.
# Rodar: make test

mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
    }
  }

  # O mock gera valores aleatórios; a assinatura do SNS exige um ARN válido.
  mock_resource "aws_sns_topic" {
    defaults = {
      arn = "arn:aws:sns:us-east-2:123456789012:lab-data-dev-alerts"
    }
  }

  # O archive exige o ARN válido do barramento.
  mock_resource "aws_cloudwatch_event_bus" {
    defaults = {
      arn = "arn:aws:events:us-east-2:123456789012:event-bus/lab-data-dev-assets"
    }
  }

  mock_resource "aws_s3_bucket" {
    defaults = {
      arn = "arn:aws:s3:::lab-data-dev-audit-123456789012"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }
}

variables {
  alert_emails = ["teste@lab-data.dev"]
}

run "nomes_seguem_a_convencao" {
  command = plan

  assert {
    condition     = aws_budgets_budget.monthly.name == "lab-data-dev-mensal"
    error_message = "O budget deve se chamar <platform>-<env>-mensal."
  }

  assert {
    condition     = aws_sns_topic.alerts.name == "lab-data-dev-alerts"
    error_message = "O tópico de alertas deve se chamar <platform>-<env>-alerts."
  }
}

run "budget_tem_limite_e_quatro_alertas" {
  command = plan

  assert {
    condition     = aws_budgets_budget.monthly.limit_amount == "10" && aws_budgets_budget.monthly.limit_unit == "USD"
    error_message = "O limite padrão do budget deve ser 10 USD."
  }

  assert {
    condition     = length(aws_budgets_budget.monthly.notification) == 4
    error_message = "O budget deve ter alertas em 50%, 80%, 100% e de previsão."
  }
}

run "cada_email_vira_uma_assinatura" {
  command = plan

  variables {
    alert_emails = ["a@lab-data.dev", "b@lab-data.dev"]
  }

  assert {
    condition     = length(aws_sns_topic_subscription.alerts_email) == 2
    error_message = "Cada e-mail de alerta deve gerar uma assinatura no tópico."
  }
}

run "contrato_publica_os_parametros_esperados" {
  command = apply

  assert {
    condition = toset([for p in aws_ssm_parameter.contract : p.name]) == toset([
      "/lab-data/dev/foundation/account_id",
      "/lab-data/dev/foundation/alerts_topic_arn",
      "/lab-data/dev/foundation/assets_event_bus_arn",
      "/lab-data/dev/foundation/assets_event_bus_name",
      "/lab-data/dev/foundation/name_prefix",
      "/lab-data/dev/foundation/region",
    ])
    error_message = "Os parâmetros do contrato mudaram: atualize data-platform/docs/contratos.md."
  }

  assert {
    condition     = aws_ssm_parameter.contract["name_prefix"].value == "lab-data-dev"
    error_message = "O parâmetro name_prefix deve conter o prefixo da plataforma."
  }
}

run "barramento_de_assets_com_historico" {
  command = plan

  assert {
    condition     = aws_cloudwatch_event_bus.assets.name == "lab-data-dev-assets"
    error_message = "O barramento de assets deve se chamar <prefixo>-assets."
  }

  assert {
    condition     = aws_cloudwatch_event_archive.assets.retention_days == 90
    error_message = "O archive deve guardar os eventos por 90 dias por padrão."
  }
}

run "trilha_de_auditoria_protegida" {
  command = plan

  assert {
    condition     = aws_s3_bucket.audit.bucket == "lab-data-dev-audit-123456789012"
    error_message = "O bucket de auditoria deve se chamar <prefixo>-audit-<account_id>."
  }

  assert {
    condition     = !aws_s3_bucket.audit.force_destroy
    error_message = "O bucket de auditoria não pode ser destruído com logs dentro."
  }

  assert {
    condition     = aws_cloudtrail.audit.enable_log_file_validation && aws_cloudtrail.audit.include_global_service_events
    error_message = "A trilha deve validar a integridade dos logs e incluir os serviços globais."
  }

  assert {
    condition     = aws_s3_bucket_versioning.audit.versioning_configuration[0].status == "Enabled"
    error_message = "O bucket de auditoria deve ser versionado."
  }
}

run "rejeita_ambiente_invalido" {
  command = plan

  variables {
    environment = "hml"
  }

  expect_failures = [var.environment]
}

run "exige_pelo_menos_um_email" {
  command = plan

  variables {
    alert_emails = []
  }

  expect_failures = [var.alert_emails]
}

run "rejeita_email_de_exemplo" {
  command = plan

  variables {
    alert_emails = ["seu-email@exemplo.com"]
  }

  expect_failures = [var.alert_emails]
}
