Red [needs: 'view]

view [
    title "A4 Image Viewer"
    size 1024x768
    
    ; on-key FIRST — binds to the window/layout, not to any face
    on-key [
        case [
            event/key = #"+" [print "Zoom in"]
            event/key = #"-" [print "Zoom out"]
            event/key = #"q"    [unview]
            event/key = 'escape [unview]
            true [false]
        ]
    ]
    
    ; Top white panel with button
    panel  white [
        across
        btn-load: button "Load Image" [
            file: request-file
            probe file
            if file [
                img/data: to image! load first file
                show img
            ]
        ]
    ]
    return
    
    ; Scrollable image area
    img-panel: panel [
        img: image 800x600
    ]
]