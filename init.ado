program define init , rclass
version 14
	syntax [, proj(string) route(string) debug hard]
	clear all
	discard
	set more off

	gl deb = "`debug'"
	set type double
	
	if ("$deb" == "debug" & "`proj'" != "") {
		project `proj' , cd
	}
	else if "`route'" != "" & "$deb" == ""{
			cd `route'
		}
	
	if "`hard'" == "hard"{
		macro drop _all
	}
end
