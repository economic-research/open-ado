program define psave , rclass
	version 14
	
	// Verify dependencies
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax , file(string asis) [clear com csvnone debug eopts(string) ///
			old(string) preserve]
	
	if "`clear'" == "clear"{
		di "Option clear is ignored in psave"
	}
	
	// Drops CSV, DTA file extensions, if any are present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	// Define names for output files
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	local filedta_old = "`newfile'" + "_v`old'" + ".dta"
	
	// If csvnone is selected, check that CSV file doesn't exist
	if "`csvnone'" == "csvnone"{
		capture confirm file "`filecsv'"
		if _rc ==0{ //If CSV file exists throw exception
			di "CSV file already exists. Consider deleting it or avoiding option csvnone."
			error 602
		}
	}
	
	// Optionally compress to save information
	if "`com'" == "com"{
		qui compress
	}
	
	// Save DTA in current format
	save "`filedta'" , replace
	
	// Optionally save DTA in old version
	if "`old'" != ""{
		confirm integer number `old'
		saveold "`filedta_old'" , replace version(`old')
	}
	
	// If debug and CSVnone are not set, store CSV
	if "`debug'" == "" & "`csvnone'" == ""{
		export delimited using "`filecsv'", replace `eopts'
		project, creates("`filecsv'") `preserve'
	}

	// Register with project
	if "`debug'" == "" & "`csvnone'" == "csvnone"{
		project , creates("`filedta'") `preserve'
	}
end
