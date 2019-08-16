program evstudy , rclass
version 14
	syntax varlist , basevar(string) debug file(string) periods(string) ///
		tline(string) varstem(string)  [absorb(varlist) cl(varlist) ///
		othervar(varlist min=2 max=2)]
	
	// Check if othervar is empty
	local j = 0
	foreach var in `othervar'{
		local `j++' // othervar is empty if `j' == 0
	}
	
	// Build regression parameters in loop
	local conditions ""
	local regressors ""
	
	// Leads of the RHS correspond to "pre-trend" = before treatment
	if `j' > 0 {
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
	
	if `j' > 0 {
		local conditions "`conditions' (`2':_b[`2']-_b[`basevar'])"
		local regressors "`regressors' `2'"
	}
	
	// Regression
	reghdfe `varlist' `regressors' , absorb(`absorb') cl(`cl')
	nlcom `conditions' , post
				
	coefplot, ci(90) yline(0, lp(solid) lc(black)) vertical xlabel(, angle(vertical)) ///
	graphregion(color(white)) tline(`tline', lp(solid) lc(red)) xsize(8)
	graph2 , file("`file'") `debug'
end
