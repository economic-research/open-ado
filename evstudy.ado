program evstudy , rclass
version 14
	syntax varlist [if], basevar(string) periods(string) ///
		varstem(varlist min=1 max=1)  [absorb(varlist) ///
		bys(varlist min=1) cl(varlist min=1) connected datevar(varlist min=1 max=1) debug ///
		file(string) force generate kernel kopts(string) leftperiods(string) ///
		maxperiods(string) mevents nolabel ///
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
				epoch(`myevent') `surround'
			
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
		if "`surround'" == "" {
			est store evstudy
			coefplot (evstudy, mcolor(navy) ciopts(color(navy)) ci(90) yline(0, lp(solid) lc(black)) graphregion(color(white)) xsize(8) tline(7.5, lp(solid) lc(red))), ///
			vertical legend(off) offset(0)  xsize(8) `tlineval' `connected' `twopts' `ylabel_loc' scale(1.1)	
		}
		else {
			est store evstudy
			coefplot (evstudy, keep(`varstem'_pre) mcolor(navy*0.4) ciopts(color(navy*0.4))) ///
			(evstudy, drop(`varstem'_pre `varstem'_post) mcolor(navy) ciopts(color(navy)) ci(90) yline(0, lp(solid) lc(black)) graphregion(color(white)) xsize(8) tline(7.5, lp(solid) lc(red))) ///
			(evstudy, keep(`varstem'_post) mcolor(navy*0.4) ciopts(color(navy*0.4))), ///
			vertical legend(off) offset(0)  xsize(8) `tlineval' `connected' `twopts' `ylabel_loc' scale(1.1)			
		}
	}
	
	if "`file'" != "" {
		graph2 , file("`file'") `debug'
	}
	*----------------------- Generate variables----------------------------------
end
