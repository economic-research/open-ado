program define innerevent , rclass
	syntax, bys(varlist min=1) datevar(varlist min=1 max=1) ///
		eventnr(varlist min=1 max=1) ///
		epoch(varlist min=1 max=1) periods(string) [leftperiods(string)]

	/*
		Define:
		 - `bys': an ID, an entity that experiences an event (e.g., a newspaper outlet)
		 - `eventnr': an indicator for the number of event that `bys' experiences
		 - `lefperiods', `periods': the relevant ("inner") window that we consider
		 - `epoch': the counter for periods before/after the event(s)
	
		Purpose:
			We want to create dummy variables such that
			inner_`bys'_`eventnr' = `bys' x `eventnr' x inner_`eventnr'
			
			or in other words:
			indicator = ID x nr. of event x {pre-window of interest, 
					window of interest, post-window of interest}
	
		This program returns 3 variables:
			+ `bys'_`eventnr': ID x nr. of event
			+ inner_`eventnr': dummy for pre-window of interest (=1), window
			 of interest (=2), post-window of interst (=3)
			+ inner_`bys'_`eventnr': indicator for ID x nr. of event x {pre-window of interest, 
					window of interest, post-window of interest}
	*/
	
	// Check that variables do no exist
	foreach var in `bys'_`eventnr' inner_`eventnr' inner_`bys'_`eventnr' {
		capture confirm variable `var'
	
		if !_rc { // If 'eventnr' exists and 'mevents' selected, throw exception
			di "{err}Please drop variable `var'. innerevent uses this variable name."
			exit
		}
	}
	
	// If `leftperiods' doesn't exist, assume `periods'
	if "`leftperiods'" == "" {
		local leftperiods = -`periods'
	}
	
	// Calculate j: the power of ten that we need to multiply `bys' by
	// to generate an ID such that each `bys' has at most one event.
	qui su `eventnr'
	local max = r(max)

	local j 	= 0
	local rest 	= 1
	
	while `rest' >= 1{
		local `j++'
		local rest = `max'/10^`j'
	}
	
	// `bys'_eventnr: ID for `bys', such that each ID has at most one event
	qui gen `bys'_`eventnr' = `bys'*10^`j' + `eventnr'
	
	// For `bys'_`eventnr' with `epoch' that go back before `leftperiods'
	// and further than `periods', we want to be able to distinguish
	// whether the `bys'_`eventnr' x `epoch' corresponds to the window close
	// to the event or not.
	tempvar marker nvals
	
	bys `bys'_`eventnr' `epoch': gen `nvals' = _n
	
	qui gen `marker' = (`epoch' == -`leftperiods' & `nvals' == 1 | ///
		`epoch' == `periods' + 1 & `nvals' == 1)
	
	sort `bys'_`eventnr' `epoch'
	
	by `bys'_`eventnr': gen inner_`eventnr' = sum(`marker')
	qui replace inner_`eventnr' = inner_`eventnr' + 1
	
	// By construction inner_`eventnr' should have values <= 3
	qui su inner_`eventnr'
	local max = r(max)
	
	if `max' > 3 {
		di "{err}Unknown fatal error. Check variable `eventnr'"
		exit
	}

	gen inner_`bys'_`eventnr' = `bys'_`eventnr'*10 + inner_`eventnr'
	
	drop `marker' `nvals'
end
	