{smcl}
{* April 10, 2020}{...}
{hline}
help for {hi:innerevent}
{hline}

{title:innerevent} - A module that produces useful indicator variables for ID, number of event and timing of event. These indicator variables can be used as controls in event study regressions.

{p 8 16 2}{cmd:innerevent}
{cmd:,} 
{cmdab:bys:(}{it:varlist}{cmd:)} {cmdab:datevar:(}{it:varlist}{cmd:)} {cmdab:eventnr:(}{it:varlist}{cmd:)} 
{cmdab:epoch:(}{it:varlist}{cmd:)} {cmdab:periods:(}{it:integer}{cmd:)} [{cmdab:leftperiods:(}{it:integer}{cmd:)}]

{cmd:innerevent} produces indicator variables for ID x event, ID x event x {pre, during, post} and {pre, during, post}

returns new variables called:
- `bys'_`eventnr': ID x nr. of event
- inner_`eventnr': nr. of event x timing
- inner_`bys'_`eventnr': ID x nr. of event x timing

{p 4 4 2}
where

{p 8 16 2}
{cmd:bys} list of variables that constitute an ID.

{p 8 16 2}
{cmd:datevar} is a date variable.

{p 8 16 2}
{cmd:eventnr} variable that reports the number of event across ID's.

{p 8 16 2}
{cmd:epoch} see {cmd:tsperiods}. {cmd:epoch} and {cmd:datevar} may be the same variable.
  
{p 8 16 2}
{cmd:periods} relevant epochs that constitute the event window of interest.

{p 8 16 2}
{cmd:leftperiods} used to define event windows that are not symmetric: fewer or more periods before the event are considered than periods after event.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 3cd38782bb154133078fb2cd597d774dbda1c4e3

{title:Authors}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
