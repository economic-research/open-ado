program define eventin , rclass
syntax , idvar(varlist) datevar(varlist) event(varlist) periods(string) name(string)

	**** I Checks
	// Check that user provided a valid panel
	tempvar nvals
	bys `idvar' `datevar': gen `nvals' = _n
	qui count if `nvals' > 1
	local counts = r(N)
	if `counts' > 0 {
		di "{err}`idvar' and `datevar' do not uniquely identify observations"
		exit
	}
	
	// Check if event has either 0, 1
	qui count if `event' == 1 | `event' == 0
	local counter1 = r(N)
	qui count
	local counter2 = r(N)

	if `counter1' != `counter2'{
		di "{err}Event dummy can only have 0, 1 values"
		exit 175
	}

	// Check that pend > pstart
	if `pstart' >= `pend'{
		di "{err}Verify that pend > pstart"
		exit
	}

	// Check that pend < 0
	if `pend' >= 0{
		di "{err}pend must be a negative integer"
		exit
	}

	**** II Build variable
	// Compute date of events for each ID
	preserve
	tempfile count_events

	qui keep if `event' == 1

	sort `idvar' `datevar'
	
	by `idvar': gen datediff = `datevar' - `datevar'[_n-1]
	by `idvar': gen nvals 	 = _n
	
	keep `idvar' `datevar' datediff
	save `count_events'

	restore

	qui merge 1:1 `idvar' `datevar' using `count_events'  , nogen

	tsperiods , bys(`idvar') datevar(`datevar') maxperiods(1) ///
			periods(`periods') event(`event') mevents name(myevent)

	qui su nvals
	local max = r(max)
	
	forvalues i = 1(1)`max'{
		tempvar date`i' datediff`i' 
		qui gen `date`i'' 		= `datevar' if `event' == 1 & nvals == `i'
		qui gen `datediff`i'' 		= `datevar' - `datediff`i''
		
		bys `idvar': egen `eventdate`i'' = min(`date`i'') // column with date of event nr. i by ID
		qui gen `datediff`i''  = `datevar' - `eventdate`i''
		
		qui replace `name' = 1 if (`datediff`i'' < `pend' & `datediff`i'' >= `pstart')
	}
	
	qui gen `name' = 0
end
