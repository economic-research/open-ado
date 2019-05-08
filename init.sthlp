{smcl}
{* October 19, 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:init} - A module to initialize STATA dofiles that leverages {it:{help project##project:project}} functionality to track dependencies of Input/Outputs and achieve efficient compilation of large projects.

{cmdab:init} performs a {cmdab: clear all} and {cmdab:discard} commands. It can set as working directory the directory of the current dofile if used in conjunction with {it:{help project##project:project}},
or change working directory to any other directory that the user user choses. {cmdab:init} can open a log file (storing by default the logfile in the "./log/" folder, if it exists).
It can also turn on and off {it:{help project##project:project}} functionality. {it:{help project##project:project}} tracks dependencies of Input/Outputs and thus helps find bugs in the order
of execution of dofiles in a project. {it:{help project##project:project}} can also help speed the compilation of large projects by avoiding unnecessarily executing code. You may want to turn 
off this functionality to avoid having to run the entire project, and instead compile a single dofile. We call this "debug mode". 

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
{it:debroute} Changes working directory with respect to {it:{help project##project:project}} root directory, ff specified and {it:debug} selected, 

{p 8 16 2}
{it:double} adds type double option to STATA.

{p 8 16 2}
{it:hard} clears all macros --including globals. {it:hard} overrides {it:debug}. 

{p 8 16 2}
{it:ignorefold} Unless {it:ignorefold} is selected, init checks whether log folder exists in root directory, and stores logfile there. 

{p 8 16 2}
{it:logfile} opens a logfile if {it:debug} is not specified. Tip: {it:{help pexit##pexit:pexit}} ado file closes all open logfiles.

{p 8 16 2}
{it:omit} skips creation of graphs when used in conjunction with twowayscatter ado file. 

{p 8 16 2}
{it:proj} use it to pass the name of the current project (uses {it:{help project##project:project}} functionality). 

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
This version is as at least as recent as commit: abbe57645ec8c21103eb21e68ba5603044e2d4e5

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
