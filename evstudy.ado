program evstudy , rclass
version 14
	syntax varlist [if], basevar(string) periods(string) ///
		varstem(varlist min=1 max=1)  [absorb(varlist) ///
		bys(varlist min=1) cl(varlist min=1) datevar(varlist min=1 max=1) debug ///
		file(string) force generate kernel kopts(string) leftperiods(string) mevents ///
		othervar(varlist min=2 max=2) overlap(string) qui  ///
		regopts(string) tline(string) twopts(string)]
	
	*----------------------- Checks ---------------------------------------------
	// Verify that tsperiods is installed
	capture findfile tsperiods.ado
	if "`r(fn)'" == "" {
		 di as txt "user-written package tsperiods needs to be installed first;"
		 exit 498
	}
	
	// Verify that tsperiods is installed
	capture findfile regsave.ado
	if "`r(fn)'" == "" {
		 di as txt "user-written package regsave needs to be installed first;"
		 exit 498
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
	
	*----------------------- Checks ---------------------------------------------
	
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
	
	// Define capture (for use with force option)
	if "`force'" == "force"{
		if "`generate'" == ""{
			di "{err}Option force can only be specified with option generate"
			exit
		}
		local capture cap
	}
	
	// Define tline if one is specified
	if "`tline'" != "" {
		local tlineval "tline(`tline', lp(solid) lc(red))"
	}
	
	// Define periods to the left, if specified
	if "`leftperiods'" == "" {
		local leftperiods = `periods'
	}
	
	// Optionally build leads and lags
	if "`generate'" == "generate"{
		
		if "`overlap'" != "" {
			capture confirm variable overlap // check if overlap was already defined
			
			if !_rc { // If variable overlap doesn't exist, create it
				local overlaploc "overlap(`overlap')"
			}
		}
		
		local maxperiods = max(`periods', `leftperiods')
		
		tsperiods , bys(`bys') datevar(`datevar') maxperiods(`maxperiods') ///
			periods(1) event(`varstem') `mevents' name(myevent) `overlaploc'
			
		// Prevent STATA from storing myevent variable 
		tempvar myevent
		qui gen `myevent' = myevent
		qui drop myevent
			
		forvalues i = 1(1)`leftperiods' {
			`capture' gen `varstem'_f`i' = (`myevent' == -`i')
			label variable `varstem'_f`i' "t-`i'"
		}
		forvalues i = 1(1)`periods' {
			`capture' gen `varstem'_l`i' = (`myevent' == `i')
			label variable `varstem'_l`i' "t+`i'"
		}
		qui drop `myevent'
	}
	
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
		local conditions "`conditions' (`1': _b[`1'] - _b[`basevar'])"
		local regressors "`regressors' `1'"
	}
	
	forvalues i = `leftperiods'(-1)1{
		local conditions "`conditions' (`varstem'_f`i':_b[`varstem'_f`i']-_b[`basevar'])"
		local regressors "`regressors' `varstem'_f`i'"
	}
	
	local conditions "`conditions' (`varstem':_b[`varstem']-_b[`basevar'])"
	local regressors "`regressors' `varstem'"
	
	// Lags correspond to = after treatment
	forvalues i = 1(1)`periods'{
		local conditions "`conditions' (`varstem'_l`i':_b[`varstem'_l`i']-_b[`basevar'])"
		local regressors "`regressors' `varstem'_l`i'"
	}
	
	if `othervarcount' > 0 {
		local conditions "`conditions' (`2':_b[`2']-_b[`basevar'])"
		local regressors "`regressors' `2'"
	}
	
	// ------------------------ Regression -----------------------------------------
	`qui' reghdfe `varlist' `regressors' `overlapctrl' `if', `abslocal' `cluster' `regopts'
	
	// Check if any variables were omitted
	local numcoef = `periods' + `leftperiods' + 1
	
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
			legend(off) `twopts'
		
		restore
	}
	else {
		coefplot, ci(90) yline(0, lp(solid) lc(black)) vertical xlabel(, angle(vertical)) ///
		graphregion(color(white)) `tlineval' xsize(8) recast(connected) `twopts'
	}
	
	if "`file'" != "" {
		graph2 , file("`file'") `debug'
	}
end
