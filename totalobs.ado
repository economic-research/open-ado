program totalobs
	syntax varlist [if]
	
	foreach var in `varlist' {
	    qui su `var' `if'
		local tots: di %13.0fc r(N)*r(mean)
		di as error "Total observations: `tots'"
		di as error "Figure excluding decimals."
	}
end