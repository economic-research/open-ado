{smcl}
{* October 22, 2018}{...}
{hline}
help for {hi:twowayscatter}
{hline}

{title:twowayscatter - A module to plot scatterplots and display a correlation.}

{p 8 16 2}{cmd:twowayscatter} {cmdab:varlist(min=2, max=3)}
[{cmd:,} 
{cmdab:color1(}{it:string}{cmd:)} {cmdab:color2(}{it:string}{cmd:)} {cmdab:conditions(}{it:string}{cmd:)}
debug {cmdab:file(}{it:string}{cmd:)} lfit {cmdab:type1(}{it:string}{cmd:)} {cmdab:type2(}{it:string}{cmd:)} 
ncorr singleaxis omit {cmdab:twopts(}{it:string}{cmd:)}]

{p 4 4 2}
where

{p 8 16 2}
{it:color1} and {it:color2} refer to the color of the plots. 

{p 8 16 2}
{it:conditions} options passed to scatter plot.

{p 8 16 2}
{it:file} filename without extension to save.

{p 8 16 2}
{it:debug} adds debug option to use within {it:project}.

{p 8 16 2}
{it:lfit} adds linear fit line for the first two variables.

{p 8 16 2}
{it:type} optionally specifies the type of plot one wants. Default is scatterplot. Any graph type supported by {it:twoway} is valid.

{p 8 16 2}
{it:ncorr} Omitts correlation coefficient and legend.

{p 8 16 2}
{it:singleaxis} If three variables are specified, {it:singleaxis} plots both of them against the same y-axis.

{p 8 16 2}
{it:omit} If selected, graph will not be rendered or saved. Useful when one doesn't want to keep producing the same graph across multiple compiles.

{p 8 16 2}
{it:twopts} Passes valid twoway options.

{title:Author}

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 2992be718fa216ed11f795f7d304b949e3fbe191

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@alumni.brown.edu{p_end}
