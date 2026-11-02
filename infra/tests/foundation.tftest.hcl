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
