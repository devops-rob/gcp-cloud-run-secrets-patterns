ui = true

listener "tcp" {
  address         = "[::]:8200"
  cluster_address = "[::]:8201"
  tls_disable     = "true"
}

storage "raft" {
  path    = "/vault/file"

  retry_join {
    leader_api_addr = "http://127.0.0.1:8200"
  }
}

cluster_addr = "http://127.0.0.1:8201"
api_addr     = "http://127.0.0.1:8200"
license_path = "vault/license/vault.hclic"