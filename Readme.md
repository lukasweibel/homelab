setting up Argocd:
1. Installing argocd https://argo-cd.readthedocs.io/en/stable/getting_started/
2. Acess UI and setting up repository
3. applying root.yaml

# Kubernetes Dashboard

Access the dashboard at `https://k3s.local.lan`.

To generate a login token:

```bash
kubectl -n kubernetes-dashboard create token dashboard-admin
```

Copy the output and paste it into the "Bearer token" field on the login page.

# Bootstrap new Hardware for GitHub Actions

```bash
curl -fsSL https://raw.githubusercontent.com/lukasweibel/homelab/main/scripts/bootstrap-runner.sh -o /tmp/bootstrap-runner.sh
```
```bash
chmod +x /tmp/bootstrap-runner.sh
```
```bash
/tmp/bootstrap-runner.sh <TOKEN> <LABEL>
```