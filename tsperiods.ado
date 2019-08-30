program define tsperiods , rclass
	version 14
	syntax , datevar(varlist min=1 max=1) ///
		periods(string) [bys(varlist min=1) ///
		event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		maxperiods(string) id(varlist min=1 max=1) symmetric]
	
	// Confirm if user specified bys
	local byscount = 0
	foreach var in `bys'{
		local `byscount++'
	}

	// Confirm if user specified ID
	local idcount = 0
	foreach var in `idcount'{
		local `idcount++'
	}

	// Check that user specified either bys or ID
	if `byscount' == 0 & `idcount' == 0{
		di "{err}Specify either bys or id"
		exit 102
	}
	if `byscount' > 0 & `idcount' > 0{
		di "{err}Can only specify one of two bys/id"
		exit 103
	}
	
	// If user selected bys, confirm that maxperiods is specified
	if `byscount' > 0 & "`maxperiods'" == ""{
		di "{err}Need to specify maxperiods if bys specified"
		exit
	}
	
	if `idcount' > 0{ // If ID specified fill-out pannel (pannel is assumed)
		tsfill
	}
	else {
		local id "`bys'"
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
	if `eventcount' > 0 & `eventcount' > 0{
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
	
	tempvar datetemp datediff maxobs nvals
	
	// compute days to/from event
	if `eventcount' > 0{ // If user specified event
		tempvar eventdate
		gen `datetemp' 				= `datevar' if `event' == 1
		bys `id': egen `eventdate' 		= max(`datetemp')
		
		// Check that there's a maximum of 1 event per ID
		if `idcount' > 0{
			tempvar checker
			bys `id': egen `checker' 		= sum(`event')
			
			qui su `checker'
			local max = r(max)
			if `max' > 1{
				di "{err}Only one event per ID allowed"
				exit 
			}
		}
	}
	
	// Identify how many iterations we need to compute
	if "`maxperiods'" == ""{
		bys `id': gen `nvals' 		= _n
		bys `id': egen `maxobs' 	= max(`nvals')
		
		qui su `maxobs'
		local maxval 		= r(max)
		local maxperiods 	= round(`maxval'/`periods')
	}
	
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
	
	drop `checker' `datetemp' `datediff' `maxobs' `nvals' // STATA doesn't always drop temporary objects
end
