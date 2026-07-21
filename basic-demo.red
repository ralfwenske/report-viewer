Red [
    File: %basic-demo.red
    Title: "Draw Report Viewer — Zoom + Scroll"
    Needs: 'View
]

unless value? 'generate-report [
    do load %draw-report.red
]

;--- Report content (same DSL as report-generator) ---
title: "Basic Demo"
total: 5123.87654
threethousand: 3000
fourthousand: 4000
widget-C: [[red] "Widget C" [12 green '>] -45 [6.2 '>] total [red 10.3] " Check" [white 255.165.0]]

get-items: func [res [block!]] [
    repeat i 30 [append/only res reduce ["Item " i]]
    res
]

rpt: copy []
append rpt reduce [
    'HEADER
    reduce [['b] "ACME Corp" ['h1 red] (title) ['h2] "%DATE%"]
    ["Page %PAGE% of %PAGES%" "" "%TIME%"]
    []
    'CONTENT
    ["This is a draw-based report viewer:" ['h2 yellow black]]
    ['COLUMN 33 3
        ["Generated on " ['i] "%DATE%"]
        ["Generated on " ['i] now [14 'date '>]]
        [['m] "Generated on " ['i] "%DATE%"]
        [['m] "Generated on " ['i] now [14 'date '>]]
    ]
    [['m] " Sample content goes here. " [white purple] " And yellow here " [black yellow]]
    ["Table with 'box 'alt" ['u 'h2]]
    ['TABLE 'BOX 'ALT
        ["Product" ['< 30] "Qty" ['^ 10 10.4] "Total" ['> 13 'money] "Status" ['^ 13]]
        ["Widget A" 120 threethousand ['b] "OK" [white 80.128.80]]
        ["Widget A1" 120 fourthousand ['b] "OK" [white 80.128.80]]
        ["Widget B" [80.150.200] "45" total "Check" [white 55.105.90]]
        widget-C
        ["TOTALS" ['b] "" "$13'780.00" ""]
    ]
    ["and here another columns demo" ['u 'h2]]
    get-items ['COLUMN]
    'FOOTER
    []
    [['b] " Confidential " ['h3 white blue] "%DATE%" "Page %PAGE% of %PAGES%"]
]

;--- Orientation popup ---
is-landscape: false
view/options layout [
    title "Orientation"
    below
    text 200x30 "Choose page orientation:" center
    across
    button "Portrait"  [is-landscape: false unview]
    button "Landscape" [is-landscape: true unview]
][size: 280x80]

either is-landscape [paper-format/landscape 'a4][paper-format 'a4]
pages: generate-report rpt

;--- Viewer state ---
current-page: 1
zoom: 100
scroll-x: 0
scroll-y: 0
vp-w: 600
vp-h: 800
toolbar-h: 36

zoom-levels: [25 50 75 100 125 150 200]

;--- Cache native-resolution images ---
native-cache: copy []
get-native: function [pn [integer!]][
    while [pn > length? native-cache][
        append/only native-cache render-page pick pages (length? native-cache + 1) 100
    ]
    pick native-cache pn
]

;--- Zoom: scale cached native image (crisp at all levels) ---
get-zoomed: function [pn [integer!] z [integer!] /local native w h][
    native: get-native pn
    w: to integer! native/size/x * z / 100
    h: to integer! native/size/y * z / 100
    draw as-pair w h compose [image (native) 0x0 (as-pair w h)]
]

zoom-in: does [
    foreach z zoom-levels [if z > zoom [zoom: z break]]
    scroll-x: 0 scroll-y: 0
    update-display
]

zoom-out: does [
    reverse zoom-levels
    foreach z zoom-levels [if z < zoom [zoom: z break]]
    reverse zoom-levels
    scroll-x: 0 scroll-y: 0
    update-display
]

zoom-fit-width: does [
    z: to integer! vp-w / (to float! page-width) * 100
    zoom: first zoom-levels
    foreach lz zoom-levels [if lz <= z [zoom: lz]]
    scroll-x: 0 scroll-y: 0
    update-display
]

zoom-fit-page: does [
    zw: to integer! vp-w / (to float! page-width) * 100
    zh: to integer! vp-h / (to float! page-height) * 100
    z: min zw zh
    zoom: first zoom-levels
    foreach lz zoom-levels [if lz <= z [zoom: lz]]
    scroll-x: 0 scroll-y: 0
    update-display
]

update-display: does [
    if any [empty? pages current-page > length? pages][exit]
    page-img: get-zoomed current-page zoom
    full-w: page-img/size/x
    full-h: page-img/size/y

    ; Clamp scroll
    max-sx: max 0 full-w - vp-w
    max-sy: max 0 full-h - vp-h
    if scroll-x > max-sx [scroll-x: max-sx]
    if scroll-y > max-sy [scroll-y: max-sy]
    if scroll-x < 0 [scroll-x: 0]
    if scroll-y < 0 [scroll-y: 0]

    ; Crop visible portion
    vw: min vp-w full-w
    vh: min vp-h full-h
    visible: draw as-pair vw vh compose [
        image page-img (as-pair (0 - scroll-x) (0 - scroll-y)) (as-pair full-w full-h)
    ]
    page-display/image: visible

    ; Update labels
    page-label/text: rejoin ["Page " current-page " / " length? pages]
    zoom-label/text: rejoin [zoom "%"]

    ; Update scrollers
    needs-v?: full-h > vp-h
    needs-h?: full-w > vp-w
    scroller-v/visible?: needs-v?
    scroller-h/visible?: needs-h?
    if needs-v? [
        scroller-v/data: either max-sy > 0 [to float! scroll-y / max-sy][0.0]
    ]
    if needs-h? [
        scroller-h/data: either max-sx > 0 [to float! scroll-x / max-sx][0.0]
    ]
]

resize-viewport: does [
    win-sz: page-display/parent/size
    vp-w: max 200 win-sz/x - 40
    vp-h: max 200 win-sz/y - toolbar-h - 40
    page-display/size: as-pair vp-w vp-h
    scroller-v/size: as-pair 18 vp-h
    scroller-h/size: as-pair vp-w 18
    update-display
]

;--- Build viewer UI ---
view/options/flags compose/deep [
    title "Draw Report Viewer"
    below

    ; Toolbar
    across
    button "<<" [current-page: 1 scroll-x: 0 scroll-y: 0 update-display]
    button "<" [
        if current-page > 1 [current-page: current-page - 1]
        scroll-x: 0 scroll-y: 0 update-display
    ]
    page-label: text 90x24 "Page 0 / 0" center
    button ">" [
        if current-page < length? pages [current-page: current-page + 1]
        scroll-x: 0 scroll-y: 0 update-display
    ]
    button ">>" [current-page: length? pages scroll-x: 0 scroll-y: 0 update-display]
    pad 20x0
    button 30x24 "-" [zoom-out]
    zoom-label: text 50x24 "100%" center
    button 30x24 "+" [zoom-in]
    button "Fit W" [zoom-fit-width]
    button "Fit Page" [zoom-fit-page]
    return

    ; Page viewport + vertical scroller
    across
    page-display: base (as-pair vp-w vp-h) white
    scroller-v: scroller (as-pair 18 vp-h) [
        if not empty? pages [
            page-img: get-zoomed current-page zoom
            max-sy: max 0 page-img/size/y - vp-h
            scroll-y: to integer! face/data * max-sy
            update-display
        ]
    ]
    return

    ; Horizontal scroller
    scroller-h: scroller (as-pair vp-w 18) [
        if not empty? pages [
            page-img: get-zoomed current-page zoom
            max-sx: max 0 page-img/size/x - vp-w
            scroll-x: to integer! face/data * max-sx
            update-display
        ]
    ]
    return

    on-resize [resize-viewport]
    do [update-display]
][size: (as-pair vp-w + 40 vp-h + toolbar-h + 40)]['resize]
