program define tsperiods , rclass
	version 14
	syntax , bys(varlist min=1) datevar(varlist min=1 max=1) ///
		periods(string) ///
		[event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		maxperiods(string) mevents name(string) ///
		overlap(string) symmetric]
	
	*** I Checks
	// Check that eventnr and overlap variables do not exist in database
	capture confirm variable eventnr
	
	if !_rc { // If 'eventnr' exists and 'mevents' selected, throw exception
		if "`mevents'" == "mevents" {
			di "{err}Please drop variable 'eventnr'. tsperiods uses this variable to store the nr. of period."
			exit
		}
		else {
			di as error "'eventnr' already defined, but not created with this command. Caution is adviced."
		}
	}
	
	// If user specified overlap, check that variable doesn't exist yet
	if "`overlap'" != "" {
		capture confirm variable overlap
		if !_rc {
			di "{err}Please drop variable 'overlap' or omit option 'overlap' from command."
			exit
		}
	}
	
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
	tempvar anyevent
	
	local datecount = 0
	foreach var in `eventdate'{
		local `datecount++'
		
		// Used for checking whether all `bys' have at least one event
		tempvar eventdatetemp
		qui gen `eventdatetemp' 	= 0
		qui replace `eventdatetemp' = 1 if !missing(`eventdate')
		
		by `bys': egen `anyevent' = max(`eventdatetemp')
		drop `eventdatetemp'
	}
	
	// Confirm if user specified an event
	local eventcount = 0
	foreach var in `event'{
		local `eventcount++'
		
		// Used for checking whether all `bys' have at least one event
		by `bys': egen `anyevent' = max(`event')
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
	
	// If user specified overlap, check if user also specified mevents
	if "`overlap'" != "" & "`mevents'" == "" {
		di "{err}Need to specify 'mevents' if 'overlap' is specified"
		exit
	
		// Verify that periods is a positive integer
		if `overlap' <= 0{
			di "{err}overlap has to be a positive integer"
			exit
		}
		
		if `overlap' != int(`periods'){
			di "{err}overlap has to be an integer"
			exit
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
	
	// If user didn't select maxperiods, compute optimal number
	// works optimally if panel is balanced
	
	if "`maxperiods'" == "" {
		local maxperiods_selected "FALSE"
	}
	else {
		local maxperiods_selected "TRUE"
	}
	
	if "`maxperiods_selected'" == "FALSE" {
		local j 		= 1
		local counts 	= 99 
		
		while `counts' > 0 {
			qui count if (`datediff' >= -`j'*`periods' ///
					& `datediff' <= -`periods'*(`j' - 1) - 1)
			
			local total = r(N)
			
			qui count if (`datediff' >= `j' * `periods' ///
						& `datediff' <= `periods' * (`j'+1) - 1)
			
			local counts = `total' + r(N)
			local `j++'
		}
		
		local maxperiods = `j' + 1
		
		di as error "Consider specifying maxperiods if you believe the panel is unbalanced"
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
	
	// If mevents was selected compute overlapping windows and generate event-ID indicators
	if "`mevents'" == "mevents" {
		tempvar diff startevent
		
		sort `bys' `datevar'
		
		by `bys': gen `diff' = `name' - `name'[_n-1]
		
		if "`periods'" != "1" {
			qui gen `startevent' 		= (`diff' < 0)
		}
		else {
			qui gen `startevent' 		= (`diff' <= 0)
		}
		
		by `bys': gen eventnr 		= sum(`startevent')
		
		qui replace eventnr 		= eventnr + 1
		
		if "`overlap'" != "" { // If user specified an overlap window generate dummy for overlap
			
			// Create a local that contains the list of lags to consider
			local list_lags ""
			forvalues lagnum = 1(1)`overlap'{
				local list_lags "`list_lags' lag`lagnum'"
			}
		
			if `datecount' > 0 { // if user specified an event date, create event dummy
				tempvar event
				gen `event' = (`eventdate' == `datevar')
			}
			
			// Create dummies for event variable
			tempvar `list_lags'
			forvalues lagnum = 1(1)`overlap'{
				by `bys': gen lag`lagnum' = `event'[_n-`lagnum']
			}
		
			// Add dummies together to compute whether there was a nearby event
			egen overlap = rowtotal(`list_lags')
			qui replace overlap = (overlap > 0 & `name' <= 0)
			
			drop `list_lags'
			
			if `datecount' > 0 {
				drop `event'
			}
			
		}
		
		drop `diff' `startevent'
	}
	
	// Generate 'eventnr' variable if 'mevents' was NOT specified,
	// for those ID's with one event
	if "`mevents'" == "" {
		qui gen eventnr = 1 if !missing(`name')
	}
	
	// Check that epoch has no missing values and provide guidance as to why that would be the case
	qui count if missing(`name')
	local missing_epoch = r(N)
		
	qui count if missing(`name') & `anyevent' == 0
	local missing_epoch_no_event = r(N)
	
	if `missing_epoch' > 0 {
		di as error "`missing_epoch' missing values in `name' detected."
		if "`maxperiods_selected'" == "FALSE" {
			if `missing_epoch' == `missing_epoch_no_event' {
				di as error "This is caused by one or more `bys' that do not have any event"
			}
			else {
				di "{err} Unknown error caused `name' to have missing values"
			}
		}
		if  "`maxperiods_selected'" == "TRUE" {
			if `missing_epoch' == `missing_epoch_no_event' {
				di as error "This is caused by one or more `bys' that do not have any event"
			}
		else {
			di as error "Consider increasing maxperiods"
			}
		}
	}
		
	// descriptive stats
		// For epoch
	qui su `name'
	local mean 	= r(mean)
	local max  	= r(max)
	local min	= r(min)
	
	di "Descriptive stats for `name', mean: `mean', min: `min', max: `max'"
	
		// For event number
	qui su eventnr
	local mean 	= r(mean)
	local max  	= r(max)
	local min	= r(min)
	
	di "Descriptive stats for eventnr, mean: `mean', min: `min', max: `max'"
	
	drop `datediff' `anyevent'
	
	sort `bys' `datevar' 
end
