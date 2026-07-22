Red [needs: 'view]

do %draw-report.red

;--- Report content ---
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

;--- Generate and render all pages at native size ---
pages: generate-report rpt
rendered: copy []
foreach p pages [append/only rendered render-page p 100]

;--- Viewer state ---
current-page: 1
current-img: none
fit-width?: false
scroll-y: 0
toolbar-h: 32

scale-view: does [
    unless current-img [exit]
    parentsize: img-f/parent/size
    iw: current-img/size/x
    ih: current-img/size/y
    avail-w: parentsize/x - 15
    avail-h: parentsize/y - toolbar-h - 15
    either fit-width? [
        scaled-h: to integer! avail-w * ih / iw
        max-scroll: max 0 scaled-h - avail-h
        scroll-y: max 0 min scroll-y max-scroll
        ; Scale full page to viewport width, then crop visible portion
        scaled: draw as-pair avail-w scaled-h compose [image (current-img) 0x0 (as-pair avail-w scaled-h)]
        img-f/image: draw as-pair avail-w avail-h compose [image (scaled) (as-pair 0 (0 - scroll-y)) (as-pair avail-w scaled-h)]
        img-f/size: as-pair avail-w avail-h
        img-f/offset/x: 0
    ][
        img-f/image: current-img
        either (iw / ih) > (avail-w / avail-h) [
            img-f/size: as-pair avail-w to integer! avail-w * ih / iw
            img-f/offset/x: 0
        ][
            img-f/size: as-pair to integer! avail-h * iw / ih  avail-h
            img-f/offset/x: to integer! (avail-w - img-f/size/x) / 2
        ]
        scroll-y: 0
    ]
]

show-page: does [
    if all [not empty? rendered current-page >= 1 current-page <= length? rendered][
        current-img: pick rendered current-page
        scroll-y: 0
        page-label/text: rejoin ["Page " current-page " / " length? rendered]
        scale-view
    ]
]

;--- Build viewer ---
win: layout/flags [
    title "Report Viewer"
    size 800x600

    ; Toolbar
    p: panel white 100x30 [
        across
        button "<<" [current-page: 1 show-page]
        button "<" [if current-page > 1 [current-page: current-page - 1 show-page]]
        page-label: text 120 "" center
        button ">" [if current-page < length? rendered [current-page: current-page + 1 show-page]]
        button ">>" [current-page: length? rendered show-page]
        pad 10x0
        fit-cb: check "Fit Width" [
            fit-width?: fit-cb/data
            scroll-y: 0
            scale-view
        ]
    ] react [face/size: as-pair (face/parent/size/x - 15) toolbar-h]
    return

    ; Page image
    img-f: image white
        on-wheel [
            delta: either pair? event/picked [event/picked/y][to integer! event/picked]
            either fit-width? [
                scroll-y: scroll-y - (delta * 30)
                scale-view
            ][
                either delta < 0 [
                    if current-page < length? rendered [current-page: current-page + 1 show-page]
                ][
                    if current-page > 1 [current-page: current-page - 1 show-page]
                ]
            ]
        ]
        on-key [
            case [
                event/key = 'left  [if current-page > 1 [current-page: current-page - 1 show-page]]
                event/key = 'right [if current-page < length? rendered [current-page: current-page + 1 show-page]]
                all [fit-width? event/key = 'up] [
                    scroll-y: max 0 scroll-y - 40
                    scale-view
                ]
                all [fit-width? event/key = 'down] [
                    scroll-y: scroll-y + 40
                    scale-view
                ]
            ]
        ]
        react [
            face/parent/size
            scale-view
        ]
] ['resize]

show-page
view win
