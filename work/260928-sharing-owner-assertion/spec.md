# Spec: sharing-owner-assertion

**Intent:** accepted 2026-09-28 · **Status:** approved (a verification-only change Ty specified himself; he ships the PR)

## Requirements
1. Step 4 gets a code block, with its own fetch stub whose RPC returns `null`.
2. Its assertions are: `askedTheRpc` true; `writesToShares` 0 (any method other than GET to `passbook_shares`), measured after the 2.5 s background sync window; `shareOn` false; `saidWhy` equal to "There is nobody to share with".
3. The Adversary row changes from "only the RPC call fires; no POST to `passbook_shares`" to "the RPC is asked; zero writes to `passbook_shares`; the switch goes back off and the page says why. Background book sync (`passbook_state`) may fire and is not a failure".

## Design
Source of truth, `index.html`:
- `whoInvitedMe()` caches `_orch`, so the block resets `_orch = undefined` first.
- `sharePush()` with no recipient sets `S.shareOn = false` and `shareMsg.k = "There is nobody to share with"`, and returns before any `passbook_shares` request.

## Conflicts
None found. Loaded: this intent, `index.html` lines 4332–4379 and 4540–4550, and the protocol's own conventions (bare `AUTH =`, stub before auth). It isn't a Pages or Supabase change, and the repo is public: no personal data is quoted.

## Promise
The verifier runs `sharing` on 2026-09-28 and gets PASS, with every assertion in step 4 at its expected value, and none reported as literally false.

## Out of scope
The other protocol steps, and `front-door`.
