# Cyllene brand kit and design system

A wing from Hermes' sandals: the messenger who carries your app to the store.

## The mark
One bold flat white glyph on an accent gradient tile. No text, no outline, no emblem.

- `../Cyllene.icon` is the source of truth (Icon Composer). Light and dark fills are set in it.
- `../icon.svg` is the flat copy for READMEs (shown at 80 px). `icon-1024.png` is the App Store icon, no alpha.
- `mark.svg` is the glyph alone in `currentColor` for your own background.
- Clear space equal to the width of the glyph's thickest stroke.
- At 32 px and below use `favicon.svg`: four thick feathers and wider gaps, so it still reads at 16 px. `scripts/gen_icon.py` draws every size.

## Colour
Cool paper in light, navy black in dark. One accent, flat surfaces, no gradients except the icon tile, no shadows.

| Role | Light | Dark |
|---|---|---|
| Accent (actions, links, solid buttons, bands) | `#0847C4` | `#6F9DFF` |
| Band (full-bleed blue sections) | `#0847C4` | `#0A33B5` |
| Icon tile | `#0074D9` (clrs.cc blue) to `#004C8F` | same |
| Background | `#FDFDFD` | `#0A0E19` |
| Surface (cards, grouped lists, hover) | `#F2F3F7` | `#141A2A` |
| Line | `#DCDDE5` | `#252D44` |
| Text | `#1A1A1A` | `#F2F2F5` |
| Secondary text | `#5A5C6B` | `#A2A9BC` |

State dots, the same on every screen a version shows: on sale `#2F8A4E` / `#4CAF6E`, in review or processing `#B07A00` / `#E0A800` (amber, so it never reads as a link), rejected `#C0392B` / `#D9534F`, preparing `#8A8D99` / `#6F7488`. Apple's state codes are never shown raw: `WAITING_FOR_REVIEW` reads "Waiting for review" (`Theme.words`).

## Type
System type only: SF Pro on Apple platforms, Helvetica on the web, no bundled face. Scale: display 64/64 bold, title 34/40 bold, headline 20/28 semibold, body 17/24, footnote 13/16. The app uses 17 semibold for titles, 14 semibold for rows and 11 medium for version lines.

## Space and shape
- Space on the 8 point grid: 4, 8, 12, 16, 24, 32, 48. Side margin 20. Reading column 680.
- Radii: cards 28, grouped lists 20, rows 8, controls fully round, icon 22.5 percent. The landing's buttons and panels are square cornered (2).
- Controls are 48 points tall capsules, one height in a row. Focus is a 4 point ring at 30 percent accent.
- Motion is 0.2 s ease and honours reduced motion.

`tokens.css` is the single source. `Shared/Tokens.swift` mirrors it for the Mac and iPhone apps, so a colour changes in two places and nowhere else. On the Mac, rows hover to the surface colour with an 8 point radius (`Sources/Theme.swift`). On iPhone, lists are inset grouped on the surface colour, the tab bar and back buttons are system Liquid Glass, and App Lock, Appearance and Accounts live in Settings.
