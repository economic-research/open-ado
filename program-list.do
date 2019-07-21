program define date2string , rclass
version 14
	syntax varlist(max=1) , gen(string) [drop]
	
	tokenize `varlist'
	tempvar day month year
	
	gen `day' 	= day(`1')
	gen `month' 	= month(`1')
	gen `year' 	= year(`1')
	
	qui tostring `day' `month' `year' , replace
	
	gen `gen' = `month' + "/" + `day' + "/" + `year'
	drop `year' `month' `year'
	
	if "`drop'" == "drop"{
		drop `1'
	}
end
program esttab2 , rclass
version 14
	// This extension is experimental.
		//Known issues:
			// Can only accept one line of addnotes
	syntax , file(string asis) [addnotes(string) debug option(string asis) ///
		title(string asis)]

	if "`title'" == ""{
		local titleloc ""
	}
	else {
		local titleloc "title(`title')"
	}

	if "`addnotes'" == ""{
		local addnotesloc ""
	}
	else {
		local addnotesloc "addnotes(`addnotes')"
	}


	esttab using "`file'" , se label ///
		replace ///
		b(4) se(4) `addnotesloc' `option' `titleloc'
		
	if "`debug'" == "" {
		project , creates("`file'") preserve
	}
	
	eststo clear
end
program define graph2 , rclass
version 14
	syntax , file(string asis) [options(string) debug]
	
	local pngfile = `file' + ".png"
	local pdffile = `file' + ".pdf"
	
	graph export "`pngfile'" , replace `options'
	graph export "`pdffile'" , replace `options'
	
	if "`debug'" == ""{
		project , creates("`pngfile'") preserve
	}
end
program define init , rclass
	version 14
	
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
	clear all
	discard
	
	if "`hard'" == "hard" & ("`debug'" == "debug" | "`omit'" == "omit"){
		di "Cannot use option 'hard' with either 'debug' or 'omit'"
		error 184
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
program define isorder , rclass
	syntax varlist
	
	tempvar order1 order2
		
	gen `order1' = _n
	
	sort `varlist'
	
	gen `order2' = _n
	
	qui count if `order1' != `order2'
	
	local counts = r(N)
	
	if `counts' == 0{
		di "Database ordered according to `varlist'"
		local statusval 1
	}
	else{
		di "Database is NOT ordered according to `varlist'"
		local statusval 0
	}
		
	return local ordered `statusval'
end
program mcompare , rclass
version 14
	syntax varlist(min=2)
	local counter = 0
	foreach var in `varlist'{
		local `counter++'
	}

	token `varlist'
	
	forvalues i=2(1)`counter'{
		compare `1' ``i''
	}
end
program define merge2 , rclass
version 14	
	syntax varlist , type(string) file(string asis) ///
		[datevar(varlist) tdate(string) ///
		fdate(string) moptions(string)  ///
		idstr(varlist) idnum(varlist) original debug]
		
	tempfile masterfile usingfile
		
	save `masterfile'
	import delimited using `file' , clear case(preserve)
	
	capture destring `idnumeric' , replace
	capture tostring `idstring' , replace
	
	if "`debug'" == ""{
		if "`original'" == "" {
			project, uses(`file') preserve	
		}
		else{
			project, original(`file') preserve
		}
	}
	
	if "`datevar'" != "" {
		tempvar newdate
		
		gen `newdate' = date(`datevar', "`tdate'")
		drop `datevar'
		gen `datevar' = `newdate'
		format `fdate' `datevar'
	}
	
	capture tostring `idstr', replace
	capture destring `idnum', replace
	
	save `usingfile'
	
	use `masterfile' , clear
	
	capture destring `idstr' , replace
	capture tostring `idnum' , replace
	
	if "`moptions'" != "" {
		merge `type' `varlist' using `usingfile' , `moptions'
	}
	else {
		merge `type' `varlist' using `usingfile'
	}
end
program define missing2zero , rclass
version 14
	syntax varlist (numeric) [, substitute(integer 0)]
	
	foreach var in `varlist'{
		replace `var' = `substitute' if `var' == .
	}
end
program define pexit , rclass
	version 14
	capture findfile project.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package project needs to be installed first;"
		 di as txt "use -ssc install project- to do that"
		 exit 498
	}
	
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax [, summary(string) debug]
	if "`debug'" == ""{
		cap log close
		
		if "`summary'" != ""{
			eststo clear
			estpost summarize _all
			esttab using "`summary'" , ///
			cells("mean(fmt(2)) sd(fmt(2)) min(fmt(1)) max(fmt(0))") ///
			nomtitle nonumber replace
		}
	}
	
	exit
