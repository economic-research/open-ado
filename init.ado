program define init , rclass
version 14
	syntax [, proj(string) route(string) debug]
	clear all	
	set more off

	gl deb = "`debug'"
	set type double
	
	if ("$deb" == "debug" & "`proj'" != "") {
		project `proj' , cd
	}
	else{
		if "`route'" != "" {
			cd `route'
		}
	}
end
