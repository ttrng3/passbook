# CLAUDE.md — passbook

A personal and family medical record book kept in the browser, entity **personal** (a hobby tool, not a venture). Live: https://ttrng3.github.io/passbook/

## Commands
- Rebuild `index.html` from `frag.html` and confirm the committed copy matches: `node build.js && git diff --exit-code --stat index.html` (exit 0 = in step)
- Confirm Pages serves what you built: `[ "$(shasum -a 256 < index.html)" = "$(curl -s https://ttrng3.github.io/passbook/ | shasum -a 256)" ]` (exit 0 = same bytes)

## Layout
- `frag.html` is the source: a fragment with no doctype, `<html>`, `<head>` or `<body>`. `index.html` is generated from it by `build.js`. Edit `frag.html`, never `index.html`, and commit both.
- `.pages-allow` publishes `index.html` only; `.github/workflows/pages.yml` deploys only what it lists. Add a line only for a file the page itself needs.
- `supabase/` holds copies of migrations; they are applied from Ty's separate private backend project, and nothing in this repo applies them.
- `verification/front-door.md` and `verification/sharing.md` are the two protocols; `.claude/skills/verify/SKILL.md` says how to serve and drive the page and lists the browser traps.
- `README.md` states the clinical rules and exactly where records go; `REVIEW.md` holds the reviewer's rules.

## Rules
- Changes reach `main` through a PR and Ty's ship. There is no routine and no direct write.
- HOBBY scope (ruled 2026-09-24, REVIEW.md): no price, no paid tier, no public listing, no sign-up opened to strangers. Anything that adds a paying or unknown user stops here and goes back to Ty.
- No personal data in the repo, fixtures included: test names, dates and readings are invented and look invented. `.gitignore` keeps records out; never weaken it.
- A change to the signed-out page, sign-in or sign-out re-runs `verification/front-door.md`; a change to sharing, sync or `syncable()` re-runs `verification/sharing.md`.
- The six clinical rules in the README ("Why it is built this way") hold, and every sentence about where records go must stay true of the code.
- Row-level security is the lock; the front door is presentation. A grant or policy that lets `anon` read or write a row is Critical.
- Never write a Cowork preview URL or artifact id, a person's details or a secret into this public repo.

## Known mistakes
- In this project revoking from `PUBLIC` is not revoking from `anon`: new functions are granted to `anon` by name. Name `anon` in every revoke (`supabase/0024_my_orchestrator_refuses_anon.sql`, 2026-09-26).
- A `200 null` is not a lock: an inert function and a locked one return the same body. Assert the error code, and make a control call to something that does not exist (verify skill, 2026-09-26).
- When an observable and a privilege check disagree, read the privilege itself. A "plan cache" was misdiagnosed before one ACL query showed the real grant (2026-09-26).
- A convenience escape on the front door let whoever held an unlocked phone past it. Ask who is actually standing at the door, not who typed the address (README, 2026-09-25).
- The example book was the default, so an invited relative's first view was a stranger's named medical record. Examples are asked for, never arrive on their own (`frag.html` above `emptyBook()`, 2026-09-25).
- "Erase this device" once erased nothing: an undeclared name inside a `try/catch` threw and was swallowed. `wipeLocal()` walks every key a book can live under (`frag.html` above `wipeLocal()`, 2026-09-25).
- Renaming a storage key, the IndexedDB name, the hand-off `kind` or the sync table without reading the old address first strands records with no error (README, "The name", 2026-09-24).
- A magic link works once. A mail scanner or a first open in an in-app browser spends it; there is no code fallback on the free plan. Tell an invitee to open it in the real browser and set a password (2026-09-25).
- `main` once carried a stale `frag.html` that did not match the live `index.html`. Before any rebase, run the build check above (2026-09-24).
