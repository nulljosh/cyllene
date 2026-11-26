# Cyllene loop handoff (2026-11-26, night, state checked against asc)

## What the loop is

Cyllene is a native SwiftUI Mac and iPhone app for App Store Connect, driven by the `asc` CLI. The loop works through the open rows of the iPhone gap matrix 11 in docs/roadmap.md, one minor version at a time. Each tick takes the next open row, checks the real `asc` flags with `--help` first, builds it, QAs it in the simulator with screenshots, fixes anything below A+, and commits and pushes.

Versioning is honest semver. A feature is a minor bump, a fix is a patch, and a major only on Joshua's call.

Rules that bite:

- Stage by exact path. `iOS/CyllenePhoneApp.swift` and `iOS/PhoneViews.swift` hold Joshua's uncommitted debug edits. Never stage them. The tree also holds untracked `.asc/`, `docs/ad/` and `scripts/` leftovers. Leave them alone.
- Never run `asc-login`. Every attempt texts Joshua a code.
- QA reads go through `asc --read-only`. Never mutate a live app, or send an Apple reply, without Joshua's yes.
- Never launch a fresh Mac build headless. Each new build sets off macOS privacy prompts. Simulator QA is fine.
- The bundle id, keychain services and `HERMES_*` env vars keep the old name on purpose.

## Where things stand

- iPhone 11.0.0 is live on the App Store (READY_FOR_SALE). Cyllene's own record is 6829353117.
- The Mac build packages the rejection index (fixes.json). Resolve All drafts replies on Ollama, falls back to Claude through the Mac's own subscription, splits Apple's numbered asks, and turns answers only the developer can give into [bracket] blanks that block sending. Nothing has been sent.
- Flamingo Map 2.0.0 (2.1 Information Needed) is the one open rejection being answered. The reply is drafted with every answer filled except the screen recording link. Tabs are now pressed through accessibility. A third recording take was running when the session ran out of room and is unchecked. Handoff: runs/2026-11-26-flamingo-review/HANDOFF.md in labs.
- Gap matrix 11 (eight rows in docs/roadmap.md) is still the open work: review filters, versions grouped by platform, add a build to a TestFlight group (asks first), an account dashboard with sparklines, a 7, 30 and 90 day downloads chart, a notice when yesterday's sales report is in, a Home Screen widget, and more share card styles.

## Next, in order

1. Finish the Flamingo Map recording (check the third take, re-record if it failed), then fill the link in the reply. Send only on Joshua's yes.
2. Work gap matrix 11 one minor at a time, starting at the first open row, same QA and push.

## Restart prompt

```
/loop Cyllene: finish the Flamingo Map 2.1 screen recording and reply (send only on Joshua's yes), then build the open iPhone gap matrix 11 rows in docs/roadmap.md one minor at a time; QA every feature with simulator screenshots and fix anything below A+, send the screenshots, commit and push each, staging by exact path and leaving Joshua's debug edits in iOS/ unstaged
```
