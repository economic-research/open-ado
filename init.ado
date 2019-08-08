program define init , rclass
	version 14
	
	// Check dependencies
	capture findfile project.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package project needs to be installed first;"
		 di as txt "use -ssc install project- to do that"
		 exit 498
	}
	
	capture findfile pexit.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package pexit needs to be installed first;"
		 di as txt "use -ssc install pexit- to do that"
		 exit 498
	}
	
	capture macro drop debug
	
	syntax [, debug debroute(string) double hard ignorefold logfile(string) omit proj(string) route(string)]
	
	// Clean session
	clear all
	discard
	
	// Check that user parameters are correct
	if "`hard'" == "hard" & ("`debug'" == "debug" | "`omit'" == "omit"){
		di "Cannot use option 'hard' with either 'debug' or 'omit'"
		error 184
	}
	
	// Define global debug and omit
	gl deb = "`debug'"
	gl omit = "`omit'"
	
	// Optionally set type double
	if "`double'" == "double"{ 
		set type double
	}
	
	// Set working directory
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
		cap log close
		mata : st_numscalar("LogExists", direxists("./log/")) //check if a log directory exists
		
		local LogFolderSpecified = strpos("`logfile'", "log/") + strpos("`logfile'", "log\")
		
		// If directory exists, but wasn't specified by user, then store logfile there
		if LogExists == 1 & `LogFolderSpecified' == 0 & "`ignorefold'" == ""{ 
			local logfile = "./log/" + "`logfile'"
		}
		log using "`logfile'" , replace
	}
	
	// Optionally drop all macros
	if "`hard'" == "hard"{
		macro drop _all
	}
end
