{smcl}
{* April 17, 2019}{...}
{hline}
help for {hi:pexit}
{hline}

{title:pexit} - A module to end a dofile, generate a table with summary statistics and any open logfile. 
Can use {it:{help project##project:project}} to track dependencies of Input/Outputs and achieve efficient compilation of large projects.

{p 8 16 2}{cmd:pexit}
[{cmd:,} 
{cmdab:debug} {cmdab:summary(}{it:string}{cmd:)}]

{p 4 4 2}
{it:pexit} closes all open logfiles if {it:debug} option is not provided. 

where

{p 8 16 2}
{it:summary} If specified stores summary stats (min, max, mean and SD). This command is ignored in {it:debug} mode.

{cmdab:pexit} is intended to be used in conjunction with {it:{help project##project:project}}, {it:{help init##init:init}}, {it:{help psave##psave:psave}} and {it:{help puse##puse:puse}}.

{marker examples}{...}
{title:Examples}

Exit dofile, close open log files and generate a table with summary stats. Note that {it:{help init##init:init}} creates a global variable $deb with values "" (empty) or "debug". 
{it:{help init##init:init}} in "debug" mode turns off project functionality.
{phang}{cmd:. pexit, summary("./summary/auto") $deb}{p_end}

{cmdab:pexit} is intended to be used in conjunction with {it:{help project##project:project}}, {it:{help init##init:init}}, {it:{help psave##psave:psave}} and {it:{help puse##puse:puse}}. 

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 6ced919f2d7d880c6db3815aeebe834323adf211

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
