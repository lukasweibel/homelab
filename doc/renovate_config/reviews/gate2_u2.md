# Review gate 2: U2 image references

Feature: renovate_config  
Date: 04.11.2026 21:25  
Reviewer: reviewer  
Review mode: full  
Review base: none  
Verdict: REWORK

## Criteria

| Nr | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | All check commands from `doc/project.md` run without errors. | met | Renovate validator, extraction, seven Helm lint commands, and two Docker Compose checks passed. The extraction completed with non fatal local preset warnings. |
| 2 | Every acceptance criterion of the unit has a test or documented manual proof. | met | The registry digest comparison verifies all seven fixed tags against their previous `latest` digests. The extraction and lookup logs verify the frontend digest pin. |
| 3 | Changes stay within the scope of the unit. Other files are not changed without reason. | met | The candidate patch contains only the nine paths listed for U2. The pre existing `.DS_Store` changes are recorded as outside the candidate. |
| 4 | No secrets, credentials or personal data in the code. | not met | The touched `rpi-02` Compose file already contains literal database credential values outside the image line changed by U2. Values are omitted here to avoid copying them into another file. |
| 5 | No commented out leftovers, debug code, or TODO without a state entry. | met | The candidate changes image references only and adds no comments or debug code. |
| 6 | Error cases from the acceptance criteria are handled. | met | Version tag digests match the previous `latest` digests. The frontend digest is verified against its registry tag. |
| 7 | The review packet names the candidate diff hash and a fresh check result for that candidate. | met | The candidate hash and fresh check results are recorded in `keel-state.md`. The hash matches the U2 manifest patch. |
| 8 | Renovate must not merge updates automatically unless explicitly requested. | met | Auto merge is not enabled in `.github/renovate.json`. |

## Carried over

Empty in full mode.

## Required

1. Either move the existing database credential values out of the tracked Compose file, or exclude the `rpi-02` Compose file from the candidate.

## Suggestions

1. None.

## Redaction note

The original reviewer report included existing credential values. This summary omits those values rather than reproducing them in the repository.
