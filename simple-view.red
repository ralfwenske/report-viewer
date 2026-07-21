Red [needs: 'view]

win: layout/flags [
    title "A4 Image Viewer"
    size 800x600
    
    p: panel white 100x50 [ 
        note: text 300 ""
    ] react [face/size: as-pair (face/parent/size/x - 15) 50]
    return
    
    img-f: image white %../report-generator/reports/PDF-Report.png
        react [ parentsize: face/parent/size 
            either (img-f/size/x / img-f/size/y) > (parentsize/x / (parentsize/y - 50)) [
                note/text: "img ratio smaller"
                img-f/size: as-pair parentsize/x ((parentsize/x ) * img-f/size/y / img-f/size/x)
                img-f/offset/x: 0
            ][
                img-f/size: as-pair ((parentsize/y - 50) * (img-f/size/x / img-f/size/y)) parentsize/y - 50
                img-f/offset/x: to-integer (parentsize/x - img-f/size/x) / 2
                note/text: rejoin ["img ratio larger " img-f/size " " img-f/parent/size]
            ] 
        ]
    
] ['resize]

view win

