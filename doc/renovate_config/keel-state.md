# keel state: Renovate configuration

Feature: renovate_config
Phase: done
Profile: full
Modifier: none
Current unit: none
Next step: none

## Review packet

* Candidate: `.github/renovate.json` and eight in scope image manifests
* Diff hash: `95a2052c009100fc20d935af47ed64364ea41759ada4c76c950aedbb4437b205`
* Checks: Gate 3 reviewer reran all applicable project checks successfully
* Evidence: final review `doc/renovate_config/reviews/gate3_final.md`; implementation hash `95a2052c009100fc20d935af47ed64364ea41759ada4c76c950aedbb4437b205`
* Previous review: U1 review `doc/renovate_config/reviews/gate2_u1_digest.md`; prior U2 report `doc/renovate_config/reviews/gate2_u2.md`

## Gates

| Gate | Subject | Reviewer | Approval |
|---|---|---|---|
| 1 | Inception | reviewer PASS | approved by user |
| 1 | Inception delta for image migration | reviewer PASS | approved by user |
| 1 | Inception delta after deferring UniFi | reviewer PASS | approved by user |
| 2 | U1 configuration | reviewer PASS | approved by user |
| 2 | U2 image references | reviewer PASS | approved by user |
| 3 | Build and test | reviewer PASS | approved by user |

## Units of work

| Unit | Title | Status |
|---|---|---|
| U1 | Configure Renovate managers and update policy | done |
| U2 | Replace in scope latest image references | done |

## Decisions

1. Use Renovate's built in Argo CD manager for external Helm charts, with explicit file matching.
2. Schedule updates weekly before 06:00 in the Europe/Zurich time zone.
3. Allow major updates as separate pull requests. Keep each dependency in its own pull request and do not auto merge.
4. Initially leave Docker images using the `latest` tag unmanaged. This was superseded by the image migration approval below.
5. Validate the configuration and run a local dependency extraction dry run.
6. Track `RUNNER_VERSION` in `scripts/bootstrap-runner.sh` against `actions/runner` releases, normalizing the release tag to the script's version format.
7. Replace seven unique images with fixed tags that currently match the `latest` digest. Update rclone in both locations.
8. Pin `my-frontend` to its current digest because its registry publishes no version tags.
9. Leave Helm chart versions pinned as they are and let Renovate open chart update PRs.
10. Validate affected Helm charts and Docker Compose manifests.
11. Supersede decision 4: replace seven images with same digest version tags and pin `my-frontend` by its current digest.
12. User approved the exact image tag mapping listed in `requirements.md` and confirmed the expanded validation checks.
13. Defer the rpi-02 UniFi image tag change and leave its Compose file untouched until its credentials are handled separately.

## Open items

None. The rpi-02 UniFi reference remains `latest` by user choice. The pre-existing `.DS_Store` changes remain outside the feature candidate. Mend silent mode remains an external service setting.

## Audit log

* 04.11.2026 feature created
* 04.11.2026 configuration policy and project checks confirmed by user
* 04.11.2026 added runner release tracking to scope at user's request
* 04.11.2026 Gate 1 approved by user; construction started
* 04.11.2026 U1 configuration validated; local extraction confirmed chart and runner detection
* 04.11.2026 Gate 2 rework received; user expanded scope to solve latest image handling
* 04.11.2026 user approved fixed image tags, a digest pin for my-frontend, and chart updates through Renovate PRs
* 04.11.2026 user approved the proposed image tag mapping and Helm and Compose validation
* 04.11.2026 Gate 1 image migration delta approved by user; construction resumed
* 04.11.2026 U1 config checks passed; `my-frontend` digest update detected by local lookup
* 04.11.2026 U1 Gate 2 reviewer PASS
* 04.11.2026 U1 approved by user; U2 started
* 04.11.2026 U2 image references updated; validators, chart lint, Compose checks, and registry digest comparisons passed
* 04.11.2026 U2 Gate 2 rework received; original report sanitized because it repeated existing credentials
* 04.11.2026 user chose to defer UniFi image change and leave rpi-02 Compose untouched
* 04.11.2026 removed UniFi from U2 scope and returned to Gate 1 for delta review
* 04.11.2026 Gate 1 UniFi deferral delta approved by user; construction resumed
* 04.11.2026 revised U2 checks passed with rpi-02 Compose excluded
* 04.11.2026 U2 delta Gate 2 reviewer PASS
* 04.11.2026 U2 approved by user; final review started
* 04.11.2026 Gate 3 reviewer PASS
* 04.11.2026 Gate 3 approved by user; feature complete
* 04.11.2026 final implementation candidate checks confirmed; Gate 3 reviewer requested
