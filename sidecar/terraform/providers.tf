terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.4.0"
    }

    hcp = {
      source  = "hashicorp/hcp"
      version = "~> 0.96.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = "/Users/rbarnes/Downloads/premium-fuze-216211-ddf131c6759f.json"
}

provider "google-beta" {
  project     = var.project_id
  region      = var.region
  credentials = "/Users/rbarnes/Downloads/premium-fuze-216211-ddf131c6759f.json"
}


provider "vault" {
  address   = var.vault_address
  namespace = var.vault_namespace
  token     = hcp_vault_cluster_admin_token.root.token
}

provider "hcp" {
  project_id    = var.hcp_project_id
  client_id     = var.hcp_client_id
  client_secret = var.hcp_client_secret
}