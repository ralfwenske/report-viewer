# draw-report.red

A Red module that generates multi-page A4 reports using Red's `draw` dialect and displays them in a Red-View page viewer. No PostScript, no ps2pdf, no external dependencies.

## How it works

The module renders report content into `draw` command blocks (one per page), converts them to images via `draw <size> <block>`, and displays them in a View window with page navigation.

**Dependencies:** Red with View (`red-view`)

## Usage

```red
do %draw-report.red
```

### Exported functions

```red
generate-report content          ; returns block of image! (one per page)
paper-format 'a4                 ; set paper size (default: a4)
paper-format/landscape 'a4       ; set paper size in landscape orientation
fontsize 14                      ; set font size in points (default: 12)
```

## The one rule

Same content DSL as `report-generator`:

```red
[ [styles] value [styles] value value [styles]]
```

All styles work everywhere. See the [report-generator README](../report-generator/README.md) for the complete styles reference.

## Viewing reports

`generate-report` returns a `block!` of `image!` values (one per page). Display in a viewer:

```red
pages: generate-report rpt

current-page: 1
show-page: does [
    page-display/image: pick pages current-page
    page-label/text: rejoin ["Page " current-page " of " length? pages]
]

view/options layout [
    title "Report Viewer"
    below
    page-label: text 595x20 "" center
    page-display: base 595x842
    across
    button "<<" [current-page: 1 show-page]
    button "<" [if current-page > 1 [current-page: current-page - 1 show-page]]
    button ">" [if current-page < length? pages [current-page: current-page + 1 show-page]]
    button ">>" [current-page: length? pages show-page]
][size: 620x920]
```

## Examples

- `draw-report-test.red` — full test harness with page viewer
- `basic-demo.red` — minimal demo

## Differences from report-generator

| | report-generator | draw-report |
|---|---|---|
| Output | PostScript → PDF (via ps2pdf) | draw → image! (in-memory) |
| Dependencies | Ghostscript (ps2pdf) | None (pure Red) |
| Viewing | PDF viewer (external) | Red-View (built-in) |
| Content DSL | Identical | Identical |
| Font metrics | PostScript `stringwidth` | `size-text/with` |
| Coordinates | PostScript (Y up from bottom) | Draw (Y down from top) |

## Architecture

Same `context [...]` structure as report-generator. All parsing, formatting, style, and layout code is identical. The render layer (`draw-styled-text`, `draw-rect`, etc.) emits `draw` block commands instead of PostScript strings.

Font objects are cached by style combination and size. Text measurement uses `size-text/with` on a shared face object. The Y-axis is flipped via `to-draw-y` (draw has origin at top-left, the layout code tracks Y from top-down).
