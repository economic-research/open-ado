{smcl}
{* April 17, 2019}{...}
{hline}
help for {hi:pexit}
{hline}

{title:pexit} - A module to end a dofile.

{p 8 16 2}{cmd:pexit}
[{cmd:,} 
{cmdab:debug} {cmdab:summary(}{it:string}{cmd:)}]

{p 4 4 2}
{it:pexit} closes all open logfiles if {it:debug} option is not provided. 
It is intended to be used in conjunction with {it:init}.

where

{p 8 16 2}
{it:summary} If specified stores summary stats (min, max, mean and SD). This command is ignored in {it:debug} mode.

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
