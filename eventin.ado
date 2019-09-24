program define eventin , rclass
syntax , idvar(varlist min=1 max=1) datevar(varlist min=1 max=1) event(varlist min=1 max=1) periods(string) name(string)

	**** I Checks
	// Verify that tsperiods is installed
	capture findfile tsperiods.ado
	if "`r(fn)'" == "" {
		 di as txt "user-written package tsperiods needs to be installed first;"
		 exit 498
	}
	
	// Check that user provided a valid panel
	tempvar nvals
	bys `idvar' `datevar': gen `nvals' = _n
	qui count if `nvals' > 1
	local counts = r(N)
	if `counts' > 0 {
		di "{err}`idvar' and `datevar' do not uniquely identify observations"
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
	
	// Check if event has either 0, 1
	qui count if `event' == 1 | `event' == 0
	local counter1 = r(N)
	qui count
	local counter2 = r(N)

	if `counter1' != `counter2'{
		di "{err}Event dummy can only have 0, 1 values"
		exit 175
	}
	
	**** II Build variable
	qui gen tempval = 0
	
	sort `idvar' `datevar'
	
	forvalues i = 1(1)`periods'{
		by `idvar': replace tempval = tempval + `event'[_n-`i']
	}
	
	tsperiods , bys(`idvar') datevar(`datevar') maxperiods(`periods') ///
		periods(1) event(`event') mevents name(myevent)
	
	qui gen `name' = 0 
	qui replace `name' = 1 if (tempval >= 2 & myevent > 0 & !missing(tempval) & !missing(myevent))
	qui replace `name' = 1 if (tempval >= 1 & my event <= 0 & !missing(tempval) & !missing(myevent))
	
	qui drop tempval myevent
end
