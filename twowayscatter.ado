program twowayscatter , rclass
version 14
	syntax varlist(min=2 max=3) ///
	 [ ,  color1(string) color2(string) conditions(string) ///
		debug file(string) lfit ///
	    type1(string) type2(string)]
	
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
	qui corr `1' `2' `conditions'
	local corr : di  %5.3g r(rho)

	if "`lfit'" == "lfit"{
		local linegraph "(lfit `1' `2')"
	}

	if `k' == 3{
		if "`color1'" != "" & "`color2'" != ""{
		twoway (`type1' `1' `3' `conditions' , mcolor("`color1'")) ///
			(`type2' `2' `3' `conditions' , yaxis(2) mcolor("`color2'")) `linegraph' , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
		else {
		twoway (`type1' `1' `3' `conditions') ///
			(`type2' `2' `3' `conditions'  , yaxis(2)) `linegraph' , ///
			graphregion(color(white)) subtitle("correlation `corr'") 
		}
	}
	else if `k' == 2{
		if "`color1'" != "" {
		twoway (`type1' `1' `2' `conditions' , mcolor("`color1'")) `linegraph' , ///
			graphregion(color(white)) subtitle("correlation `corr'")
		}
		else {
		twoway (`type1' `1' `2' `conditions') `linegraph' , ///
			graphregion(color(white)) subtitle("correlation `corr'") 
		}
	}
	
	if "`file'" != ""{
		graph2 , file("`file'") `debug'
	}
end
