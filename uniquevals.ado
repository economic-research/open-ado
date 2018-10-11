program define uniquevals , rclass
version 14
	syntax varlist
	
	foreach var in `varlist'{
		tempvar j
		bys `var': gen `j' = _n
		qui count if `j' == 1
		di "`var' has " r(N) " distinct values"
		drop `j'
	}

end
