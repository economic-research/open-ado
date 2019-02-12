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
end
