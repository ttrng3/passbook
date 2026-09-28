# Plan: public-personal-data

1. Placeholders in the protocols. The email becomes `owner@example.com` at `verification/front-door.md:67` and `verification/sharing.md:36`. The name becomes `Test Owner` at `verification/front-door.md:42`, and the assertion regex at `:47` changes with it.
2. Write `.pages-allow` (one line: `index.html`) and `.github/workflows/pages.yml` (allowlist copy, fail closed, deploy).
3. Check the workflow's copy step locally: run its shell block against the repo. `_site/` must hold only `index.html`. A missing path and a `..` path must each exit non-zero.
4. Run the `verifier` agent on `front-door` and `sharing` → PASS both (Promise 5).
5. Grep for the email and the name → 0 (Promise 1). Push the branch and open the PR.
6. After Ty's `ship passbook#N`: watch the first workflow run. Then `gh api -X PUT repos/ttrng3/passbook/pages -f build_type=workflow`, re-run the workflow, and check Promise items 2–4 and 6 with curl and secure-pages.

Rollback: `gh api -X PUT repos/ttrng3/passbook/pages -f build_type=legacy -f 'source[branch]=main' -f 'source[path]=/'`, then revert the merge.
