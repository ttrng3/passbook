# Verification: one-way sharing

## Promise

A person can hand a **read-only** copy of their book to **only** the account
that invited them; the recipient can never write it; **records somebody else
handed the sharer never travel**; and switching off **deletes** the copy
rather than hiding it.

## Clean state

```bash
cd ~/Projects/passbook && node build.js
(python3 -m http.server 8777 >/dev/null 2>&1 &)
```
Navigate to `http://127.0.0.1:8777/index.html`, then:
```js
localStorage.clear(); sessionStorage.clear(); location.reload();
```

## Sanctioned substitutes

No test account exists. Stub `window.fetch` **before** assigning `AUTH`, and
capture every outgoing request so the *contents* of the share document can be
asserted — that is the point of this protocol, not the round trip:

```js
window.confirm = () => true;
var sent = [];
window.fetch = async (url, opts) => {
  sent.push({url:String(url).replace(/^https?:\/\/[^/]+/,''), method:(opts&&opts.method)||'GET',
             body: opts && opts.body ? JSON.parse(opts.body) : null});
  if(String(url).includes('rpc/my_orchestrator')) return new Response('"u-ty-uuid"',{status:200});
  return new Response('[]',{status:200});
};
AUTH = {tok:"tok", ref:"ref", uid:"u-me-uuid", email:"owner@example.com"};
```

**`AUTH = {...}` with no prefix is load-bearing, not styling.** The app
declares `let AUTH = null` at top-level script scope. `window.AUTH = {...}`
sets an unrelated property, throws nothing, and the app goes on reading its
own lexical binding as null — the sign-in screen just stays up and the run
looks broken for no visible reason. Assign bare. (Found 26/09 by a cold run
that hit it.)

**Proves:** what leaves the device, the recipient's provenance, the on/off
verbs, the recipient-side render and merge. **Does not prove:** that the
server enforces any of it — that is the curl section, which is not optional
here, because every client-side guarantee in this feature has a server-side
twin and only the twin is load-bearing.

## Steps

1. **Turn sharing on.** Settings › Share my book, type a name, flip the
   switch. Expect a `POST /rest/v1/rpc/my_orchestrator` followed by a
   `POST /rest/v1/passbook_shares`.
2. **Inspect what left.** The share document must contain the owner's rows
   and nothing marked `local`.
3. **Turn it off.** Expect `DELETE /rest/v1/passbook_shares`, the switch off,
   `S.lastShare` null.
4. **The owner's own account.** With `my_orchestrator` returning `null`,
   flipping the switch must write **nothing** and say so.
5. **Recipient side.** With a row in `shareRows`, a "Shared with me" tab
   appears; "Bring it into my book" merges.

## Invariants

Plant a relative's records via the hand-off path first, so the exclusion is
tested against records that really are marked `local`:

```js
S.observations.push({id:"mine-1",memberId:S.members[0].id,code:"ldl_c",valueRaw:"3.2",
  unit:"mmol/L",value:3.2,refLow:0,refHigh:3.4,refLabel:"< 3.4 mmol/L",
  observedAt:"2026-09-20",source:"Example Lab",fasting:"fasting",specimen:"",note:"",
  manualStatus:null,origin:""});
mergeIn({kind:"passbook",v:2,
  members:[{id:"rel-1",name:"Relative (example)",sex:"female",dob:"1990-01-01",population:"asian_pacific"}],
  observations:[{id:"rel-o1",memberId:"rel-1",code:"glucose_fasting",valueRaw:"6.9",
    unit:"mmol/L",value:6.9,refLow:3.9,refHigh:6.1,refLabel:"3.9–6.1 mmol/L",
    observedAt:"2026-09-01",source:"Example Lab",fasting:"fasting",specimen:"",note:"",
    manualStatus:null,origin:""}],
  actions:[],meds:[],allergies:[],conditions:[],shots:[],visits:[]}, "from Relative (example)");
_orch = undefined; S.shareOn = false; shareRows = [];
tab="settings"; setPage="share"; render();
document.getElementById('shareName').value = "Ty";
document.getElementById('shareSw').click();
```

Wait ~4s, then read in a separate paste. The app's `save()` queues a sync 2.5s
after a change (frag.html, the comment above the share push), so step 1's sync
has fired before anything later reads traffic:

