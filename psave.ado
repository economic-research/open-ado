program define psave , rclass
version 14
	syntax , file(string asis) [preserve eopts(string) debug com norand]
	
	// Drops CSV file extension if any is present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr(`file', ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	if "`norand'" != "norand"{
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
	
	if "`debug'" == ""{
		export delimited using "`filecsv'", replace `eopts'
		project, creates("`filecsv'") `preserve'
	}
end
