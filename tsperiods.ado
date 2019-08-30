program define tsperiods , rclass
	version 14
	syntax , datevar(varlist min=1 max=1) ///
	id(varlist min=1 max=1) periods(string) [event(varlist min=1 max=1) eventdate(varlist min=1 max=1)]
		
	// tsperiods is intended for use with panel data (balanced)
	tsfill
	
	tempvar datetemp datediff maxobs nvals
	
	// Confirm if user specified eventdate
	local j = 0
	foreach var in `eventdate'{
		local `j++'
	}
	
	// Confirm is user specified an event
	local k = 0
	foreach var in `event'{
		local `k++'
	}
	
	// Check that either event or eventdate were specified (but not both)
	if `j' == 0 & `k' == 0{
		di "{err}Specify either event or eventdate"
		exit 102
	}
	if `j' > 0 & `k' > 0{
		di "{err}Can only one of two event/eventdate"
		exit 103
	}
	
	// Check if event has either 0, 1 or missing (if event specified)
	if `k' > 0 {
		qui count if `event' == 1 | `event' == 0 | missing(`event')
		local counter1 = r(N)
		qui count
		local counter2 = r(N)
		
		if `counter1' != `counter2'{
			di "{err}Event dummy can only have 0, 1 or missing values"
			exit 175
		}
	}
	
	// compute days to/from event
	if `k' > 0{ // or j == 0: if user didn't specify an eventdate
		tempvar checker eventdate
		gen `datetemp' 				= `datevar' if `event' == 1
		bys `id': egen `checker' 		= sum(`event')
		bys `id': egen `eventdate' 		= max(`datetemp')
		
		// Check that there's a maximum of 1 event per ID
		qui su `checker'
		local max = r(max)
		if `max' > 1{
			di "{err}Only one event per ID allowed"
			exit 
		}
	}
	
	// Identify how many iterations we need to compute
	bys `id': gen `nvals' 		= _n
	bys `id': egen `maxobs' 	= max(`nvals')
	
	qui su `maxobs'
	local maxval 	= r(max)
	local maxiter 	= round(`maxval'/`periods')
	
	qui gen `datediff' 	= `datevar' - `eventdate'
	
	qui gen epoch = 0 if (`datediff' >= 0 & `datediff' <= `periods'-1)
	
	forvalues i=1(1)`maxiter'{
		qui replace epoch = -`i' if (`datediff' >= -`i'*`periods' ///
			& `datediff' <= -`periods'*(`i' - 1) - 1)
		
		qui replace epoch = `i' if (`datediff' >= `i' * `periods' ///
			& `datediff' <= `periods' * (`i'+1) - 1)
	}
	
	drop `checker' `datetemp' `datediff' `maxobs' `nvals' // STATA doesn't always drop temporary objects
end
