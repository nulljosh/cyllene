# Cyllene loop handoff (2026-10-31, evening)

## What the loop is

Cyllene is a native SwiftUI Mac and iPhone app for App Store Connect, driven by the `asc` CLI. The loop works through the open rows of the iPhone gap matrix in docs/roadmap.md, one minor version at a time. Each tick takes the next open row, checks the real `asc` flags with `--help` first, builds it, QAs it in the simulator with screenshots, fixes anything below A+, and commits and pushes.

Versioning is honest semver. A feature is a minor bump, a fix is a patch, and a major only on Joshua's call. Joshua's goal for this stretch is 11.0.0, but calling it 11.0.0 is his decision, so the loop stops and asks before it does.

Rules that bite:

- Stage by exact path. The working tree holds an untracked `.build/`. Leave it alone.
- Never run `asc-login`. The Apple web session is fresh; every attempt texts Joshua a code.
- QA reads go through `asc --read-only`. Never mutate a live app, or send an Apple reply, without Joshua's yes.
- Helm's assets, text and code stay out of the repo.
- Never launch a fresh Mac build headless. Each new build sets off macOS privacy prompts. Simulator QA is fine.
- The bundle id, keychain services, `HERMES_*` env vars and the hermes Worker keep the old name on purpose.

## Where things stand

- The iPhone app is on the App Store as Cyllene (record 6829353117, bundle com.nulljosh.hermes). Version 10.9.0 is in Apple review.
- iPhone 10.10.0 adds a TestFlight tab (groups, testers, public link, add a tester after asking). 10.11.0 translates What's New into every listing language on the device with Apple's Translation, and one yes saves all changed languages. Both are committed and not uploaded. They ship after 10.9.0 clears review.
- The Mac app is 10.9.1: a notarized DMG on GitHub, and the cyllene Homebrew cask.
- Done in the iPhone gap matrix: TestFlight groups and testers (10.10), translate What's New (10.11), reviews translated (10.8).
- Open rows: sales and downloads at a glance with a sparkline (AppFigures), and a "new version out" share card.
- Open roadmap items outside the matrix: translations of app metadata on the device, text improvements for store copy, setup export (mirrored as a GitHub issue on 2026-10-31), and shipping the iPhone app.
- Every open App Store rejection was answered or resubmitted on 2026-10-31. Oohaah, Cartons, Horula and Atlin wait on Apple. Do not reply again without Joshua's yes.
- Simulator QA helper: `qa/launch.sh` lives in the session scratchpad, not in this repo. It launches the iPhone app with `SIMCTL_CHILD_HERMES_*` hooks: `HERMES_OPEN_APP`, `HERMES_TAB`, `HERMES_OPEN_GROUP`, `HERMES_ANY_VERSION`, `HERMES_EDIT_WHATSNEW`, `HERMES_TRANSLATE`. The signing key values come from `~/.asc/config.json` and are never printed. If the script is gone, rebuild it from those hooks.

## Next, in order

1. Sales and downloads at a glance with a sparkline. Build it, QA it in the simulator with screenshots on iPhone (and iPad where the layout changes), fix anything below A+, commit and push.
2. A "new version out" share card. Same QA and push.
3. Stop and ask Joshua before calling the set 11.0.0.

## Restart prompt

```
/loop Cyllene to 11.0.0: build the open iPhone gap rows in docs/roadmap.md one minor at a time, QA every feature with simulator screenshots and fix anything below A+, send the screenshots, commit and push each
```
