# GoD SK — Spring 2026

[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square&logo=opensourceinitiative)](LICENSE)
[![HTML5](https://img.shields.io/badge/HTML5-E34F26?style=flat-square&logo=html5&logoColor=white)](https://developer.mozilla.org/en-US/docs/Web/HTML)
[![JavaScript](https://img.shields.io/badge/JavaScript-vanilla-F7DF1E?style=flat-square&logo=javascript&logoColor=black)](https://developer.mozilla.org/en-US/docs/Web/JavaScript)
[![ECharts](https://img.shields.io/badge/ECharts-5.4.3-AA344D?style=flat-square)](https://echarts.apache.org/)
[![PWA](https://img.shields.io/badge/PWA-ready-5A0FC8?style=flat-square&logo=pwa)](index.html)
[![Version](https://img.shields.io/badge/version-1.6.2-blue?style=flat-square)](CHANGELOG.md)
[![Netlify](https://img.shields.io/badge/Netlify-deployed-00C7B7?style=flat-square&logo=netlify&logoColor=white)](https://god-sk-spring-2026.netlify.app/)

Internal clan analytics dashboard for **Guardians of Death (GoD)** in *Total Battle*. A single HTML file reads live Google Sheets data and renders performance views for the current cycle.

## Overview

Self-contained single-file HTML/JS dashboard — vanilla JavaScript, [ECharts](https://echarts.apache.org/) for charts, no build step. On load it fetches one or more Google Sheets via the public **gviz JSON API** and renders clan analytics in the browser.

Deployed on [Netlify](https://god-sk-spring-2026.netlify.app/) as a static site (inferred from repo history; there is no `netlify.toml` in this repo). The sheet must be shared as **“Anyone with the link can view”** or fetches fail (see the error text in `loadData()` around line 736).

Current version: `1.6.2` (shown in the status bar; tracked in `package.json` for [Release Please](.github/workflows/release-please.yml)).

## Tech stack

- **Vanilla JavaScript** — single `index.html`, no framework, no build step
- **[Apache ECharts](https://echarts.apache.org/)** 5.4.3 — charts (CDN)
- **[Tabler Icons](https://tabler.io/icons)** 3.19.0 — icon font (CDN)
- **[Google Fonts](https://fonts.google.com/)** — DM Sans, DM Mono
- **Google Sheets gviz API** — live data (`/gviz/tq?tqx=out:json`)
- **Netlify** — static hosting at [god-sk-spring-2026.netlify.app](https://god-sk-spring-2026.netlify.app/)
- **PWA** — inline manifest blob + `beforeinstallprompt` install banner
- **[Release Please](https://github.com/googleapis/release-please)** — automated versioning (`.github/workflows/release-please.yml`)

## Features

Seven tabs appear in the desktop tab bar and mobile bottom nav. An eighth view (`#premium`) is hash-only — no nav link.

### Overview (`#overview`)

Rendered by `renderOverview()` (line ~1159).

- Metric cards: clan total points, active player count, average score, count above average
- **Top 10 players** bar chart (`ec-top10`)
- **Chest category breakdown** donut chart — counts chests by group (`CHEST_GROUPS`, not premium types)
- **Score distribution** histogram with dynamic bucket sizing

### Leaderboard (`#leaderboard`)

`renderLeaderboard()` (line ~1329). Sortable columns (rank, name, points, Epic Monster, vs avg). Search filter via `filterLB()`. Rows are clickable → opens a player profile.

### Contest rankings (`#contest`)

`renderContest()` (line ~1408). Four tables, top and bottom 20 each:

- Overall score — top 20 / bottom 20
- Epic Monster chests — top 20 / bottom 20 (`epicScore()`)

Rows open player profiles. Shows auto-refresh interval from `AUTO_REFRESH_SECS`.

### Chest breakdown (`#chests`)

`renderChests()` (line ~1424). Clan-wide totals:

- Category bar chart (`CHEST_GROUPS` — Crypt, Rare Crypt, Epic Crypt, Citadel, Heroic, Special)
- Per-chest-type table with points value, total collected, and top collector

Premium chest types (`PREMIUM_CHEST_COLS`) are parsed but **not** shown here.

### Compare players (`#compare`)

`renderCompare()` / `updateCompare()` (lines ~1029–1156). Two player dropdowns; defaults to #1 vs #2 by points.

- Summary stat bars: total points, rank, vs clan avg, Epic Monster, per-category points
- Radar chart by category (`ec-cmp-radar`)
- Grouped bar chart (`ec-cmp-bar`)

### Activity (`#activity`)

`renderActivity()` (line ~886). Log-based engagement from the log tab (`LOG_GID`).

- Metrics: total log entries, chests logged in last 24h / 7d
- Hourly chest activity chart (last 24h)
- Top earners by points — last 24h and last 7d
- **Hot streaks** panel (`act-streaks`) — multi-day streaks via `getPlayerStreaks()`
- **Inactive 48h+** panel (`act-inactive`) — players with no recent log activity

Uses `getParticipationStats()` and `getPlayerStreaks()` internally.

### Cycle history (`#history`)

`renderHistory()` (line ~1790). Compares the **current cycle** against a selected archived cycle.

- Archive selector dropdown when `allArchives.length > 1` (`setArchiveCycle()`)
- Metrics: cycle delta, avg score, days elapsed, most improved, new players
- Charts: top score changes bar chart, current-vs-previous scatter plot
- Sortable comparison table with current/previous scores, pts/day, daily pace delta, and change bars

Defaults to the most recent entry in `ARCHIVE_SHEETS` (index 0).

### Player profiles (overlay on Leaderboard)

`openProfile()` (line ~1458). Opened by clicking a name on leaderboard, contest, history, activity panels, or premium table. Deep-linkable via `#leaderboard?player=Name` (`getUrlPlayer()` / `setUrlPlayer()`, lines ~2182–2187).

- Header stats: rank, percentile, total points, vs avg, Epic Monster + rank, pts/day, vs last cycle pace
- Deterministic hero portrait (`HERO_PORTRAITS` / `getPortrait()`, line ~593)
- Log-derived status pills (streak, activity, pts today)
- Charts: score vs clan average radar, points-by-category pie
- Chest counts relative to clan best, grouped by category
- **Points earned from log** trend (`renderProfileTrend()`) — 24h (hourly buckets) or 7d (daily buckets) toggle
- **Performance by cycle** bar chart (`renderProfileCycles()`) — current + all archives; Total / Per day toggle

Prev/next player navigation. Back button calls `closeProfile()`.

### Premium (`#premium` — hidden)

`renderPremium()` (line ~1976). Not in tab bar or bottom nav; navigate to `#premium` directly.

- Metric cards: premium points total, **estimated spend** (`fmtUsd(grandUsd)`), **top spender**, players active
- Per-type breakdown bars with estimated USD, points per chest, and pack price (`fmtUsd(c.usd)/pack`)
- Per-player table: each premium chest type, total chest count, premium points, **Est. $** column (`fmtUsd(premUsd)`)

Premium types and pack pricing are defined in `PREMIUM_CHEST_COLS` (lines ~560–567). `chestUsd()` (line ~569) estimates spend as `floor(count/3) * usdPerPack`; `fmtUsd()` (line ~570) formats dollar strings. Players are sorted by `premUsd`.

### Other UI (not separate tabs)

- **Auto-refresh** — 180s countdown badge; click to refresh manually (`AUTO_REFRESH_SECS`, `startAutoRefresh()`)
- **PWA** — inline manifest blob, install banner on Android/Chrome (`beforeinstallprompt`)
- **Mobile bottom nav** — 7 tabs (no premium)
- **Dark mode** — CSS `prefers-color-scheme` + ECharts theme helpers (`isDark()`, line ~507)
- **Version tag** — current version in status bar; click to open the changelog modal

## Data sources

All data is fetched client-side via gviz:

```
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:json&gid={GID}&t={timestamp}
```

Configured at lines ~462–470:

| Purpose | Variable | Sheet ID | GID |
|---|---|---|---|
| Current cycle scores | `SHEET_ID` + `GID` | `17W1y5fZdl3YWofkWnubwAtLvhWrFBzgPdN0VdDi4Sa0` | `181827579` |
| Chest event log | `SHEET_ID` + `LOG_GID` | same sheet | `1476283132` |
| Archived cycles | `ARCHIVE_SHEETS[]` | per-entry `id` | per-entry `gid` |

Current archives (newest first):

```js
{id: '1r2YlgZ6XYtxMP1Td0KUmme9qY0xwNDSGIogqWlzTFVE', gid: '181827579'}  // July 22-August 1
{id: '1yAws-c9M77tjiznUQTz3NVJKuijJDup6cL4f6vmv9P4', gid: '181827579'}  // July 7-22
{id: '11CRdC5-iITvrrxEaF-hVCjRNHrhtrMRe0ziw4PbfjOU', gid: '181827579'}  // June 27-July 7
{id: '1axcher13cHG2eAmDu2sJje1Iu3Y5UVIBDB5VrBUFgJA', gid: '181827579'}  // June 17-27
{id: '1H3IkN_isr4d3o2HwtID5mRktycMByZahvsmaw876g2k', gid: '181827579'}  // June 7-17
{id: '1J4OhqHSZfQIHrfTSLRtjQIoT6aLb9wfGHqdDOiYZoRQ', gid: '181827579'}  // May 25-June 7
{id: '1LxTP1f4JWB79z8O-SgU3gClWniDF6LeXcBXFh8Kcwbc', gid: '181827579'}  // May 14-25
```

`ARCHIVE_GID` (`'181827579'`, line 470) is defined but unused — each archive entry carries its own `gid`.

### What each source provides

- **Main tab (`GID`)** — current-cycle player names, total points, and per-chest-type counts. Parsed by `buildPlayers()` (line ~608): name at column index 2, points at index 3, player rows start at row 6. Cycle label extracted by `extractCycleLabel()` from header rows.
- **Log tab (`LOG_GID`)** — timestamped chest events. Parsed by `parseLogEvents()` (line ~652): clean name col 6, type col 7, timestamp col 5 (fallback col 4). Point values mapped via `LOG_TYPE_PTS` (lines ~628–630), built from both `CHEST_COLS` and `PREMIUM_CHEST_COLS`. Log type strings match column names (e.g. `Magic Chest`, `Golden Chest`).
- **Archive sheets** — same layout as the main tab. Loaded in parallel by `loadArchiveData()` (line ~680). Cycle label read from `rows[0].c[2]`; duration estimated by `parseCycleDays()`.

On each full load, `loadData()` fetches the main sheet first, then `loadLogData()` and `loadArchiveData()` in parallel — **1 + N + 1** gviz requests where N = `ARCHIVE_SHEETS.length` (currently 9 total).

## Architecture notes

- **Single file** — everything lives in `index.html` (~2208 lines). No bundler, no local npm dependencies at runtime.
- **CDN dependencies** — ECharts 5.4.3, Tabler Icons 3.19.0, Google Fonts (DM Sans, DM Mono).
- **Hash routing** — `activateTab()` (line ~2052) syncs tab visibility, desktop tabs, bottom nav, and `history.replaceState`. Valid hashes: `overview`, `leaderboard`, `contest`, `chests`, `compare`, `activity`, `history`, `premium`. Leaderboard profiles add `?player=` query param.
- **Auto-refresh** — `setInterval` countdown in `startAutoRefresh()` (line ~749). Silent refreshes (`loadData(true)`) skip re-rendering leaderboard and compare (and profile) to avoid disrupting interaction; other tabs still re-render.
- **PWA** — manifest injected as a blob URL (skull SVG icon in header and manifest). `apple-mobile-web-app-*` meta tags present.
- **SEO** — `<meta name="robots" content="noindex, nofollow">` (line 5).
- **Player dedup** — `EXCLUDED_PLAYERS` hides old names from score sheets; `getPlayerAliases()` maps canonical names back to old names for log lookups.

## Maintenance

### End of cycle — add an archive

When a clan cycle ends and the sheet is copied/archived:

1. Create the archived Google Sheet (same column layout as the current main tab).
2. Prepend `{id, gid}` to `ARCHIVE_SHEETS` at **line ~466** (newest first):

```js
const ARCHIVE_SHEETS = [
  {id: 'NEW_SHEET_ID', gid: '181827579'},  // most recent
  {id: '1J4OhqHSZfQIHrfTSLRtjQIoT6aLb9wfGHqdDOiYZoRQ', gid: '181827579'},
  // ...
];
```

3. Point `SHEET_ID` / `GID` at the new current-cycle sheet if the active sheet changed.

### Renamed or duplicate players

Edit `EXCLUDED_PLAYERS` (line ~475):

```js
const EXCLUDED_PLAYERS = new Map([
  ['Toxin', 'ToXin'],  // old name → canonical name (for log alias lookup)
]);
```

- **Key** — name to hide from score-sheet parsing (`buildPlayers()` skips keys).
- **Value** — canonical name; `getPlayerAliases()` (line ~480) adds old names when querying log data.

### Chest column layout

If new chest types are added to the sheet, update `CHEST_COLS` (line ~515) and/or `PREMIUM_CHEST_COLS` (line ~560) with the correct `col` index and metadata. If log chest type labels change, ensure they match keys in `LOG_TYPE_PTS`.

### Releases

Version bumps are automated via Release Please on conventional commits (`feat:`, `fix:`, etc.). Manual fallback: `./scripts/release.sh patch|minor|major`.

Whenever `CHANGELOG.md` is updated, sync the new version number everywhere it appears: the README version badge and "Current version" line, `package.json`, `.release-please-manifest.json`, and the three `x-release-please-version` markers in `index.html` (meta tag, status-bar tag, PWA manifest) plus `CHANGELOG_ENTRIES`.

## Deployment

Static single-file deploy. Publish `index.html` — Netlify (or any static host) serves it as the site root. No build command required.

To deploy manually: push to the connected Netlify branch, or drag-and-drop `index.html` in the Netlify UI.

## Known constraints / gotchas

- **Hardcoded column indices** — `CHEST_COLS`, `PREMIUM_CHEST_COLS`, and `buildPlayers()` (`nameIdx=2`, `ptsIdx=3`) assume a fixed sheet layout. Reordering or inserting columns will break parsing until the `col` values are updated.
- **Log column indices** — `parseLogEvents()` hardcodes cols 4–7 for timestamps, name, and type.
- **Slow initial load** — the browser fires multiple live gviz requests on every load/refresh (main + log + each archive). Expect several seconds, especially on mobile.
- **Log type labels** — `LOG_TYPE_PTS` keys must match the clean `TYPE` strings in the log tab (col 7). If the sheet uses different labels, add explicit mappings rather than assuming names match `CHEST_COLS` / `PREMIUM_CHEST_COLS`.

### Unverified

- **Netlify deploy config** — deployment target is inferred from git history (`Initial commit via Netlify`), not from any config file in this repo.
- **Clan name “Guardians of Death”** — appears in the user-facing title/branding context but is not spelled out in the HTML source; the code uses “GoD SK” throughout.
## License

Released under the [MIT License](LICENSE). Copyright (c) 2026 Summit Fortress Investments - Nevis IBC.
