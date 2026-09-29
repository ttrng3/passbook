# Intent: the sharing protocol's owner-account check asserts what matters, and only that

**Status:** accepted 2026-09-28 (Ty asked for it in his own prompt: "tighten onlyRpcFired in sharing.md so it asserts what matters … A protocol shouldn't pass with a false assertion in it.")
**Source:** chat, 2026-09-28, after the verifier run of 17:21–17:28

**Problem.** `verification/sharing.md` states for the owner's own account "only the RPC call fires; no POST to passbook_shares" (Adversary table), and step 4 has no code. The 28/09 verifier improvised `onlyRpcFired`, and it came out **false**: routine book sync (`passbook_state`) legitimately fires in the same window. The protocol passed with a false assertion in it.

**Outcome.**
- Step 4 has its own code block with assertions that are all true when the app behaves correctly: the RPC was asked, zero writes (POST, PATCH or DELETE) reached `passbook_shares`, the switch went back off, and the page says why.
- The Adversary row says the same, with nothing about "no other request".

**Who and what is affected.** `verification/sharing.md` only. No app code.

**Constraints.** The assertions come from the app code (`whoInvitedMe`, `sharePush`), not from memory, and are proved by a verifier run. The change goes out as a PR that Ty ships.

**Open questions.** None known.
