program mcompare , rclass
version 14
	syntax varlist(min=2)
	local counter = 0
	foreach var in `varlist'{
		local `counter++'
	}

	token `varlist'
	
	forvalues i=2(1)`counter'{
		compare `1' ``i''
	}
end
