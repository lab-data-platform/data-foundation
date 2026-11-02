# Trilha de auditoria da conta (ADR-0017): quem fez o quê, quando e de onde.
# Sem trilha, o histórico do CloudTrail some em 90 dias. A primeira trilha de eventos
# de gerenciamento é gratuita; paga-se só o armazenamento dos logs no S3 (centavos).

resource "aws_s3_bucket" "audit" {
  bucket = "${local.name_prefix}-audit-${local.account_id}"

  # Logs de auditoria não devem sumir num `make destroy` por engano.
  force_destroy = false
}

resource "aws_s3_bucket_versioning" "audit" {
  bucket = aws_s3_bucket.audit.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit" {
  bucket = aws_s3_bucket.audit.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_ownership_controls" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit" {
  bucket = aws_s3_bucket.audit.id

  rule {
    id     = "reter-logs-de-auditoria"
    status = "Enabled"

    filter {}

    expiration {
      days = var.audit_retention_days
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.audit]
}

locals {
  trail_name = "${local.name_prefix}-audit"
  trail_arn  = "arn:aws:cloudtrail:${var.aws_region}:${local.account_id}:trail/${local.trail_name}"
}

data "aws_iam_policy_document" "audit" {
  statement {
    sid       = "CloudTrailLerAcl"
    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.audit.arn]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid       = "CloudTrailGravarLogs"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.audit.arn}/AWSLogs/${local.account_id}/*"]

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = [local.trail_arn]
    }
  }

  statement {
    sid     = "NegarTransporteSemTLS"
    effect  = "Deny"
    actions = ["s3:*"]

    resources = [
      aws_s3_bucket.audit.arn,
      "${aws_s3_bucket.audit.arn}/*",
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "audit" {
  bucket = aws_s3_bucket.audit.id
  policy = data.aws_iam_policy_document.audit.json

  depends_on = [aws_s3_bucket_public_access_block.audit]
}

resource "aws_cloudtrail" "audit" {
  name           = local.trail_name
  s3_bucket_name = aws_s3_bucket.audit.id

  # Inclui os eventos dos serviços globais (IAM, STS, Budgets).
  include_global_service_events = true
  is_multi_region_trail         = var.audit_multi_region

  # Detecta se um log foi alterado ou apagado depois de gravado.
  enable_log_file_validation = true

  depends_on = [aws_s3_bucket_policy.audit]
}
