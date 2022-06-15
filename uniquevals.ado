program define uniquevals , rclass
	syntax varlist [if] [, qui]

	// Count number of variables
	local k = 0
	foreach var in `varlist'{
		local `k++'
	}
	
	if "`if'" != "" {
		preserve
		drop `if'
	}
	
	foreach var in `varlist' {
		tempvar nvals
		bys `var': gen `nvals' = _n
		
		qui count if `nvals' == 1
		local count = r(N)
		
		if "`qui'" == "" {
			di as error "`var' has " `count' " distinct values."
		}
		drop `nvals'
		
		return scalar uniquecounts = `count'
	}
	
	if `k' > 1 {
		tempvar nvals
		bys `varlist': gen `nvals' = _n
		
		qui count if `nvals' == 1
		local count = r(N)
		
		if "`qui'" == "" {
			di as error "`varlist' has " `count' " distinct values."
		}
		drop `nvals'
				
		return scalar uniquecounts = `count'
	}
	
	if "`if'" != "" {
		restore
	} 
	
end
