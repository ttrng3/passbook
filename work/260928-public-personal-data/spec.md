# Spec: public-personal-data

**Approved:** 2026-09-28
**Intent:** accepted 2026-09-28 · **Status:** approved

## Requirements
1. The two verification protocols use placeholders instead of Ty's email and name (intent: Outcome 1). Four places: the email in `verification/front-door.md:67` and `verification/sharing.md:36`; the name in `verification/front-door.md:42` and the regex that asserts on it at `verification/front-door.md:47`.
2. Pages serves only what the app needs; `verification/`, `supabase/`, `work/`, `build.js`, `frag.html` and `README.md` return 404 (intent: Outcome 2).
3. Anything added to the repo later is **not** published unless someone lists it explicitly (Ty's steer on 2026-09-28).
4. Both protocols still pass (intent: Outcome 3). The repo stays public, and history is not rewritten (intent: Decisions).

## Design

**Pages approach: a GitHub Actions deploy from an explicit allowlist.** Pages switches from "deploy from branch `main` /" to "GitHub Actions". A workflow copies only the paths listed in `.pages-allow` into `_site/` and deploys that. Today the list holds one line, `index.html`: the app is one self-contained file (Verified: `build.js` inlines everything, and `index.html` references no other local file).

Why this one, over the alternatives:

| Option | New folder added later | Verdict |
|---|---|---|
| Serve from `docs/` | published by default, if it lands in `docs/` | fails Ty's steer: the folder is the allowlist, so anything dropped in it leaks |
| Build branch (`gh-pages`) pushed from the Mac | not published unless copied | works, but needs a second branch, a manual push step, and the Mac |
| **Actions + `.pages-allow`** | **not published unless named in the list** | **chosen**: the list is the only door, it runs with no Mac, and `main` stays the one source |

**The workflow fails closed.** If a listed path is missing, the job fails and the live site stays as it was, rather than deploying a partial site. A path in the list that escapes the repo (`..`, an absolute path) also fails the job.

**Files**
- `.pages-allow`: one path per line, `#` comments allowed. First version: `index.html`.
- `.github/workflows/pages.yml`: on push to `main` and on manual dispatch. Permissions `pages: write`, `id-token: write`, `contents: read`. Steps: checkout → read `.pages-allow`, reject any `..` or leading `/`, `cp --parents` each listed path into `_site/`, fail if any is missing → `configure-pages` → `upload-pages-artifact` (path `_site`) → `deploy-pages`. Action versions (Verified, latest releases on 2026-09-28): `actions/checkout@v7`, `actions/configure-pages@v6`, `actions/upload-pages-artifact@v5`, `actions/deploy-pages@v5`.
- The two protocols: the email placeholder is `owner@example.com` and the name placeholder is `Test Owner`. The regex at `front-door.md:47` changes with the name, so the "door doesn't leak the name" assertion still tests something.
- Pages setting: `gh api -X PUT repos/ttrng3/passbook/pages -f build_type=workflow`, run after the workflow is on `main`, so the site is never without a deploy source.

**Order:** PR (placeholders + allowlist + workflow) → Ty ships → the first workflow run deploys → switch `build_type` → re-run the workflow → check the Promise.

## Conflicts
| Rule (by name) | What in the design touches it | Resolution |
|---|---|---|
| Artifact mirror contract | Passbook has one preview artifact, built from `frag.html` | Untouched: this change doesn't edit `frag.html` or the preview, and the preview keeps existing |
| Artifact mirror contract: wiring page | a Pages change can mean a Pipeline Wiring update | Passbook has no routine, and its wiring entry is the preview row (Likely, per memory). The Pages address `ttrng3.github.io/passbook/` doesn't change, so no wiring update is needed. Question for Ty if you want the deploy method recorded there anyway |
| Code reaches main only through a PR Ty ships | the workflow and protocol edits are code | PR on `work/public-personal-data`, Ty types `ship passbook#N` |
| Passbook HOBBY ruling (24/09) | must not widen scope | No feature, no user-facing change, no new surface |
| Verify before you assert (kernel §4) | action versions are present-day facts | looked up by `gh api …/releases/latest` today |
| Entity separation | none: Passbook holds no OMNI or ECOPM data | n/a |

Policy loaded: kernel standing instructions §1–9 (Read tool), artifact mirror contract (memory), secure-pages (run today), the passbook README. `ty-report-standard` and `apple-design` don't apply: no report, and no UI change.

## Security
secure-pages on 2026-09-28, before this change:
- 1 Secrets: PASS (0 hits in the tree, 0 in history, no JWTs)
- 2 Visibility: PUBLIC. FAIL on Ty's email and name in the two protocols (the locations above)
- 3 Pages: FAIL. The whole repo is served from `main:/`
- 4 Supabase: PASS (RLS on every table; every policy anon can reach gates on `auth.uid()`; the callable functions check `auth.uid()`)

Expected after this change: 2 PASS, 3 PASS. The email stays in git history by Ty's decision (accepted risk), so history is not a FAIL for this change.

## Promise
Measured on the day it's shipped:
1. `git grep -c` for Ty's email and for his name (values given at run time, not stored here) → 0 and 0.
2. `curl -s -o /dev/null -w '%{http_code}'` on the Pages site for `verification/front-door.md`, `supabase/0010_famrec_sync.sql`, `work/260928-public-personal-data/intent.md` and `README.md` → 404 each.
3. The Pages root returns 200, and its body's sha256 equals the sha256 of `index.html` on `main`.
4. The workflow run is green, and a dry run with a missing path in `.pages-allow` fails.
5. The `verifier` agent runs `front-door` and `sharing` → PASS both.
6. secure-pages re-run: checks 2 and 3 PASS.

## Out of scope
- Rewriting git history (Ty: accepted risk).
- Making the repo private.
- The shared `ttrng3.github.io` origin question (H2, open since 24/09).
- Moving the database's anon grants: they're the Supabase default and effectively closed by RLS.
