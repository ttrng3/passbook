# Intent: a real person's health data leaves the public test fixture

**Status:** accepted 2026-09-29 (Ty, in chat, confirmed the fixture's relative is a real person)
**Source:** the reviewer's Critical finding on passbook#5 (drill 2/2), 29/09.

- **Problem:** `verification/sharing.md` pairs a real person's given name with her date of birth, a fasting-glucose reading and the lab that took it. The repo is public, so anyone can read it on GitHub. It is not served on Pages (only `index.html` is).
- **Outcome:** the file holds invented values only; the `sharing` protocol still passes unchanged, because its assertions key on ids (`va-1`, `vb-1`, `u-va`), never on the name, birth date, reading or lab.
- **Not in this change:** the git history. Commit caba857 onward still holds the old values; removing them needs a history rewrite or a visibility change, which is Ty's call (see the PR).
