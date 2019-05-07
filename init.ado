program define init , rclass
	version 14
	
	capture findfile project.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package project needs to be installed first;"
		 di as txt "use -ssc install project- to do that"
		 exit 498
	}
	
	syntax [, debug debroute(string) double hard ignorefold logfile(string) omit proj(string) route(string)]
	clear all
	discard
	
	if "`hard'" == "hard" & ("`debug'" == "debug" | "`omit'" == "omit"){
		di "Cannot use option 'hard' with either 'debug' or 'omit'"
		break
	}
	
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
