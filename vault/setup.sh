docker run \
  --cap-add=IPC_LOCK \
  -p 8200:8200 \
  --name=dev-vault \
  --volume ./config/:/vault/config \
  --volume ./license/:/vault/license \
  hashicorp/vault-enterprise server