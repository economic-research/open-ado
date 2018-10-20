program define init , rclass
version 14
	clear all
	
	syntax [, proj(string) route(string) debug]
	
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
