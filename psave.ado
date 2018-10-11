program define psave , rclass
version 14
	syntax , file(string asis) [preserve eopts(string) debug]
	
	// Drops CSV file extension if any is present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr(`file', ".dta", "", .)
	
	// guarantees that the rows in the CSV are always ordered the same---
	set seed 13237 // from random.org
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	gen ordervar = runiform()
	sort ordervar
	drop ordervar
	// guarantees that the rows in the CSV are always ordered the same---
	
	save "`filedta'" , replace
	export delimited using "`filecsv'", replace `eopts'
	
	if "`debug'" == ""{
		project, creates("`filecsv'") `preserve'
	}
end
