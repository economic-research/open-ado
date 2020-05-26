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
end