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

;--- Generate and render all pages at native size ---
pages: generate-report pdf-report
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

    img-f: image white
        on-wheel [
            either fit-width? [
                scroll-y: max 0 scroll-y - (event/picked/y * 40)
                max-scroll: max 0 img-f/size/y - img-f/parent/size/y + toolbar-h + 15
                scroll-y: min scroll-y max-scroll
                img-f/offset/y: 0 - scroll-y
            ][
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
                face/size: as-pair avail-w to-integer (avail-w * ih / iw)
                face/offset/x: 0
                max-scroll: max 0 face/size/y - avail-h
                scroll-y: min scroll-y max-scroll
                face/offset/y: 0 - scroll-y
            ][
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
