Red [
    File: %draw-report.red
    Title: "Draw Report Renderer v1"
    Purpose: "Generate multi-page A4 reports using Red's draw dialect — no PostScript, no ps2pdf"
    Author: "Ralf Wenske"
    Helpers: "Kilo and MiMo-V2.5-Pro"
    Exports: [generate-report render-page paper-format fontsize]
    Date: 2026-07-20
    Needs: 'View
]

context [
    page-width: 595
    page-height: 842
    margin-left: 50
    margin-right: 50
    margin-top: 50
    margin-bottom: 50
    font-size: 12
    font-scale: 0.82
    line-height: 18
    row-padding: 4
    cell-pad: 3
    underline-offset: 2
    stroke-width: 0.5
    header-gray: 0.85
    alt-row-gray: 0.95
    default-col-width: 12

    paper-sizes: [
        a4     [595  842]
        letter [612  792]
        legal  [612 1008]
        a3     [842 1190]
        a5     [420  595]
    ]

    landscape?: false

    set 'fontsize func ["Set font size in points" size [integer!]] [
        font-size: size
        line-height: font-size + 6
    ]

    set 'paper-format func [
        "Set paper size by name. Returns none if unknown."
        name [word!] "One of: a4 letter legal a3 a5"
        /landscape "Swap width and height for horizontal orientation"
        /local sz
    ][
        sz: select paper-sizes name
        either sz [
            landscape?: landscape
            either landscape [
                page-width: sz/2
                page-height: sz/1
            ][
                page-width: sz/1
                page-height: sz/2
            ]
        ][
            print rejoin ["Unknown paper format: " name ". Valid: " mold words-of paper-sizes]
            none
        ]
    ]

    ;--- Color helpers ---

    style-fg-color: func [
        "Extract first tuple from styles as font color, or none"
        styles [block!]
        /local s
    ][
        foreach s styles [if tuple? s [return s]]
        none
    ]

    style-bg-color: func [
        "Extract second tuple from styles as background color, or none"
        styles [block!]
        /local s count
    ][
        count: 0
        foreach s styles [
            if tuple? s [
                count: count + 1
                if count = 2 [return s]
            ]
        ]
        none
    ]

    resolve-colors: func [
        "Resolve color words (e.g. red) to tuples in a style block"
        styles [block!]
        /local result s val
    ][
        result: copy []
        foreach s styles [
            case [
                word? s     [
                    val: attempt [get s]
                    either tuple? val [append result val][append result s]
                ]
                lit-word? s [append result to word! s]
                true        [append result s]
            ]
        ]
        result
    ]

    ;--- Style helpers ---

    style-has: func ["Check if style block contains target word" styles [block!] target [word!]][
        not none? find styles target
    ]

    style-align: func [
        "Extract alignment from styles ('< = L, '^ = C, '> = R), or return default"
        styles [block!] default [string!]
    ][
        case [
            find styles '< ["L"]
            find styles '^ ["C"]
            find styles '> ["R"]
            true [default]
        ]
    ]

    style-width: func ["Extract integer width from styles, or 0" styles [block!] /local s][
        foreach s styles [if integer? s [return s]]
        0
    ]

    style-heading: func ["Return heading level (1-3) from styles, or 0" styles [block!] /local s][
        foreach s styles [
            if find [h1 h2 h3] s [return case [s = 'h1 [1] s = 'h2 [2] true [3]]]
        ]
        0
    ]

    heading-size: func ["Font size for heading level (1=24, 2=18, 3=14)" hd [integer!]][
        case [hd = 1 [24] hd = 2 [18] hd = 3 [14] true [font-size]]
    ]

    max-style-size: function [
        "Largest font size from style blocks in a line/row"
        line-block [block!]
    ][
        best: font-size
        foreach v line-block [
            if block? v [
                foreach s v [
                    hd: case [s = 'h1 [1] s = 'h2 [2] s = 'h3 [3] true [0]]
                    if hd > 0 [
                        sz: heading-size hd
                        if sz > best [best: sz]
                    ]
                ]
            ]
        ]
        best
    ]

    heading-gap: func [
        "Extra spacing above a line with heading-sized segments"
        line-block [block!]
        /local sz
    ][
        sz: max-style-size line-block
        either sz > font-size [sz - font-size + 2][0]
    ]

    row-height: func [
        "Height for a table row, adapting to largest segment font"
        row [block!]
        /local sz
    ][
        sz: max-style-size row
        either sz > font-size [sz + row-padding + 1][line-height + row-padding]
    ]

    merge-styles: func [
        "Merge line-wide styles into segment styles. Segment styles take precedence."
        base [block!] "Line-wide styles (e.g. ['m])"
        override [block!] "Segment styles (e.g. ['b])"
        /local result s
    ][
        either empty? override [copy base][
            result: copy base
            foreach s override [unless find result s [append result s]]
            result
        ]
    ]

    pad-text: func [
        "Pad text to fixed width according to alignment"
        text [string!] width [integer!] align [string!]
        /local diff left-pad right-pad
    ][
        if width <= 0 [return text]
        diff: width - length? text
        if diff <= 0 [return text]
        case [
            align = "R" [
                insert/dup text " " diff
            ]
            align = "C" [
                left-pad: to integer! diff / 2
                right-pad: diff - left-pad
                insert/dup text " " left-pad
                append/dup text " " right-pad
            ]
            true [
                append/dup text " " diff
            ]
        ]
        text
    ]

    ;--- Number formatting ---

    format-number-value: function ["Format number with optional money/decimal/1000 format" val [number!] fmt [none! word! float!]][
        case [
            none? fmt [to string! val]
            fmt = 'money [
                either val < 0 [
                    rejoin ["-$" format-decimal (0 - val) 2]
                ][
                    rejoin ["$" format-decimal val 2]
                ]
            ]
            fmt = 's1000 [
                format-decimal val 0
            ]
            float? fmt [
                s: form fmt
                dpos: find s #"."
                either dpos [
                    int-width: to integer! copy/part s dpos
                    decimals: to integer! copy next dpos
                ][
                    int-width: to integer! s
                    decimals: 0
                ]
                result: format-decimal val decimals
                if (length? result) < int-width [
                    insert/dup result " " (int-width - length? result)
                ]
                result
            ]
            true [to string! val]
        ]
    ]

    format-decimal: function [
        "Format number with fixed decimals and thousand separators"
        val [number!] decimals [integer!]
    ][
        s: form val
        neg?: false
        if all [(length? s) > 0 s/1 = #"-"][
            neg?: true
            s: copy next s
        ]
        dpos: find s #"."
        either dpos [
            ipart: copy/part s dpos
            dec-part: copy next dpos
        ][
            ipart: copy s
            dec-part: copy ""
        ]
        if decimals > 0 [
            dpad: copy ""
            loop (decimals - length? dec-part) [append dpad "0"]
            dec-part: rejoin [dec-part dpad]
            if (length? dec-part) > decimals [dec-part: copy/part dec-part decimals]
        ]
        result: copy ""
        n: length? ipart
        i: 1
        foreach ch ipart [
            if all [i > 1 ((n - i + 1) // 3) = 0][append result "'"]
            append result ch
            i: i + 1
        ]
        either decimals > 0 [
            rejoin [either neg? ["-"][""] result "." dec-part]
        ][
            rejoin [either neg? ["-"][""] result]
        ]
    ]

    format-date-value: function [
        "Format date value as date, time, or datetime string"
        val [date!] fmt [word!]
    ][
        case [
            fmt = 'date [form val/date]
            fmt = 'time [
                t: form any [val/time 0:00]
                copy/part t ((length? t) - 3)
            ]
            true [
                d: form val/date
                t: form any [val/time 0:00]
                rejoin [d " " copy/part t ((length? t) - 3)]
            ]
        ]
    ]

    ;--- Parsing ---

    parse-columns: function [
        "Parse column header row: data followed by style block"
        cols [block!]
    ][
        col-titles: copy []
        col-widths: copy []
        col-aligns: copy []
        col-formats: copy []
        col-bolds: copy []
        col-blanks: copy []
        num-cols: 0
        cur-text: none

        foreach v cols [
            either block? v [
                if cur-text [
                    append col-titles cur-text
                    cur-align: "L"
                    cur-bold: false
                    cur-format: none
                    cur-width: to integer! default-col-width * font-size * 0.5
                    cur-blank: false
                    foreach s v [
                        case [
                            s = '<      [cur-align: "L"]
                            s = '^      [cur-align: "C"]
                            s = '>      [cur-align: "R"]
                            s = 'b      [cur-bold: true]
                            s = 'blank  [cur-blank: true]
                            s = 'money  [cur-format: 'money]
                            s = 's1000   [cur-format: 's1000]
                            integer? s  [cur-width: to integer! s * font-size * 0.5]
                            float? s    [cur-format: s]
                        ]
                    ]
                    append col-widths cur-width
                    append col-aligns cur-align
                    append col-formats cur-format
                    append col-bolds cur-bold
                    append col-blanks cur-blank
                    num-cols: num-cols + 1
                    cur-text: none
                ]
            ][
                case [
                    string? v  [cur-text: v]
                    word? v    [cur-text: form v]
                    integer? v [cur-text: form v]
                    float? v   [cur-text: form v]
                ]
            ]
        ]
        reduce [col-titles col-widths col-aligns col-formats col-bolds col-blanks num-cols]
    ]

    eval-val: func ["Resolve word to its value, or return as-is" v /local val][
        case [
            word? v     [val: attempt [get v] either val [val][v]]
            get-word? v [val: attempt [get v] either val [val][v]]
            true        [v]
        ]
    ]

    parse-row-segments: function [
        "Parse a row: data elements followed by style blocks. Returns [styles text ...] pairs."
        row [block!]
    ][
        result: copy []
        cur-text: none
        cur-styles: copy []
        fmt: none
        val: none

        foreach v row [
            either block? v [
                cur-styles: resolve-colors v
                fmt: none
                foreach s cur-styles [
                    if float? s [fmt: s]
                ]
                if cur-text [
                    if all [find cur-styles 'blank number? cur-text cur-text = 0][cur-text: ""]
                    if number? cur-text [
                        case [
                            find cur-styles 'money [cur-text: format-number-value cur-text 'money]
                            find cur-styles 's1000 [cur-text: format-decimal cur-text 0]
                            fmt                    [cur-text: format-number-value cur-text fmt]
                        ]
                    ]
                    if date? cur-text [
                        case [
                            find cur-styles 'date     [cur-text: format-date-value cur-text 'date]
                            find cur-styles 'time     [cur-text: format-date-value cur-text 'time]
                            find cur-styles 'datetime [cur-text: format-date-value cur-text 'datetime]
                        ]
                    ]
                    append/only result cur-styles
                    append result cur-text
                    cur-text: none
                    cur-styles: copy []
                    fmt: none
                ]
            ][
                if cur-text [
                    append/only result copy []
                    append result cur-text
                ]
                cur-text: case [
                    string? v  [v]
                    number? v  [v]
                    word? v    [
                        val: attempt [get v]
                        case [
                            none? val    [form v]
                            string? val  [val]
                            number? val  [val]
                            date? val    [val]
                            true         [form val]
                        ]
                    ]
                    true       [form v]
                ]
            ]
        ]
        if cur-text [
            append/only result copy cur-styles
            append result cur-text
        ]
        result
    ]

    parse-line: func [
        "Parse a content line block. Returns [line-styles segments]."
        line-block [block!]
        /local line-styles rest
    ][
        either all [
            not empty? line-block
            block? line-block/1
        ][
            line-styles: resolve-colors line-block/1
            rest: copy next line-block
        ][
            line-styles: copy []
            rest: line-block
        ]
        reduce [line-styles parse-row-segments rest]
    ]

    ;--- Table helpers ---

    table-modifiers: function [
        "Scan table block for modifiers. Returns [boxed? alt? col-index]"
        item [block!]
    ][
        idx: 2
        boxed?: false
        alt?: false
        col-idx: idx
        found: false
        while [all [idx <= length? item not found]][
            v: eval-val pick item idx
            case [
                v = 'box  [boxed?: true  idx: idx + 1]
                v = 'alt  [alt?: true    idx: idx + 1]
                string? v [col-idx: idx  found: true]
                true      [col-idx: idx  found: true]
            ]
        ]
        reduce [boxed? alt? col-idx]
    ]

    replace-tokens: func [
        "Replace %PAGE%, %PAGES%, %DATE%, %TIME%, %DATETIME% tokens"
        text [string!] page-num [integer!] total-pages [integer!]
        date-str [string!] time-str [string!] datetime-str [string!]
    ][
        text: copy text
        text: replace/all text "%PAGE%" to string! page-num
        text: replace/all text "%PAGES%" to string! total-pages
        text: replace/all text "%DATE%" date-str
        text: replace/all text "%TIME%" time-str
        text: replace/all text "%DATETIME%" datetime-str
        text
    ]

    ;--- Layout math ---

    col-w: does [page-width - margin-left - margin-right]

    ceil-div: func ["Integer division rounding up" a [integer!] b [integer!]][
        to integer! (a + b - 1) / b
    ]

    char-est-width: func [
        "Estimated pixel width of a character at current font-size"
        ch [char!]
    ][
        case [
            find "il1|!.,;:'-_" ch [font-size * 0.3]
            find "mwMW@%&$#"    ch [font-size * 0.7]
            true                [font-size * 0.5]
        ]
    ]

    measure-column-pixels: function [
        "Measure max pixel width across all column lines"
        col-rows [block!]
        /local mono? mx ln segs val-w si text s ch
    ][
        mono?: false
        if all [not empty? col-rows block? col-rows/1 block? col-rows/1/1][
            foreach s col-rows/1/1 [if s = 'm [mono?: true]]
        ]
        if not mono? [
            if all [not empty? col-rows block? col-rows/1][
                segs: parse-line col-rows/1
                if all [segs/1 segs/1/1 = 'm] [mono?: true]
            ]
        ]
        mx: 0
        foreach ln col-rows [
            val-w: 0
            either block? ln [
                segs: parse-line ln
                si: 2
                while [si <= length? segs/2][
                    text: segs/2/:si
                    s: either any [string? text number? text date? text][form text][mold text]
                    either mono? [
                        val-w: val-w + to integer! (length? s) * font-size * 0.60
                    ][
                        foreach ch s [val-w: val-w + char-est-width ch]
                    ]
                    si: si + 2
                ]
            ][
                if string? ln [
                    either mono? [
                        val-w: to integer! (length? ln) * font-size * 0.60
                    ][
                        foreach ch ln [val-w: val-w + char-est-width ch]
                    ]
                ]
            ]
            if val-w > mx [mx: val-w]
        ]
        to integer! mx
    ]

    ;--- Section parser ---

    parse-sections: function [
        "Parse flat content into [header content footer]."
        block [block!]
    ][
        header: none
        content: copy []
        footer: none
        current: 'content

        foreach item block [
            case [
                item = 'HEADER  [current: 'header  header: copy []]
                item = 'CONTENT [current: 'content]
                item = 'FOOTER  [current: 'footer  footer: copy []]
                true [
                    if not none? item [
                        if word? item [item: eval-val item]
                        case [
                            current = 'header  [append/only header item]
                            current = 'content [append/only content item]
                            current = 'footer  [append/only footer item]
                        ]
                    ]
                ]
            ]
        ]
        reduce [header content footer]
    ]

    is-page-break-row?: func [
        "Check if a table row is a page break marker (^L)"
        row
    ][
        all [
            block? row
            not empty? row
            string? first row
            (first row) = "^L"
        ]
    ]

    ;=========================================================================
    ; Draw-specific: font management, measurement, and emit functions
    ;=========================================================================

    page-draw: none
    current-font: none
    measure-face: none
    font-cache: make map! []
    join-x: 0
    join-y: 0

    make-font: func [
        "Create font! for style combo and size"
        styles [block!] sz [integer!]
        /local name b? i? hd spec
    ][
        b?: style-has styles 'b
        i?: style-has styles 'i
        hd: style-heading styles
        if all [hd > 0 not b? not (style-has styles 'm) not i?][b?: true]
        name: font-serif
        case [
            style-has styles 'm [name: font-fixed]
            style-has styles 's [name: font-sans-serif]
        ]
        spec: copy [name: "" size: 0]
        spec/2: name
        spec/4: to integer! sz * font-scale
        if any [b? i?] [
            append spec to set-word! "style"
            append/only spec collect [if b? [keep 'bold] if i? [keep 'italic]]
        ]
        make font! spec
    ]

    set-font: func [
        "Set current-font and update measure-face"
        styles [block!] sz [integer!]
    ][
        current-font: make-font styles sz
        unless measure-face [measure-face: make face! [size: 800x1200]]
        measure-face/font: current-font
    ]

    measure-text: func [
        "Measure pixel width of text using current font"
        text [string!]
        /local sz
    ][
        sz: size-text/with measure-face text
        to integer! sz/x
    ]

    measure-height: func [
        "Measure pixel height of current font"
        /local sz
    ][
        sz: size-text/with measure-face "Hg"
        to integer! sz/y
    ]

    to-draw-y: func [
        "Convert PS-style y (0 at bottom, increases upward) to draw y (0 at top)"
        y [integer!]
    ][
        page-height - y
    ]

    gray-to-tuple: func [
        "Convert 0.0–1.0 gray float to RGB tuple"
        g [float!]
    ][
        to tuple! reduce [to integer! g * 255 to integer! g * 255 to integer! g * 255]
    ]

    ;--- Draw emit primitives ---

    draw-rect: func [
        "Append rectangle stroke to page-draw"
        x [integer!] y [integer!] w [integer!] h [integer!]
    ][
        append page-draw compose [
            pen black fill-pen off line-width (stroke-width)
            box (as-pair x (to-draw-y y + h)) (as-pair (x + w) (to-draw-y y))
        ]
    ]

    draw-vline: func [
        "Append vertical line to page-draw"
        x [integer!] y [integer!] h [integer!]
    ][
        append page-draw compose [
            pen black line-width (stroke-width)
            line (as-pair x (to-draw-y y)) (as-pair x (to-draw-y (y + h)))
        ]
    ]

    draw-filled-rect: func [
        "Append filled rectangle to page-draw"
        x [integer!] y [integer!] w [integer!] h [integer!] gray [float!]
    ][
        append page-draw compose [
            fill-pen (gray-to-tuple gray) pen off
            box (as-pair x (to-draw-y (y + h))) (as-pair (x + w) (to-draw-y y))
        ]
    ]

    draw-text-simple: func [
        "Append positioned text to page-draw (left-aligned)"
        x [integer!] y [integer!] text [string!] fg [tuple!]
    ][
        append page-draw compose [
            pen (fg) font (current-font)
            text (as-pair x (to-draw-y y)) (text)
        ]
    ]

    draw-image-func: func [
        "Append image to page-draw"
        x [integer!] y [integer!] display-w [integer!] display-h [integer!] file [file!]
        /local img
    ][
        img: attempt [load file]
        unless img [
            print rejoin ["Warning: cannot load image " file]
            return false
        ]
        append page-draw compose [
            image (img)
                (as-pair x (to-draw-y y))
                (as-pair display-w display-h)
        ]
        true
    ]

    ;--- Draw styled text (the big one) ---

    draw-styled-text: func [
        "Render text with style-aware font, alignment, colors, underline"
        x [integer!] y [integer!] text [string!]
        col-w-arg [integer!] align [string!] styles [block!]
        /join "Continue from join-x/join-y position"
        /local any-style? pad-w bg fg sz fh tw dx ul-x
    ][
        if (length? text) = 0 [exit]

        any-style?: any [
            style-has styles 'b
            style-has styles 'i
            style-has styles 'u
            style-has styles 'm
            (style-heading styles) > 0
        ]
        bg: style-bg-color styles
        fg: any [style-fg-color styles 0.0.0]
        sz: heading-size style-heading styles

        either any-style? [set-font styles sz][set-font [] font-size]
        fh: measure-height
        tw: measure-text text

        either join [
            pad-w: style-width styles
            if pad-w > 0 [text: pad-text copy text pad-w align]
            tw: measure-text text

            if bg [
                append page-draw compose [
                    fill-pen (bg) pen off
                    box (as-pair join-x ((to-draw-y join-y) - fh - 2))
                        (as-pair (join-x + tw) ((to-draw-y join-y) + 4))
                ]
            ]

            ul-x: join-x

            append page-draw compose [
                pen (fg) font (current-font)
                text (as-pair join-x ((to-draw-y join-y) - fh)) (text)
            ]

            join-x: join-x + tw

            if all [any-style? style-has styles 'u][
                append page-draw compose [
                    pen (fg)
                    line (as-pair ul-x ((to-draw-y join-y) + 2))
                         (as-pair (ul-x + tw) ((to-draw-y join-y) + 2))
                ]
            ]
        ][
            pad-w: style-width styles
            if pad-w > 0 [text: pad-text copy text pad-w align]
            tw: measure-text text

            if bg [
                append page-draw compose [
                    fill-pen (bg) pen off
                    box (as-pair x ((to-draw-y y) - fh - 2))
                        (as-pair (x + tw) ((to-draw-y y) + 4))
                ]
            ]

            dx: x
            case [
                align = "C" [dx: x + to integer! (col-w-arg - tw) / 2]
                align = "R" [dx: x + col-w-arg - tw]
            ]
            append page-draw compose [
                pen (fg) font (current-font)
                text (as-pair dx ((to-draw-y y) - fh)) (text)
            ]

            if all [any-style? style-has styles 'u][
                ul-x: dx
                append page-draw compose [
                    pen (fg)
                    line (as-pair ul-x ((to-draw-y y) + 2))
                         (as-pair (ul-x + tw) ((to-draw-y y) + 2))
                ]
            ]

            if any-style? [set-font [] font-size]
        ]
    ]

    ;--- Content/header/footer line renderers ---

    draw-content-line: func [
        "Render a content line with parsed styles and segments"
        line-block [block!] page-y [integer!]
        /local parsed line-styles segments nsegs styles text i
    ][
        parsed: parse-line line-block
        line-styles: parsed/1
        segments: parsed/2
        nsegs: (length? segments) / 2
        if nsegs > 0 [
            either nsegs = 1 [
                styles: merge-styles line-styles segments/1
                text: segments/2
                if any [number? text date? text] [text: form text]
                draw-styled-text margin-left page-y text col-w (style-align styles "L") styles
            ][
                join-x: margin-left
                join-y: page-y
                i: 1
                while [i <= length? segments][
                    styles: merge-styles line-styles pick segments i
                    text: pick segments (i + 1)
                    if any [number? text date? text] [text: form text]
                    draw-styled-text/join margin-left page-y text col-w (style-align styles "L") styles
                    i: i + 2
                ]
            ]
        ]
    ]

    draw-header-line: function [
        "Render a header/footer line with positional alignment (1st=L, 2nd=C, 3rd=R)"
        y [integer!] line-block [block!]
        page-num [integer!] total-pages [integer!]
        date-str [string!] time-str [string!] datetime-str [string!]
        /default-style def-styles [block!]
        /skip-tokens "Don't replace tokens; deferred for later"
    ][
        parsed: parse-line line-block
        line-styles: parsed/1
        segments: parsed/2
        nsegs: (length? segments) / 2
        if nsegs > 0 [
            repeat idx nsegs [
                styles: merge-styles line-styles pick segments ((idx - 1) * 2 + 1)
                text: pick segments (idx * 2)
                if number? text [text: form text]
                align: case [idx = 1 ["L"] idx = 2 ["C"] idx = 3 ["R"] true ["L"]]
                either skip-tokens [
                    text: replace/all text "%DATE%" date-str
                    text: replace/all text "%TIME%" time-str
                    text: replace/all text "%DATETIME%" datetime-str
                ][
                    text: replace-tokens text page-num total-pages date-str time-str datetime-str
                ]
                either all [empty? styles default-style][
                    draw-styled-text margin-left y text col-w align def-styles
                ][
                    draw-styled-text margin-left y text col-w align styles
                ]
            ]
        ]
    ]

    draw-header: func [
        "Render header block at top of page, return updated page-y"
        hdr [block! none!] page-y [integer!]
        date-str [string!] time-str [string!] datetime-str [string!]
        /local line
    ][
        if none? hdr [return page-y]
        foreach line hdr [
            either block? line [
                draw-header-line/skip-tokens/default-style page-y line 0 0 date-str time-str datetime-str ['b]
            ][
                draw-styled-text margin-left page-y line col-w "L" ['b]
            ]
            page-y: page-y - line-height
        ]
        set-font [] font-size
        page-y
    ]

    draw-footer: func [
        "Render footer block at bottom of page"
        ftr [block! none!] page-num [integer!] total-pages [integer!]
        date-str [string!] time-str [string!] datetime-str [string!]
        /local ftr-y line
    ][
        if none? ftr [exit]
        ftr-y: margin-bottom + ((length? ftr) * line-height)
        foreach line ftr [
            either block? line [
                draw-header-line ftr-y line page-num total-pages date-str time-str datetime-str
            ][
                draw-styled-text margin-left ftr-y (replace-tokens line page-num total-pages date-str time-str datetime-str) col-w "L" []
            ]
            ftr-y: ftr-y - line-height
        ]
    ]

    ;--- Table rendering ---

    header-row-h: does [line-height + row-padding]

    draw-table-row: function [
        "Render a table row (header or data)"
        y [integer!] rh [integer!]
        tl [integer!] tw [integer!] boxed? [logic!] alt? [logic!]
        is-header [logic!] row-num [integer!]
        col-info [block!] row [block!]
    ][
        box-top: y - rh
        text-y: box-top + row-padding

        col-titles:  col-info/1
        col-widths:  col-info/2
        col-aligns:  col-info/3
        col-formats: col-info/4
        col-bolds:   col-info/5
        col-blanks:  col-info/6
        num-cols:    col-info/7

        either is-header [
            draw-filled-rect tl box-top tw rh header-gray
        ][
            if all [alt? (row-num // 2) = 0] [
                draw-filled-rect tl box-top tw rh alt-row-gray
            ]
        ]

        either all [not empty? row block? row/1][
            row-styles: resolve-colors row/1
            col-styles: parse-row-segments copy next row
        ][
            row-styles: copy []
            col-styles: parse-row-segments row
        ]

        col-x: tl
        col-i: 1
        while [col-i <= num-cols][
            c-w: pick col-widths col-i
            col-align: pick col-aligns col-i
            col-format: pick col-formats col-i

            either is-header [
                col-text: pick col-titles col-i
                draw-styled-text (col-x + cell-pad) text-y col-text (c-w - (cell-pad * 2)) col-align ['b]
            ][
                styles: either col-i <= ((length? col-styles) / 2) [
                    pick col-styles ((col-i - 1) * 2 + 1)
                ][copy []]
                foreach s row-styles [unless find styles s [append/only styles s]]
                raw-val: either col-i <= ((length? col-styles) / 2) [
                    pick col-styles (col-i * 2)
                ][none]

                final-styles: copy []
                if pick col-bolds col-i [append final-styles 'b]
                foreach s styles [unless any [find final-styles s  s = 'blank  s = 's1000  s = 'money] [append final-styles s]]

                text: case [
                    none? raw-val   [""]
                    all [pick col-blanks col-i number? raw-val raw-val = 0] [""]
                    all [find styles 'blank number? raw-val raw-val = 0] [""]
                    string? raw-val [raw-val]
                    number? raw-val [
                        either col-format [
                            format-number-value raw-val col-format
                        ][
                            cell-fmt: none
                            foreach s styles [if float? s [cell-fmt: s]]
                            case [
                                find styles 'money [format-number-value raw-val 'money]
                                find styles 's1000 [format-decimal raw-val 0]
                                cell-fmt           [format-number-value raw-val cell-fmt]
                                true               [form raw-val]
                            ]
                        ]
                    ]
                    date? raw-val   [
                        case [
                            find styles 'date     [format-date-value raw-val 'date]
                            find styles 'time     [format-date-value raw-val 'time]
                            find styles 'datetime [format-date-value raw-val 'datetime]
                            true                  [form raw-val]
                        ]
                    ]
                    true            [form raw-val]
                ]
                    cell-bg: style-bg-color final-styles
                    if cell-bg [
                        append page-draw compose [
                            fill-pen (cell-bg) pen off
                            box (as-pair col-x (to-draw-y (box-top + rh))) (as-pair (col-x + c-w) (to-draw-y box-top))
                        ]
                    ]
                    draw-styled-text (col-x + cell-pad) text-y text (c-w - (cell-pad * 2)) (style-align final-styles col-align) final-styles
            ]
            col-x: col-x + c-w
            col-i: col-i + 1
        ]

        if boxed? [draw-rect tl box-top tw rh]

        col-x: tl
        col-i: 2
        while [col-i <= num-cols][
            c-w: pick col-widths (col-i - 1)
            col-x: col-x + c-w
            draw-vline col-x box-top rh
            col-i: col-i + 1
        ]
    ]

    ;--- Token replacement in draw blocks ---

    replace-tokens-in-draw: func [
        "Replace tokens in all strings within a draw block"
        blk [block!] page-num [integer!] total-pages [integer!]
        date-str [string!] time-str [string!] datetime-str [string!]
        /local i v
    ][
        i: 1
        while [i <= length? blk][
            v: pick blk i
            case [
                string? v [
                    replace/all v "%PAGES%" to string! total-pages
                    replace/all v "%PAGE%" to string! page-num
                    replace/all v "%DATE%" date-str
                    replace/all v "%TIME%" time-str
                    replace/all v "%DATETIME%" datetime-str
                ]
                block? v [
                    replace-tokens-in-draw v page-num total-pages date-str time-str datetime-str
                ]
            ]
            i: i + 1
        ]
    ]

    ;=========================================================================
    ; Main entry point
    ;=========================================================================

    set 'generate-report func [
        "Generate a multi-page report using draw dialect. Returns block of image!"
        content [block!] "Content block with 'HEADER 'CONTENT 'FOOTER sections"
        /local sections hdr ctn ftr
            usable-top usable-bottom page-bottom
            date-str time-str datetime-str
            pages page-num page-y new-page
            item mods boxed? alt? table-col-idx table-columns rows-start
            table-rows ci row-item col-info table-left table-width row-h
            table-total-h row-num
            col-col-w col-gap col-rows col-total col-num col-idx col-remaining
            col-rows-per-col col-avail col-cols-fit col-rendered
            col-ci col-ri col-r col-emit-y col-offset col-draw saved-pd
            img-file img-obj img-display-w img-display-h max-page-h
            pn total-pages result
    ][
        sections: parse-sections content
        hdr: sections/1
        ctn: sections/2
        ftr: sections/3

        usable-top: page-height - margin-top
        usable-bottom: margin-bottom
        page-bottom: usable-bottom + either ftr [(length? ftr) * line-height][0]

        date-str: form now/date
        time-str: copy/part form now/time ((length? form now/time) - 3)
        datetime-str: rejoin [date-str " " time-str]

        pages: copy []
        page-draw: copy []
        page-num: 1
        set-font [] font-size

        page-y: usable-top
        page-y: draw-header hdr page-y date-str time-str datetime-str

        new-page: does [
            append/only pages page-draw
            page-num: page-num + 1
            page-draw: copy []
            set-font [] font-size
            page-y: usable-top
            page-y: draw-header hdr page-y date-str time-str datetime-str
        ]

        foreach item ctn [
            either block? item [
                either all [not empty? item item/1 = 'table][
                    mods: table-modifiers item
                    boxed?: mods/1
                    alt?: mods/2
                    table-col-idx: mods/3
                    table-columns: pick item table-col-idx
                    rows-start: table-col-idx + 1

                    table-rows: copy []
                    ci: rows-start
                    while [ci <= length? item][
                        append/only table-rows eval-val pick item ci
                        ci: ci + 1
                    ]

                    col-info: parse-columns table-columns

                    table-left: margin-left
                    table-width: 0
                    foreach w col-info/2 [table-width: table-width + w]

                    row-h: header-row-h

                    table-total-h: row-h
                    forall table-rows [
                        row-item: first table-rows
                        either is-page-break-row? row-item [
                            table-total-h: table-total-h + row-h
                        ][
                            table-total-h: table-total-h + row-height row-item
                        ]
                    ]

                    if (page-y - table-total-h - line-height) < page-bottom [new-page]

                    draw-table-row page-y row-h table-left table-width boxed? alt? true 0 col-info []
                    page-y: page-y - row-h

                    row-num: 0
                    forall table-rows [
                        row-item: first table-rows
                        row-h: row-height row-item
                        either is-page-break-row? row-item [
                            new-page
                            row-h: header-row-h
                            draw-table-row page-y row-h table-left table-width boxed? alt? true 0 col-info []
                            page-y: page-y - row-h
                        ][
                            if (page-y - row-h) < page-bottom [
                                new-page
                                row-h: header-row-h
                                draw-table-row page-y row-h table-left table-width boxed? alt? true 0 col-info []
                                page-y: page-y - row-h
                                row-h: row-height row-item
                            ]

                            row-num: row-num + 1
                            draw-table-row page-y row-h table-left table-width boxed? alt? false row-num col-info row-item
                            page-y: page-y - row-h
                        ]
                    ]
                    page-y: page-y - line-height
                ][
                    either all [
                        not empty? item
                        item/1 = 'column
                    ][
                        ;--- Column layout ---
                        either all [(length? item) >= 3 number? item/2 number? item/3][
                            col-col-w: to integer! item/2 * font-size * 0.5
                            col-gap: to integer! item/3 * font-size * 0.5
                            col-rows: copy []
                            ci: 4
                            while [ci <= length? item][
                                append/only col-rows pick item ci
                                ci: ci + 1
                            ]
                        ][
                            either all [(length? item) >= 3 item/2 = '* integer? item/3][
                                col-gap: to integer! item/3 * font-size * 0.5
                                col-rows: copy []
                                ci: 4
                                while [ci <= length? item][
                                    append/only col-rows pick item ci
                                    ci: ci + 1
                                ]
                            ][
                                col-gap: 0
                                col-rows: copy []
                                ci: 2
                                while [ci <= length? item][
                                    append/only col-rows pick item ci
                                    ci: ci + 1
                                ]
                            ]
                            col-col-w: measure-column-pixels col-rows
                            if col-gap < to integer! 1 * font-size * 0.5 [col-gap: to integer! 1 * font-size * 0.5]
                        ]
                        col-total: length? col-rows
                        col-num: to integer! (page-width - margin-left - margin-right) / (col-col-w + col-gap)
                        if col-num < 1 [col-num: 1]
                        col-idx: 1
                        col-remaining: col-total
                        while [col-remaining > 0][
                            col-rows-per-col: ceil-div col-remaining col-num
                            col-avail: to integer! (page-y - page-bottom) / line-height
                            if col-avail < 1 [new-page col-avail: to integer! (page-y - page-bottom) / line-height]
                            either col-rows-per-col <= col-avail [
                                col-cols-fit: col-num
                            ][
                                col-rows-per-col: col-avail
                                col-cols-fit: col-num
                            ]
                            col-rendered: 0
                            repeat col-ci col-cols-fit [
                                col-offset: (col-ci - 1) * (col-col-w + col-gap)
                                col-draw: copy []
                                saved-pd: page-draw
                                page-draw: col-draw
                                repeat col-ri col-rows-per-col [
                                    col-r: col-idx + ((col-ci - 1) * col-rows-per-col) + col-ri - 1
                                    if col-r <= col-total [
                                        col-emit-y: page-y - ((col-ri - 1) * line-height)
                                        draw-content-line col-rows/:col-r col-emit-y
                                        col-rendered: col-rendered + 1
                                    ]
                                ]
                                page-draw: saved-pd
                                if not empty? col-draw [
                                    append page-draw reduce ['push reduce ['translate as-pair col-offset 0 col-draw]]
                                ]
                            ]
                            col-idx: col-idx + col-rendered
                            col-remaining: col-remaining - col-rendered
                            page-y: page-y - (col-rows-per-col * line-height)
                            if col-remaining > 0 [new-page]
                        ]
                    ][
                        either all [
                            not empty? item
                            (length? item) = 3
                            item/1 = 'IMAGE
                            integer? item/2
                            any [file? item/3 string? item/3]
                        ][
                            ;--- Image: ['IMAGE display-width %file] ---
                            img-file: to file! item/3
                            img-obj: attempt [load img-file]
                            either img-obj [
                                img-display-w: item/2
                                img-display-h: to integer! img-display-w * img-obj/size/y / img-obj/size/x
                                max-page-h: usable-top - page-bottom
                                if img-display-h > max-page-h [
                                    img-display-w: to integer! img-display-w * max-page-h / img-display-h
                                    img-display-h: max-page-h
                                ]
                                if (page-y - img-display-h) < page-bottom [new-page]
                                draw-image-func margin-left page-y img-display-w img-display-h img-file
                                page-y: page-y - img-display-h - 8
                            ][
                                print rejoin ["Warning: unsupported or unreadable image: " img-file]
                            ]
                        ][
                        either all [
                            not empty? item
                            string? first item
                            (first item) = "^L"
                            (length? item) > 1
                            number? item/2
                        ][
                            if (page-y - (item/2 * line-height)) < page-bottom [new-page]
                        ][
                            page-y: page-y - heading-gap item
                            if (page-y - line-height) < page-bottom [new-page]
                            draw-content-line item page-y
                            page-y: page-y - line-height
                        ]
                    ]
                ]
            ]
            ][
                if string? item [
                    if item = "^L" [new-page continue]
                    if (page-y - line-height) < page-bottom [new-page]
                    draw-content-line reduce [item] page-y
                    page-y: page-y - line-height
                ]
            ]
        ]

        append/only pages page-draw
        total-pages: length? pages

        ;--- Token replacement: walk each page's draw block, replace in strings ---
        pn: 0
        foreach page pages [
            pn: pn + 1
            replace-tokens-in-draw page pn total-pages date-str time-str datetime-str
        ]


        ;--- Draw footer on each page (needs %PAGES% which is now known) ---
        pn: 0
        foreach page pages [
            pn: pn + 1
            page-draw: page
            draw-footer ftr pn total-pages date-str time-str datetime-str
        ]


        ;--- Return draw blocks; use render-page to render at any zoom ---
        pages
    ]

    set 'render-page function [
        "Render a page draw block at given zoom percent (100 = native size)"
        page-block [block!] zoom [integer!]
    ][
        z: zoom / 100.0
        sz: as-pair to integer! page-width * z  to integer! page-height * z
        draw sz compose/deep [scale (z) (z) (page-block)]
    ]

    set 'get-page-width does [page-width]
    set 'get-page-height does [page-height]

    set 'show-viewer function [
        "Display rendered pages in a viewer window with navigation and zoom"
        rendered [block!] "Block of image! (one per page, from render-page)"
        /title window-title [string!] "Window title"
    ][
        current-page: 1
        current-img: none
        scaled-img: none
        scaled-w: 0
        fit-width?: false
        scroll-y: 0
        toolbar-h: 50

        scale-view: does [
            unless current-img [exit]
            parentsize: clip-f/parent/size
            vp-w: parentsize/x - 18
            vp-h: parentsize/y - toolbar-h - 30
            if any [vp-w < 50 vp-h < 50][exit]
            clip-f/size: as-pair vp-w vp-h
            iw: current-img/size/x
            ih: current-img/size/y
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

        update-buttons: does [
            btn-first/enabled?: current-page > 1
            btn-prev/enabled?: current-page > 1
            btn-next/enabled?: current-page < length? rendered
            btn-last/enabled?: current-page < length? rendered
        ]

        show-page: does [
            if all [not empty? rendered current-page >= 1 current-page <= length? rendered][
                current-img: pick rendered current-page
                scaled-img: none
                scroll-y: 0
                page-label/text: rejoin ["Page " current-page " / " length? rendered]
                update-buttons
                scale-view
            ]
        ]
        a-title: (either title [window-title]["Report Viewer"])
        win: layout/flags  [
            title a-title
            size 800x600
            on-key [
                case [
                    all [event/ctrl? event/key = 'left]  [current-page: 1 show-page]
                    all [event/ctrl? event/key = 'right] [current-page: length? rendered show-page]
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
            p: panel white 100x50 [
                across
                btn-first: button "<<" [current-page: 1 show-page]
                btn-prev: button "<" [if current-page > 1 [current-page: current-page - 1 show-page]]
                page-label: text 120 "" center
                btn-next: button ">" [if current-page < length? rendered [current-page: current-page + 1 show-page]]
                btn-last: button ">>" [current-page: length? rendered show-page]
                pad 10x0
                fit-cb: check "Fit Width" [
                    fit-width?: fit-cb/data
                    scroll-y: 0
                    scale-view
                ]
            ] react [face/size: as-pair (face/parent/size/x - 18) toolbar-h]
            return

            clip-f: panel white 600x800 [
                img-f: image white
            ]
                on-wheel [
                    delta: either event/picked [event/picked][0]
                    either fit-width? [
                        scroll-y: scroll-y - (30 * delta)
                        scale-view
                    ][
                        either delta < 0 [
                            if current-page < length? rendered [current-page: current-page + 1 show-page]
                        ][
                            if current-page > 1 [current-page: current-page - 1 show-page]
                        ]
                    ]
                ]
                react [
                    face/size: as-pair (face/parent/size/x - 18) (face/parent/size/y - toolbar-h - 20)
                    scale-view
                ]
                do [show-page]
        ] ['resize]

        view win 
    ] ; show-viewer

];context
