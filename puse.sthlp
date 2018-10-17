{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:puse}
{hline}

{title:puse - A module that reads to DTA (and CSV if a DTA is not found) and documents dependencies.}

{p 8 16 2}{cmd:puse}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:clear} {cmdab:debug} {cmdab:original}]

{p 4 4 2}
where

{p 8 16 2}
{it:file} stands for the route and name of the article {it:without} file extension. E.g., "./dirname/data_file". Note that the extension has experimental functionality that handles files extensions automatically.

{p 8 16 2}
{it:clear} clears local memory.

{p 8 16 2}
{it:debug} prevents puse from using {cmdab:project} functionality.

{p 8 16 2}
{it:original} directs {cmdab:project} to treat datafile as original using the {cmdab: project , original(filename)} functionality.

{title:Authors}

{p 4} Lorenzo Aldeco and Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
