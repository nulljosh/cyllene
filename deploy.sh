#!/bin/sh
# Copy the brand files the landing shares with the app, then deploy the Worker.
set -e
cd "$(dirname "$0")"
cp brand/tokens.css brand/mark.svg icon.svg favicon.svg favicon-32.png apple-touch-icon.png landing/
[ "$1" = "--copy-only" ] && exit 0
npx wrangler deploy
