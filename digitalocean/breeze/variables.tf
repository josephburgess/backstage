variable "do_token" {
  description = "DigitalOcean Token"
  sensitive   = true
}

variable "ssh_public_key_path" {
  description = "ssh key path"
  default     = "~/.ssh/do_key.pub"
}

variable "region" {
  description = "DO region"
  default     = "nyc1"
}

variable "domain_name" {
  description = "domain"
  default     = "joeburgess.dev"
}
