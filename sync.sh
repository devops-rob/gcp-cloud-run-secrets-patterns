# Enable secrets sync
vault write -f sys/activation-flags/secrets-sync/activate


vault write sys/sync/destinations/gcp-sm/my-dest \
    credentials='@/Users/rbarnes/Downloads/premium-fuze-216211-36fd2584b6e2.json'
