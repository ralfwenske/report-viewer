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
    get-items: func [res [block!]] [repeat i 30 [append/only res reduce ["Item " i]] res]
    get-items ['COLUMN]
    'FOOTER
    []
    [['b] " Confidential " ['h3 white blue] "%DATE%" "Page %PAGE% of %PAGES%"]
]

;--- Generate report (returns draw blocks) ---
pages: generate-report rpt

;--- Viewer state ---
current-page: 1
zoom: 100
scroll-y: 0
vp-w: 600
vp-h: 820

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

;--- Zoom levels ---
zoom-levels: [25 50 75 100 125 150 200]

zoom-in: does [
    foreach z zoom-levels [if z > zoom [zoom: z break]]
    scroll-y: 0
    update-display
]

zoom-out: does [
    reverse zoom-levels
    foreach z zoom-levels [if z < zoom [zoom: z break]]
    reverse zoom-levels
    scroll-y: 0
    update-display
]

zoom-fit-width: does [
    z: to integer! vp-w / 595.0 * 100
    zoom: first zoom-levels
    foreach lz zoom-levels [if lz <= z [zoom: lz]]
    scroll-y: 0
    update-display
]

zoom-fit-page: does [
    zw: to integer! vp-w / 595.0 * 100
    zh: to integer! vp-h / 842.0 * 100
    z: min zw zh
    zoom: first zoom-levels
    foreach lz zoom-levels [if lz <= z [zoom: lz]]
    scroll-y: 0
    update-display
]

;--- Render and display ---
update-display: does [
    if any [empty? pages current-page > length? pages][exit]
    page-img: render-page pick pages current-page zoom
    full-h: page-img/size/y
    full-w: page-img/size/x

    ; Clamp scroll
    max-scroll: max 0 full-h - vp-h
    if scroll-y > max-scroll [scroll-y: max-scroll]
    if scroll-y < 0 [scroll-y: 0]

    ; Crop visible portion
    vw: min vp-w full-w
    vh: min vp-h full-h
    visible: draw as-pair vw vh [
        image page-img (as-pair 0 (0 - scroll-y)) as-pair full-w full-h
    ]
    page-display/image: visible

    ; Update UI
    page-label/text: rejoin ["Page " current-page " / " length? pages]
    zoom-label/text: rejoin [zoom "%"]

    ; Update scroller
    either full-h > vp-h [
        sc/data: either max-scroll > 0 [to float! scroll-y / max-scroll][0.0]
    ][
        sc/data: 0.0
    ]
]

;--- Build viewer UI ---
view/options compose/deep [
    title "Draw Report Viewer"
    below

    ; Toolbar row 1: page navigation
    across
    tbar: panel 0x0 [
        across
        button "<<" [current-page: 1 scroll-y: 0 update-display]
        button "<" [
            if current-page > 1 [current-page: current-page - 1]
            scroll-y: 0 update-display
        ]
        page-label: text 80x20 "Page 0 / 0" center
        button ">" [
            if current-page < length? pages [current-page: current-page + 1]
            scroll-y: 0 update-display
        ]
        button ">>" [current-page: length? pages scroll-y: 0 update-display]
        return
    ]

    ; Toolbar row 2: zoom controls
    across
    zbar: panel 0x0 [
        across
        button "-" 30x22 [zoom-out]
        zoom-label: text 50x20 "100%" center
        button "+" 30x22 [zoom-in]
        button "Fit W" [zoom-fit-width]
        button "Fit Page" [zoom-fit-page]
        return
    ]
    return

    ; Page viewport + scroller
    across
    page-display: base (as-pair vp-w vp-h) white
    sc: scroller (as-pair 16 vp-h) [
        if not empty? pages [
            page-img: render-page pick pages current-page zoom
            max-scroll: max 0 page-img/size/y - vp-h
            scroll-y: to integer! face/data * max-scroll
            update-display
        ]
    ]
    return

    do [update-display]
][size: (as-pair vp-w + 30 vp-h + 80)]
