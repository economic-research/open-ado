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
