Red [
    File: %what-columns.red
    Title: "Provide data for report-generator-test.red"
    Exports: [what-columns]
    Note: { 
        Provides same data as 'what' funcion in red.
        Instead of using 'what/buffer' it loads that
        data from a file (%what-columns.txt) and provides it in a format suitable for report-generator-test.red (created using an extrem wide terminal).
        'what/buffer' limits data width to terminal width, which is not suitable for report generation.

            red
            --== Red 0.6.6 ==-- 
            Type HELP for starting information. 

            >> what
                %               op!           Returns what is left over when o...
                *               op!           Returns the product of two values.
                **              op!           Returns a number raised to a giv...

    }
]

what-functions: load %what-columns.txt
; structure: [["name" "type" {description}] ...]

context [
    kinds: function [
        "Returns a list of all unique kinds like op! action! function! etc."
    ] [
        result: copy []
        foreach item what-functions [
            unless find result item/2 [
                append result item/2
            ]
        ]
        result
    ] ; kinds

    filter: function [filter [string!]] [
        result: copy []
        foreach item what-functions [
            if item/2 = filter [
                append result trim item/1
            ]
        ]
        result
    ] ; filter

    set 'what-columns function [] [
        result: copy []
        foreach kind kinds [
            title: copy rejoin ["Red - " kind]
            append result reduce [
                []
                ["^L" 10]       ; 10 lines minimum for page break
                reduce [
                    title ['h2] 
                    "  shown in as many columns as fit (automatically)" ['i]]
                []
            ]
            kind-column: copy ['COLUMN * 0]
            f: copy filter kind
            repeat ix (length? f) [
                append/only kind-column reduce [f/(ix)]
            ]
            append/only result kind-column
        ]
        result
    ] ; what-columns
]