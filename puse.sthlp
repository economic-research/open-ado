{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:puse}
{hline}

{title:puse} - A module that reads to DTA's, CSV and Excel files and documents dependencies using project functionality.

{p 8 16 2}{cmd:puse}
{cmd:,} 
{cmdab:file:(}{it:string}{cmd:)} [{cmdab:clear} {cmdab:debug} {cmdab:opts:(}{it:string}{cmd:)}  {cmdab:original}]

{p 4 4 2}
where

{p 8 16 2}
{it:clear} clears local memory.

{p 8 16 2}
{it:debug} prevents puse from using {cmdab:project} functionality.

{p 8 16 2}
{it:opts} insheet/import excel options.

{p 8 16 2}
{it:original} directs {cmdab:project} to treat datafile as original using the {cmdab: project, original(filename)} functionality.

{title:Authors}

{it:puse} tries to read data and register project functionality in the following way (unless user specifies a specific file extension)

Read:
	1. DTA
	2. CSV
	3. Excel
project (dependencies):
	1. CSV
	2. DTA
	3. Excel

{it:puse} can guess the file extension of DTA's and CSV files, but Excel file extensions must be specified by the user.

{p 4} Lorenzo Aldeco and Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
