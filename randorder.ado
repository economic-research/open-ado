program randorder
syntax [seed(int)]
	
	local seconds 	= tc($S_TIME)/1000
	local days 	 	= td($S_DATE)
	
	local seed = (`seconds' + `days')*`days'

	tempvar randorder
	set seed `seed'
	
	qui gen `randorder' = runiform()
	
	gsort `randorder'
end