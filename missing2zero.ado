program define missing2zero , rclass
version 14
	syntax varlist [, substitute(string) mean bys(varlist)]
	
	// Check for mixed-types in varlist
	local rcSum 	= 0 // rcSum > 0 indicates at least one string variable
	local rcProduct = 1 // rcProduct == 0 indicates at least one numeric variable
	
	local byscount = 0
	foreach var in `bys' {
		local `byscount++'
	}
	
	foreach var in `varlist'{
		capture confirm numeric variable `var'
		local rcSum 	= `rcSum' + _rc
		local rcProduct = `rcProduct'*_rc
	}
		
	if `rcSum' > 0 & `rcProduct' == 0{
		di "Cannot mix numeric and string variables"
		exit 109
	}
	
	if "`substitute'" != "" & "`mean'" == "mean" {
		di as error "'substitute' cannot be combined with 'mean'"
		exit
	}
	
	if `rcSum' > 0 & "`mean'" == "mean" {
		di as error "'mean' is not defined for string variables"
		exit
	}
	
	// Assign default values if none specified
	if `rcSum' == 0 & "`substitute'" == ""{ // If numeric variables specified
		local substitute = 0
	}
	else if `rcProduct' > 0 &  "`substitute'" == "" { // If string variables specified
		local substitute "NaN"
	}
	
	foreach var in `varlist'{
		capture confirm numeric variable `var' // check type of variable
		
		if _rc == 0 { // If numeric
			if "`mean'" == "mean" { // if user wants to fill missing with mean value
				tempvar vartemp
				
				if `byscount' > 0 {
					bys `bys': egen `vartemp' = mean(`var')
				}
				else {
					 egen `vartemp' = mean(`var')
				}
				
				qui replace `var' = `vartemp' if missing(`var')
				drop `vartemp'
			}
			else { // if user wants to fill with zero or custom value
				recode `var' (. = `substitute')
			}
		} // If string
		else {
			qui replace `var' = "`substitute'" if `var' == ""
		}
	}
end
