{smcl}
{* May 19, 2020}{...}
{hline}
help for {hi:timedummy}
{hline}

{title:timedummy} - A module that generates time dummy variables for event studies.

{p 8 16 2}{cmd:timedummy},
{cmdab:epoch(}{it:varlist min=1 max=1}{cmd:)} {cmdab:periods(}{it:integer}{cmd:)} 
{cmdab:varstem(}{it:string}{cmd:)} [{cmdab:leftperiods(}{it:integer}{cmd:)}  surround]

{p 4 4 2}
where

{p 8 16 2}
{cmdab:epoch} a variable that counts periods to/from event.

{p 8 16 2}
{cmdab:periods} number of dummy variables of the form {it:t+j} to include.

{p 8 16 2}
{cmdab:varstem} root name for the dummy variables created.

{p 8 16 2}
{cmdab:leftperiods} number of dummy variables of the form {it:t-j} to include. If left unspecified, {cmdab:periods} will be used instead.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: a3ff6f9ea13d40708588ec8ca02322f3e0d7376f

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
