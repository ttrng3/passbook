# Intent: the sharing protocol's step 4 and its evidence hold up on a cold run

**Status:** accepted 2026-09-29 (Ty: "start the two follow up", after the rollback drills)
**Source:** the reviewer's findings on passbook#5 (drill 2/2) and the verifier's three runs on 29/09.

- **Problem.** Five weaknesses in `verification/sharing.md`, none of them in the app: (1) the step 1–2 invariants read after ~500 ms, so step 1's queued 2.5 s background sync can land inside step 4's window; (2) the Evidence list asks for "both invariant JSON blocks" while the protocol has three; (3) `const sent4 = []` throws on a retry in the same page; (4) "Update the copy now must still send" is prose only, so a verifier either skips it or improvises a check (one did on 29/09); (5) PR #2's spec ties its promise to a 2026-09-28 run.
- **Outcome.** Every assertion is runnable code, a retry doesn't throw, the evidence names every JSON block, and no step can read another step's traffic.
- **Not in this change.** The app. PR #2's closed work folder (finding 5 stays as history).