end
program polgenerate
	syntax varlist(numeric) , p(int)
	
	foreach var in `varlist'{
		forvalues i = 2(1)`p'{
			* Generate variable
			cap gen `var'_`i' = `var'^`i'
			
			* Label variable
			local lab: variable label `var'
			label variable `var'_`i' "`lab', p(`i')"
		}
	}
end
program define psave , rclass
	version 14
	
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax , file(string asis) [com csvnone debug eopts(string) preserve  randnone]
	
	// Drops CSV, DTA file extensions if any are present
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	// If csvnone is selected, check that CSV file doesn't exist
	if "`csvnone'" == "csvnone"{
		capture confirm file "`filecsv'"
		if _rc ==0{ //If CSV file exists throw exception
			di "CSV file already exists. Consider deleting it or avoiding option csvnone."
			error 602
		} 
	}
	
	if "`randnone'" == "randnone"{
		di "Option randnone has been deprecated, and will be removed at a latter date."
		di "psave does not shuffle data by default."
		di "Consider omitting this argument."
	}
	
	// compress to save information
	qui count
	if 10^6 < r(N) | "`com'" == "com"{
		qui compress
	}
	
	save "`filedta'" , replace
	
	if "`debug'" == "" & "`csvnone'" == ""{
		export delimited using "`filecsv'", replace `eopts'
		project, creates("`filecsv'") `preserve'
	}

	if "`debug'" == "" & "`csvnone'" == "csvnone"{
		project , creates("`filedta'") `preserve'
	}
end
program define puse, rclass
	version 14
	
	/*
		puse tries to read data and register project functionality in the following
		order (unless specified otherwise by user):
		
		Read:
			1. DTA
			2. CSV
			3. Excel
		project:
			1. CSV
			2. DTA
			3. Excel
	*/
	capture findfile init.ado
		if "`r(fn)'" == "" {
		 di as txt "user-written package init needs to be installed first;"
		 di as txt "use -ssc install init- to do that"
		 exit 498
	}
	
	syntax, file(string asis) [clear debug opts(string) original]
	
	// Generate names of files based on extension
	local newfile = subinstr(`file', ".csv", "", .)
	local newfile = subinstr("`newfile'", ".dta", "", .)
	
	local filecsv = "`newfile'" + ".csv"
	local filedta = "`newfile'" + ".dta"
	
	if strpos(`file', ".xls") > 0{
		local filexls = `file'
	}
		
	// Check existance of files
	capture confirm file "`filedta'"
	local dtaExists = _rc
	
	capture confirm file "`filecsv'"
	local csvExists = _rc
	
	capture confirm file "`filexls'"
	local xlsExists = _rc
	
	local exists = min(`dtaExists', `csvExists', `xlsExists')
	
	if `exists' != 0{
		di "No files found: `filedta'	 `filecsv'	`filexls'"
		error 601
	}
	
	// Throw exception if user specifies a file extension, but puse reads a different one.
	if strpos(`file', ".csv") > 0 & `dtaExists' == 0{
		di "CSV specified, but puse reads DTA file."
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `dtaExists' == 0{
		di "XLS specified, but puse reads DTA file"
		error 601
	}
	else if strpos(`file', ".xls") > 0 & `csvExists' == 0{
		di "XLS/XLSX specified, but puse reads CSV file"
		error 601
	}
	
	// Import data
	if `dtaExists' ==0{ //If DTA file exists read DTA file
		use "`filedta'" , `clear'	
	} 
	else if `csvExists' == 0{ // If no DTA present and CSV exists, read CSV
		import delimited using "`filecsv'", ///
		`clear' case(lower) `opts'
	}
	else if `xlsExists' == 0 { // Otherwise read Excel
		if "`opts'" == "" & "`clear'" == ""{
			import excel using "`filexls'"
		}
		else {
			import excel using "`filexls'" , `opts' `clear'
		}
	}
	
	*** CSV files are better for project functionality since they don't
	*** store metadata
	
	// Register project functionality
	if `csvExists' == 0{ // If  CSV file exists register project functionality using CSV
		if "`debug'" == ""{ // If debug option wasn't set, use project functionality
			if "`original'" == ""{
				project , uses("`filecsv'") preserve
				}
			else{
				project , original("`filecsv'") preserve
				}
			}
		}
	else if strpos(`file', ".xls") == 0{ // IF CSV wasn't found and no Excel file specified, register project using DTA
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filedta'") preserve
				}
			else{
					project , original("`filedta'") preserve
				}
			}
		}
	else {
			if "`debug'" == ""{ // If debug option wasn't set, use project functionality
				if "`original'" == ""{
					project , uses("`filexls'") preserve
					}
			else{
				project , original("`filexls'") preserve
				}
			}
		}
