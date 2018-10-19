program define missing2zero , rclass
version 14
	syntax varlist (numeric) [, substitute(integer 0)]
	
	foreach var in `varlist'{
		replace `var' = `substitute' if `var' == .
	}
end
