program define date2string , rclass
version 14
	syntax varlist(max=1) , gen(string) [drop]
	
	tokenize `varlist'
	tempvar day month year
	
	gen `day' 	= day(`1')
	gen `month' 	= month(`1')
	gen `year' 	= year(`1')
	
	qui tostring `day' `month' `year' , replace
	
	gen `gen' = `month' + "/" + `day' + "/" + `year'
	drop `year' `month' `year'
	
	if "`drop'" == "drop"{
		drop `1'
	}
end
program esttab2 , rclass
version 14
	// This extension is experimental.
		//Known issues:
			// Can only accept one line of addnotes
	syntax , file(string asis) [addnotes(string) debug option(string asis) ///
		title(string asis)]

	if "`title'" == ""{
		local titleloc ""
	}
	else {
		local titleloc "title(`title')"
	}

	if "`addnotes'" == ""{
		local addnotesloc ""
	}
	else {
		local addnotesloc "addnotes(`addnotes')"
	}


	esttab using "`file'" , se label ///
		replace ///
		b(4) se(4) `addnotesloc' `option' `titleloc'
		
	if "`debug'" == "" {
		project , creates("`file'") preserve
	}
	
	eststo clear
end
program evstudy , rclass
version 14
	syntax varlist [if], basevar(string) periods(string) ///
		varstem(varlist min=1 max=1)  [absorb(varlist) ///
		bys(varlist min=1) cl(varlist min=1) connected datevar(varlist min=1 max=1) debug ///
		file(string) force generate kernel kopts(string) leftperiods(string) ///
		maxperiods(string) mevents nolabel omit_graph ///
		othervar(varlist min=2 max=2) overlap(string) qui  ///
		regopts(string) tline(string) surround twopts(string)]
	
	*----------------------- Checks ---------------------------------------------
	// Verify that tsperiods is installed
	capture findfile tsperiods.ado
	if "`r(fn)'" == "" {
		 di as error "user-written package 'tsperiods' needs to be installed first;"
		 exit 498
	}
	
	// Verify that regsave is installed
	capture findfile regsave.ado
	if "`r(fn)'" == "" {
		 di as error "user-written package 'regsave' needs to be installed first;"
		 exit 498
	}
	
	// Verify that graph2 is installed
	capture findfile graph2.ado
	if "`r(fn)'" == "" {
		 di as error "user-written package 'graph2' needs to be installed first;"
		 exit 498
	}
	
	// Verify that timedummy exists
	capture findfile timedummy.ado
	if "`r(fn)'" == "" {
		 di as error "user-written package 'timedummy' needs to be installed first;"
		 exit 498
	}
	
	// Verify that no variable called 'myevent' exists
	if "`generate'" == "generate" {
		capture confirm variable myevent
		if !_rc {
			di "{err}Please drop variable 'myevent'. Evstudy uses this object to temporary store information"
			exit
		}
	}
	
	// Check if absorb is empty
	local abscount = 0
	foreach var in `absorb'{
		local `abscount++'
	}
	
	// Check if bys is empty
	local byscount = 0
	foreach var in `bys'{
		local `byscount++'
	}
	
	// Check if cl is empty
	local clcount = 0
	foreach var in `cl'{
		local `clcount++'
	}
	
	// Check that connected and kernel not used together
	if "`connected'" == "connected" & "`kernel'" == "kernel" {
		di "{err} 'connected' and 'kernel' cannot both be specified"
		exit
	}
	
	// Check if datevar is empty
	local datecount = 0
	foreach var in `datevar'{
		local `datecount++'
	}
	
	// Check if othervar is empty
	local othervarcount = 0
	foreach var in `othervar'{
		local `othervarcount++'
	}
	
	// Verify that if option generate was selected, then bys and datevar specified
	if "`generate'" == "generate"{
		if `byscount' == 0 | `datecount' == 0{
			di "{err}Need to specify bys and datevar if option generate is specified"
			exit
		}
	}
	
	// If user specified overlap, check if user also specified mevents
	// Verify that overlap is a positive integer
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
	
	// If user specified omit_graph, check that filename is not specified
	if "`omit_graph'" == "omit_graph" & "`file'" != "" {
		di "{err}Cannot specify 'file' with option 'omit_graph'"
		exit
	}
	
	// Warn user that in kernel graphs only time coefficients are plotted
	if "`kernel'" == "kernel" {
		if "`surround'" == "surround" | `othervarcount' > 0 {
			di as error "`surround' `othervar' will be included in estimation but the coefficients will NOT be ploted"
		}
	}
	
	// Verify that periods is a positive integer
	if "`maxperiods'" != "" {
		if `maxperiods' <= 0{
			di "{err}overlap has to be a positive integer"
			exit
		}
	}
	
	// Warn user if panel is unbalanced
	sort `bys' `datevar'
	tempvar diffdate
	
	by `bys': gen `diffdate' = `datevar' - `datevar'[_n-1]
	qui su `diffdate'
	local max = r(max)
	
	if `max' > 1 {
	    di as error "Warning: panel might be unbalanced"
	} 
	
	drop `diffdate'
	
	*----------------------- Checks ---------------------------------------------
	
	*----------------------- Definitions ----------------------------------------
	// Create local for absorb
	if `abscount' >0{
		local abslocal "absorb(`absorb')"
	}
	else {
		local abslocal "noabsorb"
	}
	
	// Define cluster variable
	if `clcount' > 0 {
		local cluster "cl(`cl')"
	}
	
	// Optionally connect graph
	if "`connected'" == "connected" {
		local connected "recast(connected)"
	}
	
	// Define capture (for use with force option)
	if "`force'" == "force" & "`generate'" == ""{
		di "{err}Option force can only be specified with option generate"
		exit
	}
	
	if "`nolabel'" == "" {
		// Obtain name of dependant variable
		local depvar `: word 1 of `varlist''
		// Store label
		local label_loc : var label `depvar'
		
		local ylabel_loc "ytitle(`label_loc')"
	}
	
	// Define tline if one is specified
	if "`tline'" != "" {
		local tlineval "tline(`tline', lp(solid) lc(red))"
	}
	
	// Define periods to the left, if not specified
	if "`leftperiods'" == "" {
		local leftperiods = `periods'
	}	
	*----------------------- Definitions ----------------------------------------

	*----------------------- Generate variables----------------------------------
	// Optionally build leads and lags
	if "`generate'" == "generate"{ // BEGIN GENERATE LEADS AND LAGS
		
		if "`overlap'" != "" { // If overlap was specified
			capture confirm variable overlap // check if overlap was already defined
			
			if "`force'" == "" { // If option force was not specified and variable overlap exists throw error
				if !_rc {
					di "{err}Variable 'overlap' is already defined."
					di "{err}Option 1: drop variable 'overlap'."
					di "{err}Option 2: omit 'generate' option."
					di "{err}Option 3: specify 'force option'."
					exit
				}
			}
			
			if  _rc { // If variable overlap doesn't exist, create it
				local overlaploc "overlap(`overlap')"
			}
		}
		
		// Determine if it's necessary to generate periods dummies or not
		// Check whether user specified 'generate', but not 'force', and still the variable exists
		local period_dummies_required "FALSE"
		
		forvalues i = 1(1)`leftperiods' {
			capture confirm variable `varstem'_f`i'
				
			if _rc { // If it doesn't exist flag to generate
				local period_dummies_required "TRUE"
			}
			else if "`force'" == ""{
				di "{err}Variable `varstem'_f`i' already specified"
				exit
			}
		}
		
		forvalues i = 1(1)`periods' {
			capture confirm variable `varstem'_l`i'
				
			if _rc { // If it doesn't exist flag to generate
				local period_dummies_required "TRUE"
			}
			else if "`force'" == ""{
				di "{err}Variable `varstem'_l`i' already specified"
				exit
			}
		}
			 
		if "`surround'" == "surround" {
			foreach type in pre post {
				capture confirm variable `varstem'_`type'
				
				if _rc {
					local period_dummies_required "TRUE"
				}
				else if "`force'" == ""{
					di "{err}Variable `varstem'_`type' already specified"
					exit
				}
			}
		}
		
		if "`period_dummies_required'" == "TRUE" {
			if "`maxperiods'" == "" { // Use heuristic to determine nr of leads and lags if user did not specify
				// Compute the absolute maximum number of leads and lags that we could need
				tempvar counts maxcounts
				
				bys `bys': gen `counts' 	= _n
				by `bys' : egen `maxcounts' = max(`counts')
				
				qui su `maxcounts'
				
				local maxperiods = r(max)
				
				drop `counts' `maxcounts'
			}
			
			// Construct periods to/from event ---------------------------------------------------------------
			tsperiods , bys(`bys') datevar(`datevar') maxperiods(`maxperiods') ///
				periods(1) event(`varstem') `mevents' name(myevent) `overlaploc'
			// Construct periods to/from event ---------------------------------------------------------------	
			
			// Prevent STATA from storing myevent variable 
			tempvar myevent
			qui gen `myevent' = myevent
			qui drop myevent
				
			timedummy, varstem(`varstem') periods(`periods') leftperiods(`leftperiods') ///
				`surround' epoch(`myevent')
			
			qui drop `myevent'
		}
	} // END GENERATE LEADS AND LAGS
	
	// Include control for overlap if user specified it
	if "`overlap'" != "" {
		local overlapctrl "overlap"
	}
	
	// Build regression parameters in loop
	local conditions ""
	local regressors ""
	
	// Leads of the RHS correspond to "pre-trend" = before treatment
	if `othervarcount' > 0 {
		tokenize `othervar'
		
		if "`kernel'" == "" { // Only include in graph if kernel was not selected
			local conditions "`conditions' (`1': _b[`1'] - _b[`basevar'])"
		}
		
		local regressors "`regressors' `1'"
	}
	
	// Include pre and post controls if selected
	if "`surround'" == "surround" {
		
		if "`kernel'" == "" { // Only include in graph if kernel was not selected
			local conditions "`conditions' (`varstem'_pre: _b[`varstem'_pre] - _b[`basevar'])"
		}
		local regressors "`regressors' `varstem'_pre"
	}
	
	forvalues i = `leftperiods'(-1)1{
		local conditions "`conditions' (`varstem'_f`i':_b[`varstem'_f`i']-_b[`basevar'])"
		local regressors "`regressors' `varstem'_f`i'"
	}
	
	local conditions "`conditions' (`varstem':_b[`varstem']-_b[`basevar'])"
	local regressors "`regressors' `varstem'"
	
	// Lags correspond to "post-trends" = after treatment
	forvalues i = 1(1)`periods'{
		local conditions "`conditions' (`varstem'_l`i':_b[`varstem'_l`i']-_b[`basevar'])"
		local regressors "`regressors' `varstem'_l`i'"
	}
	
	// Include pre and post controls if selected
	if "`surround'" == "surround" {
		
		if "`kernel'" == "" { // Only include in graph if kernel was not selected
			local conditions "`conditions' (`varstem'_post: _b[`varstem'_post] - _b[`basevar'])"
		}
		local regressors "`regressors' `varstem'_post"
	}
	
	if `othervarcount' > 0 {
		
		if "`kernel'" == "" { // Only include in graph if kernel was not selected
			local conditions "`conditions' (`2':_b[`2']-_b[`basevar'])"
		}
		
		local regressors "`regressors' `2'"
	}
	
	// ------------------------ Regression -----------------------------------------
	`qui' reghdfe `varlist' `regressors' `overlapctrl' `if', `abslocal' `cluster' `regopts'
	
	// Check if any variables were omitted
	local numcoef = `periods' + `leftperiods'
	
	forvalues i = 1(1)`numcoef'{
		if !missing(r(label`i')) {
			if r(label`i') == "(omitted)"{
				di "{err}One or more coefficients were omitted"
				exit
			}
		}
	}
	
	// Normalize coefficients
	`qui' nlcom `conditions', post
	est store NL_EVresults
	
	if "`omit_graph'" == "" {
		if "`kernel'" == "kernel"{
			preserve
			regsave
			
			tempvar days post
			qui gen `days' 		= _n
			qui replace `days' 	= `days' - `periods' - 1
			
			qui gen `post' 		= (`days' >= 0)
			
			graph twoway (scatter coef `days' if !`post', msize(small) graphregion(color(white)) graphregion(lwidth(vthick))) ///
				(lpolyci coef `days' if !`post', lcolor(navy) ciplot(rline) `kopts') ///
				(scatter coef `days' if `post', msize(small) color(cranberry*0.5)) ///
				(lpolyci coef `days' if `post', `tlineval' lcolor(cranberry) ciplot(rline) `kopts') , ///
				legend(off) `twopts' `ylabel_loc'
			
			restore
		}
		else {
			coefplot (NL_EVresults, keep(`varstem'_pre) mcolor(dknavy*0.4) ciopts(color(dknavy*0.4))) ///
			(NL_EVresults, drop(`varstem'_pre `varstem'_post) mcolor(dknavy) ciopts(color(dknavy))) ///
			(NL_EVresults, keep(`varstem'_post) mcolor(dknavy*0.4) ciopts(color(dknavy*0.4))), ///
			ci(90) legend(off) offset(0) scale(1.1) yline(0, lp(solid) lc(black*0.4%80)) `tlineval' xsize(8) `connected' ///
			vertical xlabel(, angle(vertical)) graphregion(color(white)) `twopts' `ylabel_loc'
		}
		
		if "`file'" != "" {
			graph2 , file("`file'") `debug'
		}
	}
endprogram define graph2 , rclass
version 14
	syntax , file(string asis) [options(string) debug]
	
	local pngfile = `file' + ".png"
	local pdffile = `file' + ".pdf"
	
	graph export "`pngfile'" , replace `options'
	graph export "`pdffile'" , replace `options'
	
	if "`debug'" == ""{
		project , creates("`pngfile'") preserve
	}
end
program define init , rclass
	version 14
	
	// Check dependencies
	capture findfile project.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package project needs to be installed first;"
		 di as txt "use -ssc install project- to do that"
		 exit 498
	}
	
	capture findfile pexit.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package pexit needs to be installed first;"
		 di as txt "use -ssc install pexit- to do that"
		 exit 498
	}
	
	capture macro drop debug
	
	syntax [, debug debroute(string) double hard ignorefold logfile(string) omit proj(string) route(string)]
	
	// Clean session
	clear all
	discard
	
	// Check that user parameters are correct
	if "`hard'" == "hard" & ("`debug'" == "debug" | "`omit'" == "omit"){
		di "Cannot use option 'hard' with either 'debug' or 'omit'"
		error 184
	}
	
	// Define global debug and omit
	gl deb = "`debug'"
	gl omit = "`omit'"
	
	// Optionally set type double
	if "`double'" == "double"{ 
		set type double
	}
	
	// Set working directory
	if ("$deb" == "debug" & "`proj'" != "") { // In debug mode change to route if specified
		project `proj' , cd
		if "`debroute'" != ""{ // If debroute specified change WD with respect to root directory
			cd `debroute'
		}
	}
	else if "`route'" != "" & "$deb" == ""{
			cd `route'
	}
	
	// If log option set and not in debug mode open logile
	if ("$deb" == "" & "`logfile'" != "") {
		cap log close
		mata : st_numscalar("LogExists", direxists("./log/")) //check if a log directory exists
		
		local LogFolderSpecified = strpos("`logfile'", "log/") + strpos("`logfile'", "log\")
		
		// If directory exists, but wasn't specified by user, then store logfile there
		if LogExists == 1 & `LogFolderSpecified' == 0 & "`ignorefold'" == ""{ 
			local logfile = "./log/" + "`logfile'"
		}
		log using "`logfile'" , replace
	}
	
	// Optionally drop all macros
	if "`hard'" == "hard"{
		macro drop _all
	}
end
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
	program define isorder , rclass
	syntax varlist
	
	tempvar order1 order2
		
	gen `order1' = _n
	
	sort `varlist'
	
	gen `order2' = _n
	
	qui count if `order1' != `order2'
	
	local counts = r(N)
	
	if `counts' == 0{
		di "Database ordered according to `varlist'"
		local statusval 1
	}
	else{
		di "Database is NOT ordered according to `varlist'"
		local statusval 0
	}
		
	return local ordered `statusval'
end
program mcompare , rclass
version 14
	syntax varlist(min=2)
	local counter = 0
	foreach var in `varlist'{
		local `counter++'
	}

	token `varlist'
	
	forvalues i=2(1)`counter'{
		compare `1' ``i''
	}
end
program define merge2 , rclass
version 14	
	syntax varlist , type(string) file(string asis) ///
		[datevar(varlist) tdate(string) ///
		fdate(string) moptions(string)  ///
		idstr(varlist) idnum(varlist) original debug]
	
	// If not in debug mode register project functionality
	if "`debug'" == ""{
		if "`original'" == "" {
			project, uses(`file') preserve	
		}
		else{
			project, original(`file') preserve
		}
	}
	
	// Routine if user selected a DTA file as using file
	if strpos(`file', ".dta") > 0{
		// Check for invalid options when using DTA files as using file
		if "`datevar'" != "" | "`tdate'" != "" | "`fdate'" != "" | "`idstr'" != "" |"`idnum'" != ""{
			di "Only variables file, type, varlist, original and debug are allowed when using file is a STATA file."
			error 601
		}
		
		if "`moptions'" != "" {
			merge `type' `varlist' using `file' , `moptions'
		}
		else {
			merge `type' `varlist' using `file'
		}
	}
	else { // Routine if user selected a CSV file as using file
		tempfile masterfile usingfile
			
		// Save masterfile and import using file -----------------------------------
		save `masterfile'
		import delimited using `file' , clear case(preserve)
		
		// If requested string/destring variables
		if "`idnumeric'" != ""{
			destring `idnumeric' , replace
		}
		if "`idstring'" != ""{
			tostring `idstring' , replace
		}
		
		// If requested create a date variable
		if "`datevar'" != "" {
			tempvar newdate
			
			gen `newdate' = date(`datevar', "`tdate'")
			drop `datevar'
			gen `datevar' = `newdate'
			format `fdate' `datevar'
		}
	
		save `usingfile'
		// ---------------------------------------------------------------------------
		
		// Load masterfile and perform merge
		use `masterfile' , clear
		
		// If requested string/destring variables
		if "`idnumeric'" != ""{
			destring `idnumeric' , replace
		}
		if "`idstring'" != ""{
			tostring `idstring' , replace
		}
		
		// Merge
		if "`moptions'" != "" {
			merge `type' `varlist' using `usingfile' , `moptions'
		}
		else {
			merge `type' `varlist' using `usingfile'
		}
	}
end
program define missing2zero , rclass
version 14
	syntax varlist [, substitute(string) mean bys(varlist)]
	
	// Check for mixed-types in varlist
	local rcSum 	= 0 // rcSum > 0 indicates at least one string variable
	local rcProduct = 1 // rcProduct == 0 indicates at least one numeric variable
	
	local byscount = 0
	foreach var in `bys' {
		local `byscount++'
	}
	
	foreach var in `varlist'{
		capture confirm numeric variable `var'
		local rcSum 	= `rcSum' + _rc
		local rcProduct = `rcProduct'*_rc
	}
		
	if `rcSum' > 0 & `rcProduct' == 0{
		di "Cannot mix numeric and string variables"
		exit 109
	}
	
	if "`substitute'" != "" & "`mean'" == "mean" {
		di as error "'substitute' cannot be combined with 'mean'"
		exit
	}
	
	if `rcSum' > 0 & "`mean'" == "mean" {
		di as error "'mean' is not defined for string variables"
		exit
	}
	
	// Assign default values if none specified
	if `rcSum' == 0 & "`substitute'" == ""{ // If numeric variables specified
		local substitute = 0
	}
	else if `rcProduct' > 0 &  "`substitute'" == "" { // If string variables specified
		local substitute "NaN"
	}
	
	foreach var in `varlist'{
		capture confirm numeric variable `var' // check type of variable
		
		if _rc == 0 { // If numeric
			if "`mean'" == "mean" { // if user wants to fill missing with mean value
				tempvar vartemp
				
				if `byscount' > 0 {
					bys `bys': egen `vartemp' = mean(`var')
				}
				else {
					 egen `vartemp' = mean(`var')
				}
				
				qui replace `var' = `vartemp' if missing(`var')
				drop `vartemp'
			}
			else { // if user wants to fill with zero or custom value
				recode `var' (. = `substitute')
			}
		} // If string
		else {
			qui replace `var' = "`substitute'" if `var' == ""
		}
	}
