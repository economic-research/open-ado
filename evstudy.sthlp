{smcl}
{* August 25, 2019}{...}
{hline}
help for {hi:evstudy}
{hline}

{title:evstudy} - A module that performs an event study analysis. Can use {it:{help project##project:project}} functionality.

{p 8 16 2}{cmd:evstudy} {cmd:varlist} , {cmdab:basevar:(}{it:string}{cmd:)} {cmdab:debug} {cmdab:file:(}{it:string}{cmd:)} {cmdab:periods:(}{it:integer}{cmd:)} 
{cmdab:tline:(}{it:numeric}{cmd:)} {cmdab:varstem:(}{it:string}{cmd:)} [{cmdab:absorb:(}{it:varlist}{cmd:)} {cmdab:cl:(}{it:varlist}{cmd:)}
{cmdab:generate} {cmdab:kernel} {cmdab:kopts:(}{it:string}{cmd:)} {cmdab:qui}
{cmdab:othervar:(}{it:varlist min=2 max=2}{cmd:)}]

{p 4 4 2}
where

{p 8 16 2}
{it:varlist} has at least one variable, the left hand side variable. Every other variable included here is considered a control.

{p 8 16 2}
{it:basevar} the variable that will be used to normalize the regression coefficients.

{p 8 16 2}
{it:debug} turn off {it:{help project##project:project}} functionality.

{p 8 16 2}
{it:file} name of file, {it:without} extension where the resulting graphs will be saved.

{p 8 16 2}
{it:periods} number of periods around the event that will be considered.

{p 8 16 2}
{it:tline} position of a vertical line in the resulting plot.

{p 8 16 2}
{it:varstem} {cmd:evstudy} requires that the leads and lags included have the same stem.

{p 8 16 2}
{it:absorb} fixed effects.

{p 8 16 2}
{it:cl} stands for cluster.

{p 8 16 2}
{it:generate} optionally generates leads and lags of the variable that codifies the event of interest. 
It generates a sequence of variables of the type: {it:varstem_f`periods',..., varstem_l`periods'} 

{p 8 16 2}
{it:kernel} produce kernel plots of event study instead of displaying regression coefficients. Uses {it:{help lpoly##lpoly:lpoly}}.

{p 8 16 2}
{it:kopts} {it:{help lpoly##lpoly:lpoly}} options.

{p 8 16 2}
{it:qui} supress regression output.

{p 8 16 2}
{it:othervar} can accept two additional variable that are included at the extreme left and right in the plot respectively. Useful when one wants to include dummies that include every period before/after t.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 6c2746ced791f470fc9df4d5a50ffdfe8656a5ed

{title:Authors}

{p 4} Andres Jurado and Juan Morales {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
