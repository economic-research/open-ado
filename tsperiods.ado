program define tsperiods , rclass
	version 14
	syntax , datevar(varlist min=1 max=1) ///
		maxperiods(string) periods(string) ///
		[bys(varlist min=1) event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		symmetric]
	
	// Confirm if user specified eventdate
	local datecount = 0
	foreach var in `eventdate'{
		local `datecount++'
	}
	
	// Confirm is user specified an event
	local eventcount = 0
	foreach var in `event'{
		local `eventcount++'
	}
	
	// Check that either event or eventdate were specified (but not both)
	if `datecount' == 0 & `eventcount' == 0{
		di "{err}Specify either event or eventdate"
		exit 102
	}
	if `datecount' > 0 & `eventcount' > 0{ // Check that at least one option was specified
		di "{err}Can only specify one of two event/eventdate"
		exit 103
	}
	
	// Check if event has either 0, 1 or missing (if event specified)
	if `eventcount' > 0 {
		qui count if `event' == 1 | `event' == 0 | missing(`event')
		local counter1 = r(N)
		qui count
		local counter2 = r(N)
		
		if `counter1' != `counter2'{
			di "{err}Event dummy can only have 0, 1 or missing values"
			exit 175
		}
	}
	
	// Confirm if user specified bys
	local byscount = 0
	foreach var in `bys'{
		local `byscount++'
	}	
		
	// Check that if event was specified, then bys was also specified
	if `byscount' == 0 & `eventcount' > 0{
		di "{err}If event is specified, then bys must also be specified"
		exit
	} 
	
	// compute days to/from event
	if `eventcount' > 0{ // If user specified event
		tempvar datetemp eventdate
		gen `datetemp' 				= `datevar' if `event' == 1
		bys `bys': egen `eventdate' 		= max(`datetemp')
		drop `datetemp' // STATA doesn't always drop temporary objects
	}
		
	tempvar datediff
	qui gen `datediff' 	= `datevar' - `eventdate'
	
	if "`symmetric'" == "" { // t-0 covers [0,periods) 
		qui gen epoch = 0 if (`datediff' >= 0 & `datediff' <= `periods'-1)
		
		forvalues i=1(1)`maxperiods'{
			qui replace epoch = -`i' if (`datediff' >= -`i'*`periods' ///
				& `datediff' <= -`periods'*(`i' - 1) - 1)
			
			qui replace epoch = `i' if (`datediff' >= `i' * `periods' ///
				& `datediff' <= `periods' * (`i'+1) - 1)
		}
	}
	else{ // t-0 covers [-periods/2, periods/2]
		if mod(`periods',2) != 0{
			di "{err}Periods must be an even number if option symmetric selected"
			exit 7
		}
		
		qui gen epoch = 0 if (`datediff' >= -`periods'/2 & `datediff' <= `periods'/2)
	
		forvalues i=1(1)`maxiter'{
			qui replace epoch = -`i' if (`datediff' >= -(`i'+1/2)*`periods'-`i' ///
				& `datediff' <= -(`i'-1/2)*`periods'-`i')
			
			qui replace epoch = `i' if (`datediff' >= (`i'-1/2)*`periods' + `i' ///
				& `datediff' <= (`i'+1/2)*`periods'+`i')
			}
	}
	
	drop `datediff' 
end
