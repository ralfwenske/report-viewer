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
current-img: none
scaled-img: none
scaled-w: 0
fit-width?: false
scroll-y: 0
toolbar-h: 32
vp-w: 600
vp-h: 800

scale-view: does [
    unless current-img [exit]
    parentsize: clip-f/parent/size
    iw: current-img/size/x
    ih: current-img/size/y
    vp-w: parentsize/x - 15
    vp-h: parentsize/y - toolbar-h - 15
    clip-f/size: as-pair vp-w vp-h
    either fit-width? [
        either any [none? scaled-img scaled-w <> vp-w][
            scaled-w: vp-w
            scaled-h: to integer! vp-w * ih / iw
            scaled-img: draw as-pair scaled-w scaled-h compose [image (current-img) 0x0 (as-pair scaled-w scaled-h)]
        ][
            scaled-h: scaled-img/size/y
        ]
        max-scroll: max 0 scaled-h - vp-h
        scroll-y: max 0 min scroll-y max-scroll
        img-f/image: scaled-img
        img-f/size: as-pair scaled-w scaled-h
        img-f/offset: as-pair 0 (0 - scroll-y)
    ][
        scaled-img: none
        img-f/image: current-img
        either (iw / ih) > (vp-w / vp-h) [
            img-f/size: as-pair vp-w to integer! vp-w * ih / iw
        ][
            img-f/size: as-pair to integer! vp-h * iw / ih  vp-h
        ]
        img-f/offset: as-pair to integer! (vp-w - img-f/size/x) / 2  0
        scroll-y: 0
    ]
]

show-page: does [
    if all [not empty? rendered current-page >= 1 current-page <= length? rendered][
        current-img: pick rendered current-page
        scaled-img: none
        scroll-y: 0
        page-label/text: rejoin ["Page " current-page " / " length? rendered]
        scale-view
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
        fit-cb: check "Fit Width" [
            fit-width?: fit-cb/data
            scroll-y: 0
            scale-view
        ]
    ] react [face/size: as-pair (face/parent/size/x - 15) toolbar-h]
    return

    clip-f: panel white 600x800 [
        img-f: image white
    ] react [face/size: as-pair (face/parent/size/x - 15) (face/parent/size/y - toolbar-h - 15)]
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
] ['resize]

show-page
view win
