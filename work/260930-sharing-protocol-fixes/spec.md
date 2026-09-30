# Spec: sharing protocol fixes

**Intent:** accepted 2026-09-29 · **Status:** approved by Ty's ship of this PR.

1. Step 1–2 invariants: the click and the reads become two pastes, with a ~4 s wait between them, instead of ~500 ms inside one block. The app's `save()` queues a sync 2.5 s after a change (frag.html, comment above the share push), so step 1's sync has fired before any later step reads traffic.
2. Step 4: `var sent4 = [];` instead of `const`, so pasting the block again doesn't throw.
3. The one-POST count and a new runnable "Update the copy now" check move to a "Before step 3" block right after the invariants, while sharing is on and step 1's `sent` log is still the live one (step 4 replaces the stub and turns sharing off). Every block declares with `var`, so re-pasting never throws; a Traps line says a re-paste re-runs its actions, so a retry starts from Clean state (review rounds 2–3). Click `#shareNow`, wait for the "Copy updated" panel message, then in a separate paste expect exactly one more POST to `passbook_shares`.
4. Evidence lists all seven results: four JSON blocks (step 1–2 invariants, step 3, step 4, recipient merge), two counts (one-POST, explicit update), and the server-side curl output with its control.
5. Step 3 (turn it off) gets a runnable block too: click `#shareStop`, wait for "Sharing stopped", assert the DELETE, no `revoked` field, the switch off and `S.lastShare` null (review round 4); the stop check counts only traffic after its click, and step 4's read is its own paste after a ~4 s wait (review round 5). Each wait keys on what the panel says ("Copy updated", "Sharing stopped") where the app shows something, then ~4 s more wherever a queued 2.5 s sync must have fired before the next read; after an explicit update and after stop, the reads also assert that no background upload followed (review round 6).

**Promise (checkable):** the verifier's `sharing` run PASSes every step with no step reported "not covered" and no improvised check, and its report contains every JSON result the Evidence list names.
