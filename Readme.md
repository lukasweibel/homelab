setting up Argocd:
1. Installing argocd https://argo-cd.readthedocs.io/en/stable/getting_started/
2. Acess UI and setting up repository
3. applying root.yaml

# Bootstrap new Hardware for GitHub Actions

```bash
curl -fsSL https://raw.githubusercontent.com/lukasweibel/homelab/main/scripts/bootstrap-runner.sh | bash -s -- <TOKEN> rpi-01
```