program define puse, rclass
version 14
	// Registers CSV as using with project.
	// Tries to load DTA file if it exists, if it doesn't it loads a CSV file
	syntax, file(string asis) [clear debug original]
	
	// Drops CSV file extension if any is present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr(`file', ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	//project, uses("`filecsv'")
	
	capture confirm file "`filedta'"
	
	if _rc ==0{
		use "`filedta'" , `clear'
		if "`debug'" == ""{
			if "`original'" == ""{
				project , uses("`filedta'") preserve
				}
			else{
				project , original("`filedta'")
				}
			}
	} 
	else {
		import delimited using "`filecsv'", `clear' case(preserve)
		if "`debug'" == ""{
			if "`original'" == ""{
				project , uses("`filecsv'") preserve
				}
			else{
				project , original("`filecsv")
				}
			}
	}
end
