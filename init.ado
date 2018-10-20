program define init , rclass
version 14
    syntax [, lor trace debug]
     
     clear all
     macro drop _all
     set more off
     
     gl deb "`debug'"
     set type double
     
     if "`trace'" == "trace"{
          set trace on
     }
     else {
           set trace off
          }
     
     if "`lor'" == "lor"{
        # delimit;
     } `limit'
end
