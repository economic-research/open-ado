program define init , rclass
version 14
    syntax [, lor trace debug]
    if "`lor'" == "lor"{
        # delimit;
        local limit ";" ;
     } `limit'
     
     clear all `limit'
     macro drop _all `limit'
     set more off `limit'
     
     gl deb "`debug'" `limit'
     set type double `limit'
     
     if "`trace'" == "trace"{ `limit'
          set trace on `limit'
     } `limit'
end
