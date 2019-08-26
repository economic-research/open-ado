{smcl}
{* August 26, 2019}{...}
{hline}
help for {hi:tsperiods}
{hline}

{title:tsperiods} - A module that divides a panel dataset into equisized periods, with zero denoting the date of an event.  

{p 8 16 2}{cmd:tsperiods}
{cmd:,} 
{cmdab:datevar:(}{it:varlist}{cmd:)} {cmdab:id:(}{it:varlist}{cmd:)} {cmdab:periods:(}{it:even integer}{cmd:)} 
[{cmdab:event:(}{it:varlist}{cmd:)} {cmdab:eventdate:(}{it:varlist}{cmd:)}]

{p 4 4 2}
where

{p 8 16 2}
{it:datevar} is a date variable

{p 8 16 2}
{it:event} is a binary variable that captures the timing of an event

{p 8 16 2}
{it:id} the group identifier

{p 8 16 2}
{it:periods} number of periods to use

{p 8 16 2}
{it:eventdate} a variable with the date of the event


This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 872ca8e46514291a9acd28f4d59e152de5116b31

{title:Authors}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