end
program define pdo , rclass
	version 14
	syntax , file(string) [debug quietly]
	
	if "`debug'" == "debug"{
		`quietly' do "`file'"
	}
	else{
		project , do("`file'")
	}
end
program define pexit , rclass
	version 14
	capture findfile project.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package project needs to be installed first;"
		 di as txt "use -ssc install project- to do that"
		 exit 498
	}
	
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax [, summary(string) debug]
	if "`debug'" == ""{
		cap log close
		
		if "`summary'" != ""{
			eststo clear
			estpost summarize _all
			esttab using "`summary'" , ///
			cells("mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))") ///
			nomtitle nonumber replace
		}
	}
	
	exit
end
program polgenerate
	syntax varlist(numeric) , p(int)
	
	foreach var in `varlist'{
		forvalues i = 2(1)`p'{
			* Generate variable
			cap gen `var'_`i' = `var'^`i'
			
			* Label variable
			local lab: variable label `var'
			label variable `var'_`i' "`lab', p(`i')"
		}
	}
end
program define psave , rclass
	version 14
	
	// Verify dependencies
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax , file(string asis) [clear com csvnone debug eopts(string) ///
			old(string) preserve]
	
	if "`clear'" == "clear"{
		di "Option clear is ignored in psave"
	}
	
	// Drops CSV, DTA file extensions, if any are present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	// Define names for output files
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	local filedta_old = "`newfile'" + "_v`old'" + ".dta"
	
	// If csvnone is selected, check that CSV file doesn't exist
	if "`csvnone'" == "csvnone"{
		capture confirm file "`filecsv'"
		if _rc ==0{ //If CSV file exists throw exception
			di "CSV file already exists. Consider deleting it or avoiding option csvnone."
			error 602
		}
	}
	
	// Optionally compress to save information
	if "`com'" == "com"{
		qui compress
	}
	
	// Save DTA in current format
	save "`filedta'" , replace
	
	// Optionally save DTA in old version
	if "`old'" != ""{
		confirm integer number `old'
		saveold "`filedta_old'" , replace version(`old')
	}
	
	// If debug and CSVnone are not set, store CSV
	if "`debug'" == "" & "`csvnone'" == ""{
		export delimited using "`filecsv'", replace `eopts'
		project, creates("`filecsv'") `preserve'
	}

	// Register with project
	if "`debug'" == "" & "`csvnone'" == "csvnone"{
		project , creates("`filedta'") `preserve'
	}
end
program define puse, rclass
	version 14
	
	/*
		puse tries to read data and register project functionality in the following
		order (unless specified otherwise by user):
		
		Read:
			1. DTA
			2. CSV
			3. Excel
		project:
			1. CSV
			2. DTA
			3. Excel
	*/
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax, file(string asis) [clear debug opts(string) original preserve]
	
	if "`preserve'" == "preserve"{
		di "Option preserve is ignored in puse"
	}
	
	// Generate names of files based on extension
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	if strpos(`file', ".xls") > 0{
		local filexls = `file'
	}
		
	// Check existance of files
	capture confirm file "`filedta'"
	local dtaExists = _rc
	
	capture confirm file "`filecsv'"
	local csvExists = _rc
	
	capture confirm file "`filexls'"
	local xlsExists = _rc
	
	local exists = min(`dtaExists', `csvExists', `xlsExists')
	
	if `exists' != 0{
		di as error "No files found: `filedta'	 `filecsv'	`filexls'"
		error 601
	}
	
	// Throw exception if user specifies a file extension, but puse reads a different one.
	if strpos(`file', ".csv") > 0 & `dtaExists' == 0{
		di as error "CSV specified, but puse reads DTA file."
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `dtaExists' == 0{
		di as error "XLS specified, but puse reads DTA file"
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `csvExists' == 0{
		di as error "XLS/XLSX specified, but puse reads CSV file"
		error 601
	}
	
	// Import data
	if `dtaExists' ==0{ //If DTA file exists read DTA file
		use "`filedta'" , `clear'	
	} 
	else if `csvExists' == 0{ // If no DTA present and CSV exists, read CSV
		import delimited using "`filecsv'", ///
		`clear' case(lower) `opts'
	}
	else if `xlsExists' == 0 { // Otherwise read Excel
		if "`opts'" == "" & "`clear'" == ""{
			import excel using "`filexls'"
		}
		else {
			import excel using "`filexls'" , `opts' `clear'
		}
	}
	
	*** CSV files are better for project functionality since they don't
	*** store metadata
	
	// Register project functionality
	if `csvExists' == 0{ // If  CSV file exists register project functionality using CSV
		if "`debug'" == ""{ // If debug option wasn't set, use project functionality
			if "`original'" == ""{
				project , uses("`filecsv'") preserve
				}
			else{
				project , original("`filecsv'") preserve
				}
			}
		}
	else if strpos(`file', ".xls") == 0{ // IF CSV wasn't found and no Excel file specified, register project using DTA
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filedta'") preserve
				}
			else{
					project , original("`filedta'") preserve
				}
			}
		}
	else {
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filexls'") preserve
					}
			else{
				project , original("`filexls'") preserve
				}
			}
		}
