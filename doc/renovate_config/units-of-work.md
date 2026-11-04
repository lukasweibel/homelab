# Units of work: Renovate configuration

| Unit | Title | Covers | Files | Depends on |
|---|---|---|---|---|
| U1 | Configure Renovate managers and update policy | AC1.1, AC1.2, AC2.1, AC2.2, AC3.2, AC4.1 | `.github/renovate.json` | Gate 1 approval |
| U2 | Replace in scope latest image references | AC3.1, AC3.2 | `infrastructure/hosts/rpi-01/docker-compose.yml`, `clusters/home-cluster/apps/actual-budget/values.yaml`, `clusters/home-cluster/apps/actualbudget-raw-backup/values.yaml`, `clusters/home-cluster/apps/paperless-raw-backup/values.yaml`, `clusters/home-cluster/apps/paperless-ngx/values.yaml`, `clusters/home-cluster/apps/my-frontend/values.yaml`, `clusters/home-cluster/apps/cloudflared/values.yaml`, `clusters/home-cluster/apps/actualtap/values.yaml` | U1 |
