{smcl}
{* October 19, 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:init - A module to initialize STATA dofiles.}

{p 8 16 2}{cmd:init}
{cmd:,} 
[{cmdab:proj(}{it:string}{cmd:)} {cmdab:route(}{it:string}{cmd:)} {cmdab:debug} {cmdab:hard}
{cmdab:omit}]

{p 4 4 2}
where

{p 8 16 2}
{it:proj} use it to pass the name of the current project (uses {it:project} functionality). 

{p 8 16 2}
{it:route} if {it:debug} is not set changes the directory to the one specified here.

{p 8 16 2}
{it:debug} adds {cmdab: global deb "debug"}.

{p 8 16 2}
{it:hard} clears all macros --including globals. {it:hard} overrides {it:debug}. 

{p 8 16 2}
{it:omit} skips creation of graphs when used in conjunction with twowayscatter. 

{p 8 16 2}
This ado file does the following:

clear all
discard
set more off
set type double 

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
