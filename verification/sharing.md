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
const sent = [];
window.fetch = async (url, opts) => {
  sent.push({url:String(url).replace(/^https?:\/\/[^/]+/,''), method:(opts&&opts.method)||'GET',
             body: opts && opts.body ? JSON.parse(opts.body) : null});
  if(String(url).includes('rpc/my_orchestrator')) return new Response('"u-ty-uuid"',{status:200});
  return new Response('[]',{status:200});
};
AUTH = {tok:"tok", ref:"ref", uid:"u-me-uuid", email:"t.trng3@gmail.com"};
```

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
S.observations.push({id:"mine-1",memberId:S.members[0].id,code:"ldl_c",valueRaw:"3.1",
  unit:"mmol/L",value:3.1,refLow:0,refHigh:3.4,refLabel:"< 3.4 mmol/L",
  observedAt:"2026-09-20",source:"Medlatec",fasting:"fasting",specimen:"",note:"",
  manualStatus:null,origin:""});
mergeIn({kind:"passbook",v:2,
  members:[{id:"va-1",name:"Vân Anh",sex:"female",dob:"1994-02-09",population:"asian_pacific"}],
  observations:[{id:"va-o1",memberId:"va-1",code:"glucose_fasting",valueRaw:"7.2",
    unit:"mmol/L",value:7.2,refLow:3.9,refHigh:6.1,refLabel:"3.9–6.1 mmol/L",
    observedAt:"2026-09-01",source:"Vinmec",fasting:"fasting",specimen:"",note:"",
    manualStatus:null,origin:""}],
  actions:[],meds:[],allergies:[],conditions:[],shots:[],visits:[]}, "from Vân Anh");
_orch = undefined; S.shareOn = false; shareRows = [];
tab="settings"; setPage="share"; render();
document.getElementById('shareName').value = "Ty";
document.getElementById('shareSw').click();
// wait ~500ms, then:
const push = sent.find(s=>s.url.includes('passbook_shares') && s.method==='POST');
const doc = push && push.body[0].doc;
JSON.stringify({
  askedTheDatabaseWhoTheRecipientIs: sent.some(s=>s.url.includes('rpc/my_orchestrator')),
  recipient: push && push.body[0].shared_with,        // "u-ty-uuid", from the DB
  sharedEmail: push && push.body[0].shared_email,     // the caller's own
  docMembers: doc && doc.members.map(m=>m.name),      // ["Me"] only
  docObsIds: doc && doc.observations.map(o=>o.id),    // ["mine-1"] only
  RELATIVE_LEAKED: doc ? (doc.observations.some(o=>o.memberId==='va-1')
                       || doc.members.some(m=>m.id==='va-1')) : "no push"   // MUST be false
}, null, 1)
```

`RELATIVE_LEAKED` is the assertion this whole protocol exists for.

## Adversary

| Who / what | Must happen | Assertion |
|---|---|---|
| The page tries to choose a recipient | it cannot — the client never sends one | `shared_with` equals only what the RPC returned |
| Sharer holds a third person's records | they do not travel | `RELATIVE_LEAKED === false` |
| Sharer switches off | the copy is **deleted**, not flagged | a `DELETE` is issued; no `revoked` field anywhere |
| An account nobody invited (the owner) | nothing is written at all | only the RPC call fires; no POST to `passbook_shares` |
| Anonymous reader | sees nothing | curl below returns `[]` |
| Anonymous writer | refused by the database | curl below returns `401` / `42501` |
| Recipient merging a book in | every row marked device-only | `syncable()` excludes all of it |
| The row on screen | not mutated by the merge | source `doc` still has no `local` flags |

Recipient-side merge assertions:

```js
shareRows = [{user_id:"u-va", shared_email:"vananh@example.com", label:"Vân Anh",
  doc:{kind:"passbook",v:2,members:[{id:"vb-1",name:"Vân Anh",sex:"female",dob:"1994-02-09",population:"asian_pacific"}],
    observations:[{id:"vb-o1",memberId:"vb-1",code:"glucose_fasting",valueRaw:"7.2",unit:"mmol/L",
      value:7.2,refLow:3.9,refHigh:6.1,refLabel:"",observedAt:"2026-09-01",source:"Vinmec",
      fasting:"fasting",specimen:"",note:"",manualStatus:null,origin:""}],
    actions:[],meds:[],allergies:[],conditions:[],shots:[],visits:[]},
  updated_at:new Date().toISOString()}];
render();
document.querySelector('[data-shmerge]').click();
// then:
const imported = S.observations.filter(o=>o.memberId==='vb-1');
JSON.stringify({
  tabAppeared: [...document.querySelectorAll('#tabs .tab')].some(b=>/Shared/.test(b.textContent)),
  importedCount: imported.length,
  allMarkedLocal: imported.every(o=>o.local===true),
  excludedFromSync: syncable(S.observations).filter(o=>o.memberId==='vb-1').length,  // 0
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
```
A `[]` only means "locked" if the control proves a missing table looks
different. Run the control every time.

## Evidence

- both invariant JSON blocks
- a screenshot of the Share my book panel, and of the Shared with me tab
- console clean of `TypeError|ReferenceError|Uncaught`

## Traps

- Stub `fetch` **before** `AUTH`, or the queued sync gets a 401 and clears it.
- Stub `window.confirm`; switching off asks for confirmation.
- `_orch` caches the recipient for the session — reset it between cases.
- Build first; test `index.html`, never `frag.html`.
