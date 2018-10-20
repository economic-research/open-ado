{smcl}
{* October 19, 2018}{...}
{hline}
help for {hi:psave}
{hline}

{title:init - A module to initialize STATA dofiles.}

{p 8 16 2}{cmd:init}
{cmd:,} 
[{cmdab:lor}{cmdab:trace}{cmdab:debug}]

[, lor trace debug]

{p 4 4 2}
where

{p 8 16 2}
{it:lor} stands for {it:Lorenzo mode}. This adds {cmd:#delimit;} to the initialization. 

{p 8 16 2}
{it:trace} adds {cmdab:set trace on}. Default is {cmdab:set trace off}.

{p 8 16 2}
{it:debug} adds {cmdab: global deb "deb"}.

{p 8 16 2}
This ado file does the following:

clear all
macro drop _all 
set more off
set type double 

{title:Author}

{p 4} Andres Jurado {p_end}
{p 4}jose_jurado_vadillo@brown.edu{p_end}
