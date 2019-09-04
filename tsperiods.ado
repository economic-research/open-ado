program define tsperiods , rclass
	version 14
	syntax , bys(varlist min=1) datevar(varlist min=1 max=1) ///
		maxperiods(string) periods(string) ///
		[event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		mevents name(string) symmetric]
	
	// Set name for new variable
	if "`name'" == ""{
		local name epoch
	}
	
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
	
	// Check that at least one option event or eventdate was specified
	if `datecount' > 0 & `eventcount' > 0{
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
			
	// compute days to/from event
	tempvar mindate maxdate
	if `eventcount' > 0{ // If user specified event
		tempvar datetemp eventdate
		gen `datetemp' 				= `datevar' if `event' == 1
		bys `bys': egen `eventdate' 		= max(`datetemp')
		
		bys `bys': egen `mindate' = min(`datetemp')
		bys `bys': egen `maxdate' = max(`datetemp')
		
		qui count if `mindate' != `maxdate'
		local counts = r(N)
		if `counts' != 0 & "`mevents'" == "" {
			di "{err}More than one event specified by ID. This warning can be turned off with option mevents."
			exit
		}
		drop `datetemp' `maxdate' `mindate' // STATA doesn't always drop temporary objects
	}
	else{ // If user specified a date
		bys `bys': egen `mindate' = min(`eventdate')
		bys `bys': egen `maxdate' = max(`eventdate')
		
		qui count if `mindate' != `maxdate'
		local counts = r(N)
		if `counts' != 0 & "`mevents'" == "" {
			di "{err}More than one eventdate specified by ID. This warning can be turned off with option mevents."
			exit
		}
		drop `maxdate' `mindate'
	}
			
	tempvar datediff
	qui gen `datediff' 	= `datevar' - `eventdate'
	
	if "`symmetric'" == "" { // t-0 covers [0,periods) 
		qui gen `name' = 0 if (`datediff' >= 0 & `datediff' <= `periods'-1)
		
		forvalues i=1(1)`maxperiods'{
			qui replace `name' = -`i' if (`datediff' >= -`i'*`periods' ///
				& `datediff' <= -`periods'*(`i' - 1) - 1)
			
			qui replace `name' = `i' if (`datediff' >= `i' * `periods' ///
				& `datediff' <= `periods' * (`i'+1) - 1)
		}
	}
	else{ // t-0 covers [-periods/2, periods/2]
		if mod(`periods',2) != 0{
			di "{err}Periods must be an even number if option symmetric selected"
			exit 7
		}
		
		qui gen `name' = 0 if (`datediff' >= -`periods'/2 & `datediff' <= `periods'/2)
	
		forvalues i=1(1)`maxiter'{
			qui replace `name' 	= -`i' if (`datediff' >= -(`i'+1/2)*`periods'-`i' ///
				& `datediff' <= -(`i'-1/2)*`periods'-`i')
			
			qui replace `name'	= `i' if (`datediff' >= (`i'-1/2)*`periods' + `i' ///
				& `datediff' <= (`i'+1/2)*`periods'+`i')
			}
	}
	
	drop `datediff' 
end
