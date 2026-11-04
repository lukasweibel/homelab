# Review gate 3: Build and test

Feature: renovate_config  
Date: 04.11.2026 21:47  
Reviewer: reviewer  
Review mode: full  
Review base: none  
Verdict: PASS

## Criteria

| Nr | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | All units of work passed Gate 2 and are approved. | met | `keel-state.md` records U1 and U2 as done and approved by the user. The U1 Gate 2 report and the revised U2 Gate 2 report both have verdict PASS. |
| 2 | The full test suite runs without errors. | met | `doc/project.md` states that this repository has no general test suite. I reran the applicable checks: Renovate config validation, extraction, lookup, seven Helm lints, both Compose config checks, `jq empty`, and `git diff --check`. All exited successfully. Renovate emitted non fatal local preset warnings. |
| 3 | Every acceptance criterion from `requirements.md` is demonstrably met. | met | Evidence for each acceptance criterion is listed below. |
| AC1.1 | Weekly update window before 06:00 Europe/Zurich and no automatic merging. | met | `.github/renovate.json:4–6` sets the timezone and Monday before 06:00 schedule. The config does not enable automerging. This also meets the extra project criterion. |
| AC1.2 | Propose each dependency independently, including major updates. | met | `.github/renovate.json:6` enables separate major and minor updates. The lookup log shows distinct update branches, including separate major and minor branches for chart dependencies. |
| AC2.1 | Detect all eight external Helm charts in configured Argo CD application files. | met | The extraction log detects the eight charts: authentik, cert-manager, kubernetes-dashboard, kube-prometheus-stack, longhorn, n8n, open-webui, and traefik. The U1 Gate 2 report records the same extraction proof. |
| AC2.2 | Do not propose Git source revisions such as `main`. | met | `.github/renovate.json:24–29` disables Argo CD dependencies using the `git-tags` datasource. Extraction identifies the Git source revisions as `main`; the U1 Gate 2 report confirms they are disabled. |
| AC3.1 | Version tags match the prior `latest` digests, rclone is updated in both workloads, and rpi-02 UniFi stays unchanged. | met | The digest comparison log verifies matching digests for all six versioned images and the frontend digest. The two rclone values files use `1.75.2`. The candidate diff excludes `infrastructure/hosts/rpi-02/docker-compose.yml`, as chosen by the user. |
| AC3.2 | Pin my-frontend to its verified digest and detect future digest changes. | met | `clusters/home-cluster/apps/my-frontend/values.yaml` contains the verified digest. `.github/renovate.json:31–33` enables `pinDigests`. The lookup log recognizes the current digest for this image. |
| AC4.1 | Identify `RUNNER_VERSION` as an actions/runner release and remove the leading `v` from proposed versions. | met | The extraction log identifies `actions/runner` from `scripts/bootstrap-runner.sh` using the GitHub releases datasource. `.github/renovate.json:12–22` defines the match and `^v(?<version>.*)$` normalization. The public latest release tag is `v2.338.2`, which normalizes to `2.338.2`. Renovate lookup skips GitHub release lookup without a token, as recorded in the existing notes. |
| 4 | Documentation is updated wherever the project keeps any. | met | Feature requirements, units, and state documents record the scope, decisions, deferrals, checks, and risks. Existing `doc/project.md` and `doc/notes.md` cover project checks and Renovate operating notes. |
| 5 | The state file is complete: all decisions and deviations are recorded. | met | `keel-state.md` records the image mapping, deferred UniFi change, excluded `.DS_Store` changes, external Mend silent mode risk, review approvals, and final check results. |
| 6 | Check results are fresh for the final candidate, or the reviewer reran the checks itself. | met | I reran the applicable project checks on the current worktree. I also verified the combined patch hash for `.github/renovate.json` and the eight image manifest patches: `95a2052c009100fc20d935af47ed64364ea41759ada4c76c950aedbb4437b205`, matching the state packet and the supplied final candidate. |
| 7 | Renovate must not merge updates automatically unless explicitly requested. | met | `.github/renovate.json` does not enable automerging. The U1 and U2 Gate 2 reports also verify this policy. |

## Carried over

Empty in full mode.

## Required

Empty on PASS.

## Suggestions

1. Confirm the hosted Mend service is in a pull request capable mode before relying on it to create pull requests. The recorded `mode=silent` setting is external to this repository.
