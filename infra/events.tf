# Barramento de eventos dos assets da plataforma (ADR-0015).
# Todo produtor publica "AssetUpdated" aqui quando um asset fica pronto; cada consumidor
# cria, no próprio repositório, a regra para os assets de que depende.
# Formato do evento: data-platform/docs/eventos.md.

resource "aws_cloudwatch_event_bus" "assets" {
  name        = "${local.name_prefix}-assets"
  description = "Eventos de atualização dos assets da plataforma ${var.platform}"
}

# Guarda todos os eventos do barramento. Permite auditoria e replay:
# reenviar os eventos de um período reprocessa tudo que depende deles.
resource "aws_cloudwatch_event_archive" "assets" {
  name             = "${local.name_prefix}-assets"
  description      = "Histórico dos eventos de assets, para auditoria e replay"
  event_source_arn = aws_cloudwatch_event_bus.assets.arn
  retention_days   = var.assets_events_retention_days
}
