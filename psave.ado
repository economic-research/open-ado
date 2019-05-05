program define psave , rclass
	syntax , file(string asis) [com csvnone debug eopts(string) preserve  randnone]
	
	// Drops CSV, DTA file extensions if any are present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	// If csvnone is selected, check that CSV file doesn't exist
	if "`csvnone'" == "csvnone"{
		capture confirm file "`filecsv'"
		if _rc ==0{ //If CSV file exists throw exception
			di "CSV file already exists. Consider deleting it or avoiding option csvnone."
			break
		} 
	}
	
	if "`randnone'" != "randnone"{
		// guarantees that the rows in the CSV are always ordered the same---
		set seed 13237 // from random.org
		
		tempvar ordervar
		gen `ordervar' = runiform()
		sort `ordervar'
		drop `ordervar'
		// guarantees that the rows in the CSV are always ordered the same---
	}
	
	// compress to save information
	qui count
	if 10^6 < r(N) | "`com'" == "com"{
		qui compress
	}
	
	save "`filedta'" , replace
	
	if "`debug'" == "" & "`csvnone'" == ""{
		export delimited using "`filecsv'", replace `eopts'
		project, creates("`filecsv'") `preserve'
	}

	if "`debug'" == "" & "`csvnone'" == "csvnone"{
		project , creates("`filedta'") `preserve'
	}
end
