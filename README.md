# GCP Cloud Run Secrets Consumption Patterns

This repo shows 2 patterns for secrets consumption using Googles's Cloud Run offering. Secrets sync and side car

## Secrets Sync Pattern

Set up Instructions

1. Create a GCP service account with secretsManager.Admin permissions
2. Start up docker container ```
docker run \
   --cap-add=IPC_LOCK \
   -p 8200:8200 \
   --name=dev-vault \
   --volume ./config/:/vault/config \
   --volume ./license/:/vault/license \
   hashicorp/vault-enterprise server```
3. Init and unseal. Add root token to `VAULT_ADDR` env var

### Demo workflowgit add

1. Enable Secret Sync
2. Configure GCP destination in Vault
3. Create a KV secret
4. Show secret manager being empty
5. Create a KV secret
6. Create an association with secret sync and the secret to the destination
7. Show updated Secret Manager
8. Walk through the code of demo app
9. Deploy it to Cloud run
10. Update the secret and show it updating in the demo app

## Vault Agent Sidecar Pattern