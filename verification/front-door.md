# Verification: the front door

## Promise

With no signed-in session, the page renders the introduction and **nothing
derived from any book stored in this browser** — and renders the *same bytes*
whether or not a book is there.

## Clean state

```bash
cd ~/Projects/passbook && node build.js
(python3 -m http.server 8777 >/dev/null 2>&1 &)
```
Navigate to `http://127.0.0.1:8777/index.html`, then in the page:
```js
localStorage.clear(); sessionStorage.clear(); location.reload();
```

## Steps

1. **Land as a stranger.** Empty browser, no session. Expect: heading
   *Passbook*, the *By invitation only* card, a sign-in box, the *what it is
   and what it never does* callout, and an erase button in the footer. Expect
   **no** tab strip, **no** people strip, **no** sync badge text.
2. **Plant a book and keep the session dead.** Add a member name and a
   flagged reading, `save()`, `render()`. Expect the page to be unchanged.
3. **Sign in.** Expect the book: 6 tabs, the people strip populated.
4. **Sign out.** Expect the door again, the stored book gone, and the banner
   *Signed out, and this browser is clear*.
5. **Refresh.** Expect the stranger's door, identical to step 1.

## Invariants

```js
window.confirm = () => true;
const strangerDoor = document.getElementById('view').innerHTML;
S.observations.push({id:"x1",memberId:S.members[0].id,code:"ldl_c",valueRaw:"9.9",
  unit:"mmol/L",value:9.9,observedAt:"2026-09-20",source:"A private lab",
  refLow:0,refHigh:3.4,refLabel:"",fasting:"",specimen:"",note:"",
  manualStatus:null,origin:""});
S.members[0].name = "Ty Truong"; S.ownerUid = "u-me"; save(); render();
const loadedDoor = document.getElementById('view').innerHTML;
JSON.stringify({
  IDENTICAL: strangerDoor === loadedDoor,
  len: strangerDoor.length,                       // expect 2093
  leaksTheName: /Ty Truong/.test(loadedDoor),     // expect false
  leaksAValue: /9\.9|private lab/i.test(loadedDoor), // expect false
  saysABookExists: /book in this browser|There is a book/i.test(loadedDoor), // expect false
  eraseOfferedInBoth: /doorWipe/.test(strangerDoor) && /doorWipe/.test(loadedDoor),
  tabs: document.getElementById('tabs').innerHTML,      // expect ""
  people: document.getElementById('people').innerHTML   // expect ""
}, null, 1)
```

`len` is load-bearing. A byte count that drifts means somebody added a
conditional to the door; find out what it reveals before changing the number.

## Sanctioned substitutes

There is no test account and no test Supabase project. Where a step needs an
authenticated state, **this is the approved stand-in**, and it must be said
out loud in the report rather than left to inference:

```js
window.fetch = async () => new Response('[]', {status:200});  // stub FIRST
AUTH = {tok:"t", ref:"r", uid:"u-me", email:"t.trng3@gmail.com"};
claimDevice(); render();
```

**What this proves:** the gate, the claim logic, rendering, sign-out and the
wipe. **What it does not:** `signInPassword()`, `verifyCode()`, the real form
submission, token renewal, and `syncNow()`'s merge, 401 and missing-table
branches. Those are unverified by this protocol and a report must say so.
Covering them needs a throwaway Supabase project; until one exists, this line
is the honest boundary.

## Server side — no credentials needed

The invitation gate is a database rule, so it is proved with `curl`, not the
UI. The publishable key is in the built page and is safe to use:

```bash
KEY=$(grep -o 'key:"[^"]*"' index.html | head -1 | sed 's/key:"//;s/"//')
URL=https://uoncyxguauemrqupqxto.supabase.co
# an uninvited address must be refused on BOTH routes
curl -s -X POST "$URL/auth/v1/signup" -H "apikey: $KEY" -H 'Content-Type: application/json' \
  -d '{"email":"not-invited-probe@example.invalid","password":"throwaway-probe-value"}'
curl -s -X POST "$URL/auth/v1/otp" -H "apikey: $KEY" -H 'Content-Type: application/json' \
  -d '{"email":"not-invited-probe@example.invalid","create_user":true}'
# anon must not read or write the share table
curl -s "$URL/rest/v1/passbook_shares?select=user_id" -H "apikey: $KEY"
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$URL/rest/v1/passbook_shares" -H "apikey: $KEY" \
  -H 'Content-Type: application/json' -d '[{"user_id":"00000000-0000-0000-0000-000000000001","shared_with":"00000000-0000-0000-0000-000000000002","shared_email":"x@x.com"}]'
# CONTROL: a table that does not exist, so a 404 is never mistaken for a lock
curl -s "$URL/rest/v1/does_not_exist?select=x" -H "apikey: $KEY"
```

Expected: `23514 This address has not been invited to this family book.` on both
auth routes; `[]` then `401` on the share table; `PGRST205` on the control.
Use an `example.invalid` address only — the gate refuses it, so nothing is created.

## Adversary

| Who is standing here | Must get | Assertion |
|---|---|---|
| Stranger, empty browser | the introduction | `tabs === "" && people === ""` |
| **Someone holding Ty's unlocked phone** | the identical page | `IDENTICAL === true` |
| Someone after a sign-out | the door, and nothing stored | `storedObs === 0` |
| Expired session, book still present | the door, no way through | `atDoor() === true`, no `doorIn` element |
| A second account signing in here | the first person's book cleared first | `claimDevice()` returns `true`, `S.observations.length === 0` |
| Same account signing back in | its book kept | `claimDevice()` returns `false`, records intact |

**26/09 — `saysABookExists: false`.** A card used to appear only when a book
was present, reading *"there are records on this device — open them."* It
showed no records, but it told whoever held the phone that there was one, and
it let them in. Ty: *"that is pretty much the back door to my app."* The
conditional is the bug; the byte-identity check is what catches its return.

**25/09 — legacy keys.** `removeItem(LS_OLD)` with `LS_OLD` undeclared threw
inside a try/catch, so erasing left `vitals-journal-v2` behind and `load()`
read it back on the next reload. Plant that key, erase, reload, assert gone.

## Evidence

- the invariants JSON
- one screenshot of the door, `save_to_disk: true`
- console clean of `TypeError|ReferenceError|Uncaught`

## Traps

- Stub `window.confirm` before any click; a native dialog freezes the extension.
- Stub `window.fetch` before setting a fake `AUTH`, or the queued background
  sync gets a 401 and clears `AUTH` mid-test.
- Test `index.html` after `node build.js`, never `frag.html`.
