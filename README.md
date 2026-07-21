# draw-report.red

A Red module that generates multi-page A4 reports using Red's `draw` dialect with zoom and scroll viewing. No PostScript, no ps2pdf, no external dependencies.

## How it works

The module renders report content into `draw` command blocks (one per page). The `render-page` function renders any page at any zoom level via `draw <size> [scale ...]`. Pages are displayed in a Red-View window with zoom controls and scrollbar.

**Dependencies:** Red with View (`red-view`)

## Usage

```red
do %draw-report.red
```

### Exported functions

```red
generate-report content          ; returns block of draw blocks (one per page)
render-page page-block zoom      ; render a draw block at zoom % (100 = native size)
paper-format 'a4                 ; set paper size (default: a4)
paper-format/landscape 'a4       ; set paper size in landscape orientation
fontsize 14                      ; set font size in points (default: 12)
```

### Zoom rendering

```red
pages: generate-report rpt

; Render page 1 at different zoom levels
img-100: render-page pick pages 1 100   ; 595x842 (native)
img-50:  render-page pick pages 1 50    ; 297x421 (half size)
img-200: render-page pick pages 1 200   ; 1190x1684 (double)
```

## The one rule

Same content DSL as `report-generator`:

```red
[ [styles] value [styles] value value [styles]]
```

All styles work everywhere. See the [report-generator README](../report-generator/README.md) for the complete styles reference.

## Viewer features

Both demo files include a full viewer with:

- **Orientation popup** — choose portrait or landscape before opening
- **Zoom controls** — `−` / `+` buttons, Fit Width, Fit Page
- **Scrollable viewport** — vertical scroller for pages taller than the viewport
- **Page navigation** — `<<` / `<` / `>` / `>>` buttons

Zoom levels: 25%, 50%, 75%, 100%, 125%, 150%, 200%

## Examples

- `draw-report-test.red` — full test harness with all features
- `basic-demo.red` — minimal demo

## Differences from report-generator

| | report-generator | draw-report |
|---|---|---|
| Output | PostScript → PDF (via ps2pdf) | draw blocks → images (in-memory) |
| Dependencies | Ghostscript (ps2pdf) | None (pure Red) |
| Viewing | PDF viewer (external) | Red-View with zoom + scroll |
| Content DSL | Identical | Identical |
| Font metrics | PostScript `stringwidth` | `size-text/with` |
| Coordinates | PostScript (Y up from bottom) | Draw (Y down from top) |
| Zoom | Fixed (PDF page size) | Any % via `render-page` |

## Architecture

Same `context [...]` structure as report-generator. All parsing, formatting, style, and layout code is identical. The render layer (`draw-styled-text`, `draw-rect`, etc.) emits `draw` block commands instead of PostScript strings.

Font objects are created via `compose` with set-words and cached. Text measurement uses `size-text/with` on a shared face object. The Y-axis is flipped via `to-draw-y`. Text positioning accounts for draw's top-left anchoring (vs PostScript baseline).
