{smcl}
{* September 24, 2019}{...}
{hline}
help for {hi:eventin}
{hline}

{title:eventin} - A module that constructs a dummy variable that identifies overlapping periods. Intended for use with event study analysis.  

{p 8 16 2}{cmd:eventin}
{cmd:,} 
{cmdab:idvar:(}{it:varlist}{cmd:)} {cmdab:datevar:(}{it:varlist}{cmd:)} {cmdab:event:(}{it:integer}{cmd:)} {cmdab:periods:(}{it:integer}{cmd:)} 
{cmdab:name:(}{it:string}{cmd:)}

{cmd:eventin} returns a new variabled that is equal to one for periods where two events overlap, and is zero otherwise. 
More precisely, for each event window the dummy variable is equal to one if an event took place within the last number of {cmd:periods}
{it:excluding} the actual event that is considered in the time window.

{p 4 4 2}
where

{p 8 16 2}
{cmd:idvar} a variable that identifies individuals in the sample.

{p 8 16 2}
{cmd:datevar} is a date variable

{p 8 16 2}
{cmd:event} is a binary variable that captures the timing of an event. Can only be 0 or 1.

{p 8 16 2}
{cmd:periods} the number of periods that {cmd:eventin} will use to determine which periods have overlapping events.

{p 8 16 2}
{cmd:name} of new variable created.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 22337645e8782b8f608f19490638c0d50e8d30ef

{title:Authors}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
