data "hcp_vault_cluster" "devopsrob_dev" {
  cluster_id = "devopsrob-dev"
}

resource "hcp_vault_cluster_admin_token" "root" {
  cluster_id = data.hcp_vault_cluster.devopsrob_dev.cluster_id
}

resource "vault_policy" "cloud_run_policy" {
  #  namespace = var.vault_namespace
  name   = "cloud_run_policy"
  policy = <<EOF
path "${var.secret_path}" {
  capabilities = [
    "read",
    "list"
  ]
}
EOF
}

resource "vault_gcp_auth_backend" "gcp" {
  credentials = file("/Users/rbarnes/Downloads/premium-fuze-216211-ddf131c6759f.json")

}

resource "vault_gcp_auth_backend_role" "cloud_run" {
  backend                = vault_gcp_auth_backend.gcp.path
  role                   = var.vault_role
  type                   = "iam"
  bound_service_accounts = [google_service_account.cloud_run_sa.email]

  bound_projects = [
    var.project_id
  ]

  token_ttl         = 300
  token_max_ttl     = 600
  token_policies    = ["hcp-root"]
  add_group_aliases = true

}

resource "vault_mount" "kvv2" {
  path = "secret"
  type = "kv-v2"

  options = {
    version = "2"
  }
}
resource "vault_kv_secret_backend_v2" "secret" {
  mount = vault_mount.kvv2.path
}

resource "vault_kv_secret_v2" "mock_secret" {

  mount = vault_kv_secret_backend_v2.secret.mount
  name  = "google_meetup"

  data_json = <<EOF
{
  "location": "Belgium"
}
EOF
}
