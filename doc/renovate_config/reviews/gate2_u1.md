# Review gate 2: U1 configuration

Feature: renovate_config  
Date: 04.11.2026 20:53  
Reviewer: reviewer  
Review mode: full  
Review base: none  
Verdict: REWORK

## Criteria

| Nr | Criterion | Result | Evidence |
|---|---|---|---|
| 1 | All check commands from `doc/project.md` run without errors. | met | The validator passed. The extraction command exited successfully and extracted dependencies. It logged a warning about local presets, but completed extraction. Test, types, and build are marked not applicable in `doc/project.md:7–11`. |
| 2 | Every acceptance criterion of the unit has a test or a documented manual proof. | met | The extraction output identifies eight external Helm charts and `actions/runner` at `2.322.0` with the configured version extraction. The lookup output shows Git Argo CD sources and `latest` images disabled, and includes separate major update branches. `.github/renovate.json:4–33` provides the weekly schedule, separate major updates, and no auto merge setting. |
| 3 | The changes stay within the scope of the unit. Other files are not changed without reason. | not met | U1 names only `.github/renovate.json` in `units-of-work.md:5`. `git status --short` also shows modified `.DS_Store` and `infrastructure/.DS_Store`, with no reason recorded in the review packet. |
| 4 | No secrets, credentials or personal data in the code. | met | `.github/renovate.json` contains configuration only. No credentials or personal data are present. |
| 5 | No commented out leftovers, no debug code, no TODO without an entry in the state file. | met | `.github/renovate.json:1–35` contains no comments, debug code, or TODOs. |
| 6 | The error cases from the acceptance criteria are handled. | met | The lookup output shows Git source revisions disabled and `latest` image dependencies disabled, covering AC2.2 and AC3.1. The configuration validator passed. |
| 7 | The review packet names the candidate diff hash and a fresh check result for that candidate. | not met | The packet names hash `692224d8…dff4169` and check results. The current U1 file is untracked; hashing its `git diff --no-index` patch gives `87720571…aaaaf5c2`, not the packet hash. The packet hash therefore does not verify against the current U1 diff. |

## Carried over

Empty in full mode.

## Required

1. Remove the unrelated `.DS_Store` changes from the candidate, or record a concrete reason they belong in this unit.
2. Recompute and record the candidate diff hash using the current U1 diff, then ensure the fresh check result corresponds to that hash.

## Suggestions

1. None.
