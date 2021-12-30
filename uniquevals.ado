program define uniquevals , rclass
	syntax varlist [if]

	// Count number of variables
	local k = 0
	foreach var in `varlist'{
		local `k++'
	}
	
	foreach var in `varlist' {
		tempvar nvals
		bys `var': gen `nvals' = _n `if'
		
		qui count if `nvals' == 1
		local count = r(N)
		
		di as error "`var' has " `count' " distinct values."
		drop `nvals'
	}
	
	if `k' > 1 {
		tempvar nvals
		bys `varlist': gen `nvals' = _n `if'
		
		qui count if `nvals' == 1
		local count = r(N)
		
		di as error "`varlist' has " `count' " distinct values."
		drop `nvals'
	}
end
