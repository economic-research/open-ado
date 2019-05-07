{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:psave} - A module that saves to CSV, DTA and documents dependencies.

{p 8 16 2}{cmd:psave}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:com} {cmdab:csvnone} {cmdab:debug} {cmdab:eopts:(}{it:string}{cmd:)} {cmdab:preserve}]

{p 4 4 2}
where

{p 8 16 2}
{it:com} compresses the database to save space without losing precission. Regardless of user input {it:psave} will perform that operation if there are more than 1 million observations.

{p 8 16 2}
{it:csvnone} Don't store results in CSV format. If debug mode isn't specified will register DTA with project.

{p 8 16 2}
{it:debug} prevents psave from using {cmdab:project} functionality. In debug mode {it: psave} will not save a CSV file.

{p 8 16 2}
{it:eopts} refers to standard options of {cmdab:export delimited}.

{p 8 16 2}
{it:preserve} avoids clearing local memory.

This is open source software distributed under the GPL-3 license. Ownership belong to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is up to date with commit: XX

{title:Authors}

{p 4} Andres Jurado and Lorenzo Aldeco {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
