# Cyllene Roadmap

## Ingested 2026-11-06

## Stashed 2026-11-07
- [ ] Revoke the App Review API key SJRG5NNJUU ("App Review Cyllene", Customer Support role, made 2026-11-07) once 10.9.0 review ends. Its .p8 is ~/.asc/keys/AuthKey_SJRG5NNJUU.p8. Putting the key text in the App Review notes was blocked by the permission classifier, Key, answers and walkthrough video went into the review notes and 10.9.0 was resubmitted 2026-11-07 (WAITING_FOR_REVIEW). Walkthrough: UITests/ReviewWalkthrough.swift (CyllenePhone scheme); trimmed video /tmp/cyllene-rec/Cyllene-review.mp4.

## Stashed 2026-11-07

## Stashed 2026-11-07 (late)
- [ ] App Store screenshots to A+: round 1 graded (store set B/C: charging bolt, "Hermes" in iPad status bar, Status leads with Rejected, Reviews shot mostly empty). Capture script `scratchpad/cylshot.sh` pattern: debug build + `simctl launch` with HERMES_KEY_ID/ISSUER_ID/KEY_PEM_B64, status_bar override discharging 100. Uncommitted debug hooks in iOS/CyllenePhoneApp.swift and iOS/PhoneViews.swift (status scroll, sales note) from the stopped fork: build-check before committing. Skip TestFlight (tester email) and Settings (vendor number). Upload only after 10.9.0 review ends.
- [ ] Click-test Resolve All picker (checkboxes, "Resolve N") and right-click "Resolve <app>" (a6f4db3); unit tests compile, not run.

## Ingested 2026-11-08
- [ ] Submit iPhone 11.0.0 for review: staged 2026-11-08 with build 2, What's New and the review notes copied from 10.9.0, validate clean (0 blocking). The submit step was stopped by the permission gate, so it needs Joshua: `asc review submit --app 6829353117 --version-id 347545d5-6514-4d72-9d8b-58ec281eb94c --build-id d1a59144-4b5c-48ca-8f2e-69e7ab31c5ae --confirm`. Keep the reviewer key SJRG5NNJUU until this review ends, the notes use it.
- [x] Splash screen shows title without ending E lol (`notes/attachments/2026-11-08/cyllene-3.png`: wordmark reads CYLLEN mid-animation). Fixed in code 2026-11-08 (the letter loop counted to 6, left from the Hermes name). Reaches users with the next iOS build.
- [ ] Shouldn't ask user for keys, instead should ask user for their login id and help them login that way. Don't ask for keys, ask for login with Apple (`notes/attachments/2026-11-08/cyllene-2.png`: first screen is Key ID, Issuer ID, Import .p8 file, Connect). Built 2026-11-08 and compiled, not yet tried with a real Apple sign-in (needs your login on a device), ships after 11.0.0. App Store Connect has no Sign in with Apple or OAuth for third-party apps: its API only takes a key made in Users and Access. Plan: a Log in with Apple button opens Apple's own Integrations page in an in-app browser, you sign in there with your Apple ID, then Cyllene picks up the Key ID, Issuer ID and the one-time .p8 download so nothing gets typed. Keep the manual form as the fallback. Needs a real Apple sign-in on a device to QA, and App Review may push back on it.
- [ ] Needs animated hero banner like other apps (`notes/attachments/2026-11-08/cyllene-1.png`: the App Store page). Started 2026-11-08, not built. Read as an App Preview video at the top of the App Store page, since the screenshot is that page. Cyllene has none. docs/ad/cyllene-11-field.mp4 and eleven.mp4 are 20 s, 1920x1080 launch films, and Apple wants previews cut from real app footage at iPhone preview size, so this needs a fresh screen capture and goes on the next iOS version.
