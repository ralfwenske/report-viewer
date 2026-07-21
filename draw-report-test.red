Red [
    Title: "Draw Report Viewer Test"
    Needs: 'View
]

do load %what-columns.red
do %draw-report.red

std-header: func [title [string!]] [
    reduce [
        'HEADER
        reduce [['b] "ACME Corp" ['h1 red] (title) ['h2] "%DATE%"]
        reduce ["Page %PAGE% of %PAGES%" "" "%TIME%"]
        [""]
    ]
]

std-footer: function [extra [string!]] [
    result: [
        'FOOTER
        []
        [['b] "Confidential" "%DATE%" "Page %PAGE% of %PAGES%"]
    ]
    if extra <> "" [
        append/only result reduce [extra ['i]]
    ]
    result
]

widgetC: ["Widget C" "245" ['b] 8890.00]
threethousand: 3000
total: 1890.0
zero: 0

pdf-report: function [] [
    rpt: copy std-header "Long Report Demo"
    append rpt [
        'CONTENT
        ["Sales Summary for " ['b] "Q1 2015" ['u]]
        ["Q1 sales data for all product lines. " ['u] zero ['b]]
        ["a bold monofont here" ['m 'b]]
        ["                   *" ['m 'u]]
        [""]
        ["Table with 'box 'alt" ['u 'h2]]
        ['table 'box 'alt
            ["Product" ['< 30] "Qty" ['^ 10 10.4 ] "Total" ['> 13 'money] "Status" ['^ 13]]
            ["Widget A" 120 threethousand ['b] "OK" [white 0.128.0]]
            ["Widget B" [80.150.200] "45" total "Check" [white 255.165.0]]
            widgetC
            [['b] "TOTALS" "" "$13'780.00" "All Bold"]
        ]
        [""]
        ["Table with 'box" ['u 'h2]]
        ['table 'box
            ["Product" ['< 25] "Qty" ['^ 10 10.4 ] "Total" ['> 13 'money]]
            ["Widget A" 3120 threethousand ['b] ]
            ["Widget B" "45" total]
        ]
        [""]
        ["^L" 6]
        ["Table " ['u 'h2]]
        ['table
            ["Product" ['< 20] "Qty" ['^ 10 10.4 ] "Total" ['> 13 'money]]
            ["Widget A" 120 threethousand ['b] ]
            ["Widget B" "45" total]
        ]
        [""]
    ]
    append/only rpt ["words-of system shown in columns " ['h2]]
    f-cols: copy ['COLUMN * 2]
    foreach w sort words-of system [
        append/only f-cols reduce [mold w]
    ]
    append/only rpt f-cols
    append rpt [""]
    append rpt ["(1) first paren"]
    append rpt ["2) second paren"]
    append rpt ["We start a new page (if needed)"]
    append rpt [{(each 'RED' word columns tests min 10 lines for page breaks)}]
    append rpt what-columns
    append rpt std-footer ""
    rpt
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
pages: generate-report pdf-report

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

    max-sx: max 0 full-w - vp-w
    max-sy: max 0 full-h - vp-h
    if scroll-x > max-sx [scroll-x: max-sx]
    if scroll-y > max-sy [scroll-y: max-sy]
    if scroll-x < 0 [scroll-x: 0]
    if scroll-y < 0 [scroll-y: 0]

    vw: min vp-w full-w
    vh: min vp-h full-h
    visible: draw as-pair vw vh compose [
        image page-img (as-pair (0 - scroll-x) (0 - scroll-y)) (as-pair full-w full-h)
    ]
    page-display/image: visible

    page-label/text: rejoin ["Page " current-page " / " length? pages]
    zoom-label/text: rejoin [zoom "%"]

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