end
program define sumby , rclass
version 14
	syntax varlist , by(varlist max=1)
	
	local condvar `by'
	tokenize `varlist'
	
	local counter = 0
	foreach k in `varlist'{
		local `counter++'
	}
	
	qui levelsof `condvar' , local(categories)
	
	forvalues k = 1(1)`counter'{
		foreach cat in `categories'{
			di "`condvar' == `cat':" 
			su ``k'' if `condvar' == `cat'
	}
	}
end
program timedummy, rclass
version 14
	syntax , epoch(varlist min=1 max=1) periods(string) varstem(string)  ///
		[leftperiods(string) surround]

			if "`leftperiods'" == "" {
				local leftperiods = `periods'
			}
			
			cap gen `varstem' = (`epoch' == 0)
			label variable `varstem' "0"
			
			forvalues i = 1(1)`leftperiods' {
				qui gen `varstem'_f`i' = (`epoch' == -`i')
				label variable `varstem'_f`i' "-`i'"
			}
			
			forvalues i = 1(1)`periods' {
				qui gen `varstem'_l`i' = (`epoch' == `i')
				label variable `varstem'_l`i' "`i'"
			}
			
			// Create variables for pre and postperiods if surround was selected
			if "`surround'" == "surround" {
				qui gen `varstem'_pre = (`epoch' < -`leftperiods')
				label variable `varstem'_pre "pre"
				
				qui gen `varstem'_post = (`epoch' > `periods')
				label variable `varstem'_post "post"
			}
