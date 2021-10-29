program define uniquevals , rclass
version 14
	syntax varlist [if]

	// Count number of variables
	local k = 0
	foreach var in `varlist'{
		local `k++'
	}
	
	if `k' > 1 {
		// Calculate distinct values for interaction
		preserve
		cap keep `if'
		qui duplicates drop `varlist' , force
		local N_all = _N
		restore
		
		di as error "The interaction of {`varlist'} has " `N_all' " distinct values"
	}
	
	// Calculate distinct values for each variable
	foreach var in `varlist' {
		preserve
		cap keep `if'
		qui duplicates drop `var', force
		local N_var = _N
		di as error "`var' has " `N_var' " distinct values"
		restore
	}
end
