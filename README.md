# Vitals Journal

A personal and family medical record book that runs entirely in the browser.
Paste a lab report, check every value against the sheet, keep the series.

**There is no server, no account and no database.** Records live in the
browser's own storage on the device that entered them; attached report images
live in that browser's IndexedDB. Nothing is uploaded, nothing is synced and
nothing crosses a border, because nothing leaves the machine.

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

On a phone, photograph the sheet and use the camera's own text selection to copy
the table, then paste. That reads a Vietnamese lab sheet considerably better
than any OCR this page could run itself, and the image never leaves the phone.

## Not a medical device

Decision-support only, not a diagnosis. This is a patient-held copy — give a
clinician the original report, which carries the laboratory's method, its
accreditation and its own flags. It holds no critical-value table and will never
tell you a result is dangerous. If you feel unwell, contact a doctor.
