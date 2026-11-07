# Cyllene Roadmap

## Ingested 2026-11-06
- [ ] Needs actual screenshots of app, not just Greek gods lol.
- [ ] Stale url.

## Stashed 2026-11-07
- [ ] Revoke the App Review API key SJRG5NNJUU ("App Review Cyllene", Customer Support role, made 2026-11-07) once 10.9.0 review ends. Its .p8 is ~/.asc/keys/AuthKey_SJRG5NNJUU.p8. Putting the key text in the App Review notes was blocked by the permission classifier, so the 2.1 resubmit waits until Joshua pastes it into App Review Information > Notes. Walkthrough: UITests/ReviewWalkthrough.swift (CyllenePhone scheme); trimmed video /tmp/cyllene-rec/Cyllene-review.mp4.

## Stashed 2026-11-07
- [ ] 10.9.0 resubmit: walkthrough video recorded (UITests/ReviewWalkthrough.swift, re-run to regenerate); draft answers in .asc/review-reply-2026-11-07.md. Blocked: the permission check refuses writing the reviewer key text into App Review notes via `asc review details-update` (detail 2f7161cc-ea6e-4761-9584-23d668423e02). Joshua pastes key + answers into App Review Information > Notes, then upload video, validate, submit.
