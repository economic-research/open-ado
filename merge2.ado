program define merge2 , rclass
version 14	
	syntax varlist , type(string) file(string asis) ///
		[datevar(varlist) tdate(string) ///
		fdate(string) moptions(string)  ///
		idstr(varlist) idnum(varlist) original debug]
		
	tempfile masterfile usingfile
		
	save `masterfile'
	import delimited using `file' , clear case(preserve)
	
	capture destring `idnumeric' , replace
	capture tostring `idstring' , replace
	
	if "`debug'" == ""{
		if "`original'" == "" {
			project, uses(`file') preserve	
		}
		else{
			project, original(`file') preserve
		}
	}
	
	if "`datevar'" != "" {
		tempvar newdate
		
		gen `newdate' = date(`datevar', "`tdate'")
		drop `datevar'
		gen `datevar' = `newdate'
		format `fdate' `datevar'
	}
	
	capture tostring `idstr', replace
	capture destring `idnum', replace
	
	save `usingfile'
	
	use `masterfile' , clear
	
	capture destring `idstr' , replace
	capture tostring `idnum' , replace
	
	if "`moptions'" != "" {
		merge `type' `varlist' using `usingfile' , `moptions'
	}
	else {
		merge `type' `varlist' using `usingfile'
	}
end
