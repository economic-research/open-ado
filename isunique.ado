program define isunique , rclass
	capture findfile uniquevals.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package uniquevals needs to be installed first;"
		 exit 498
	}
	
	syntax varlist [if], test(varlist)
	
	uniquevals `varlist' `if', qui
	
	local base_combinations = r(uniquecounts)
	
	uniquevals `varlist' `test' `if', qui
	
	local extended_combinations = r(uniquecounts)
	
	if `extended_combinations' == `base_combinations' {
		di as error "`test' does not vary across `varlist'"
	}
	else {
		di as error "`test' varies across `varlist'"
		exit 459
	}
end
