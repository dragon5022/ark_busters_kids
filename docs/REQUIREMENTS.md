# ARK BUSTERS — Detailed Requirements Document

| Field | Value |
|---|---|
| Document | Detailed Product & Technical Requirements |
| Products | **ARK BUSTERS KIDS**, **ARK BUSTERS TEEN** (separate apps) |
| Client | アーク総合学院 (ARK Sogo Gakuin) / ケイティ＆エリー |
| Contractor | Ninja Worker |
| Primary tech (agreed direction) | **Flutter** (iOS + Android), one app per product |
| Web reference (KIDS) | https://arkbusters-kids.netlify.app/ark-kids-top.html |
| Web reference (TEEN) | https://arkbusters-teen.netlify.app/ark-top.html |
| Source of truth (content) | Client Google Drive / local HTML packs |
| Doc version | 1.1 |
| Date | 2026-09-11 |
| Status | Living document — update when scope is confirmed with client |
| Related | [CONTENT_UPDATE.md](CONTENT_UPDATE.md) — post-launch problem editing |

---

## 1. Purpose

Port the existing browser English-learning games into **native mobile apps** that:

1. Preserve the look, characters, audio, and battle flow of the web versions.
2. Run smoothly on **iOS and Android**.
3. Support **offline-capable** play for bundled free content.
4. Prepare a clear path for **paid unlock / IAP**, parent gate (KIDS), and juku Offer Codes.

KIDS and TEEN are **two separate apps** (not one combined app). Series may expand later (e.g. 適性バスターズ).

---

## 2. Goals & non-goals

### 2.1 Goals (v1)

- Faithful Flutter port of **KIDS hub + 4 English battle modes** (free/pilot content packs).
- Local progress persistence (compatible key names with web `localStorage` where practical).
- Audio: BGM, SFX, English voice clips; mute toggles.
- Collection (ずかん), profile, settings, intro story.
- Store readiness: free sample + buyout IAP hooks, restore purchases, KIDS parent gate.
- Ship **Android + iOS** builds for KIDS; TEEN as phase 2 unless client prioritizes parallel.

### 2.2 Non-goals (v1)

- Rebuilding TEEN’s multi-subject catalogue in the first KIDS milestone.
- Full paid content packs until asset delivery + IAP SKUs are confirmed.
- Web/desktop Flutter targets (mobile first).
- Account-as-unlock (login is optional light sync later, not the primary unlock path).
- Exact pixel cloning of every CSS animation if it hurts performance — prefer visual parity + smooth 60fps.

---

## 3. Stakeholders & constraints

| Item | Detail |
|---|---|
| Brand | アーク総合学院 / ARK BUSTERS |
| Contract (chat) | 税込 ¥250,000; ~4 weeks after subsidy 交付開始通知 |
| Preferred delivery | GitHub (`tiger5247` preferred by client) |
| Stack preference | Originally Capacitor + HTML reuse; **Flutter** preferred for KIDS UI smoothness — confirm with client if not already approved |
| Languages | UI Japanese; learning content English (+ Japanese glosses as in web) |
| Audience KIDS | Elementary / 英検 5・4・3級 oriented |
| Audience TEEN | Junior high / multi-subject exam prep |

---

## 4. Product overview — KIDS

### 4.1 Concept

Children battle four English “monsters” through mini-games. Winning befriends monsters and unlocks pose cards. Story framing introduces the world and motivates play.

### 4.2 Characters (monsters)

| Key | Japanese | Mode |
|---|---|---|
| `vocamon` | ボキャモン | Vocabulary |
| `lismon` | リスモン | Listening |
| `talkmon` | トークモン | Talk |
| `gramon` | グラモン | Sentence |

### 4.3 Platforms

- **Required:** Android 8+ (API 26+ recommended), iOS 13+ (confirm store minimums at submit time).
- **Package (current):** `com.ark` / Flutter project `ark_busters_kids`.

### 4.4 Information architecture

```
Hub
├── Hero artwork
├── Brand (ARK BUSTERS KIDS / アーク総合学院)
├── Mode prompt
├── Mode cards (4) → Game flow
├── Story (auto / button)
└── Bottom nav
    ├── ずかん (Collection)
    ├── マイページ (Profile)
    └── せってい (Settings)
```

---

## 5. Functional requirements — Hub

