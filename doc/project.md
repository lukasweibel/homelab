# Project

## Check commands

Run before each quality gate.

1. Test: not applicable, this repository has no general test suite.
2. Lint: `npx --yes --package renovate@44.204.0 -- renovate-config-validator --no-global .github/renovate.json`
3. Configuration behavior: `RENOVATE_CONFIG_FILE=.github/renovate.json npx --yes --package=node@24.11.0 --package=renovate@44.204.0 -- renovate --platform=local --require-config=ignored --dry-run=extract`; inspect detected dependencies.
4. Helm charts: `for chart in clusters/home-cluster/apps/actual-budget clusters/home-cluster/apps/actualbudget-raw-backup clusters/home-cluster/apps/paperless-raw-backup clusters/home-cluster/apps/paperless-ngx clusters/home-cluster/apps/my-frontend clusters/home-cluster/apps/cloudflared clusters/home-cluster/apps/actualtap; do helm lint "$chart" || exit; done`
5. Docker Compose: `docker compose -f infrastructure/hosts/rpi-01/docker-compose.yml config --quiet && docker compose -f infrastructure/hosts/rpi-02/docker-compose.yml config --quiet`
6. Types: not applicable.
7. Build: not applicable.

## Conventions

Kubernetes state is managed through GitOps. Durable cluster changes belong in the repository and are applied through Argo CD. Keep changes minimal and follow the existing YAML layout.

## Extra criteria

1. Renovate must not merge updates automatically unless explicitly requested.
