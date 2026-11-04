# Notes

1. Renovate's Argo CD manager has no default file patterns. Configure it to scan the Argo CD application manifests.
2. The previous Renovate log used silent mode, so it scanned dependencies but deliberately created no pull requests.
3. Tags named `latest` are not normal version values and were skipped in the previous scan.
4. Local Renovate checks need `RENOVATE_CONFIG_FILE`, `--require-config=ignored`, and Node 24.11.0. GitHub release lookups need a token, but extraction can still verify the dependency format.
5. `lukasweibel99/my-frontend` currently publishes only the `latest` tag. Use its digest until the source build publishes version tags.
