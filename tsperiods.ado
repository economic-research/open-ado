program define tsperiods , rclass
	version 14
	syntax , bys(varlist min=1) datevar(varlist min=1 max=1) ///
		maxperiods(string) periods(string) ///
		[event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		mevents name(string) symmetric]
	
	*** I Checks
	// Check that user provided a valid panel
	tempvar nvals
	bys `bys' `datevar': gen `nvals' = _n
	qui count if `nvals' > 1
	local counts = r(N)
	if `counts' > 0 {
		di "{err}`bys' and `datevar' do not uniquely identify observations"
		exit
	}
	
	// Verify that periods is a positive integer
	if `periods' <= 0{
		di "{err}periods has to be a positive integer"
		exit
	}
	
	if `periods' != int(`periods'){
		di "{err}periods has to be an integer"
		exit
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
	
	// Check whether no event or eventdate were specified
	if `datecount' == 0 & `eventcount' == 0{
		di "{err}Specify either event or eventdate"
		exit 102
	}
	
	// Check that user didn't specify event AND eventdate
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
	
	// Check that eventdate has no missing values if specified
	if `datecount' > 0 {
		qui count if `eventdate' == .
		local counts = r(N)
		if `counts' > 0{
			di "{err}`eventdate' cannot have missing values"
			exit
		}
	}
	
	// Check that there's at most one event per ID if mevents wasn't specified
	if "`mevents'" == ""{

		tempvar maxdate mindate
		if `eventcount' > 0{ // If user specified an event
			tempvar datetemp
			gen `datetemp' 					= `datevar' if `event' == 1
			bys `bys': egen `mindate' 		= min(`datetemp')
			bys `bys': egen `maxdate' 		= max(`datetemp')
			
			qui count if `mindate' != `maxdate'
			local counts = r(N)
			if `counts' != 0 {
				di "{err}More than one event specified by ID. This warning can be turned off with option mevents."
				exit
			}
			drop `datetemp' `mindate' `maxdate' // STATA doesn't always drop temporary objects
		}
		else{ // If user specified a date
			bys `bys': egen `mindate' = min(`eventdate')
			bys `bys': egen `maxdate' = max(`eventdate')
			
			qui count if `mindate' != `maxdate'
			local counts = r(N)
			if `counts' != 0 {
				di "{err}More than one eventdate specified by ID. This warning can be turned off with option mevents."
				exit
			}
			drop `maxdate' `mindate'
		}
	}
	
	*** II compute days to/from event
	tempvar datediff
	if `eventcount' > 0{ // If user specified event
		
		preserve
		tempfile count_events
		
		qui keep if `event' == 1

		sort `bys' `datevar'
		by `bys': gen nvals = _n // identifies order of events within panel ID
		
		keep `bys' `datevar' nvals
		save `count_events'
		
		restore
		
		qui merge 1:1 `bys' `datevar' using `count_events'  , nogen
		
		qui su nvals
		local max = r(max)

		local varlist
		
		gen `datediff' = .
		
		forvalues i = 1(1)`max'{
			tempvar date`i' eventdate`i'
			qui gen `date`i'' 		= `datevar' if `event' == 1 & nvals == `i'
			
			bys `bys': egen `eventdate`i'' 	= min(`date`i'') // column with date of event nr. i by ID
			
			qui gen datediff`i' 		= `datevar' - `eventdate`i'' // date difference WRT event date nr. i
			qui gen datediff`i'_abs 	= abs(datediff`i')
			
			local varlist "`varlist' datediff`i'_abs"
			drop `date`i'' `eventdate`i''
		}

		tempvar datemin
		
		egen `datemin' = rowmin(`varlist')
		
		forvalues i = 1(1)`max'{
			qui replace `datediff' = datediff`i' if datediff`i'_abs == `datemin'
			drop datediff`i' datediff`i'_abs
		}
		
		drop `datemin' nvals
	}
	else { // If user provided an eventvar
		qui gen `datediff' = `datevar' - `eventdate'
	}
	
	*** III Generate periods to/from variables
	// Set name for new variable
	if "`name'" == ""{
		local name epoch
	}
	
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
