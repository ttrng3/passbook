# Spec: sharing protocol fixes

**Intent:** accepted 2026-09-29 · **Status:** approved by Ty's ship of this PR.

1. Step 1–2 invariants: wait ~4 s before reading, instead of ~500 ms. The app's `save()` queues a sync 2.5 s after a change (frag.html, comment above the share push), so step 1's sync has fired before any later step reads traffic.
2. Step 4: `var sent4 = [];` instead of `const`, so pasting the block again doesn't throw.
3. The one-POST count and a new runnable "Update the copy now" check move to a "Before step 3" block right after the invariants, while sharing is on and step 1's `sent` log is still the live one (step 4 replaces the stub and turns sharing off). Both use `var`. Click `#shareNow`, wait ~1 s, expect exactly one more POST to `passbook_shares`.
4. Evidence lists all five results: three JSON blocks (step 1–2 invariants, step 4, recipient merge) and two counts (one-POST, explicit update).

**Promise (checkable):** the verifier's `sharing` run PASSes every step with no step reported "not covered" and no improvised check, and its report contains every JSON result the Evidence list names.
