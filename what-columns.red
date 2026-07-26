Red [
    File:    %what-columns.red
    Title:   "Provide data for draw-report-test.red"
    Purpose: {Generate column layout data from Red's built-in
              function reference, grouped by type (op!, action!,
              function!, etc.)}
    Exports: [what-columns]
    Tabs:    4
    Note:    {
        Provides same data as 'what' function in Red.
        Instead of using 'what/buffer', it loads data from
        a file (%what-columns.txt) and formats it for use
        with draw-report-test.red. 'what/buffer' limits
        data width to terminal width, which is not suitable
        for report generation.

        Example Red console output:
            red
            --== Red 0.6.6 ==--
            Type HELP for starting information.

            >> what
                %               op!           Returns what is left over when o...
                *               op!           Returns the product of two values.
                **              op!           Returns a number raised to a giv...
    }
]

;=== Load function reference data ===
; Structure: [["name" "type" {description}] ...]

what-functions: load %what-columns.txt

context [
    kinds: function [
        "Return unique datatype names from the function list"
    ][
        result: copy []
        foreach item what-functions [
            unless find result item/2 [
                append result item/2
            ]
        ]
        result
    ]

    filter: function [
        "Return function names matching the given type"
        filter [string!] "Type name to match (e.g. 'op!')"
    ][
        result: copy []
        foreach item what-functions [
            if item/2 = filter [
                append result trim item/1
            ]
        ]
        result
    ]

    set 'what-columns function [
        "Build column layout blocks for each Red datatype"
        style [block!] "Styles to apply to each entry"
    ][
        result: copy []
        foreach kind kinds [
            title: copy rejoin ["Red - " kind]
            append result reduce [
                []
                ["^L" 10]                  ;-- 10 lines minimum for page break
                reduce [
                    title ['h2]
                    "  shown in as many columns as fit (automatically)" ['i]
                ]
                []
            ]
            kind-column: copy ['COLUMN * 0]
            f: copy filter kind
            repeat ix (length? f) [
                append/only kind-column reduce [f/(ix) style]
            ]
            append/only result kind-column
        ]
        result
    ]
]
