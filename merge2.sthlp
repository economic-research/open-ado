{smcl}
{* 6 September 2018}{...}
{hline}
help for {hi:merge2}
{hline}

{title:merge2} - A module that merges CSV and DTA files.

{p 8 16 2}{cmd:merge2}
{it:varlist} {cmd:,} 
{cmdab:type:(}{it:string}{cmd:)} {cmdab:file:(}{it:string}{cmd:)} [{cmdab:datevar:(}{it:date variable}{cmd:)} 
{cmdab:tdate:(}{it:type of date}{cmd:)} {cmdab:fdate:(}{it:desired format}{cmd:)}
{cmdab:moptions:(}{it:merge options}{cmd:)} {cmdab:idstr:(}{it:varlist}{cmd:)} 
{cmdab:idnum:(}{it:varlist}{cmd:)} {cmdab:original} {cmdab:debug}]

{p 4 4 2}
where

{p 8 16 2}
{it:varlist} refers to the variables against which the merge will be carried out.

{p 8 16 2}
{it:type} is the type of merge desired, such as 1:1, 1:m, m:1, or m:m.

{title:Description}

{p 4 4 2}
{cmd:merge2} merges a using file in CSV or DTA format. When merging a DTA file only {it:file}, {it:type}, {it:varlist}, {it:original} and {it:debug} options are allowed.

{title:Options}
{p 8 16 1}
{it:datevar} is a single date variable. It is assumed that the date variable will be a string, since STATA converts to string properly formated date variable when exporting to CSV.

{p 8 16 1}
{it:tdate} is the type of date variable, such as DMY, YMD, etc.

{p 8 16 1}
{it:fdate} is the desired format for date, such as %td.

{p 8 16 1}
{it:moptions} options that will be passed through to merge, e.g., nogen.

{p 8 16 1}
{it:idstr} variables to convert to string in both datasets.

{p 8 16 1}
{it:idnum} variables to destring in both datasets.

{p 8 16 1}
{it:original} original indicates that the imported file is original, i.e., that it was not generated within the project.

{p 8 16 1}
{it:debug} {it:merge2} registers project functionality by default. If {it:debug} is selected, this is skipped.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is as at least as recent as commit: 3cd38782bb154133078fb2cd597d774dbda1c4e3

{title:Author}

{p 4} Andres Jurado{p_end}
{p 4} jose_jurado_vadillo@brown.edu{p_end}
