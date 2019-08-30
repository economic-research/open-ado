program evstudy , rclass
version 14
	syntax varlist , basevar(string) file(string) periods(string) ///
		tline(string) varstem(varlist min=1 max=1)  [absorb(varlist) ///
		bys(varlist min=1) cl(varlist min=1) datevar(varlist min=1 max=1) debug ///
		generate kernel kopts(string) qui othervar(varlist min=2 max=2)]
	

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
	
	// Verify that is option generate was selected, then bys and datevar specified
	if "`generate'" == "generate"{
		if `byscount' == 0 | `datecount' == 0{
			di "{err}Need to specify bys and datevar if option generate is specified"
			exit
		}
	}
	
	
	if `clcount' > 0 {
		local cluster "cl(`cl')"
	}
	
	// Optionally build leads and lags
	if "`generate'" == "generate"{
		tsperiods , bys(`bys') datevar(`datevar') maxperiods(`periods') ///
			periods(1) event(`varstem') name(myevent)
			
		forvalues i = 1(1)`periods'{
			qui gen `varstem'_f`i' = (myevent == -`i')
			label variable `varstem'_f`i' "t-`i'"
			
			qui gen `varstem'_l`i' = (myevent == `i')
			label variable `varstem'_l`i' "t+`i'"
		}
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
	
	forvalues i = `periods'(-1)1{
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
	
	`qui' reghdfe `varlist' `regressors' , absorb(`absorb') `cluster'
	`qui' nlcom `conditions' , post
	
	if "`kernel'" == "kernel"{
		preserve
		regsave
		
		tempvar days post
		qui gen `days' 		= _n
		qui replace `days' 	= `days' - `periods'
		
		qui gen `post' 		= (`days' > -1)
		
		graph twoway (scatter coef `days' if !`post', msize(small) graphregion(color(white)) graphregion(lwidth(vthick))) ///
			(lpoly coef `days' if !`post', lcolor(navy) `kopts') ///
			(scatter coef `days' if `post', msize(small) color(cranberry*0.5)) ///
			(lpoly coef `days' if `post', tline(`tline', lc(red)) lcolor(cranberry) `kopts') , legend(off)
		
		restore
	}
	else {
		coefplot, ci(90) yline(0, lp(solid) lc(black)) vertical xlabel(, angle(vertical)) ///
		graphregion(color(white)) tline(`tline', lp(solid) lc(red)) xsize(8)
	}
	
	graph2 , file("`file'") `debug'
end
