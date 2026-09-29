# Spec: invented values in the sharing fixture

**Intent:** accepted 2026-09-29 · **Status:** approved by Ty's ship of this PR.

- Replace, in both fixture blocks of `verification/sharing.md` (the "Adversary" setup and the recipient-side merge): the relative's name → "Relative (example)"; her date of birth → 1990-01-01; the lab → "Example Lab"; the fasting-glucose reading → 6.9 mmol/L (still above the 6.1 upper bound, so the fixture keeps its "high" meaning); the share email → `relative@example.com`; the merge label → "from Relative (example)". The old values are not quoted here or anywhere else in this change.
- Ids stay (`va-1`, `va-o1`, `vb-1`, `vb-o1`, `u-va`): every assertion reads them.

**Promise (checkable):** (1) a search of the working tree for the old name, birth date and lab (run from the operator's shell, not written into the repo) prints nothing; (2) the live page's sha256 is unchanged (nothing served changes); (3) the verifier's `sharing` run PASSes every step, as it did at dd74cd1.
