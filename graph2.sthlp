{smcl}
{* 12 September 2018}{...}
{hline}
help for {hi:graph2}
{hline}

{title:graph2 - A module that exports to PNG and PDF.}

{p 8 16 2}{cmd:graph2}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:options:(}{it:string}{cmd:)} {cmdab:debug} {cmdab:full}]

{p 4 4 2}
where

{p 8 16 2}
{it:file} stands for the route and name of the article {it:without} file extension. E.g., "../../Violencia Mexico/constructed/homicide".

{p 8 16 2}
{it:options} refers to standard options of {cmdab:graph export}.

{p 8 16 2}
{it:debug} If debug is selected, {it:project} functionality is not used.

{p 8 16 2}
{it:full} If  selected, the graph is additionally saved in gph format and the data is also stored to disk using {it:{help psave##psave:psave}}.

{title:Author}

{p 4}Andres Jurado{p_end}
{p 4}jose.jurado.vadillo@gmail.com{p_end}