```js
var push = sent.find(s=>s.url.includes('passbook_shares') && s.method==='POST');
var doc = push && push.body[0].doc;
JSON.stringify({
  askedTheDatabaseWhoTheRecipientIs: sent.some(s=>s.url.includes('rpc/my_orchestrator')),
  recipient: push && push.body[0].shared_with,        // "u-ty-uuid", from the DB
  sharedEmail: push && push.body[0].shared_email,     // the caller's own
  docMembers: doc && doc.members.map(m=>m.name),      // ["Me"] only
  docObsIds: doc && doc.observations.map(o=>o.id),    // ["mine-1"] only
  RELATIVE_LEAKED: doc ? (doc.observations.some(o=>o.memberId==='rel-1')
                       || doc.members.some(m=>m.id==='rel-1')) : "no push"   // MUST be false
}, null, 1)
```

`RELATIVE_LEAKED` is the assertion this whole protocol exists for.

**Before step 3, while sharing is still on** (still on the step 1 stub and its
`sent` log, and after the ~4s wait above), two counts:

```js
// one toggle, one upload: the background sync must not re-send an unchanged book
var postsAfterToggle = sent.filter(s=>s.url.includes('passbook_shares') && s.method==='POST').length;
postsAfterToggle   // expect 1
```

Then press "Update the copy now", which must still send:

```js
shareMsg = null; document.getElementById('shareNow').click();
```

Wait until the panel says "Copy updated" (`shareMsg && shareMsg.k === "Copy updated"`), then:

```js
sent.filter(s=>s.url.includes('passbook_shares') && s.method==='POST').length - postsAfterToggle   // expect 1
```

**Step 3, turn it off.** (`window.confirm` is stubbed, so the button's
confirmation passes.)

```js
var sentBeforeStop = sent.length;
shareMsg = null; document.getElementById('shareStop').click();
```

Wait until the panel says "Sharing stopped", then:

```js
JSON.stringify({
  deleteIssued: sent.slice(sentBeforeStop).some(s=>s.url.includes('passbook_shares') && s.method==='DELETE'),   // expect true
  noRevokedField: sent.every(s=>!JSON.stringify(s.body||'').includes('revoked')),          // expect true
  shareOn: S.shareOn,                                                                       // expect false
  lastShare: S.lastShare                                                                    // expect null
}, null, 1)
```

Before step 4, wait ~4s after "Sharing stopped", so the stop's own queued sync
(2.5s, as above) has fired before step 4's stub goes in.

**Step 4, the owner's own account.** The database answers `null` for the
account that does the inviting. Re-stub so the RPC says so, reset the cached
answer, and flip the switch:

```js
var sent4 = [];   // var, not const: pasting this block again must not throw
window.fetch = async (url, opts) => {
  sent4.push({url:String(url).replace(/^https?:\/\/[^/]+/,''), method:(opts&&opts.method)||'GET'});
  if(String(url).includes('rpc/my_orchestrator')) return new Response('null',{status:200});
  return new Response('[]',{status:200});
};
_orch = undefined; S.shareOn = false; shareMsg = null; _lastShareDoc = null;
tab="settings"; setPage="share"; render();
document.getElementById('shareSw').click();
```

Wait ~4s (past the 2.5s queued sync), then read in a separate paste:

```js
JSON.stringify({
  askedTheRpc: sent4.some(s=>s.url.includes('rpc/my_orchestrator')),                       // expect true
  writesToShares: sent4.filter(s=>s.url.includes('passbook_shares') && s.method!=='GET').length, // expect 0
  shareOn: S.shareOn,                                                                       // expect false
  saidWhy: shareMsg && shareMsg.k                                                           // expect "There is nobody to share with"
}, null, 1)
```

Assert on writes to `passbook_shares`, not on "no other request". Routine book
sync (`passbook_state`) legitimately fires in the same window. A check that
says "only the RPC fired" comes out false on a correct app, and a protocol
must not pass with a false assertion in it. (28/09: a verifier improvised that
check here, and it read false.)

## Adversary

| Who / what | Must happen | Assertion |
|---|---|---|
| The page tries to choose a recipient | it cannot — the client never sends one | `shared_with` equals only what the RPC returned |
| Sharer holds a third person's records | they do not travel | `RELATIVE_LEAKED === false` |
| Sharer switches off | the copy is **deleted**, not flagged | a `DELETE` is issued; no `revoked` field anywhere |
| An account nobody invited (the owner) | nothing is written to the shares table, and the page says why | the RPC is asked; **zero writes** (POST/PATCH/DELETE) to `passbook_shares`; switch back off; "There is nobody to share with" shown. Background book sync (`passbook_state`) may fire and is not a failure |
| Anonymous reader | sees nothing | curl below returns `[]` |
| Anonymous writer | refused by the database | curl below returns `401` / `42501` |
| Recipient merging a book in | every row marked device-only | `syncable()` excludes all of it |
| The row on screen | not mutated by the merge | source `doc` still has no `local` flags |
| A background sync after a push | **no second upload** | exactly one POST to `passbook_shares` per toggle |

