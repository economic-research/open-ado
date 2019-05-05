program define init , rclass
	syntax [, debug debroute(string) double hard ignorefold logfile(string) omit proj(string) route(string)]
	clear all
	discard
	
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
	
	// If log option set and not in debug mode open logile
	if ("$deb" == "" & "`logfile'" != "") {
		capture confirm file "./log/" //check if a log directory exists
		// If directory exists, but wasn't specified by user, then store logfile there
		local LogFolderSpecified = strpos("`logfile'", "log/") + strpos("`logfile'", "log\")
		
		if _rc == 0 & `LogFolderSpecified' == 0 & "`ignorefold'" == ""{ 
			local logfile = "./log/" + "`logfile'"
		}
		
		log using "`logfile'" , replace
	}
	
	if "`hard'" == "hard"{
		macro drop _all
	}
end
