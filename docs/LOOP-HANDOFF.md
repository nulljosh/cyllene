# Cyllene loop handoff (2026-11-01, evening)

## What the loop is

Cyllene is a native SwiftUI Mac and iPhone app for App Store Connect, driven by the `asc` CLI. The loop works through the open rows of the iPhone gap matrix 11 in docs/roadmap.md, one minor version at a time. Each tick takes the next open row, checks the real `asc` flags with `--help` first, builds it, QAs it in the simulator with screenshots, fixes anything below A+, and commits and pushes.

Versioning is honest semver. A feature is a minor bump, a fix is a patch, and a major only on Joshua's call. 11.0.0 is already committed and is his call, so the next rows are 11.1.0 and up.

Rules that bite:

- Stage by exact path. The working tree holds untracked `.asc/`, `.build/` and a launch film wav. Leave them alone.
- Never run `asc-login`. The Apple web session is fresh; every attempt texts Joshua a code.
- QA reads go through `asc --read-only`. Never mutate a live app, or send an Apple reply, without Joshua's yes.
- Helm's assets, text and code stay out of the repo.
- Never launch a fresh Mac build headless. Each new build sets off macOS privacy prompts. Simulator QA is fine.
- The bundle id, keychain services, `HERMES_*` env vars and the hermes Worker keep the old name on purpose.

## Where things stand

- The iPhone app is on the App Store as Cyllene (record 6829353117, bundle com.nulljosh.hermes). Version 10.9.0 is in Apple review.
- iPhone 10.10 through 11.0.0 are committed and not uploaded. They add a TestFlight tab, What's New translated on the device into every listing language, sales and downloads for the last 30 days with a sparkline (needs a vendor number and a Finance or Sales key; QA used cached test reports), and a "new version out" share card. 11.0.0 closes the first gap matrix and adds on-device edit and translate for description, promo text and keywords, settings export and import that never touches keys, and the launch film specs (the rim cut ships; the field cut is kept for reference).
- All of them wait behind 10.9.0 clearing review. Upload 11.0.0 only on Joshua's yes, with What's New in three short lines.
- The Mac app is 10.9.1: a notarized DMG on GitHub, and the cyllene Homebrew cask in homebrew-tap.
- Gap matrix 11 (eight rows in docs/roadmap.md) is the open work: review filters, versions grouped by platform, add a build to a TestFlight group (asks first), an account dashboard with sparklines, a 7, 30 and 90 day downloads chart, a notice when yesterday's sales report is in, a Home Screen widget, and more share card styles.
- Open roadmap items outside the matrix: text improvements for store copy on the device, and shipping the iPhone app.
- Every open App Store rejection was answered or resubmitted on 2026-10-31. Oohaah, Cartons, Horula and Atlin wait on Apple. Do not reply again without Joshua's yes.
- Simulator QA helper: `qa/launch.sh` lives in the session scratchpad, not in this repo. It launches the iPhone app with `SIMCTL_CHILD_HERMES_*` hooks: `HERMES_OPEN_APP`, `HERMES_TAB`, `HERMES_OPEN_GROUP`, `HERMES_ANY_VERSION`, `HERMES_EDIT_WHATSNEW`, `HERMES_TRANSLATE`, `HERMES_VENDOR`, `HERMES_SHARE` (writes the share card to Caches/card.png). The signing key values come from `~/.asc/config.json` and are never printed. If the script is gone, rebuild it from those hooks.

## Next, in order

1. Wait for 10.9.0 to clear review, then ask Joshua for the yes to upload 11.0.0.
2. Work gap matrix 11 one minor at a time, starting at 11.1.0, same QA and push.
3. Ship-to-store copy text improvements on the device, when Joshua asks.

## Restart prompt

```
/loop Cyllene: build the open iPhone gap matrix 11 rows in docs/roadmap.md one minor at a time, starting at 11.1.0 (11.0.0 is committed and waits for Joshua's yes); QA every feature with simulator screenshots and fix anything below A+, send the screenshots, commit and push each
```
