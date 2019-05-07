{smcl}
{* October 19, 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:init} - A module to initialize STATA dofiles that leverages {it:{help project##project:project}} functionality to track dependencies of Input/Outputs and achieve efficient compilation of large projects.

{p 8 16 2}{cmd:init}
[{cmd:,} 
{cmdab:debug} {cmdab:debroute(}{it:string}{cmd:)} {cmdab:double} {cmdab:hard} 
{cmdab:ignorefold} {cmdab:logfile(}{it:string}{cmd:)} {cmdab:omit}
{cmdab:proj(}{it:string}{cmd:)} {cmdab:route(}{it:string}{cmd:)}]

{p 4 4 2}
where

{p 8 16 2}
{it:debug} adds {cmdab: global deb "debug"}.

{p 8 16 2}
{it:debroute} If specified and {it:debug} selected, changes working directory with respect to
	{it:project} root directory.

{p 8 16 2}
{it:double} adds type double option to STATA.

{p 8 16 2}
{it:hard} clears all macros --including globals. {it:hard} overrides {it:debug}. 

{p 8 16 2}
{it:ignorefold} If option is not selected init checks whether log folder exists in root directory, and stores logfile there. 

{p 8 16 2}
{it:logfile} opens a logfile if {it:debug} is not specified. Tip: {it:pexit} ado file closes all open logfiles.

{p 8 16 2}
{it:omit} skips creation of graphs when used in conjunction with twowayscatter. 

{p 8 16 2}
{it:proj} use it to pass the name of the current project (uses {it:project} functionality). 

{p 8 16 2}
{it:route}: {it:{help project##project:project}} changes the working directory to the current dofile that is compiling. {it:route} changes the working directory back if the user choses to do so.

{p 8 16 2}
This ado file does the following:

clear all
discard

{marker examples}{...}
{title:Examples}

Initialize a STATA dofile, pass project functionality and link to project "auto"
{phang}{cmd:. init, proj(auto) route("../..")}{p_end}
{phang}{it:. rest of the code}{p_end}
Use debug mode to compile a single dofile instead of the entire project. Also, turn off {it:{help project##project:project}} functionality entirely.
{phang}{cmd:. init, proj(auto) route("../..") debug}{p_end}
{phang}{it:. rest of the code}{p_end}

{cmdab:init} is intended to be used in conjunction with {it:{help project##project:project}}, {it:{help pexit##pexit:pexit}}, {it:{help psave##psave:psave}} and {it:{help puse##puse:puse}}. 
Note that {cmdab:init} creates global variables "deb" and "omit" and might overwrite existing macros with the same name.

This is open source software distributed under the GPL-3 license. Ownership belongs to their respective authors.
For more documentation, examples and the most up to date code visit {browse "https://github.com/economic-research/open-ado/"}
This version is up to date with commit: XX

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
