# Requirements: Renovate configuration

## Intent

Configure Renovate to propose reviewed dependency updates for this GitOps repository, including external Helm charts used by Argo CD, and replace the in scope `latest` image references with fixed versions or digests.

**Out of scope:**

1. Changing current Helm chart versions manually.
2. Granting Renovate access to the Kubernetes cluster.
3. Automatically merging or deploying updates.
4. Changing the rpi-02 UniFi Compose entry, which is deferred while its existing credentials remain in that file.

## Context

The repository has nine `latest` image references across eight images in Helm values and Docker Compose files, GitHub Actions references, and external Helm chart versions in Argo CD Application manifests. The rpi-02 UniFi reference remains unchanged by user choice. Six other images have stable version tags matching the current `latest` digest. The `my-frontend` image publishes only `latest`, so it will be pinned by digest. Renovate's Argo CD manager needs an explicit file pattern.

| Image | New reference | Scope |
|---|---|---|
| `adguard/adguardhome` | `v0.107.80` | Host `rpi-01` |
| `actualbudget/actual-server` | `26.11.0` | Kubernetes |
| `rclone/rclone` | `1.75.2` | Both backup workloads |
| `ghcr.io/paperless-ngx/paperless-ngx` | `3.4.2` | Kubernetes |
| `cloudflare/cloudflared` | `2026.10.7` | Kubernetes |
| `ghcr.io/mattfaz/actualtap` | `v1.0.39` | Kubernetes |
| `lukasweibel99/my-frontend` | `latest@sha256:0bc00f7c0a54106d6e4d43f739cebe1126645c363cfdd73835d791ad0c3a5ae6` | Kubernetes, no version tags are published |
| `lscr.io/linuxserver/unifi-network-application` | `latest` | Host `rpi-02`, deliberately deferred |

## Requirements

### R1 Renovate update policy (functional)

Schedule supported updates weekly before 06:00 in the Europe/Zurich time zone. Keep each dependency in its own pull request, include major updates separately, and do not automatically merge.

* AC1.1: When Renovate scans the repository, update pull requests are eligible only during the weekly window before 06:00 in the Europe/Zurich time zone, and automatic merging is not enabled.
* AC1.2: When Renovate finds updates, each dependency is proposed independently, including major updates.

### R2 Argo CD Helm chart detection (functional)

Detect external Helm chart versions in Argo CD Application manifests and ignore Git source revisions.

* AC2.1: When Renovate scans the configured Argo CD application files, all eight external Helm charts are detected using their chart repositories and names.
* AC2.2: When Renovate scans Git based Argo CD sources, branch revisions such as `main` are not proposed for updates.

### R3 Stable container image references (functional)

Replace mutable image tags with version tags where available, pin the image that has no published version tags by digest, and allow Renovate to track that digest.

* AC3.1: After the eight in scope references are updated, six unique images use version tags whose registry digests match their `latest` digests, rclone is updated in both workloads, and the rpi-02 UniFi reference remains unchanged.
* AC3.2: When Renovate scans the `my-frontend` image, its `latest` tag is pinned to the verified current digest and Renovate detects future digest changes.

### R4 Self hosted runner release (functional)

Track the pinned GitHub Actions runner release in the bootstrap script. Updating this value affects new installations; existing registered runners update through GitHub's runner update mechanism.

* AC4.1: When Renovate scans `scripts/bootstrap-runner.sh`, it identifies `RUNNER_VERSION` as a release of `actions/runner` and proposes the version without a leading `v`.

## Category checklist

| Category | Covered / N/A | AC or note |
|---|---|---|
| Happy path | Covered | AC1.1, AC1.2, AC2.1, AC3.1, AC3.2, AC4.1 |
| Failure and error cases | Covered | Configuration validator must pass |
| Empty and edge cases | Covered | AC2.2, AC3.2 |
| Persistence and restart | Covered | Image references only change; persistent volumes and data configuration stay unchanged |
| Ordering and concurrency | N/A | No runtime behavior is added |
| Exclusions and boundaries | Covered | No cluster access, auto merge, or live state change before merge |
| Documentation and manual proof | Covered | Validate extraction against the repository files |
| Backward compatibility | Covered | Six explicit tags resolve to the current image digests; the frontend digest is the current `latest` digest; UniFi stays unchanged |
| Performance and scale | N/A | One small repository configuration |
| Secrets and privacy | Covered | No credentials are added |

## Risks and assumptions

1. Renovate's hosted service must run in a pull request capable mode rather than silent mode.
2. Chart manager extraction must be verified against the multi source Dashboard Application.
3. The image tag digests were compared against registry data on 04.11.2026. They may change after this date.
4. Merging image reference changes can trigger Argo CD rollouts and the rpi-01 host deployment workflow, even though the selected tags currently resolve to the same image digests. UniFi remains on `latest` until its credentials are handled separately.
