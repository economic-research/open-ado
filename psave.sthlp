{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:psave} - A module that saves to CSV, DTA and documents dependencies using {it:{help project##project:project}} to track dependencies of Input/Outputs and achieve efficient compilation of large projects.

{p 8 16 2}{cmd:psave}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:com} {cmdab:csvnone} {cmdab:debug} {cmdab:eopts:(}{it:string}{cmd:)} {cmdab:preserve}]

{p 4 4 2}
where

{p 8 16 2}
{it:com} compresses the database to save space without losing precission. Regardless of user input {it:psave} will perform that operation if there are more than 1 million observations.

{p 8 16 2}
{it:csvnone} Don't store results in CSV format. If debug mode isn't specified will register DTA with project.

{p 8 16 2}
{it:debug} prevents psave from using {cmdab:project} functionality. In debug mode {it: psave} will not save a CSV file.

{p 8 16 2}
{it:eopts} refers to standard options of {cmdab:export delimited}.

{p 8 16 2}
{it:preserve} avoids clearing local memory.

{marker examples}{...}
{title:Examples}

Save DTA and CSV files with names "auto.dta" and "auto.csv", respectively. Note that {it:{help init##init:init}} creates a global variable $deb with values "" (empty) or "debug". 
{it:{help init##init:init}} in "debug" mode turns off project functionality.
{phang}{cmd:. psave, file("../constructed-data/auto") $deb }{p_end}

{cmdab:psave} is intended to be used in conjunction with {it:{help project##project:project}}, {it:{help init##init:init}}, {it:{help pexit##pexit:pexit}} and {it:{help puse##puse:puse}}.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: abbe57645ec8c21103eb21e68ba5603044e2d4e5

{title:Authors}

{p 4} Andres Jurado and Lorenzo Aldeco {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
