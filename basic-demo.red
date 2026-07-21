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
toolbar-h: 32

show-page: does [
    if all [not empty? rendered current-page >= 1 current-page <= length? rendered][
        img-f/image: pick rendered current-page
        page-label/text: rejoin ["Page " current-page " / " length? rendered]
    ]
]

;--- Build viewer ---
win: layout/flags [
    title "Report Viewer — Page View"
    size 800x600

    ; Toolbar — scales to window width
    p: panel white 100x30 [
        across
        button "<<" [current-page: 1 show-page]
        button "<" [if current-page > 1 [current-page: current-page - 1 show-page]]
        page-label: text 120 "" center
        button ">" [if current-page < length? rendered [current-page: current-page + 1 show-page]]
        button ">>" [current-page: length? rendered show-page]
    ] react [face/size: as-pair (face/parent/size/x - 15) toolbar-h]
    return

    ; Page image — scales to fit window while maintaining aspect ratio
    img-f: image white
        react [
            parentsize: face/parent/size
            img: face/image
            unless img [exit]
            iw: img/size/x
            ih: img/size/y
            avail-w: parentsize/x - 15
            avail-h: parentsize/y - toolbar-h - 15
            either (iw / ih) > (avail-w / avail-h) [
                face/size: as-pair avail-w (avail-w * ih / iw)
                face/offset/x: 0
            ][
                face/size: as-pair (avail-h * iw / ih) avail-h
                face/offset/x: to-integer (avail-w - face/size/x) / 2
            ]
        ]
] ['resize]

; Show first page and open viewer
show-page
view win