**26/09 — one toggle, two uploads.** Flipping the switch pushed once, and the
sync `save()` queued pushed the identical document again 2.5s later; every
later background sync re-uploaded it unchanged. Nothing leaked, but a medical
document was being sent repeatedly for no reason. A cold run reported the
duplicate as an observation; the protocol had made no claim about it, which is
why it survived. It makes one now: the two counts in "Before step 3" above.

Recipient-side merge assertions:

```js
shareRows = [{user_id:"u-rel", shared_email:"relative@example.com", label:"Relative (example)",
  doc:{kind:"passbook",v:2,members:[{id:"relb-1",name:"Relative (example)",sex:"female",dob:"1990-01-01",population:"asian_pacific"}],
    observations:[{id:"relb-o1",memberId:"relb-1",code:"glucose_fasting",valueRaw:"6.9",unit:"mmol/L",
      value:6.9,refLow:3.9,refHigh:6.1,refLabel:"",observedAt:"2026-09-01",source:"Example Lab",
      fasting:"fasting",specimen:"",note:"",manualStatus:null,origin:""}],
    actions:[],meds:[],allergies:[],conditions:[],shots:[],visits:[]},
  updated_at:new Date().toISOString()}];
render();
document.querySelector('[data-shmerge]').click();
// then:
var imported = S.observations.filter(o=>o.memberId==='relb-1');
JSON.stringify({
  tabAppeared: [...document.querySelectorAll('#tabs .tab')].some(b=>/Shared/.test(b.textContent)),
  importedCount: imported.length,
  allMarkedLocal: imported.every(o=>o.local===true),
  excludedFromSync: syncable(S.observations).filter(o=>o.memberId==='relb-1').length,  // 0
  sourceRowNotMutated: shareRows[0].doc.observations.every(o=>o.local===undefined)
}, null, 1)
```

## Server side — no credentials needed

Every client guarantee above has a server twin, and only the twin is
load-bearing. The publishable key is in the built page.

```bash
KEY=$(grep -o 'key:"[^"]*"' index.html | head -1 | sed 's/key:"//;s/"//')
URL=https://uoncyxguauemrqupqxto.supabase.co
curl -s "$URL/rest/v1/passbook_shares?select=user_id" -H "apikey: $KEY"              # expect []
curl -s -o /dev/null -w '%{http_code}\n' -X POST "$URL/rest/v1/passbook_shares" -H "apikey: $KEY" \
  -H 'Content-Type: application/json' \
  -d '[{"user_id":"00000000-0000-0000-0000-000000000001","shared_with":"00000000-0000-0000-0000-000000000002","shared_email":"x@x.com"}]'
                                                                                     # expect 401 / 42501
curl -s "$URL/rest/v1/does_not_exist?select=x" -H "apikey: $KEY"                     # CONTROL: PGRST205
curl -s -X POST "$URL/rest/v1/rpc/my_orchestrator" -H "apikey: $KEY" \
  -H 'Content-Type: application/json' -d '{}'
             # expect 401 {"code":"42501","message":"permission denied for function my_orchestrator"}
```

**26/09 — a null is not a lock.** For a day and a half this call answered
`200 null` and was read as "inert, therefore fine". The live ACL said
`anon=X`: anon held EXECUTE the whole time, and two rounds of diagnosis blamed
a PostgREST plan cache that was never involved. The cause is that Supabase
grants execute on new `public` functions to anon **by name**, so
`revoke all ... from public` leaves it standing — *in this project, revoking
from PUBLIC is not revoking from anon.* Migration 0024. Assert the `42501`,
never the `null`: a function that is merely inert and one that is actually
locked return the same body.
A `[]` only means "locked" if the control proves a missing table looks
different. Run the control every time.

## Evidence

- every result, seven in all: the step 1–2 invariants JSON, the one-POST count, the explicit-update count, the step 3 JSON, the step 4 JSON, the recipient-merge JSON, and the server-side curl output with its control
- a screenshot of the Share my book panel, and of the Shared with me tab
- console clean of `TypeError|ReferenceError|Uncaught`

## Traps

- Re-pasting a block never throws (every block declares with `var`), but it runs
  its actions again: a second invariants paste adds a second observation and a
  second push. To retry a step, start again from **Clean state**.

- Stub `fetch` **before** `AUTH`, or the queued sync gets a 401 and clears it.
- Stub `window.confirm`; switching off asks for confirmation.
- `_orch` caches the recipient for the session — reset it between cases.
- Build first; test `index.html`, never `frag.html`.
