program define uniquevals , rclass
version 14
	syntax varlist [if]
	tempvar condition	
	
	if "`if'" != ""{
		qui gen `condition' = 1 `if'
		local localif "& `condition' == 1"
	}
	
	foreach var in `varlist'{
		tempvar j
		bys `var': gen `j' = _n
		qui count if `j' == 1 `localif'
		di "`var' has " r(N) " distinct values"
		drop `j'
	}
end
