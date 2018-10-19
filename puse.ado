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
	
	if _rc ==0{ //If DTA file exists read DTA file, otherwise read CSV
		use "`filedta'" , `clear'	
	} 
	else {
		import delimited using "`filecsv'", `clear' case(lower)
	}
	
	*** CSV files are better for project functionality since they don't
	*** store (as much) metadata
	
	capture confirm file "`filecsv'"
	if _rc == 0{ // If  CSV file exists register project functionality using CSV
		if "`debug'" == ""{ // If debug option wasn't set, use project functionality
			if "`original'" == ""{
				project , uses("`filecsv'") preserve
				}
			else{
				project , original("`filecsv")
				}
			}
		}
		else{ // IF CSV wasn't found, register project using DTA
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
			if "`original'" == ""{
				project , uses("`filedta'") preserve
				}
			else{
				project , original("`filedta'")
				}
			}
		}		
end