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
scroll-y: 0
vp-w: 600
vp-h: 820

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

update-display: does [
    if any [empty? pages current-page > length? pages][exit]
    page-img: render-page pick pages current-page zoom
    full-h: page-img/size/y
    full-w: page-img/size/x
    max-scroll: max 0 full-h - vp-h
    if scroll-y > max-scroll [scroll-y: max-scroll]
    if scroll-y < 0 [scroll-y: 0]
    vw: min vp-w full-w
    vh: min vp-h full-h
    visible: draw as-pair vw vh [
        image page-img (as-pair 0 (0 - scroll-y)) as-pair full-w full-h
    ]
    page-display/image: visible
    page-label/text: rejoin ["Page " current-page " / " length? pages]
    zoom-label/text: rejoin [zoom "%"]
    either full-h > vp-h [
        sc/data: either max-scroll > 0 [to float! scroll-y / max-scroll][0.0]
    ][
        sc/data: 0.0
    ]
]

view/options compose/deep [
    title "Draw Report Viewer"
    below
    across
    panel 0x0 [
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
    panel 0x0 [
        across
        button "-" 30x22 [zoom-out]
        zoom-label: text 50x20 "100%" center
        button "+" 30x22 [zoom-in]
        button "Fit W" [zoom-fit-width]
        button "Fit Page" [zoom-fit-page]
        return
    ]
    return
    across
    page-display: base (as-pair vp-w vp-h) white
    sc: scroller 16x(vp-h) [
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