| ID | Requirement | Priority | Notes |
|---|---|---|---|
| H-01 | Show full-bleed purple starfield background matching web radial + sparkles | Must | Image `page_bg` + twinkle overlay OK |
| H-02 | Show hero banner as **single composite image** (no layered crop) | Must | `kidtop1–4` rotation optional like web |
| H-03 | Show brand title + academy name | Must | Match web styling; Bungee / rounded JP fonts |
| H-04 | Mode prompt text: 「たたかうモンスターを / えらんでね」 with star accents | Must | App may omit white card (mobile UX decision) |
| H-05 | Four mode entry cards as **single PNGs** (vocab / listening / talk / sentence) | Must | No double frames; no `BoxFit.cover` clipping |
| H-06 | Tap card → enter that mode’s grade/level select | Must | |
| H-07 | Hub BGM (`bgm-top.mp3`) with mute control | Should | |
| H-08 | Bottom nav: ずかん / プロフィール / せってい panels | Must | Labels align with web (ずかん preferred) |
| H-09 | Optional TEEN teaser link (out of app / store) | Could | Web has text teaser |

**Visual parity rules (agreed in build):**

- Prefer **one image asset per component** when web uses a flattened PNG (hero, mode cards).
- Do not wrap card art in extra cream borders that already exist in the PNG.
- Use native image aspect ratios; avoid wrong `AspectRatio` + `BoxFit.cover` clipping.

---

## 6. Functional requirements — Game modes

Shared battle rules (unless a mode README says otherwise):

| ID | Requirement | Priority |
|---|---|---|
| G-01 | Grade select: 英検 5 / 4 / 3級 (or mode-specific grade keys) | Must |
| G-02 | Ready-Go countdown / cue before questions | Must |
| G-03 | Session length default **10 questions** where web uses 10 | Must |
| G-04 | Correct / wrong feedback + SFX | Must |
| G-05 | End screen with rank **S–F**; win threshold ≈ **≥60% correct** | Must |
| G-06 | On win: chance to **befriend** monster (`ark_friends`) | Must |
| G-07 | On S-rank: increment `ark_s_*` and award pose card progress | Must |
| G-08 | Persist mode best score | Must |
| G-09 | Respect SE / voice mute settings | Must |
| G-10 | Battle BGM (`bgm-battle.mp3`) | Should |
| G-11 | Back / quit returns to hub without corrupting progress | Must |

### 6.1 Vocabulary Busters（ボキャブラリー）

| ID | Requirement | Priority |
|---|---|---|
| V-01 | Monster: ボキャモン | Must |
| V-02 | After grade: levels 1 / 2 / 3 | Must |
| V-03 | Lv1: picture → 4 choices; timer **5s** | Must |
| V-04 | Lv2: spelling → 3 choices; timer **7s** | Must |
| V-05 | Lv3: letter scramble; timer **10s**; short a–z words only | Must |
| V-06 | Free content: **210 words** (70 × 3 grades) + matching voice clips | Must |
| V-07 | Pool filter by grade (`lv`) and level rules as web | Must |

### 6.2 Listening Busters（リスニング）

| ID | Requirement | Priority |
|---|---|---|
| L-01 | Monster: リスモン | Must |
| L-02 | Grades `g5` / `g4` / `g3`; levels Lv0–Lv3 | Must |
| L-03 | Pick **10** questions per run | Must |
| L-04 | Lives: Lv0 = 5; other levels = 3 | Must |
| L-05 | Lv0 easy/slow/pics/no timer; Lv1 sentence→pic; Lv2 reply; Lv3 dialogue | Must |
| L-06 | Free content: **200 questions** + listening audio | Must |
| L-07 | Persist per-level best `lb2_{grade}_{level}` | Must |

### 6.3 Talk Busters（トーク）

| ID | Requirement | Priority |
|---|---|---|
| T-01 | Monster: トークモン | Must |
| T-02 | Modes: STEP1 聞いてマネ / STEP2 マイクで言う / STEP3 4択テスト | Must |
| T-03 | Free content: **36 lines** (12 per grade) + voice | Must |
| T-04 | STEP2: device speech recognition (iOS/Android permission + fallback UI) | Must |
| T-05 | Empty grade pool → friendly “じゅんびちゅう” message | Must |
| T-06 | Mic permission rationale (JP) and graceful denial | Must |

