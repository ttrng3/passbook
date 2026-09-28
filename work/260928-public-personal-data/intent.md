# Intent: stop the public Passbook repo and its Pages site exposing Ty's email and name

**Status:** accepted 2026-09-28
**Source:** secure-pages run in chat, 2026-09-28

**Problem.** `ttrng3/passbook` is PUBLIC, and GitHub Pages serves `main:/`, the whole repo. Two verification protocols use Ty's real email as a test fixture: `verification/front-door.md:67` and `verification/sharing.md:36` (the `email:` field of the stubbed auth object). `front-door.md:42` uses his real name. So the email and name are published both on GitHub and on the Pages site. Every one of the 70 commits uses the GitHub no-reply address, so these fixtures are the only place the email appears. Pages also publishes `supabase/*.sql`, the database schema.

**Outcome.**
- A search of the tracked tree for the email or the name returns 0 hits: the protocols use placeholders.
- Pages no longer serves `verification/` or `supabase/`: their URLs on the Pages site return 404, while the app page still loads.
- Both protocols still pass with the placeholder values.
- The repo stays public.

**Who and what is affected.** The passbook repo and its Pages site, and the two verification protocols. No app code, no user data, no Supabase change.

**Constraints.**
- Passbook is a HOBBY, ruled 24/09, and this change must not widen it.
- The protocols must still run, and the verifier must pass them after the edit.
- A code change reaches `main` only through a PR and `ship passbook#N`.
- The preview artifact is untouched ("Artifact mirror contract").

**Decisions (Ty, 2026-09-28).**
- **No history rewrite; accepted risk.** The email has been public since the first push. Rewriting now wouldn't pull back copies already in clones, forks or caches, and a force-push on a public repo is risky for little gain. The old copies in history stay.
- **Both fixes:** placeholders in the protocols, and Pages stops serving `verification/` and `supabase/`. The public site has no reason to publish test protocols or database config.
- **The repo stays public.**

**Open questions.** None. How Pages is restricted (a `docs/` folder, a build branch or a workflow) is a design choice for the spec.
