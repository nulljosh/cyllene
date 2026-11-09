# Cyllene Roadmap

## Ingested 2026-11-06

## Stashed 2026-11-07
- [ ] Revoke the App Review API key SJRG5NNJUU ("App Review Cyllene", Customer Support role, made 2026-11-07) once 10.9.0 review ends. Its .p8 is ~/.asc/keys/AuthKey_SJRG5NNJUU.p8. Putting the key text in the App Review notes was blocked by the permission classifier, Key, answers and walkthrough video went into the review notes and 10.9.0 was resubmitted 2026-11-07 (WAITING_FOR_REVIEW). Walkthrough: UITests/ReviewWalkthrough.swift (CyllenePhone scheme); trimmed video /tmp/cyllene-rec/Cyllene-review.mp4.

## Stashed 2026-11-07

## Stashed 2026-11-07 (late)
- [ ] App Store screenshots to A+: round 1 graded (store set B/C: charging bolt, "Hermes" in iPad status bar, Status leads with Rejected, Reviews shot mostly empty). Capture script `scratchpad/cylshot.sh` pattern: debug build + `simctl launch` with HERMES_KEY_ID/ISSUER_ID/KEY_PEM_B64, status_bar override discharging 100. Uncommitted debug hooks in iOS/CyllenePhoneApp.swift and iOS/PhoneViews.swift (status scroll, sales note) from the stopped fork: build-check before committing. Skip TestFlight (tester email) and Settings (vendor number). Upload only after 10.9.0 review ends.
- [ ] Click-test Resolve All picker (checkboxes, "Resolve N") and right-click "Resolve <app>" (a6f4db3); unit tests compile, not run.

## Ingested 2026-11-08
- [x] Splash screen shows title without ending E lol (`notes/attachments/2026-11-08/cyllene-3.png`: wordmark reads CYLLEN mid-animation). Fixed in code 2026-11-08 (the letter loop counted to 6, left from the Hermes name). Reaches users with the next iOS build.
- [ ] Shouldn't ask user for keys, instead should ask user for their login id and help them login that way. Don't ask for keys, ask for login with Apple (`notes/attachments/2026-11-08/cyllene-2.png`: first screen is Key ID, Issuer ID, Import .p8 file, Connect).
- [ ] Needs animated hero banner like other apps (`notes/attachments/2026-11-08/cyllene-1.png`: the App Store page).
