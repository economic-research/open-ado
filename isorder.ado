program define isorder , rclass
	syntax varlist
	
	tempvar order1 order2
		
	gen `order1' = _n
	
	sort `varlist'
	
	gen `order2' = _n
	
	qui count if `order1' != `order2'
	
	local counts = r(N)
	
	if `counts' == 0{
		di "Database ordered according to `varlist'"
		local statusval 1
	}
	else{
		di "Database is NOT ordered according to `varlist'"
		local statusval 0
	}
		
	return local ordered `statusval'
end
