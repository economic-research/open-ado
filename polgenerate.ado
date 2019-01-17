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
