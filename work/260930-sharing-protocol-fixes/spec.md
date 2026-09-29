# Spec: sharing protocol fixes

**Intent:** accepted 2026-09-29 · **Status:** approved by Ty's ship of this PR.

1. Step 1–2 invariants: wait ~3 s (past the 2.5 s background sync) before reading, instead of ~500 ms, so step 1's queued sync has fired before step 4 installs its stub.
2. Step 4: `var sent4 = [];` instead of `const`, so pasting the block again doesn't throw.
3. "Update the copy now must still send" becomes runnable: click `#shareNow`, wait ~1 s, count POSTs to `passbook_shares`; expect exactly one more than before.
4. Evidence lists all four JSON results: the step 1–2 invariants, the one-POST count and the explicit-update count, step 4, and the recipient merge.

**Promise (checkable):** the verifier's `sharing` run PASSes every step with no step reported "not covered" and no improvised check, and its report contains every JSON result the Evidence list names.
