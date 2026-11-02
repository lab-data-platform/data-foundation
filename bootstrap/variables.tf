variable "platform" {
  description = "Nome da plataforma, usado como prefixo dos recursos."
  type        = string
  default     = "lab-data"
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

