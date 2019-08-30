{smcl}
{* 1 October 2018}{...}
{hline}
help for {hi:puse}
{hline}

{title:puse} - A module that reads to DTA's, CSV and Excel files and documents dependencies using {it:{help project##project:project}} functionality to track dependencies of Input/Outputs and achieve efficient compilation of large projects.

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

{it:puse} can guess the file extension of DTA's and CSV files, but Excel file extensions must be specified by the user.
In general, it is recommended to specify a file extension.

{it:puse} tries to read data and register project functionality in the following way (unless the user specifies a specific file extension)

Read:
	1. DTA
	2. CSV
	3. Excel
	
project (dependencies):
	1. CSV
	2. DTA
	3. Excel

{marker examples}{...}
{title:Examples}

Load an Excel file that was not created by any dofile within the {it:{help project##project:project}} (hence, "original"), take first row as variable 
names and clear memory. Note that {it:{help init##init:init}} creates a global variable $deb with values "" (empty) or "debug". 
{it:{help init##init:init}} in "debug" mode turns off project functionality.
{phang}{cmd:. puse, file("../raw-data/auto-data.xlsx") opts(firstrow) clear $deb original}{p_end}
Load a DTA called "auto.dta" that was created by a dofile inside the project
{phang}{cmd:. puse, file("../constructed-data/auto.dta") clear $deb}{p_end}

{cmdab:puse} is intended to be used in conjunction with {it:{help project##project:project}}, {it:{help pexit##pexit:pexit}}, {it:{help psave##psave:psave}} and {it:{help init##init:init}}

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 6ced919f2d7d880c6db3815aeebe834323adf211

{title:Authors}

{p 4} Andres Jurado and Lorenzo Aldeco  {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