end
program define sumby , rclass
version 14
	syntax varlist , by(varlist max=1)
	
	local condvar `by'
	tokenize `varlist'
	
	local counter = 0
	foreach k in `varlist'{
		local `counter++'
	}
	
	qui levelsof `condvar' , local(categories)
	
	forvalues k = 1(1)`counter'{
		foreach cat in `categories'{
			di "`condvar' == `cat':" 
			su ``k'' if `condvar' == `cat'
	}
	}
end
program twowayscatter , rclass
version 14
	syntax varlist(min=2 max=3) ///
	 [ ,  color1(string) color2(string) conditions(string) ///
		debug file(string) lfit ///
	    type1(string) type2(string) ncorr singleaxis omit]
	
	if "`omit'" == "omit"{
		di "Graph skipped: `file'"
		exit
	}
	
	if "`type1'" == ""{
		local type1 "scatter"
	}
	
	if "`type2'" == ""{
		local type2 "scatter"
	}
	
	local k = 0
	foreach var in `varlist'{
			local `k++'
	}
		
	token `varlist'

	if "`lfit'" == "lfit"{
		local linegraph "(lfit `1' `2')"
	}
	
	if "`ncorr'" != "ncorr" {
		qui corr `1' `2' `conditions'
		local corr : di  %5.3g r(rho)
		local corrs "subtitle(correlation `corr')"
	}
	
	if "`singleaxis'" != "singleaxis"{
		local yaxisval "yaxis(2)"
	}

	if `k' == 3{
		if "`color1'" != "" & "`color2'" != ""{
		twoway (`type1' `1' `3' `conditions' , mcolor("`color1'")) ///
			(`type2' `2' `3' `conditions' , `yaxisval' mcolor("`color2'")) `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
		else {
		twoway (`type1' `1' `3' `conditions') ///
			(`type2' `2' `3' `conditions'  , `yaxisval') `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
	}
	else if `k' == 2{
		if "`color1'" != "" {
		twoway (`type1' `1' `2' `conditions' , mcolor("`color1'")) `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
		else {
		twoway (`type1' `1' `2' `conditions') `linegraph' , ///
			graphregion(color(white)) `corrs'
		}
	}
	
	if "`file'" != ""{
		graph2 , file("`file'") `debug'
	}
end
program define uniquevals , rclass
version 14
	syntax varlist
	
	foreach var in `varlist'{
		tempvar j
		bys `var': gen `j' = _n
		qui count if `j' == 1
		di "`var' has " r(N) " distinct values"
		drop `j'
	}

end
program usstates , rclass
syntax varlist(min=1 max=1) , newvar(string) type(string) 
	
	if "`type'" != "full" & "`type'" != "abbv"{
		di "Please provide a valid option for type (full or abbv)"
		exit
	}
	
	token `varlist'
	local var `1'
	
	qui gen `newvar' = ""

	if "`type'" == "full" {
		qui replace `newvar' = "AK" if `var' == "Alaska"
		qui replace `newvar' = "AL" if `var' == "Alabama"
		qui replace `newvar' = "AR" if `var' == "Arkansas"
		qui replace `newvar' = "AZ" if `var' == "Arizona"
		qui replace `newvar' = "CA" if `var' == "California"
		qui replace `newvar' = "CO" if `var' == "Colorado"
		qui replace `newvar' = "CT" if `var' == "Connecticut"
		qui replace `newvar' = "DC" if `var' == "DC"
		qui replace `newvar' = "DE" if `var' == "Delaware"
		qui replace `newvar' = "FL" if `var' == "Florida"
		qui replace `newvar' = "GA" if `var' == "Georgia"
		qui replace `newvar' = "HI" if `var' == "Hawaii"
		qui replace `newvar' = "IA" if `var' == "Iowa"
		qui replace `newvar' = "ID" if `var' == "Idaho"
		qui replace `newvar' = "IL" if `var' == "Illinois"
		qui replace `newvar' = "IN" if `var' == "Indiana"
		qui replace `newvar' = "KS" if `var' == "Kansas"
		qui replace `newvar' = "KY" if `var' == "Kentucky"
		qui replace `newvar' = "LA" if `var' == "Louisiana"
		qui replace `newvar' = "MA" if `var' == "Massachusetts"
		qui replace `newvar' = "MD" if `var' == "Maryland"
		qui replace `newvar' = "ME" if `var' == "Maine"
		qui replace `newvar' = "MI" if `var' == "Michigan"
		qui replace `newvar' = "MN" if `var' == "Minnesota"
		qui replace `newvar' = "MO" if `var' == "Missouri"
		qui replace `newvar' = "MS" if `var' == "Mississippi"
		qui replace `newvar' = "MT" if `var' == "Montana"
		qui replace `newvar' = "NC" if `var' == "North Carolina"
		qui replace `newvar' = "ND" if `var' == "North Dakota"
		qui replace `newvar' = "NE" if `var' == "Nebraska"
		qui replace `newvar' = "NH" if `var' == "New Hampshire"
		qui replace `newvar' = "NJ" if `var' == "New Jersey"
		qui replace `newvar' = "NM" if `var' == "New Mexico"
		qui replace `newvar' = "NV" if `var' == "Nevada"
		qui replace `newvar' = "NY" if `var' == "New York"
		qui replace `newvar' = "OH" if `var' == "Ohio"
		qui replace `newvar' = "OK" if `var' == "Oklahoma"
		qui replace `newvar' = "OR" if `var' == "Oregon"
		qui replace `newvar' = "PA" if `var' == "Pennsylvania"
		qui replace `newvar' = "RI" if `var' == "Rhode Island"
		qui replace `newvar' = "SC" if `var' == "South Carolina"
		qui replace `newvar' = "SD" if `var' == "South Dakota"
		qui replace `newvar' = "TN" if `var' == "Tennessee"
		qui replace `newvar' = "TX" if `var' == "Texas"
		qui replace `newvar' = "UT" if `var' == "Utah"
		qui replace `newvar' = "VA" if `var' == "Virginia"
		qui replace `newvar' = "VT" if `var' == "Vermont"
		qui replace `newvar' = "WA" if `var' == "Washington"
		qui replace `newvar' = "WI" if `var' == "Wisconsin"
		qui replace `newvar' = "WV" if `var' == "West Virginia"
		qui replace `newvar' = "WY" if `var' == "Wyoming"
	}

	if "`type'" == "abbv"{
		qui replace `newvar' = "Alaska" if `var' == "AK"
		qui replace `newvar' = "Alabama" if `var' == "AL"
		qui replace `newvar' = "Arkansas" if `var' == "AR"
		qui replace `newvar' = "Arizona" if `var' == "AZ"
		qui replace `newvar' = "California" if `var' == "CA"
		qui replace `newvar' = "Colorado" if `var' == "CO"
		qui replace `newvar' = "Connecticut" if `var' == "CT"
		qui replace `newvar' = "DC" if `var' == "DC"
		qui replace `newvar' = "Delaware" if `var' == "DE"
		qui replace `newvar' = "Florida" if `var' == "FL"
		qui replace `newvar' = "Georgia" if `var' == "GA"
		qui replace `newvar' = "Hawaii" if `var' == "HI"
		qui replace `newvar' = "Iowa" if `var' == "IA"
		qui replace `newvar' = "Idaho" if `var' == "ID"
		qui replace `newvar' = "Illinois" if `var' == "IL"
		qui replace `newvar' = "Indiana" if `var' == "IN"
		qui replace `newvar' = "Kansas" if `var' == "KS"
		qui replace `newvar' = "Kentucky" if `var' == "KY"
		qui replace `newvar' = "Louisiana" if `var' == "LA"
		qui replace `newvar' = "Massachusetts" if `var' == "MA"
		qui replace `newvar' = "Maryland" if `var' == "MD"
		qui replace `newvar' = "Maine" if `var' == "ME"
		qui replace `newvar' = "Michigan" if `var' == "MI"
		qui replace `newvar' = "Minnesota" if `var' == "MN"
		qui replace `newvar' = "Missouri" if `var' == "MO"
		qui replace `newvar' = "Mississippi" if `var' == "MS"
		qui replace `newvar' = "Montana" if `var' == "MT"
		qui replace `newvar' = "North Carolina" if `var' == "NC"
		qui replace `newvar' = "North Dakota" if `var' == "ND"
		qui replace `newvar' = "Nebraska" if `var' == "NE"
		qui replace `newvar' = "New Hampshire" if `var' == "NH"
		qui replace `newvar' = "New Jersey" if `var' == "NJ"
		qui replace `newvar' = "New Mexico" if `var' == "NM"
		qui replace `newvar' = "Nevada" if `var' == "NV"
		qui replace `newvar' = "New York" if `var' == "NY"
		qui replace `newvar' = "Ohio" if `var' == "OH"
		qui replace `newvar' = "Oklahoma" if `var' == "OK"
		qui replace `newvar' = "Oregon" if `var' == "OR"
		qui replace `newvar' = "Pennsylvania" if `var' == "PA"
		qui replace `newvar' = "Rhode Island" if `var' == "RI"
		qui replace `newvar' = "South Carolina" if `var' == "SC"
		qui replace `newvar' = "South Dakota" if `var' == "SD"
		qui replace `newvar' = "Tennessee" if `var' == "TN"
		qui replace `newvar' = "Texas" if `var' == "TX"
		qui replace `newvar' = "Utah" if `var' == "UT"
		qui replace `newvar' = "Virginia" if `var' == "VA"
		qui replace `newvar' = "Vermont" if `var' == "VT"
		qui replace `newvar' = "Washington" if `var' == "WA"
		qui replace `newvar' = "Wisconsin" if `var' == "WI"
		qui replace `newvar' = "West Virginia" if `var' == "WV"
		qui replace `newvar' = "Wyoming" if `var' == "WY"
	}


	if "`type'" == "full"{
		local var `newvar'
	}

	qui gen `newvar'_num = .

	qui replace `newvar'_num = 1 if `var' == "AK"
	qui replace `newvar'_num = 2 if `var' == "AL"
	qui replace `newvar'_num = 3 if `var' == "AR"
	qui replace `newvar'_num = 4 if `var' == "AZ"
	qui replace `newvar'_num = 5 if `var' == "CA"
	qui replace `newvar'_num = 6 if `var' == "CO"
	qui replace `newvar'_num = 7 if `var' == "CT"
	qui replace `newvar'_num = 8 if `var' == "DC"
	qui replace `newvar'_num = 9 if `var' == "DE"
	qui replace `newvar'_num = 10 if `var' == "FL"
	qui replace `newvar'_num = 11 if `var' == "GA"
	qui replace `newvar'_num = 12 if `var' == "HI"
	qui replace `newvar'_num = 13 if `var' == "IA"
	qui replace `newvar'_num = 14 if `var' == "ID"
	qui replace `newvar'_num = 15 if `var' == "IL"
	qui replace `newvar'_num = 16 if `var' == "IN"
	qui replace `newvar'_num = 17 if `var' == "KS"
	qui replace `newvar'_num = 18 if `var' == "KY"
	qui replace `newvar'_num = 19 if `var' == "LA"
	qui replace `newvar'_num = 20 if `var' == "MA"
	qui replace `newvar'_num = 21 if `var' == "MD"
	qui replace `newvar'_num = 22 if `var' == "ME"
	qui replace `newvar'_num = 23 if `var' == "MI"
	qui replace `newvar'_num = 24 if `var' == "MN"
	qui replace `newvar'_num = 25 if `var' == "MO"
	qui replace `newvar'_num = 26 if `var' == "MS"
	qui replace `newvar'_num = 27 if `var' == "MT"
	qui replace `newvar'_num = 28 if `var' == "NC"
	qui replace `newvar'_num = 29 if `var' == "ND"
	qui replace `newvar'_num = 30 if `var' == "NE"
	qui replace `newvar'_num = 31 if `var' == "NH"
	qui replace `newvar'_num = 32 if `var' == "NJ"
	qui replace `newvar'_num = 33 if `var' == "NM"
	qui replace `newvar'_num = 34 if `var' == "NV"
	qui replace `newvar'_num = 35 if `var' == "NY"
	qui replace `newvar'_num = 36 if `var' == "OH"
	qui replace `newvar'_num = 37 if `var' == "OK"
	qui replace `newvar'_num = 38 if `var' == "OR"
	qui replace `newvar'_num = 39 if `var' == "PA"
	qui replace `newvar'_num = 40 if `var' == "RI"
	qui replace `newvar'_num = 41 if `var' == "SC"
	qui replace `newvar'_num = 42 if `var' == "SD"
	qui replace `newvar'_num = 43 if `var' == "TN"
	qui replace `newvar'_num = 44 if `var' == "TX"
	qui replace `newvar'_num = 45 if `var' == "UT"
	qui replace `newvar'_num = 46 if `var' == "VA"
	qui replace `newvar'_num = 47 if `var' == "VT"
	qui replace `newvar'_num = 48 if `var' == "WA"
	qui replace `newvar'_num = 49 if `var' == "WI"
	qui replace `newvar'_num = 50 if `var' == "WV"
	qui replace `newvar'_num = 51 if `var' == "WY"

end
program define values2ascii , rclass
	syntax varlist [, tolower punct]
	
	// 1. Eliminate accents
	foreach var in `varlist'{
		qui replace `var' = subinstr(`var',"á","a",.)
		qui replace `var' = subinstr(`var',"é","e",.)
		qui replace `var' = subinstr(`var',"í","i",.)
		qui replace `var' = subinstr(`var',"ó","o",.)
		qui replace `var' = subinstr(`var',"ú","u",.)
		qui replace `var' = subinstr(`var',"ñ","n",.)
		
		qui replace `var' = subinstr(`var',"Á","A",.)
		qui replace `var' = subinstr(`var',"É","E",.)
		qui replace `var' = subinstr(`var',"Í","I",.)
		qui replace `var' = subinstr(`var',"Ó","O",.)
		qui replace `var' = subinstr(`var',"Ú","U",.)
		qui replace `var' = subinstr(`var',"Ñ","N",.)
	}

	// 2. Lowercase variables
	if "`tolower'" == "tolower"{
		foreach var in `varlist'{
			qui replace `var' = lower(`var')
		}
	}
	
	// 3. Punctuation
	if "`punct'" == "punct"{
		foreach var in `varlist'{
			qui replace `var' = subinstr(`var',".","",.)
			qui replace `var' = subinstr(`var',",","",.)
			qui replace `var' = subinstr(`var',";","",.)
			qui replace `var' = subinstr(`var',"!","",.)
			qui replace `var' = subinstr(`var',"¡","",.)
			qui replace `var' = subinstr(`var',"(","",.)
			qui replace `var' = subinstr(`var',")","",.)
			qui replace `var' = subinstr(`var',"[","",.)
			qui replace `var' = subinstr(`var',"]","",.)
			qui replace `var' = subinstr(`var',"-","",.)
		}
	}
	
	// 4. Eliminate spaces
	foreach var in `varlist'{
		qui replace `var' = subinstr(`var', char(10),"",.)

	}
	
end
