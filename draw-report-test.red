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
        ["Click " ['link-1] "for details" ['hint-1]]
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
    append rpt ["(1) test first paren"]
    append rpt ["2) test second paren"]
    append rpt ["We start a new page (if needed)"]
    append rpt [{(each 'RED' word columns tests min 10 lines for page breaks)}]
    append rpt what-columns ['b 'hint-1]
    append rpt std-footer ""
    rpt
]

hint: function [id [number!] txt [string!] /link] [
    type: either /link ["Link "] ["Hint "]
    hint-size: 680x600
    tx: (rejoin [type id ": " txt])
    help-text: split fetch-help (to word! txt) newline
    rpt: copy []
    foreach h help-text [
        either find h #":" [
            append/only rpt reduce [h [ red]]
        ][
            append/only rpt reduce [h ['b blue]]
        ]
    ]
    popup: make-viewer
    popup/paper-format hint-size
    popup/fontsize 16
    popup/margin-left: 10
    rendered: popup/generate-view rpt
    view/options/flags [
        title tx
        panel [
            box draw rendered react [face/size: face/parent/size - 20x20]
        ] react [face/size: face/parent/size - 20x30]
        return
        button "OK" focus [unview] react [face/offset: face/parent/size - 80x30]
    ][size: hint-size + 50x80][modal resize]
]

link: function [id [number!] text [string!]] [
    hint/link id text
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


;--- Generate and render all pages at native size ---
either is-landscape [report-viewer/paper-format/landscape 'a4][report-viewer/paper-format 'a4]
pages: report-viewer/generate-view pdf-report
rendered: copy []
foreach p pages [append/only rendered report-viewer/render-page p 200]
report-viewer/set-hint-delay 2
report-viewer/show-viewer/title/on-link/on-hint 
    rendered 
    "Basic Demo" 
    :link
    :hint