endprogram define tsperiods , rclass
	version 14
	syntax , bys(varlist min=1) datevar(varlist min=1 max=1) ///
		periods(string) ///
		[event(varlist min=1 max=1) eventdate(varlist min=1 max=1) ///
		ignore_panel maxperiods(string) mevents name(string) ///
		overlap(string) symmetric]
	
	// Sort data by ID and date
	sort `bys' `datevar'
	
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
	if "`ignore_panel'" == "" {	
		tempvar nvals
		by `bys' `datevar': gen `nvals' = _n
		qui count if `nvals' > 1
		local counts = r(N)
		if `counts' > 0 {
			di "{err}`bys' and `datevar' do not uniquely identify observations"
			exit
		}
	}
	else { // the check of multiple events fails if we are not working with a 'real' panel
		if "`mevents'" == "" {
			di "{err}'ignore_panel' requires 'mevents'"
			exit
		}
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

		keep `bys' `datevar'
		
		if "`ignore_panel'" == "ignore_panel" {
			duplicates drop `bys' `datevar', force
		}
		
		sort `bys' `datevar'
		by `bys': gen nvals = _n // identifies order of events within panel ID
		
		save `count_events'
		
		restore
		
		qui merge m:1 `bys' `datevar' using `count_events'  , nogen
		
		qui su nvals
		local max = r(max)

		local varlist
		
		qui gen `datediff' = .
		
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
		// If ignore_panel is selected, assume that ID x datevar do not uniquely
		// identify observations. We solve this by forcing a 'real' panel
		// where ID x datevar identifies observations. Then we compute overlapping
		// windows and event-ID indicators for this panel and merge to original at end.
		if "`ignore_panel'" == "ignore_panel" {
		
			tempfile savepoint
			save `savepoint'
			if `datecount' > 0 {
				local other_keep `eventdate'
			}
			
			keep `bys' `datevar' `name' `other_keep'
			duplicates drop `bys' `datevar' `name', force
		}
		
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
		
		if "`ignore_panel'" == "ignore_panel" {
			merge 1:m `bys' `datevar' using `savepoint', nogen
		}
		
		drop `diff' `startevent'
	}
	
	// Generate 'eventnr' variable if 'mevents' was NOT specified,
	// for those ID's with no event
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
program twowayscatter , rclass
version 14
	syntax varlist(min=2 max=3) ///
	 [ ,  color1(string) color2(string) conditions(string) ///
		debug file(string) lfit ///
	    type1(string) type2(string) ncorr singleaxis omit]
	
	if "`omit'" == "omit"{
		di "Graph skipped: `file'"
		exit
	}
	
	if "`type1'" == ""{
		local type1 "scatter"
	}
	
	if "`type2'" == ""{
		local type2 "scatter"
	}
	
	local k = 0
	foreach var in `varlist'{
			local `k++'
	}
		
	token `varlist'

	if "`lfit'" == "lfit"{
		local linegraph "(lfit `1' `2')"
	}
	
	if "`ncorr'" != "ncorr" {
		qui corr `1' `2' `conditions'
		local corr : di  %5.3g r(rho)
		local corrs "subtitle(correlation `corr')"
	}
	
	if "`singleaxis'" != "singleaxis"{
		local yaxisval "yaxis(2)"
	}

	if `k' == 3{
		if "`color1'" != "" & "`color2'" != ""{
		twoway (`type1' `1' `3' `conditions' , mcolor("`color1'")) ///
			(`type2' `2' `3' `conditions' , `yaxisval' mcolor("`color2'")) `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
		else {
		twoway (`type1' `1' `3' `conditions') ///
			(`type2' `2' `3' `conditions'  , `yaxisval') `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
	}
	else if `k' == 2{
		if "`color1'" != "" {
		twoway (`type1' `1' `2' `conditions' , mcolor("`color1'")) `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
		else {
		twoway (`type1' `1' `2' `conditions') `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
	}
	
	if "`file'" != ""{
		graph2 , file("`file'") `debug'
	}
end
program define uniquevals , rclass
version 14
	syntax varlist [if]
	tempvar condition	
	
	if "`if'" != ""{
		qui gen `condition' = 1 `if'
		local localif "& `condition' == 1"
	}
	
	foreach var in `varlist'{
		tempvar j
		bys `var': gen `j' = _n
		qui count if `j' == 1 `localif'
		di "`var' has " r(N) " distinct values"
		drop `j'
	}
end
program usstates , rclass
syntax varlist(min=1 max=1) , newvar(string) type(string) 
	
	if "`type'" != "full" & "`type'" != "abbv"{
		di "Please provide a valid option for type (full or abbv)"
		exit
	}
	
	token `varlist'
	local var `1'
	
	qui gen `newvar' = ""

	if "`type'" == "full" {
		qui replace `newvar' = "AK" if `var' == "Alaska"
		qui replace `newvar' = "AL" if `var' == "Alabama"
		qui replace `newvar' = "AR" if `var' == "Arkansas"
		qui replace `newvar' = "AZ" if `var' == "Arizona"
		qui replace `newvar' = "CA" if `var' == "California"
		qui replace `newvar' = "CO" if `var' == "Colorado"
		qui replace `newvar' = "CT" if `var' == "Connecticut"
		qui replace `newvar' = "DC" if `var' == "DC"
		qui replace `newvar' = "DE" if `var' == "Delaware"
		qui replace `newvar' = "FL" if `var' == "Florida"
		qui replace `newvar' = "GA" if `var' == "Georgia"
		qui replace `newvar' = "HI" if `var' == "Hawaii"
		qui replace `newvar' = "IA" if `var' == "Iowa"
		qui replace `newvar' = "ID" if `var' == "Idaho"
		qui replace `newvar' = "IL" if `var' == "Illinois"
		qui replace `newvar' = "IN" if `var' == "Indiana"
		qui replace `newvar' = "KS" if `var' == "Kansas"
		qui replace `newvar' = "KY" if `var' == "Kentucky"
		qui replace `newvar' = "LA" if `var' == "Louisiana"
		qui replace `newvar' = "MA" if `var' == "Massachusetts"
		qui replace `newvar' = "MD" if `var' == "Maryland"
		qui replace `newvar' = "ME" if `var' == "Maine"
		qui replace `newvar' = "MI" if `var' == "Michigan"
		qui replace `newvar' = "MN" if `var' == "Minnesota"
		qui replace `newvar' = "MO" if `var' == "Missouri"
		qui replace `newvar' = "MS" if `var' == "Mississippi"
		qui replace `newvar' = "MT" if `var' == "Montana"
		qui replace `newvar' = "NC" if `var' == "North Carolina"
		qui replace `newvar' = "ND" if `var' == "North Dakota"
		qui replace `newvar' = "NE" if `var' == "Nebraska"
		qui replace `newvar' = "NH" if `var' == "New Hampshire"
		qui replace `newvar' = "NJ" if `var' == "New Jersey"
		qui replace `newvar' = "NM" if `var' == "New Mexico"
		qui replace `newvar' = "NV" if `var' == "Nevada"
		qui replace `newvar' = "NY" if `var' == "New York"
		qui replace `newvar' = "OH" if `var' == "Ohio"
		qui replace `newvar' = "OK" if `var' == "Oklahoma"
		qui replace `newvar' = "OR" if `var' == "Oregon"
		qui replace `newvar' = "PA" if `var' == "Pennsylvania"
		qui replace `newvar' = "RI" if `var' == "Rhode Island"
		qui replace `newvar' = "SC" if `var' == "South Carolina"
		qui replace `newvar' = "SD" if `var' == "South Dakota"
		qui replace `newvar' = "TN" if `var' == "Tennessee"
		qui replace `newvar' = "TX" if `var' == "Texas"
		qui replace `newvar' = "UT" if `var' == "Utah"
		qui replace `newvar' = "VA" if `var' == "Virginia"
		qui replace `newvar' = "VT" if `var' == "Vermont"
		qui replace `newvar' = "WA" if `var' == "Washington"
		qui replace `newvar' = "WI" if `var' == "Wisconsin"
		qui replace `newvar' = "WV" if `var' == "West Virginia"
		qui replace `newvar' = "WY" if `var' == "Wyoming"
	}

	if "`type'" == "abbv"{
		qui replace `newvar' = "Alaska" if `var' == "AK"
		qui replace `newvar' = "Alabama" if `var' == "AL"
		qui replace `newvar' = "Arkansas" if `var' == "AR"
		qui replace `newvar' = "Arizona" if `var' == "AZ"
		qui replace `newvar' = "California" if `var' == "CA"
		qui replace `newvar' = "Colorado" if `var' == "CO"
		qui replace `newvar' = "Connecticut" if `var' == "CT"
		qui replace `newvar' = "DC" if `var' == "DC"
		qui replace `newvar' = "Delaware" if `var' == "DE"
		qui replace `newvar' = "Florida" if `var' == "FL"
		qui replace `newvar' = "Georgia" if `var' == "GA"
		qui replace `newvar' = "Hawaii" if `var' == "HI"
		qui replace `newvar' = "Iowa" if `var' == "IA"
		qui replace `newvar' = "Idaho" if `var' == "ID"
		qui replace `newvar' = "Illinois" if `var' == "IL"
		qui replace `newvar' = "Indiana" if `var' == "IN"
		qui replace `newvar' = "Kansas" if `var' == "KS"
		qui replace `newvar' = "Kentucky" if `var' == "KY"
		qui replace `newvar' = "Louisiana" if `var' == "LA"
		qui replace `newvar' = "Massachusetts" if `var' == "MA"
		qui replace `newvar' = "Maryland" if `var' == "MD"
		qui replace `newvar' = "Maine" if `var' == "ME"
		qui replace `newvar' = "Michigan" if `var' == "MI"
		qui replace `newvar' = "Minnesota" if `var' == "MN"
		qui replace `newvar' = "Missouri" if `var' == "MO"
		qui replace `newvar' = "Mississippi" if `var' == "MS"
		qui replace `newvar' = "Montana" if `var' == "MT"
		qui replace `newvar' = "North Carolina" if `var' == "NC"
		qui replace `newvar' = "North Dakota" if `var' == "ND"
		qui replace `newvar' = "Nebraska" if `var' == "NE"
		qui replace `newvar' = "New Hampshire" if `var' == "NH"
		qui replace `newvar' = "New Jersey" if `var' == "NJ"
		qui replace `newvar' = "New Mexico" if `var' == "NM"
		qui replace `newvar' = "Nevada" if `var' == "NV"
		qui replace `newvar' = "New York" if `var' == "NY"
		qui replace `newvar' = "Ohio" if `var' == "OH"
		qui replace `newvar' = "Oklahoma" if `var' == "OK"
		qui replace `newvar' = "Oregon" if `var' == "OR"
		qui replace `newvar' = "Pennsylvania" if `var' == "PA"
		qui replace `newvar' = "Rhode Island" if `var' == "RI"
		qui replace `newvar' = "South Carolina" if `var' == "SC"
		qui replace `newvar' = "South Dakota" if `var' == "SD"
		qui replace `newvar' = "Tennessee" if `var' == "TN"
		qui replace `newvar' = "Texas" if `var' == "TX"
		qui replace `newvar' = "Utah" if `var' == "UT"
		qui replace `newvar' = "Virginia" if `var' == "VA"
		qui replace `newvar' = "Vermont" if `var' == "VT"
		qui replace `newvar' = "Washington" if `var' == "WA"
		qui replace `newvar' = "Wisconsin" if `var' == "WI"
		qui replace `newvar' = "West Virginia" if `var' == "WV"
		qui replace `newvar' = "Wyoming" if `var' == "WY"
	}


	if "`type'" == "full"{
		local var `newvar'
	}

	qui gen `newvar'_num = .

	qui replace `newvar'_num = 1 if `var' == "AK"
	qui replace `newvar'_num = 2 if `var' == "AL"
	qui replace `newvar'_num = 3 if `var' == "AR"
	qui replace `newvar'_num = 4 if `var' == "AZ"
	qui replace `newvar'_num = 5 if `var' == "CA"
	qui replace `newvar'_num = 6 if `var' == "CO"
	qui replace `newvar'_num = 7 if `var' == "CT"
	qui replace `newvar'_num = 8 if `var' == "DC"
	qui replace `newvar'_num = 9 if `var' == "DE"
	qui replace `newvar'_num = 10 if `var' == "FL"
	qui replace `newvar'_num = 11 if `var' == "GA"
	qui replace `newvar'_num = 12 if `var' == "HI"
	qui replace `newvar'_num = 13 if `var' == "IA"
	qui replace `newvar'_num = 14 if `var' == "ID"
	qui replace `newvar'_num = 15 if `var' == "IL"
	qui replace `newvar'_num = 16 if `var' == "IN"
	qui replace `newvar'_num = 17 if `var' == "KS"
	qui replace `newvar'_num = 18 if `var' == "KY"
	qui replace `newvar'_num = 19 if `var' == "LA"
	qui replace `newvar'_num = 20 if `var' == "MA"
	qui replace `newvar'_num = 21 if `var' == "MD"
	qui replace `newvar'_num = 22 if `var' == "ME"
	qui replace `newvar'_num = 23 if `var' == "MI"
	qui replace `newvar'_num = 24 if `var' == "MN"
	qui replace `newvar'_num = 25 if `var' == "MO"
	qui replace `newvar'_num = 26 if `var' == "MS"
	qui replace `newvar'_num = 27 if `var' == "MT"
	qui replace `newvar'_num = 28 if `var' == "NC"
	qui replace `newvar'_num = 29 if `var' == "ND"
	qui replace `newvar'_num = 30 if `var' == "NE"
	qui replace `newvar'_num = 31 if `var' == "NH"
	qui replace `newvar'_num = 32 if `var' == "NJ"
	qui replace `newvar'_num = 33 if `var' == "NM"
	qui replace `newvar'_num = 34 if `var' == "NV"
	qui replace `newvar'_num = 35 if `var' == "NY"
	qui replace `newvar'_num = 36 if `var' == "OH"
	qui replace `newvar'_num = 37 if `var' == "OK"
	qui replace `newvar'_num = 38 if `var' == "OR"
	qui replace `newvar'_num = 39 if `var' == "PA"
	qui replace `newvar'_num = 40 if `var' == "RI"
	qui replace `newvar'_num = 41 if `var' == "SC"
	qui replace `newvar'_num = 42 if `var' == "SD"
	qui replace `newvar'_num = 43 if `var' == "TN"
	qui replace `newvar'_num = 44 if `var' == "TX"
	qui replace `newvar'_num = 45 if `var' == "UT"
	qui replace `newvar'_num = 46 if `var' == "VA"
	qui replace `newvar'_num = 47 if `var' == "VT"
	qui replace `newvar'_num = 48 if `var' == "WA"
	qui replace `newvar'_num = 49 if `var' == "WI"
	qui replace `newvar'_num = 50 if `var' == "WV"
	qui replace `newvar'_num = 51 if `var' == "WY"

end
program define values2ascii , rclass
	syntax varlist [, tolower punct]
	
	// 1. Eliminate accents
	foreach var in `varlist'{
		qui replace `var' = subinstr(`var',"á","a",.)
		qui replace `var' = subinstr(`var',"é","e",.)
		qui replace `var' = subinstr(`var',"í","i",.)
		qui replace `var' = subinstr(`var',"ó","o",.)
		qui replace `var' = subinstr(`var',"ú","u",.)
		qui replace `var' = subinstr(`var',"ñ","n",.)
		
		qui replace `var' = subinstr(`var',"Á","A",.)
		qui replace `var' = subinstr(`var',"É","E",.)
		qui replace `var' = subinstr(`var',"Í","I",.)
		qui replace `var' = subinstr(`var',"Ó","O",.)
		qui replace `var' = subinstr(`var',"Ú","U",.)
		qui replace `var' = subinstr(`var',"Ñ","N",.)
	}

	// 2. Lowercase variables
	if "`tolower'" == "tolower"{
		foreach var in `varlist'{
			qui replace `var' = lower(`var')
		}
	}
	
	// 3. Punctuation
	if "`punct'" == "punct"{
		foreach var in `varlist'{
			qui replace `var' = subinstr(`var',".","",.)
			qui replace `var' = subinstr(`var',",","",.)
			qui replace `var' = subinstr(`var',";","",.)
			qui replace `var' = subinstr(`var',"!","",.)
			qui replace `var' = subinstr(`var',"¡","",.)
			qui replace `var' = subinstr(`var',"(","",.)
			qui replace `var' = subinstr(`var',")","",.)
			qui replace `var' = subinstr(`var',"[","",.)
			qui replace `var' = subinstr(`var',"]","",.)
			qui replace `var' = subinstr(`var',"-","",.)
			qui replace `var' = subinstr(`var',"@","",.)
			qui replace `var' = subinstr(`var',"_","",.)
		}
	}
	
	// 4. Eliminate spaces
	foreach var in `varlist'{ // Loop over variables
		qui replace `var' = subinstr(`var', char(10),"",.)
		qui replace `var' = subinstr(`var', char(13),"",.)
		qui replace `var' = strltrim(`var')
		
		// Eliminate leading and trailing blank spaces
		tempvar strLength marker
		qui gen `strLength' = strlen(`var')
		
		qui levelsof `var' , local(uniquevals)
		
		local j = 1
		qui gen `marker' = .
		
		foreach cat in `uniquevals'{ // Loop over categories of variable
			qui replace `marker' = `j' if `var' == "`cat'"
			local `j++'
		}
		
		local j = 1
		
		foreach cat in `uniquevals'{ // Loop over categories of variable
			qui sum `strLength' if `marker' == `j' , mean
			local length = r(mean)
			
			// Eliminate trailing space if present
			if substr("`cat'", `length', 1) == " "{
				local length = `length' - 1
				qui replace `var' = substr(`var',1,`length') if `marker' == `j'
			}
			else if substr("`cat'", 1, 1) == " "{ // Eliminate leading space if present
				qui replace `var' = substr(`var',2,`length') if `marker' == `j'
			}
			
			local `j++'
		} // End loop over categories of variables
		
		drop `strLength' `marker'
	} // End loop over variables
end
