program twowayscatter , rclass
version 14
	syntax varlist(min=2 max=3) ///
	 [ ,  color1(string) color2(string) file(string) ///
	  conditions(string) debug]
	
	local k = 0
	foreach var in `varlist'{
			local `k++'
	}
	 
	token `varlist'
	qui corr `1' `2' `conditions'
	local corr : di  %5.3g r(rho)

	if `k' == 3{
		if "`color1'" != "" & "`color2'" != ""{
		twoway (scatter `1' `3' `conditions' , mcolor("`color1'")) ///
			(scatter `2' `3' `conditions' , yaxis(2) mcolor("`color2'")) , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
		else {
		twoway (scatter `1' `3' `conditions') ///
			(scatter `2' `3' `conditions' , yaxis(2)) , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
	}
	else if `k' == 2{
		if "`color1'" != "" {
		twoway (scatter `1' `2' `conditions' , mcolor("`color1'")) , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
		else {
		twoway (scatter `1' `2' `conditions') , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
	}
	
	if "`file'" != ""{
		graph2 , file("`file'") `debug'
	}
end
