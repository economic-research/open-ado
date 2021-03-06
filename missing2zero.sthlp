{smcl}
{* August 18, 2019}{...}
{hline}
help for {hi:mising2zero}
{hline}

{title:missing2zero} - A module that converts missing values for either numeric or string variables.

{p 8 16 2}{cmd:missing2zero }{cmdab:varlist(all numeric or all string)} [, {cmdab:substitute(numeric or string)}
{cmdab:mean} {cmdab:bys(varlist)}]

{p 8 16 2}
By default convert missing values to zero (if numeric) or "NaN" (if string). User can specify a different value.

{p 8 16 2}
{cmdab:mean} convert numeric missing values to mean (or subgroup mean if option {cmdab:bys} is selected). Cannot be combined with string variables.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 30a15aedf15b4b2b11c37a8d142c9d797a69c4fa

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
