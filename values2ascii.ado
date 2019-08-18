program define values2ascii , rclass
	syntax varlist [, tolower punct]
	
	// 1. Eliminate accents
	foreach var in `varlist'{
		qui replace `var' = subinstr(`var',"á","a",.)
		qui replace `var' = subinstr(`var',"é","e",.)
		qui replace `var' = subinstr(`var',"í","i",.)
		qui replace `var' = subinstr(`var',"ó","o",.)
		qui replace `var' = subinstr(`var',"ú","u",.)
		qui replace `var' = subinstr(`var',"ñ","n",.)
		
		qui replace `var' = subinstr(`var',"Á","A",.)
		qui replace `var' = subinstr(`var',"É","E",.)
		qui replace `var' = subinstr(`var',"Í","I",.)
		qui replace `var' = subinstr(`var',"Ó","O",.)
		qui replace `var' = subinstr(`var',"Ú","U",.)
		qui replace `var' = subinstr(`var',"Ñ","N",.)
	}

	// 2. Lowercase variables
	if "`tolower'" == "tolower"{
		foreach var in `varlist'{
			qui replace `var' = lower(`var')
		}
	}
	
	// 3. Punctuation
	if "`punct'" == "punct"{
		foreach var in `varlist'{
			qui replace `var' = subinstr(`var',".","",.)
			qui replace `var' = subinstr(`var',",","",.)
			qui replace `var' = subinstr(`var',";","",.)
			qui replace `var' = subinstr(`var',"!","",.)
			qui replace `var' = subinstr(`var',"¡","",.)
			qui replace `var' = subinstr(`var',"(","",.)
			qui replace `var' = subinstr(`var',")","",.)
			qui replace `var' = subinstr(`var',"[","",.)
			qui replace `var' = subinstr(`var',"]","",.)
			qui replace `var' = subinstr(`var',"-","",.)
		}
	}
	
	// 4. Eliminate spaces
	foreach var in `varlist'{ // Loop over variables
		qui replace `var' = subinstr(`var', char(10),"",.)
		qui replace `var' = subinstr(`var', char(13),"",.)
		qui replace `var' = strltrim(`var')
		
		// Eliminate leading and trailing blank spaces
		tempvar strLength marker
		qui gen `strLength' = strlen(`var')
		
		qui levelsof `var' , local(uniquevals)
		
		local j = 1
		qui gen `marker' = .
		
		foreach cat in `uniquevals'{ // Loop over categories of variable
			qui replace `marker' = `j' if `var' == "`cat'"
			local `j++'
		}
		
		local j = 1
		
		foreach cat in `uniquevals'{ // Loop over categories of variable
			qui sum `strLength' if `marker' == `j' , mean
			local length = r(mean)
			
			// Eliminate trailing space if present
			if substr("`cat'", `length', 1) == " "{
				local length = `length' - 1
				qui replace `var' = substr(`var',1,`length') if `marker' == `j'
			}
			else if substr("`cat'", 1, 1) == " "{ // Eliminate leading space if present
				qui replace `var' = substr(`var',2,`length') if `marker' == `j'
			}
			
			local `j++'
		} // End loop over categories of variables
		
		drop `strLength' `marker'
	} // End loop over variables
end
