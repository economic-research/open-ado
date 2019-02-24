program define init , rclass
	syntax [, debroute(string) debug double hard omit proj(string) route(string)]
	clear all
	discard
	set more off

	gl deb = "`debug'"
	gl omit = "`omit'"
	
	if "`double'" == "double"{ 
		set type double
	}
	
	if ("$deb" == "debug" & "`proj'" != "") { // In debug mode change to route if specified
		project `proj' , cd
		if "`debroute'" != ""{ // If debroute specified change WD with respect to root directory
			cd `debroute'
		}
	}
	else if "`route'" != "" & "$deb" == ""{
			cd `route'
		}
	
	if "`hard'" == "hard"{
		macro drop _all
	}
end
