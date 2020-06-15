{smcl}
{* August 30, 2019}{...}
{hline}
help for {hi:evstudy}
{hline}

{title:evstudy} - A module that performs an event study analysis. Can use {it:{help project##project:project}} functionality.

{p 8 16 2}{cmd:evstudy} {cmd:varlist} [if], {cmdab:basevar:(}{it:string}{cmd:)} {cmdab:periods:(}{it:integer}{cmd:)} 
{cmdab:varstem:(}{it:string}{cmd:)} 
[{cmdab:absorb:(}{it:varlist}{cmd:)} {cmdab:bys:(}{it:varlist}{cmd:)} {cmdab:cl:(}{it:varlist}{cmd:)}
{cmdab:connected} {cmdab:datevar:(}{it:varlist}{cmd:)} {cmdab:debug} {cmdab:file:(}{it:string}{cmd:)} {cmdab:force} {cmdab:generate} {cmdab:kernel} 
{cmdab:kopts:(}{it:string}{cmd:)} {cmdab:leftperiods:(}{it:integer}{cmd:)} {cmdab:maxperiods:(}{it:integer}{cmd:)} {cmdab:mevents}
{cmdab:nolabel} {cmdab:omit_graph} {cmdab:othervar:(}{it:varlist min=2 max=2}{cmd:)} {cmdab:overlap:(}{it:integer}{cmd:)}
{cmdab:qui} {cmdab:regopts:(}{it:string}{cmd:)} {cmdab:surround} {cmdab:tline:(}{it:numeric}{cmd:)} {cmdab:twopts:(}{it:string}{cmd:)}]
 
{p 4 4 2}
where

{p 8 16 2}
{cmd:varlist} has at least one variable, the left hand side variable. Every other variable included here is considered a control.

{p 8 16 2}
{cmd:basevar} the variable that will be used to normalize the regression coefficients.

{p 8 16 2}
{cmd:file} name of file, {it:without} extension, where the resulting graphs will be saved.

{p 8 16 2}
{cmd:periods} number of periods around the event that will be considered.

{p 8 16 2}
{cmd:tline} position of a vertical line in the resulting plot.

{p 8 16 2}
{cmd:varstem} {cmd:evstudy} requires that the leads and lags included have the same stem.

{p 8 16 2}
{cmd:absorb} fixed effects.

{p 8 16 2}
{cmd:bys} and {cmd:datevar} need to be specified if option {cmd:generate} is used. {cmd:bys} denotes a list of variables that constitute an ID in the data.

{p 8 16 2}
{cmd:cl} stands for cluster.

{p 8 16 2}
{cmdab:connected} connect point estimates with line. Cannot be used in conjunction with {cmdab:kernel}.

{p 8 16 2}
{cmd:datevar} Optional argument. {cmd:bys} and {it:datevar} need to be specified if option {cmd:generate} is used. {cmd:datevar} indicates to {cmdab:evstudy} which is the date variable to be used for constructing leads and lags for the event.

{p 8 16 2}
{cmd:debug} turn off {it:{help project##project:project}} functionality.

{p 8 16 2}
{cmd:force} if option {cmd:generate} is selected, {cmd:force} ignores error messages when trying to create lead and lag variables that are already defined.

{p 8 16 2}
{cmd:generate} optionally generates leads and lags of the variable that codifies the event of interest. 
It generates a sequence of variables of the type: {it:varstem_f`periods',..., varstem_l`periods'} 

{p 8 16 2}
{cmd:kernel} produce kernel plots of event study instead of displaying regression coefficients. Uses {it:{help lpoly##lpoly:lpoly}}.

{p 8 16 2}
{cmd:kopts} {it:{help lpoly##lpoly:lpoly}} options.

{p 8 16 2}
{cmd:lefperiods} optionally specify the number of periods before the event that are considered.

{p 8 16 2}
{cmd:maxperiods} by default {cmd:evstudy} uses a heuristic to determine how many leads and lags it needs to construct. This process can be computationally intensive. 
The user can use command {cmd:mexperiods} to tell STATA how many periods to check for.

{p 8 16 2}
{cmd:mevents} by default {cmd:evstudy} checks if there's a maximum of 1 events per ID. {cmd:mevents} (multiple events) turns off this warning.

{p 8 16 2}
{cmdab:nolabel} prevent {cmdab:evstudy} from using the label of the dependent variable as ytitle.

{p 8 16 2}
{cmdab:omit_graph} avoid ploting and storing any graph. evstudy stores the model in the object {it:NL_EVresults}.

{p 8 16 2}
{cmd:overlap} generate dummy if epoch overlap with respect to the previous event. Can only be specified with {cmd:mevents}.

{p 8 16 2}
{cmd:qui} supress regression output.

{p 8 16 2}
{cmd:regopts} options for reghdfe

{p 8 16 2}
{cmd:surround} Includes as controls in the regression a dummy for periods before {cmd:lefperiods}, and for periods after {cmd:periods}. If {cmd:kernel} is not specified, these coefficients are included in graph.

{p 8 16 2}
{cmd:othervar} can accept two additional variable that are included at the extreme left and right in the plot respectively. Useful when one wants to include dummies that include every period before/after t-X/t+X respectively.

{p 8 16 2}
{cmd:twopts} twoway options

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 3cd38782bb154133078fb2cd597d774dbda1c4e3

{title:Authors}

{p 4} Andres Jurado and Juan Morales {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
