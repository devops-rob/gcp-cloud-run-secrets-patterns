variable "hcp_project_id" {
  default = "11eaf36a-6598-9f13-bd4f-0242ac110018"
}

variable "hcp_client_id" {}

variable "hcp_client_secret" {}

variable "my_email" {}

variable "project_id" {
  #  default = "hc-29deeab959fb4e1484a9ce98f95"
}

variable "vault_address" {
  description = "The address of Vault"
  #  default     = "https://devopsrob-dev.vault.11eaf36a-6598-9f13-bd4f-0242ac110018.aws.hashicorp.cloud:8200"
}

variable "vault_namespace" {
  description = "The Vault namespace to use"
  default     = "admin"
}

variable "vault_role" {
  description = "The role name that the service should use"
  default     = "cloud_run"
}

variable "credentials_path" {
  description = "The absolute path to the credentials file"
  default     = "/var/run/secrets/cloud.google.com/service-account.json"
}

variable "region" {
  description = "GCP region"
  default     = "europe-west1"
}

variable "token_sink_path" {
  description = "The path to the sink that the token will be written to"
  default     = "/vault/config/vault-token-via-agent"
}
variable "sink_directory" {
  default = "/vault/config"
}

variable "secret_path" {
  default = "secret/data/google_meetup"
}