### 6.4 Sentence Busters（センテンス / 語順）

| ID | Requirement | Priority |
|---|---|---|
| S-01 | Monster: グラモン | Must |
| S-02 | Courses: **10問** (3 lives) and **エンドレス** (1 life) | Must |
| S-03 | Word-order / tile arrange interaction | Must |
| S-04 | Timers by grade: g5=6s, g4=9s, g3=12s | Must |
| S-05 | Free content: **42 sentences** + gram / gramparts audio | Must |
| S-06 | Persist per-grade best `eb2_{grade}` | Must |

---

## 7. Functional requirements — Meta systems

### 7.1 Progress & save data

Use local storage (`shared_preferences` or equivalent). Prefer **same key strings as web** for future sync / migration.

| Key | Type | Description |
|---|---|---|
| `ark_friends` | JSON string[] | Befriended monster keys |
| `ark_name` | string (max 12) | Player display name |
| `ark_se` | `"0"` / other | SE off / on |
| `ark_voice` | `"0"` / other | English voice off / on |
| `ark_story_seen` | flag | Intro story viewed |
| `ark_story2_seen` | flag | Story 2 viewed |
| `ark_best_vocabulary` | number | High score |
| `ark_best_listening` | number | High score |
| `ark_best_talk` | number | High score |
| `ark_best_sentence` | number | High score |
| `ark_s_{monster}` | number | S-rank clear count |
| `ark_cards_{monster}` | JSON number[] | Unlocked pose IDs (1–30) |
| `lb2_{g}_{lv}` | number | Listening level best |
| `eb2_{k}` | number | Sentence grade best |

| ID | Requirement | Priority |
|---|---|---|
| P-01 | Read/write all keys above | Must |
| P-02 | Card economy: S-ranks → pose unlock (`floor(S/10)`, cap 30, weighted draw) | Must |
| P-03 | Free UI may **show** fewer poses (web shows 5) even if more unlock internally — confirm with client | Should |
| P-04 | Clear-data / reset option in settings (with confirm) | Could |
| P-05 | Optional cloud login for progress sync (not unlock gate) | Later |

### 7.2 Collection（ずかん）

| ID | Requirement | Priority |
|---|---|---|
| C-01 | Grid of 4 monsters locked/unlocked | Must |
| C-02 | Detail: S count + unlocked poses | Must |
| C-03 | Locked state visual (silhouette / dashed) | Must |

### 7.3 Profile（マイページ）

| ID | Requirement | Priority |
|---|---|---|
| PR-01 | Edit player name (max 12) | Must |
| PR-02 | Show friends x/4 | Must |
| PR-03 | Show pose totals and/or mode bests | Must |

### 7.4 Settings（せってい）

| ID | Requirement | Priority |
|---|---|---|
| ST-01 | Toggle こうかおん (`ark_se`) | Must |
| ST-02 | Toggle えいごの こえ (`ark_voice`) | Must |
| ST-03 | BGM mute (session and/or persisted) | Should |
| ST-04 | Restore purchases (when IAP live) | Must (at IAP) |
| ST-05 | Parent gate before purchases / sensitive settings (KIDS) | Must (at IAP) |

### 7.5 Story

| ID | Requirement | Priority |
|---|---|---|
| Y-01 | Story 1 auto-opens once if not seen; skippable | Must |
| Y-02 | Vertical panel story with character art `s1`–`s7` | Must |
| Y-03 | Story 2 unlock when collected cards ≥ **60** (`STORY2_NEED`) | Should |
| Y-04 | Mark seen flags so stories do not re-force every launch | Must |

---

## 8. Audio requirements

| ID | Requirement | Priority |
|---|---|---|
| A-01 | Hub BGM: `bgm-top.mp3` | Must |
| A-02 | Battle BGM: `bgm-battle.mp3` | Must |
| A-03 | Ready-go: `ready-go.mp3` (+ TTS fallback optional) | Must |
| A-04 | SFX: start / correct / clear / gameover | Must |
| A-05 | Per-mode voice packs under `voice/{voca,lis,talk,gram,gramparts}` | Must |
| A-06 | Respect mute flags; ducking when voice plays | Should |
| A-07 | Preload or cache hot clips to avoid lag on emulator/low devices | Should |

---

## 9. Non-functional requirements

