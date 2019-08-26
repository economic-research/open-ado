program define tsperiods , rclass
	version 14
	syntax , datevar(varlist min=1 max=1) event(varlist min=1 max=1) ///
	id(varlist min=1 max=1) periods(string) [eventdate(varlist min=1 max=1)]
	
	// tsperiods is intended for use with panel data (balanced)
	tsfill
	
	// Check if user specified an even number
	if mod(`periods',2) == 1{
		di "{err}Periods cannot be an odd number. Odd number found where even number expected"
		exit 7
	} 
	
	tempvar datetemp datediff maxobs nvals
	
	// Confirm if user specified eventdate
	local j = 0
	foreach var in `eventdate'{
		local `j++'
	}
	
	// compute days to/from event
	if `j' == 0{ // j > 0
		tempvar eventdate
		gen `datetemp' 				= `datevar' if `event' == 1
		bys `id': egen `eventdate' 		= max(`datetemp')
	}
	
	// Identify how many iterations we need to compute
	bys `id': gen `nvals' 		= _n
	bys `id': egen `maxobs' 	= max(`nvals')
	
	qui su `maxobs'
	local maxval 	= r(max)
	local maxiter 	= round(`maxval'/`periods')
	
	qui gen `datediff' 	= `datevar' - `eventdate'
	
	qui gen epoch = 0 if (`datediff' >= -`periods'/2 & `datediff' <= `periods'/2)
	
	forvalues i=1(1)`maxiter'{
		qui replace epoch = -`i' if (`datediff' >= -(`i'+1/2)*`periods'-`i' ///
			& `datediff' <= -(`i'-1/2)*`periods'-`i')
		
		qui replace epoch = `i' if (`datediff' >= (`i'-1/2)*`periods' + `i' ///
			& `datediff' <= (`i'+1/2)*`periods'+`i')
	}
	
	drop `datetemp' `datediff' `maxobs' `nvals' // STATA doesn't always drop temporary objects
end
