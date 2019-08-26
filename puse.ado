program define puse, rclass
	version 14
	
	/*
		puse tries to read data and register project functionality in the following
		order (unless specified otherwise by user):
		
		Read:
			1. DTA
			2. CSV
			3. Excel
		project:
			1. CSV
			2. DTA
			3. Excel
	*/
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax, file(string asis) [clear debug opts(string) original preserve]
	
	if "`preserve'" == "preserve"{
		di "Option preserve is ignored in puse"
	}
	
	// Generate names of files based on extension
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	if strpos(`file', ".xls") > 0{
		local filexls = `file'
	}
		
	// Check existance of files
	capture confirm file "`filedta'"
	local dtaExists = _rc
	
	capture confirm file "`filecsv'"
	local csvExists = _rc
	
	capture confirm file "`filexls'"
	local xlsExists = _rc
	
	local exists = min(`dtaExists', `csvExists', `xlsExists')
	
	if `exists' != 0{
		di "No files found: `filedta'	 `filecsv'	`filexls'"
		error 601
	}
	
	// Throw exception if user specifies a file extension, but puse reads a different one.
	if strpos(`file', ".csv") > 0 & `dtaExists' == 0{
		di "CSV specified, but puse reads DTA file."
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `dtaExists' == 0{
		di "XLS specified, but puse reads DTA file"
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `csvExists' == 0{
		di "XLS/XLSX specified, but puse reads CSV file"
		error 601
	}
	
	// Import data
	if `dtaExists' ==0{ //If DTA file exists read DTA file
		use "`filedta'" , `clear'	
	} 
	else if `csvExists' == 0{ // If no DTA present and CSV exists, read CSV
		import delimited using "`filecsv'", ///
		`clear' case(lower) `opts'
	}
	else if `xlsExists' == 0 { // Otherwise read Excel
		if "`opts'" == "" & "`clear'" == ""{
			import excel using "`filexls'"
		}
		else {
			import excel using "`filexls'" , `opts' `clear'
		}
	}
	
	*** CSV files are better for project functionality since they don't
	*** store metadata
	
	// Register project functionality
	if `csvExists' == 0{ // If  CSV file exists register project functionality using CSV
		if "`debug'" == ""{ // If debug option wasn't set, use project functionality
			if "`original'" == ""{
				project , uses("`filecsv'") preserve
				}
			else{
				project , original("`filecsv'") preserve
				}
			}
		}
	else if strpos(`file', ".xls") == 0{ // IF CSV wasn't found and no Excel file specified, register project using DTA
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filedta'") preserve
				}
			else{
					project , original("`filedta'") preserve
				}
			}
		}
	else {
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filexls'") preserve
					}
			else{
				project , original("`filexls'") preserve
				}
			}
		}
end
