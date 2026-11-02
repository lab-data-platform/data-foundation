output "state_bucket" {
  description = "Bucket do state remoto, usado no backend dos outros stacks."
  value       = aws_s3_bucket.tfstate.bucket
}

output "aws_region" {
  description = "Região do bucket de state."
  value       = var.aws_region
}
