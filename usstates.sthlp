{smcl}
{* February 24, 2019}{...}
{hline}
help for {hi:usstates}
{hline}

{title:usstates} - A simple function that returns the abbreviation of US states and an numeric id.

{p 8 16 2}{cmd:usstates} {cmdab:varlist(min=1 max=1)}
{cmd:,} 
{cmdab:newvar:(}{it:string}{cmd:)} {cmdab:type:(}{it:string}{cmd:)}

{p 4 4 2}
where

{p 8 16 2}
The user supplies a variable containing either the full name of US states or an abbreviation.

{p 8 16 2}
{it:newvar} is the name of the newvariable that will be created.

{p 8 16 2}
{it:type} either "full" or "abbv" (respectively, full name and abbreviation).

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
