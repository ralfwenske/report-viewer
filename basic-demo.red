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
fit-width?: false
scroll-y: 0
toolbar-h: 32

show-page: does [
    if all [not empty? rendered current-page >= 1 current-page <= length? rendered][
        img-f/image: pick rendered current-page
        scroll-y: 0
        page-label/text: rejoin ["Page " current-page " / " length? rendered]
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
        fit-cb: check "Fit Width" [fit-width?: fit-cb/data scroll-y: 0]
    ] react [face/size: as-pair (face/parent/size/x - 15) toolbar-h]
    return

    ; Page image
    img-f: image white
        on-wheel [
            either fit-width? [
                scroll-y: max 0 scroll-y - (event/picked/y * 40)
                max-scroll: max 0 img-f/size/y - img-f/parent/size/y + toolbar-h + 15
                scroll-y: min scroll-y max-scroll
                img-f/offset/y: 0 - scroll-y
            ][
                ; Page view: switch pages with wheel
                either event/picked/y < 0 [
                    if current-page < length? rendered [current-page: current-page + 1 show-page]
                ][
                    if current-page > 1 [current-page: current-page - 1 show-page]
                ]
            ]
        ]
        react [
            parentsize: face/parent/size
            img: face/image
            unless img [exit]
            iw: img/size/x
            ih: img/size/y
            avail-w: parentsize/x - 15
            avail-h: parentsize/y - toolbar-h - 15
            either fit-width? [
                ; Fit width: page width = viewport width, height proportional
                face/size: as-pair avail-w to-integer (avail-w * ih / iw)
                face/offset/x: 0
                ; Clamp scroll
                max-scroll: max 0 face/size/y - avail-h
                scroll-y: min scroll-y max-scroll
                face/offset/y: 0 - scroll-y
            ][
                ; Page view: fit entire page, center
                either (iw / ih) > (avail-w / avail-h) [
                    face/size: as-pair avail-w to-integer (avail-w * ih / iw)
                    face/offset/x: 0
                ][
                    face/size: as-pair to-integer (avail-h * iw / ih) avail-h
                    face/offset/x: to-integer (avail-w - face/size/x) / 2
                ]
                scroll-y: 0
                face/offset/y: 0
            ]
        ]
] ['resize]

; Keyboard: arrows for page nav and scroll
win/extra: make object! [
    on-key: func [event [event!] /local max-scroll][
        case [
            event/key = 'left  [if current-page > 1 [current-page: current-page - 1 show-page]]
            event/key = 'right [if current-page < length? rendered [current-page: current-page + 1 show-page]]
            all [fit-width? event/key = 'up] [
                scroll-y: max 0 scroll-y - 40
                img-f/offset/y: 0 - scroll-y
            ]
            all [fit-width? event/key = 'down] [
                max-scroll: max 0 img-f/size/y - img-f/parent/size/y + toolbar-h + 15
                scroll-y: min max-scroll scroll-y + 40
                img-f/offset/y: 0 - scroll-y
            ]
        ]
    ]
]

show-page
view win
