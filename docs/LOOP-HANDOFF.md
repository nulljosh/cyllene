# Hermes loop handoff (2026-10-31, night)

## What the loop is

Hermes is a native SwiftUI Mac app for App Store Connect, driven by the `asc` CLI. The loop works through the open rows of the parity matrix in docs/roadmap.md, one item at a time, toward a one-to-one clone of Helm 2.3.9 with its own brand and code. Each tick takes the next item, checks the real `asc` flags with `--help` first, builds it, QAs it with launch arguments and screenshots, bumps the version, and pushes with a tag.

Versioning is honest semver. A feature is a minor bump, a fix is a patch, and a major only on Joshua's call. The loop does not aim at any version number.

Rules that bite:

- Stage by exact path. The working tree can hold other changes, including an untracked `.build/`. Leave those alone.
- QA reads go through `asc --read-only`. Never mutate a live app without Joshua's yes.
- Helm's assets, text and code stay out of the repo.
- Long builds run in the background. One heavy job at a time.
- Never open a fresh build headless. Test through the MCP or scripts/try-writer.sh.

## Where things stand

- 2026-10-31 night: the iPhone app is on the App Store as **Cyllene** (Hermes was taken; record 6829353117, bundle com.nulljosh.hermes, SKU HERMESIOS). Free, Developer Tools, all territories, privacy "data not collected" published, age rating all none. 10.9.0 is uploaded and a background script uploads the renamed build, screenshots and review details, then submits. The iPhone already says Cyllene on screen; the repo, Mac app, landing (hermes.jaybulb.com) and fonts still say Hermes. The full rename to Cyllene is Joshua's ask and is next after Resolve All.
- 10.5.0 to 10.9.0 shipped this evening on iPhone: ratings summary, starred apps, launch checklist, Translate on reviews, Liquid Glass pass, What's New editor (asks first). 10.9.0 Mac shipped: notarized DMG, GitHub release, cask, landing.
- The Apple web session is fresh (signed in 2026-10-31 18:45 PDT). Do not run asc-login again; every attempt texts Joshua a code.
- Blackcomb iOS 1.0.0 was rejected 2026-10-31 evening, on top of the UNRESOLVED_ISSUES list below.
- App Store Connect has review submissions in UNRESOLVED_ISSUES across about 9 apps: Patois iOS, Mailbag Mac, Oohaah Mac and iOS, Scrounger iOS, Cartons iOS, Horula Mac and iOS, Atlin iOS, Airwell iOS, Blackcomb iOS. Sidewise is retired (deletion is on blocked-on-joshua).

- Rejection reasons read 2026-10-31 night (full text in the session scratchpad, re-read with `asc web review show --app ID --plain-text`): 4.3(a) spam on Oohaah, Scrounger, Cartons, Horula, Atlin, Blackcomb (answer with the nine answers, change the build where it is thin); 2.1(a) bugs on Patois and a crash on Mailbag (read the steps, fix, new build); 2.3.8 on Airwell, store name and home screen name differ (match CFBundleDisplayName to the listing, new build).

## Next, in order

1. Goal: Resolve All actually works, and every app is resolved through it. Loop: read every open thread (`asc web review show --app ID`), draft each reply from the app's facts (Sources/Facts.swift, mcp/server.py app_facts), fix the app where the rejection is a real bug, then send through Resolve All. Joshua said yes to resolving all on 2026-10-31; still never resubmit an unchanged build and check the listing name first.
2. Full rename Hermes to Cyllene with the rename skill: repo, folder, Mac app, landing domain, fonts, docs.
3. Remaining iPhone Mobbin rows in docs/roadmap.md: TestFlight groups and testers, translate What's New, sales at a glance, share card.

## Restart prompt

```
/loop Hermes: read docs/LOOP-HANDOFF.md and docs/roadmap.md. If Joshua has not yet signed in inside Hermes, stop and ask him for that one sign-in. Otherwise do the next item as the next minor version (10.5.0 next). Versioning is honest semver: features are minors, fixes are patches, a major only on Joshua's call. QA each change on a real app, notarize the DMG for the GitHub release, and never mutate a live app or send an Apple reply without Joshua's yes.
```
