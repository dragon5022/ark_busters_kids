# Content update system — how Fujii-san edits problems after launch

> **Implemented (2026-10):** questions are edited in a Google Sheet and downloaded by the app without reinstalling. Guide and setup: `ark_core/doc/CONTENT_SHEETS.md`; starting CSVs: `tools/sheets/`; config: `assets/data/content_source.json`. The design notes below are kept for history.


## What the client asked (chat)

> 今後、問題を継続的に増やしていく予定です。  
> 問題を追加するたびにアプリを再申請する必要があるのか、それとも申請なしで反映できる形にできるのか。  
> 私自身がプログラムを触らずに問題を追加・修正できる形にできるとありがたい。

## What was promised (chat)

- Separate **problem data** from the app binary  
- Add / fix problems **without writing code**  
- Reflect updates **without re-submitting the app every time**  
- Not a full enterprise CMS in ¥250k — but everyday text edits / additions must be possible  

---

## Short answer

| Question | Answer |
|---|---|
| Need App Store re-submit for every new question? | **No** — if questions live as remote JSON packs |
| Can client edit without coding? | **Yes** — via Spreadsheet or simple admin page that publishes JSON |
| Works offline? | **Yes** — app keeps last downloaded pack + ships a built-in fallback pack |
| New voice / pictures too? | Text-only updates are easy; new MP3/PNG need upload to the same content CDN |

---

## Recommended architecture (v1)

```
┌─────────────────────┐         HTTPS          ┌──────────────────────────┐
│  Editor (no code)   │  publish / export      │  Content CDN / Storage   │
│  Google Sheets or   │ ─────────────────────► │  manifest.json           │
│  simple Admin Web   │                        │  packs/vocab_v12.json    │
└─────────────────────┘                        │  packs/listening_….json  │
                                               │  media/….mp3 / .png      │
                                               └────────────▲─────────────┘
                                                            │ fetch if newer
┌─────────────────────┐                                     │
│  Flutter app        │  1) load bundled pack (offline)     │
│  ContentRepository  │  2) check manifest version ─────────┘
│                     │  3) download + cache new packs
│  Game screens       │◄── use cached / bundled JSON
└─────────────────────┘
```

### 1. Never hard-code questions in Dart

Game code reads only:

```text
assets/data/bundled/vocab.json          ← shipped in APK/IPA (fallback)
documents/content/vocab.json            ← downloaded update (preferred if present)
```

Same pattern for listening / talk / sentence.

Bundled packs today (exported from web HTML via `tools/export_packs.py` + `tools/export_vocab.py`):

- `assets/data/vocab.json` — 210 words  
- `assets/data/listening.json` — 200 items  
- `assets/data/talk.json` — 36 phrases  
- `assets/data/sentence.json` — 42 sentences  

In **せってい**, tap「もんだいデータをこうしん」after putting HTTPS URLs into `manifest.json` → `packs.*.url`.


### 2. Versioned packs + manifest

Example `manifest.json` on the server:

```json
{
  "appMinBuild": 1,
  "packs": {
    "vocab": { "version": 12, "url": "https://cdn.example.com/kids/vocab_v12.json", "sha256": "…" },
    "listening": { "version": 8, "url": "https://cdn.example.com/kids/listening_v8.json", "sha256": "…" },
    "talk": { "version": 5, "url": "https://cdn.example.com/kids/talk_v5.json", "sha256": "…" },
    "sentence": { "version": 7, "url": "https://cdn.example.com/kids/sentence_v7.json", "sha256": "…" }
  }
}
```

App on launch (or “せってい → データを更新”):

1. GET `manifest.json`  
2. Compare `version` with local  
3. If newer → download JSON (and any new media URLs inside it)  
4. Verify hash → save to app documents → use for play  

**No App Store update required** for text/question changes.

### 3. Editor for non-programmers (pick one)

#### Option A — Google Sheets (best for ¥250k / Fujii-san)

- One sheet tab per mode (`vocab`, `listening`, …)  
- Columns match JSON fields (`word`, `ja`, `grade`, `level`, `audio`, `image`, …)  
- A small **Apps Script** or GitHub Action / Netlify Function exports sheets → JSON → uploads to CDN  
- Client only edits cells; you run or auto-run “Publish”

#### Option B — Simple Admin Web (Firebase / Supabase)

- Login for 学院 staff  
- Forms: add / edit / delete question  
- “Publish” writes JSON + bumps manifest version  
- More build work; nicer long-term  

#### Option C — Hand JSON on Drive (not recommended alone)

- Easy to break JSON syntax; avoid as primary UX  

**v1 recommendation:** **Option A (Sheets → auto publish)** + Flutter remote loader.

### 4. Media (voice / images)

| Change type | How |
|---|---|
| Fix English / Japanese text | Sheets only → new JSON |
| Add question using **existing** audio/image | Sheets row + existing asset id |
| New audio / picture | Upload file to CDN folder → put URL or filename in sheet |
| No audio yet | App TTS fallback (already used on web in places) |

### 5. Store / Apple–Google rules (important)

- Updating **quiz content** for free or already-unlocked packs via download is **normal and allowed**.  
- You **must not** unlock paid content by downloading it outside IAP.  
  - Pattern: IAP unlocks entitlement → then app may download the paid pack.  
- Login (progress / juku) stays separate from “buy content”.

---

## Flutter implementation sketch

| Piece | Role |
|---|---|
| `ContentPack` models | Parse vocab / listening / talk / sentence JSON |
| `ContentRepository` | Resolve: remote cache → bundled asset |
| `ContentSyncService` | Fetch manifest, download, hash, atomic swap |
| `assets/data/bundled/*` | Offline day-0 content |
| Settings “データを更新” | Manual sync + last-updated time |
| Auto-sync | On hub open (Wi‑Fi / once per day) |

Pseudo-flow:

```dart
final pack = await contentRepository.load('vocab');
// play with pack.questions
```

Games never care whether data came from the store build or the CDN.

---

## What Fujii-san’s day-to-day looks like

1. Open Google Sheet “ARK KIDS 問題”  
2. Add a row (word, meaning, grade, level, audio file name)  
3. (If new MP3) upload to Drive/CDN folder with that file name  
4. Click **公開する** (or wait for nightly auto-publish)  
5. Children open the app → sync → new problems appear  
6. **No Xcode / Android Studio / store review**

---

## Phased delivery inside the project

| Phase | Deliverable |
|---|---|
| B (with Vocabulary) | JSON schema + bundled packs + `ContentRepository` |
| C–D | All 4 modes read from repository |
| E (store) | Remote sync + Sheets publish pipeline + short JP操作マニュアル for 学院 |
| Later | Full admin UI, per-juku packs, A/B content |

Do **not** wait until “app complete” to invent this — build games on JSON from day one, or you will rewrite later.

---

## Out of scope for the promised “no-code edits” (clarify with client)

- Redesigning game rules / new mode types (needs developer)  
- Replacing core character art / hub UI (app update)  
- Huge media libraries without CDN cost planning  

---

## Decision checklist for client

1. Editor: **Google Sheets** OK?  
2. Hosting: Firebase Storage / Cloudflare R2 / existing Netlify?  
3. Sync: auto on launch vs manual button only?  
4. Paid packs: download only after IAP entitlement?  

Once answered, implement Sheets schema + sync in Phase B alongside Vocabulary.
