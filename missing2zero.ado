program define missing2zero , rclass
version 14
	syntax varlist [, substitute(string)]
	
	// Check for mixed-types in varlist
	local rcSum 	= 0 // rcSum > 0 indicates at least one string variable
	local rcProduct = 1 // rcProduct == 0 indicates at least one numeric variable
	
	foreach var in `varlist'{
		capture confirm numeric variable `var'
		local rcSum 	= `rcSum' + _rc
		local rcProduct = `rcProduct'*_rc
	}
		
	if `rcSum' > 0 & `rcProduct' == 0{
		di "Cannot mix numeric and string variables"
		exit 109
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
			recode `var' (. = `substitute')
		}
		else {
			qui replace `var' = "`substitute'" if `var' == ""
		}
	}
end
