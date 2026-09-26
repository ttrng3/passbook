---
name: verify
description: How to build, serve and drive Passbook to observe a change actually running, and the traps that cost hours here.
---

# Verifying Passbook

Single-file browser app. One source, two targets: edit `frag.html`, run
`node build.js`, and `index.html` is what ships. **Never test `frag.html`** —
it proves nothing about the artifact.

## Handle

```bash
cd ~/Projects/passbook && node build.js
(python3 -m http.server 8777 >/dev/null 2>&1 &)
# drive http://127.0.0.1:8777/index.html with the Chrome MCP tools
lsof -ti:8777 | xargs kill      # when done
```

Confirm what you built is what is deployed:
```bash
shasum -a 256 index.html
curl -s -H 'Cache-Control: no-cache' https://ttrng3.github.io/passbook/ | shasum -a 256
```

Written protocols live in `verification/*.md` — read the one matching the
surface before driving, and run it with the `verifier` agent when you want
the browser noise kept out of the main thread.

## Traps, each of which cost an hour

- **Stub `window.confirm` before any click.** A native dialog freezes the
  Chrome extension and the session cannot recover. `window.confirm = () => true;`
- **Stub `window.fetch` BEFORE assigning `AUTH`.** `save()` queues a sync
  ~2.5s later; with a real fetch and a fake token the server returns 401 and
  the app clears `AUTH` underneath you. A run that "loses its login" is this.
- **Assign app globals bare: `AUTH = {...}`, never `window.AUTH = {...}`.**
  Top-level `let` lives in script scope, not on `window`. The windowed form
  throws nothing and does nothing.
- **Call `read_console_messages` once before you start, then reload.** It only
  captures from its first invocation, so load-time errors are invisible
  otherwise.
- **A hash-only URL change does not reload.** Navigate, then `location.reload()`.
- **`_orch` caches the share recipient per session** — reset between cases.

## Server side

Anything about RLS, grants or the invite gate is proved with `curl`, not the
UI. The publishable key is in the built page; no secret is needed.

**Always run a control call** against something that does not exist
(`/rest/v1/does_not_exist`). `[]` only means "locked" if a missing table
looks different — it returns `PGRST205`.

**Assert the error code, never the empty answer.** A function that is merely
inert and one that is actually locked both return `null`. Reading `200 null`
as "fine" cost a day and a half on `my_orchestrator`, which turned out to
still have `anon=X` in its ACL the whole time.

**Read the database directly instead of theorising.** Ty's CLI is logged in
and the project is linked:
```bash
cd ~/Projects/vitals-app && supabase db query --linked "select proacl::text from pg_proc where proname='...';"
```
When an observable and a privilege check disagree, read the privilege. Note:
**revoking from PUBLIC is not revoking from anon here** — Supabase's default
privileges grant new `public` functions to anon by name.

## The lesson that keeps recurring

Every defect Ty has found by hand passed whatever I checked, because I checked
the threat I had already imagined. Before calling something verified, ask
**who else is standing here** — not the stranger typing the address, who has
an empty browser, but the person holding the unlocked phone, and the person
who arrives just after somebody signed out. Enumerate the ways in; a fresh
arrival and a departure are different doors.
