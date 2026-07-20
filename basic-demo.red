Red [
    File: %basic-demo.red
    Title: "Basic Draw Report Demo"
    Needs: 'View
]

unless value? 'generate-report [
    do load %draw-report.red
]

report-dir: to-file rejoin [get-current-dir %reports/]
unless exists? report-dir [make-dir report-dir]

get-items: func [res [block!]] [
    repeat i 30 [
        append/only res reduce ["Item " i]
    ]
    res
]

title: "Basic Demo"
total: 5123.87654
widget-C:  [[red] "Widget C" [12 green '>] -45 [6.2 '>]  total [red 10.3] " Check" [white 255.165.0]]
fourthousand: 4000

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
        ["Product" ['< 30] "Qty" ['^ 10 10.4 ] "Total" ['> 13 'money] "Status" ['^ 13]]
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

if system/script/args = 'landscape [
    paper-format/landscape 'a4
]

pages: generate-report rpt
current-page: 1

show-page: does [
    if all [pages current-page <= length? pages][
        page-display/image: pick pages current-page
        page-label/text: rejoin ["Page " current-page " of " length? pages]
    ]
]

view/options layout [
    title "Basic Draw Report Demo"
    below
    page-label: text 400x20 "Page 0 of 0" center
    page-display: base 595x842
    across
    button "<<" [current-page: 1 show-page]
    button "<"  [if current-page > 1 [current-page: current-page - 1 show-page]]
    button ">"  [if current-page < length? pages [current-page: current-page + 1 show-page]]
    button ">>" [current-page: length? pages show-page]
    do [show-page]
][size: 700x950]
