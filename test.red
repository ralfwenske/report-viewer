Red [needs: 'view]

view [
    title "A4 Image Viewer"
    size 1024x768
    
    ; on-key FIRST — binds to the window/layout, not to any face
    on-key: func [face event] [
        case [
            event/key = #"+" [print "Zoom in"]
            event/key = #"-" [print "Zoom out"]
            event/key = #"q"    [unview]
            event/key = 'escape [unview]
            true [false]
        ]
    ]
    
    ; Top white panel with button
    panel [
        white
        across
        btn-load: button "Load Image" [
            file: request-file/filter ["Image Files" %.png %.jpg]
            if file [
                img/data: load first file
                show img
            ]
        ]
    ]
    
    return
    
    ; Scrollable image area
    img-panel: panel [
        flags [scroll]
        img: image 800x600
    ]
]