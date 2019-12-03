program evstudy , rclass
version 14
	syntax varlist , basevar(string) periods(string) ///
		varstem(varlist min=1 max=1)  [absorb(varlist) ///
		bys(varlist min=1) cl(varlist min=1) datevar(varlist min=1 max=1) debug ///
		file(string) force generate leftperiods(string) kernel kopts(string) mevents qui ///
		othervar(varlist min=2 max=2) tline(string)]
	
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
	
		local maxperiods = max(`periods', `leftperiods')

		tsperiods , bys(`bys') datevar(`datevar') maxperiods(`maxperiods') ///
			periods(1) event(`varstem') `mevents' name(myevent)
			
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
	
	`qui' reghdfe `varlist' `regressors' , `abslocal' `cluster'
	`qui' nlcom `conditions' , post
	
	if "`kernel'" == "kernel"{
		preserve
		regsave
		
		tempvar days post
		qui gen `days' 		= _n
		qui replace `days' 	= `days' - `periods' - 1
		
		qui gen `post' 		= (`days' >= 0)
		
		graph twoway (scatter coef `days' if !`post', msize(small) graphregion(color(white)) graphregion(lwidth(vthick))) ///
			(lpoly coef `days' if !`post', lcolor(navy) `kopts') ///
			(scatter coef `days' if `post', msize(small) color(cranberry*0.5)) ///
			(lpoly coef `days' if `post', `tlineval' lcolor(cranberry) `kopts') , legend(off)
		
		restore
	}
	else {
		coefplot, ci(90) yline(0, lp(solid) lc(black)) vertical xlabel(, angle(vertical)) ///
		graphregion(color(white)) `tlineval' xsize(8)
	}
	
	if "`file'" != "" {
		graph2 , file("`file'") `debug'
	}
end
