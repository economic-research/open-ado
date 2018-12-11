{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:psave - A module that saves to CSV, DTA and documents dependencies.}

{p 8 16 2}{cmd:psave}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:eopts:(}{it:string}{cmd:)} {cmdab:preserve} {cmdab:debug} {cmdab:com} {cmdab:norand}]

{p 4 4 2}
where

{p 8 16 2}
{it:file} stands for the route and name of the article {it:without} file extension. 
Note that the extension has experimental functionality that handles files extensions automatically.

{p 8 16 2}
{it:eopts} refers to standard options of {cmdab:export delimited}.

{p 8 16 2}
{it:preserve} avoids clearing local memory.

{p 8 16 2}
{it:debug} prevents psave from using {cmdab:project} functionality. In debug mode {it: psave} will not save a CSV file.

{p 8 16 2}
{it:com} compresses the database to save space without losing precission. Regardless of user input {it:psave} will perform that operation if there are more than 1 million observations.

{p 8 16 2}
{it:norand} By default {it:psave} stores data using a fixed seed. The user can turn off this functionality by specifying {it:norand}, that forces {it:psave} to store data as is.

{title:Authors}

{p 4} Lorenzo Aldeco and Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
