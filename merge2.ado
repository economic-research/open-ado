program define merge2 , rclass
version 14	
	syntax varlist , type(string) file(string asis) ///
		[datevar(varlist) tdate(string) ///
		fdate(string) moptions(string)  ///
		idstr(varlist) idnum(varlist) original debug]
	
	// If not in debug mode register project functionality
	if "`debug'" == ""{
		if "`original'" == "" {
			project, uses(`file') preserve	
		}
		else{
			project, original(`file') preserve
		}
	}
	
	// Routine if user selected a DTA file as using file
	if strpos(`file', ".dta") > 0{
		// Check for invalid options when using DTA files as using file
		if "`datevar'" != "" | "`tdate'" != "" | "`fdate'" != "" | "`idstr'" |"`idnum'" != ""{
			di "Only variables file, type, varlist, original and debug are allowed when using file is a STATA file."
			error 601
		}
		
		if "`moptions'" != "" {
			merge `type' `varlist' using `file' , `moptions'
		}
		else {
			merge `type' `varlist' using `file'
		}
	}
	else { // Routine if user selected a CSV file as using file
		tempfile masterfile usingfile
			
		// Save masterfile and import using file -----------------------------------
		save `masterfile'
		import delimited using `file' , clear case(preserve)
		
		// If requested string/destring variables
		if "`idnumeric'" != ""{
			destring `idnumeric' , replace
		}
		if "`idstring'" != ""{
			tostring `idstring' , replace
		}
		
		// If requested create a date variable
		if "`datevar'" != "" {
			tempvar newdate
			
			gen `newdate' = date(`datevar', "`tdate'")
			drop `datevar'
			gen `datevar' = `newdate'
			format `fdate' `datevar'
		}
	
		save `usingfile'
		// ---------------------------------------------------------------------------
		
		// Load masterfile and perform merge
		use `masterfile' , clear
		
		// If requested string/destring variables
		if "`idnumeric'" != ""{
			destring `idnumeric' , replace
		}
		if "`idstring'" != ""{
			tostring `idstring' , replace
		}
		
		// Merge
		if "`moptions'" != "" {
			merge `type' `varlist' using `usingfile' , `moptions'
		}
		else {
			merge `type' `varlist' using `usingfile'
		}
	}
end