| ID | Requirement | Priority |
|---|---|---|
| N-01 | Target 60fps on mid-range phones for hub + battle UI | Must |
| N-02 | First launch to hub < 3s on mid-range after install (warm) | Should |
| N-03 | Offline play for all bundled free content | Must |
| N-04 | APK/IPA size: manage assets (compress voice; don’t ship unused poses) | Should |
| N-05 | Accessibility: large tap targets (≥44pt), readable JP text | Should |
| N-06 | No crash on missing optional assets (fallback UI) | Must |
| N-07 | Privacy: mic only for Talk STEP2; declare in store listings | Must |
| N-08 | Support portrait phone; tablet layout nice-to-have | Must / Could |

---

## 10. Monetization & store (v1 direction from client chat)

| ID | Requirement | Priority |
|---|---|---|
| M-01 | Free app with **sample / 無料版** content playable | Must |
| M-02 | Full content via **buyout IAP** (one-time unlock preferred for v1) | Must |
| M-03 | Restore purchases | Must |
| M-04 | **Parent gate** before IAP on KIDS | Must |
| M-05 | Apple/Google **Offer Codes** for juku distribution | Should |
| M-06 | Light optional login for progress sync — **not** required to unlock | Later |
| M-07 | No ads in v1 unless client requests | Assumed |

Web packs are labeled パイロット／お試し／無料版; full packs live in separate 有料版 folders — confirm which pack ships in store v1.

---

## 11. Content & asset inventory (KIDS free packs)

| Mode | Questions / items | Voice | Notes |
|---|---|---|---|
| Vocabulary | 210 words | `voice/voca` ×210 | Images in `vocaimages` |
| Listening | 200 Qs | `voice/lis` ~203 | Images in `lisimages` |
| Talk | 36 lines | `voice/talk` ×36 | Mic mode |
| Sentence | 42 sentences | `gram` 42 + `gramparts` 106 | Drag tiles |
| Hub | — | `bgm-top` | Cards + kidtop art |
| Monsters | pose1–30 ×4 | — | Free UI may show 5 |

**Asset pipeline requirement:** Export HTML-inline data → versioned JSON under `assets/data/`; copy images/audio with stable paths; document any filename typos kept for parity (`card-sentense.png`).

---

## 12. TEEN app (scope summary — phase 2)

| Item | Detail |
|---|---|
| Hub | `ark-top.html` — ARK バスターズ |
| Content | Many stage HTML games: English (`e-*`), 国語 (`k-*`), 数学 (`m-*`), 理科 (`r-*`), 社会 (`s-*`) |
| Data pattern | Inline `PROBLEMS_BY_LEVEL`; little localStorage vs KIDS |
| Requirement | Separate Flutter (or agreed) app; do **not** merge into KIDS |
| v1 | Out of KIDS milestone unless client reprioritizes |

Detailed TEEN requirements should be a separate appendix after KIDS hub+modes are stable.

---

## 13. Implementation status (as of 2026-10-03)

| Area | Status |
|---|---|
| Flutter project `ark_busters_kids` | Done (Android + iOS); pushed to `dragon5022/ark_busters_kids` |
| Hub, story 1 / 2, collection / profile / settings panels | Done — ported from live site, phone layout fixes, animations |
| Vocabulary / Listening / Sentence / Talk | Done — full port of the **live** site (newer than the web pack), incl. encounter intro, review/explain panels, ranks, befriend, weighted card draw |
| Question data | Verified against live web: vocab 210, listening 200, sentence 42, talk 36 |
| Progress (web key names) | Done — local `shared_preferences` |
| Audio | Done — BGM + ducking, SFX, pre-rendered web tones, voice clips, TTS (`flutter_tts`) |
| Speech recognition (Talk STEP2) | Done (`speech_to_text`, permissions) — **not yet tested on a real device** |
| Fonts | Bundled (M PLUS Rounded 1c, Mochiy Pop One, Fredoka, Zen Maru Gothic, Bungee, DotGothic16) |
| Image lightweighting | Done — WebP q90; AI upscale (Real-ESRGAN) 199 / 466 images, rest pending |
| Content updates without re-submit (§16) | **Done** — Google Sheet → app (`ark_core` content module, version flag in `manifest` tab, validated, offline fallback). Off until the school's sheet ID is set in `assets/data/content_source.json`. Guide: `ark_core/doc/CONTENT_SHEETS.md` |
| IAP / free vs paid split / restore / parent gate / Offer Codes | **Built** (`ark_core` purchase module, wired into hub settings + mode-card locks). Hidden in release (`KidsStore.monetizationEnabled = false`) until the client defines paid content, price and product IDs |
| Light login (progress sync, device change) | **Built** (`ark_core` auth module: Firebase, school-issued IDs, merge-safe sync, admin CSV tool). Hidden until the school's Firebase project exists (`flutterfire configure`) |
| App icon, splash, app name, bundle id | **Not started** (still Flutter defaults, `com.ark.ark_busters_kids`) |
| Real-device QA (sound, mic, performance) | **Not started** — no emulator on the dev VM |
| TEEN Flutter app | **Done** — 21 stages / 1,210 questions (live site), same Sheet updater, purchase and login modules (`ark_busters_teen`) |

