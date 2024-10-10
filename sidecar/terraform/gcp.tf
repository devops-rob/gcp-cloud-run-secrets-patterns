
# Service Account for Cloud Run service
resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-service-account"
  display_name = "Cloud Run Service Account"
}

resource "google_service_account_key" "cloud_run_sa" {
  service_account_id = google_service_account.cloud_run_sa.account_id
}

resource "google_service_account_iam_binding" "token_creator" {
  service_account_id = google_service_account.cloud_run_sa.name
  role               = "roles/iam.serviceAccountTokenCreator"

  members = [
    "serviceAccount:${google_service_account.cloud_run_sa.email}",
  ]
}

# Storage bucket to house the Vault Agent config
resource "google_storage_bucket" "vault_agent_config" {
  location                    = var.region
  name                        = "demo-vault-agent-config"
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true
  force_destroy               = true
}

resource "google_storage_bucket_object" "vault_agent_config" {

  bucket  = google_storage_bucket.vault_agent_config.name
  name    = "config.hcl"
  content = <<EOF
namespace = "admin"
vault {
  address = "${var.vault_address}"
  tls_skip_verify = true
  namespace = "admin"
}

auto_auth {
   method "gcp" {
      namespace  = "admin"
      mount_path = "auth/gcp"
      config = {
         type            = "iam"
         role            = "${var.vault_role}"
         credentials     = ${jsonencode(base64decode(google_service_account_key.cloud_run_sa.private_key))}
         service_account = "${google_service_account.cloud_run_sa.email}"
      }
   }
  sink "file" {
    config = {
      path = "${var.token_sink_path}"
    }
  }
}

template_config {
  static_secret_render_interval = "5s"
}


template {
  source      = "${var.sink_directory}/secrets.txt.tmpl"
  destination = "/vault/secrets/secrets.txt"
  backup      = false
  exec {
    command = "cp /vault/secrets/secrets.txt ${var.sink_directory}/secrets.txt"
  }

}
EOF

  depends_on = [
    vault_gcp_auth_backend_role.cloud_run
  ]
}

resource "google_storage_bucket_object" "template" {

  bucket  = google_storage_bucket.vault_agent_config.name
  name    = "secrets.txt.tmpl"
  content = <<EOF
{{ with secret "secret/data/google_meetup" }}
{{ .Data.data.location }}
{{ end }}
EOF
}

resource "google_storage_bucket_object" "sink" {

  bucket  = google_storage_bucket.vault_agent_config.name
  name    = "secrets.txt"
  content = <<EOF
.
EOF

}

resource "google_storage_bucket_iam_binding" "vault_agent_config_bucket" {
  bucket = google_storage_bucket.vault_agent_config.name

  members = [
    "serviceAccount:${google_service_account.cloud_run_sa.email}"
  ]

  role = "roles/storage.admin"
}

# Cloud Run service configuration with Vault Agent as a sidecar
data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_v2_service_iam_policy" "policy" {

  project     = google_cloud_run_v2_service.demo.project
  location    = google_cloud_run_v2_service.demo.location
  name        = google_cloud_run_v2_service.demo.name
  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_v2_service" "demo" {
  launch_stage        = "BETA"
  provider            = "google-beta"
  name                = "vault-agent-sidecar-service"
  location            = var.region
  deletion_protection = false
  ingress             = "INGRESS_TRAFFIC_ALL"


  template {

    service_account                  = google_service_account.cloud_run_sa.email
    max_instance_request_concurrency = 10


    scaling {
      min_instance_count = 1
      max_instance_count = 3
    }

    containers {
      name  = "vault-agent-container"
      image = "hashicorp/vault:1.17.3"

      volume_mounts {
        name       = "vault-agent-config"
        mount_path = "/vault/config"
      }

      volume_mounts {
        mount_path = "/vault/secrets"
        name       = "in-memory"
      }


      args = [
        "vault",
        "agent",
        "-config",
        "${var.sink_directory}/config.hcl"
      ]

      env {
        name  = "VAULT_ADDR"
        value = var.vault_address
      }

      env {
        name  = "VAULT_LOG_LEVEL"
        value = "debug"
      }

      env {
        name  = "VAULT_NAMESPACE"
        value = "admin"
      }

      resources {
        limits = {
          memory = "512Mi"
        }
      }

    }

    containers {
      name  = "main-container"
      image = "devopsrob/gcp-file-sync:1.10.3"
      ports {
        container_port = 18201

      }

      volume_mounts {
        name       = "vault-agent-config"
        mount_path = "/vault/config"
      }

      volume_mounts {
        mount_path = "/vault/secrets"
        name       = "in-memory"
      }


      env {
        name  = "SECRET_PATH"
        value = "/vault/secrets/secrets.txt"
      }

      resources {
        limits = {
          memory = "512Mi"
        }
      }
    }


    volumes {
      name = "vault-agent-config"
      gcs {
        bucket    = google_storage_bucket.vault_agent_config.name
        read_only = false
      }
    }

    volumes {
      name = "in-memory"
      empty_dir {
        size_limit = "2Mi"
      }
    }
  }

  depends_on = [
    google_storage_bucket_object.vault_agent_config,
    google_storage_bucket_object.template,
    google_service_account_iam_binding.token_creator,
    vault_gcp_auth_backend_role.cloud_run
  ]
}
