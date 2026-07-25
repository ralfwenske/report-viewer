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
    [['h2 'u] "Serif (default) " "sans-serif " ['s] "['s] " ['s blue] "mono " ['m] "['m]" ['m blue]]
    ['COLUMN 33 3
        ["Generated on " ['i] "%DATE%"]
        ["Generated on " ['i] now [14 'date '>]]
        [['m] "Generated on " ['i] "%DATE%"]
        [['m] "Generated on " ['i] now [14 'date '>]]
    ]
    [['m] " Sample content goes here. " [white purple] " And yellow here " [black yellow]]
    ["Details 1" ['u 'hint-1] " — hover for info"]
    ["Details 2" ['u 'hint-2] " — hover for info"]
    ["First Link" ['u 'link-1] " — click link"]
    ["Second Link" ['u 'link-2] " — click link"]
    ["Table with 'box 'alt" ['u 'h2]]
    ['TABLE 'BOX 'ALT
        ["Product" ['< 30] "Qty" ['^ 10 10.4] "Total" ['> 13 'money] "Status" ['^ 13]]
        ["Widget A" ['link-1] 120 threethousand ['b] "OK" [white 80.128.80]]
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

hint: function [id [number!] text [string!] /link] [
    type: either link ["link "] ["hint "]
    hint-size: 480x200
    popup-title: (rejoin [type id ": " text])
    rpt: copy []
    append/only rpt [text ['h1 green]]
    if id = 2 [
        append/only rpt [ [h3 'u red] "This is marked as " type "-2"]
    ]
    popup: make-viewer
    popup/paper-format hint-size
    popup/fontsize 12
    rendered: popup/generate-view rpt
    view/options/flags [
        title popup-title
        box hint-size draw rendered 
        return
        button "OK" focus [unview] react [face/offset: face/parent/size - 88x30]
    ][size: hint-size + 20x80][ resize]
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
][size: 280x100]


;--- Generate and render all pages at native size ---
either is-landscape [report-viewer/paper-format/landscape 'a4][report-viewer/paper-format 'a4]
pages: report-viewer/generate-view rpt
rendered: copy []
foreach p pages [append/only rendered report-viewer/render-page p 200]
report-viewer/set-hint-delay 2
report-viewer/show-viewer/title/on-link/on-hint 
    rendered 
    "Basic Demo" 
    :link
    :hint

