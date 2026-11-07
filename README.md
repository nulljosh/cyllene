<img src="icon.svg" width="80" alt="Cyllene">

![version](https://img.shields.io/badge/version-10.9.1-0074D9) ![license](https://img.shields.io/badge/license-MIT-0074D9) ![tests](https://github.com/nulljosh/cyllene/actions/workflows/test.yml/badge.svg)

App Store Connect is a website built for one app at a time. Cyllene is a Mac app built for all of them at once.

Formerly Hermes.

## Features

Every app in one list, with its live version and where it stands in review. Open one for versions, metadata, screenshots, builds, TestFlight, reviews, prices and purchases. Every change shows the exact command and asks first.

Before you submit, Status runs Apple's own readiness check and lists what blocks the version. When Apple rejects an app, Resolve All drafts the reply on your Mac's own model, and nothing sends until you say so.

It runs on the [asc](https://github.com/rorkai/App-Store-Connect-CLI) tool, so your API key stays on your Mac. There's an iPhone and iPad app too.

## Get it

[Download Cyllene.dmg](https://github.com/nulljosh/cyllene/releases/latest/download/Cyllene.dmg), signed and notarized. Sign in to `asc` first.

Agents get the same view over MCP, read only unless `HERMES_ALLOW_WRITES=1`:

```sh
claude mcp add cyllene -- uv run https://raw.githubusercontent.com/nulljosh/cyllene/main/mcp/server.py
```

## Build

```sh
brew install xcodegen asc
xcodegen generate && open Cyllene.xcodeproj
./scripts/release.sh   # signed, notarized dist/Cyllene.dmg
```

[Roadmap](docs/roadmap.md) · [Whitepaper](docs/WHITEPAPER.md)