## 14. Delivery phases (recommended)

### Phase A — Hub complete (visual + nav shells)
- Parity hub, working panels (collection/profile/settings UI), BGM toggle stubs.

### Phase B — Vocabulary end-to-end
- JSON export, battle loop, audio, progress, befriend/cards.

### Phase C — Listening + Sentence
- Shared battle shell reuse; per-mode rules.

### Phase D — Talk + mic
- Permissions, recognition, fallbacks.

### Phase E — Story + polish + store
- Story 1/2, IAP, parent gate, Offer Codes, screenshots, privacy text.

### Phase F — TEEN app
- Separate requirements + project.

---

## 15. Acceptance criteria (KIDS v1 free pack)

1. Hub matches web composition (hero + brand + 4 cards) without clipped art.
2. Each of 4 modes completable offline with free pack counts above.
3. Progress survives app restart.
4. Collection reflects friends + poses after wins/S-ranks.
5. SE/voice toggles work.
6. Story 1 shows once and is skippable.
7. No P0 crashes on Pixel-class Android emulator and one physical iOS/Android device.
8. Store listing assets and IAP sandbox purchase/restore verified (when monetization enabled).

---

## 16. Post-launch problem updates (client requirement)

From chat: 学院 wants to **keep adding/fixing problems** after release, **without coding**, and **without re-submitting the app every time**.

| ID | Requirement | Priority |
|---|---|---|
| U-01 | Questions live in **JSON content packs**, not hard-coded in Dart | Must |
| U-02 | App ships **bundled packs** for offline day-0 play | Must |
| U-03 | App can **download newer packs** via versioned `manifest.json` | Must |
| U-04 | Non-dev editor (Google Sheets → publish, or simple admin) | Must |
| U-05 | Manual “データを更新” in settings + optional auto-check | Should |
| U-06 | Paid packs downloadable only after IAP entitlement | Must (at IAP) |
| U-07 | JP操作マニュアル for 学院 staff | Should |

**Detail & architecture:** [CONTENT_UPDATE.md](CONTENT_UPDATE.md)

---

## 17. Open decisions (need client confirm)

1. Flutter vs Capacitor final approval (if not already written).
2. Free pose display cap (5) vs unlock all pose art in free build.
3. Exact IAP SKU / price / what “full unlock” includes.
4. Whether TEEN ships in same 4-week window or after KIDS.
5. Cloud save / login timing.
6. Hero image: fixed `kidtop1` vs random `kidtop1–4` like web.
7. Hub prompt: keep borderless app style vs restore web white card.
8. Content editor: Google Sheets vs custom admin web.
9. CDN host for packs (Firebase / R2 / Netlify / other).

---

## 18. Reference paths

| Item | Path |
|---|---|
| Flutter app | `ark_busters_kids/` |
| KIDS web source | `ark-english-busters-20260910T174320Z-1-001/ark-english-busters/` |
| KIDS hub HTML | `.../ark-kids-top.html` |
| TEEN web source | `ark-busters-teen-20260910T174325Z-1-001/ark-busters-teen/` |
| Progress key constants | `ark_busters_kids/lib/core/progress/progress_keys.dart` |

---

## 19. Document history

| Version | Date | Change |
|---|---|---|
| 1.0 | 2026-09-11 | Initial detailed requirements from web packs + Flutter status + client chat constraints |
| 1.1 | 2026-09-11 | Added post-launch content update requirements + CONTENT_UPDATE.md |
