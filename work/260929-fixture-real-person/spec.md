# Spec: invented values in the sharing fixture

**Intent:** accepted 2026-09-29 · **Status:** approved by Ty's ship of this PR.

- Replace, in both fixture blocks of `verification/sharing.md` (the "Adversary" setup and the recipient-side merge): the relative's name → "Relative (example)"; her date of birth → 1990-01-01; the lab → "Example Lab"; the fasting-glucose reading → 6.9 mmol/L (still above the 6.1 upper bound, so the fixture keeps its "high" meaning); the share email → `relative@example.com`; the merge label → "from Relative (example)". The old values are not quoted here or anywhere else in this change.
- The relative's ids were her initials; they become `rel-1`, `rel-o1`, `relb-1`, `relb-o1`, `u-rel`, changed everywhere they appear, so every assertion still reads a matching id.
- The owner's fixture reading (`mine-1`) is also made up: lab → "Example Lab", LDL → 3.2 mmol/L (still under the 3.4 bound). Whether the old one was real doesn't matter; invented costs nothing (review round 1, finding 2).

**Promise (checkable):** (1) a search of the working tree for the old name, birth date and lab (run from the operator's shell, not written into the repo) prints nothing; (2) the live page's sha256 is unchanged (nothing served changes); (3) the verifier's `sharing` run PASSes every step on this branch before it ships, and again on main after.
