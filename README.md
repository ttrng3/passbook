# Passbook

A personal and family medical record book — the small book you carry and get
updated at every visit, kept in a browser instead of a drawer.
Paste a lab report, check every value against the sheet, keep the series.

**You need a key to open it.** As of 2026-09-25 the address shows a front
door: an introduction, the invitation rule, and a sign-in box. No session, no
book. A browser that still holds records can be *erased* from that screen but
never read from it — destroying is safe to offer a stranger, opening is not.
**Signing out erases this browser**; it syncs to the account first and refuses
to erase if that sync did not land, so a sign-out cannot silently drop
readings that never left the device.

*(Until 2026-09-25 the door let a browser holding records walk past it, so an
expired session could not strand anybody from their own chart. That modelled
the wrong threat — a stranger typing the address has an empty browser and
never sees that offer; the person holding your unlocked phone sees exactly
it. A lock that hands the key to whoever is standing at the door is not a
lock.)*

The page itself is public and always will be — it is a static file on GitHub
Pages and anyone can read its source. **The door is not what protects
records; row-level security on the database is**, and that has not changed.

**Where records go, stated exactly.** The book lives in the browser's own
storage on the device that entered it, and attached report images live in that
browser's IndexedDB. Three things leave it, and nothing else does:

1. **Signed in, your own records sync** to a single row that only your account
   can read, on Supabase in Singapore. Signed out, nothing syncs at all — and
   signed out is now also erased, so the account copy is the one that persists.
   A book carries the account id that wrote it, and a *different* account
   signing in on that device clears it before anything syncs, so one person's
   records can never be uploaded under another person's name.
2. **Reading a report sends that page off the device** — the photo goes to the
   same Supabase project and on to Anthropic in the United States to be read,
   and the stored copy is deleted as soon as the read finishes. The original
   stays in the phone's camera roll; this book's own copy stays in the browser.
3. **Records merged from someone else's hand-off file never leave the device.**
   They are marked *on this device only* and excluded from the sync document,
   so a relative's readings never reach the server through your account. That
   is enforced in `syncable()`, not just promised in the interface.

Two of those cross a border. That is a fact about the design rather than a
reassurance about it.

*(This section said "there is no server, no account and no database" until
2026-09-24. That was true when it was written and had been false since sync and
server-side extraction were added. A privacy claim that drifts behind the code
is worse than no claim.)*

This repository holds the *tool*. It must never hold anybody's records — see
`.gitignore`.

## Why it is built this way

Three rules are carried over from the original app and are not negotiable:

1. **Nothing is stored until a human has confirmed it against the source.**
   Every value is ticked off individually. There is no check-all.
2. **Reference ranges come from your own report.** The app ships none of its own
   for laboratory tests. Where you have not typed one it says *no range on file*
   rather than guess. The only thresholds in the code are the two published BMI
   standards, and both are shown precisely because they disagree.
3. **It never generates a medical recommendation.** The single fixed line it
   shows is *Mang kết quả này đi khám.*

Three more were added after a clinical review:

4. **Units travel with the value.** A reading is stored and displayed in the unit
   its own report used, and converted only when something is compared or
   plotted — with the conversion shown. This matters when family members are
   tested in different countries: mg/dL and mmol/L are the same analyte and
   very different numbers.
5. **Trends that cross laboratories are flagged.** Analysers and methods differ,
   so a step in a line can be the lab rather than the person.
6. **Under-18 is flagged.** Paediatric reference intervals are not adult ones.

## Files

| File | What it is |
|---|---|
| `frag.html` | **The source.** A fragment — no `<!doctype>`, `<html>`, `<head>` or `<body>`. This is what the claude.ai artifact platform wants; it supplies that skeleton itself and a nested one renders blank. |
| `index.html` | Generated. The standalone page for GitHub Pages or a phone home screen. |
| `build.js` | `node build.js` regenerates `index.html` from `frag.html`. |

Edit `frag.html`, never `index.html`, then run the build. One source, two
targets, no drift.

## Running it

Open `index.html`. That is the whole install. For a phone, serve it over HTTPS
(GitHub Pages does this) and add it to the home screen.

## Sharing with the person who invited you

A relative may hand a read-only copy of their book to whoever invited them,
and take it back by switching it off, which deletes it. The page never names
the recipient — the database reads it from `family_invites.invited_by`, so a
copy cannot be aimed anywhere else. The recipient can read and can never
write. Records somebody else handed the sharer are excluded, by the same
`syncable()` that keeps them out of the sync document. Migrations 0022 and
0023; the panel in the app says what it does and what it does not undo.

## Moving records between devices

Each device keeps its own book. **Hand-off** exports the readings as text you
carry across yourself — message it, AirDrop it, email it — and importing
**merges**: nothing is overwritten and duplicates are skipped, so the same file
can be imported twice safely. Every reading that arrives is stamped with who
sent it and when.

Attached images do not travel with a hand-off. They stay on the device that
took the photo.

## Getting a report in

Paste the report text and the parser fills the rows. It reads Vietnamese and
English test names, commas used as decimal separators, Vietnamese `T/L` and
`G/L` count units, and ranges written `3.9 - 6.4`, `< 5.2` or `> 1.03`.

Pasting text is still supported and is the only path that keeps the page in the
browser end to end. Photographing a report is the easier path and a different
trade: the image is sent to be read, then the stored copy is deleted. Both are
offered; the page says which is which at the point of use.

## Not a medical device

Decision-support only, not a diagnosis. This is a patient-held copy — give a
clinician the original report, which carries the laboratory's method, its
accreditation and its own flags. It holds no critical-value table and will never
tell you a result is dangerous. If you feel unwell, contact a doctor.

## The name

It was called Vitals Journal until 2026-09-24. *Vitals* is a specific clinical
term — blood pressure, pulse, temperature, breathing rate — and that is the one
category of data this book barely holds. It also collides with an iOS feature of
the same name. A passbook is what this actually is: a small book you carry, and
someone writes in it each time you are seen.

The repository was renamed with it. The old address is gone rather than
redirected, which is fine because only Ty ever had it. Storage keys, the
IndexedDB name, the hand-off file's `kind` stamp and the Postgres table were
renamed too, but each one reads its old address first and only drops it once
the new one has been written and read back — a key is an address, and renaming
one without a path leaves yesterday's records in place and unreachable.
