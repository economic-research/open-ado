*! version 1.3.2  8mar2023  picard@netbox.com
*includes user-dependent project lock file, to allow simultaneous builds, updated by Lorenzo Aldeco
program define project
/*
--------------------------------------------------------------------------------

The main project program checks that only one project command is specified and 
reroutes each call to the appropriate local program.

--------------------------------------------------------------------------------
*/

	// avoid version control but support version 9.2 to 13
	if _caller() < 9.2 version 9.2
	version `c(stata_version)'
	if c(stata_version) > 13 version 13

	
	syntax	[name(name=pname id="Project Name")], ///
			[					///
								/// --------- project database ----------------
			setup				/// use a dialog to define a project's master do-file
			setmaster(string)   /// define a project's master do-file
			plist				/// list of projects and their directory
			pclear				/// clear a project's record in the dataset of projects
			cd					/// change Stata's dir to the project directory
								/// --------- project management tasks --------
			build				/// builds the project (runs the master do-file)
			list(string)		/// list files in the project
			validate			/// check for changes in files linked to the project
			replicate			/// reruns a build and compare files created
			archive				/// archive files that have changed since last build
			share(string)		/// share files that have changed
			cleanup				/// archive files that are not part of the project
			rmcreated			/// erase all files created by the project
								/// --------- build directives ----------------
			do(string)			/// do-file to run
			original(string)	/// do-file uses a file not created within the project
			uses(string)		///	do-file uses a file created within the project
			relies_on(string)	/// a related file not directly used (info, docs, etc.)
			creates(string)		/// do-file creates a file
			doinfo				/// returns info about the do-file and current build
			break				/// to stop execution of a project at a specific point
								/// --------- command sub-options -------------
			preserve			/// preserve user data when running build directives
			TEXTlog             /// log file in plain text format
			SMCLlog             /// log file in SMCL format
			]



	local command_list setup setmaster plist pclear cd ///
		build list validate replicate archive share cleanup rmcreated ///
		do original uses relies_on creates doinfo break
	
	local nopt 0
	foreach opt in `command_list' {
		if "``opt''" ~= "" {
			local myopt `opt'
			local ++nopt
		}
	}
	
	if `nopt' > 1 {
		dis as err "options cannot be combined"
		exit 198
	}
	
	if `nopt' == 0 {
		dis as err "no option specified"
		exit 198
	}
	
	if "`textlog'" != "" & "`smcllog'" != "" {
		dis as err "options textlog and smcllog cannot be combined"
		exit 198
	}
	
	project_`myopt' `0'
	
end


program define project_break
/*
--------------------------------------------------------------------------------

This command forces an error to stop execution of a build from within a do-file.
This is functionally the same as writing -exit 1- in the do-file.

--------------------------------------------------------------------------------
*/

	dis as err "project > user set break point"
	exit 1

end


program define exit_if_in_a_build
/*
--------------------------------------------------------------------------------

Return an error if a build is currently running. This is used to stop execution
for all project commands that are not allowed from within a build. When a build
is started, a dataset is created to track its progress. This dataset is saved 
in the same directory as the program itself. This is done so that -project- can
find it irrespective of the current directory.

--------------------------------------------------------------------------------
*/

	// search along the current ado-path
	capture findfile "project.ado"
	local builtemp "`r(fn)'"

	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"

	// check using -describe- to avoid having to -preserve- user data
	cap describe using "`builtemp'"
	if !_rc {
	
		nobreak {
		
			use "`builtemp'", clear
			local pname : char _dta[pname]
			dis as err `"project "`pname'" is currently being built"' ///
				" - command not available"
				
			cap erase "`builtemp'"
			if _rc {
				dis as err "... could not erase build temporary file"
				dis as err `"you must manually delete "`builtemp'""'
				exit _rc
			}
			else dis as err "current build cancelled"
			
			clear
		}

		exit 198
	}
	
end


program define project_setup
/*
--------------------------------------------------------------------------------

This command brings up a dialog where the user selects a master do-file. The
do-file's name (minus the ".do" extension) will become the project name. The
full path to the master do-file will then be added to the project database by
the project_setmaster command. See the "project_setup.dlg".

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build
	
	// do not accept any option; can't specify the name of the project since
	// it will be overridden by the name of the master do-file
	syntax , setup

	db project_setup
	
end


program define project_pathname, rclass
/*
--------------------------------------------------------------------------------

Separate a file name from its path name. Return the full path name.

--------------------------------------------------------------------------------
*/

	args fn
	
	
	// To avoid macro expansion problems
	local fn: subinstr local fn "\" "/", all
	
	// never allow temporary files
	tempfile f
	local tempdir : subinstr local f "\" "/", all
	local tempdir = regexr("`tempdir'","[^/]*$","")	
	local fcheck : subinstr local fn "`tempdir'" ""
	local len1 : length local fcheck
	local len2 : length local fn
	if `len1' != `len2' {
		dis as err `"Temporary file not allowed: "`fn'""'
		exit 198
	}
	
	
	// Navigate and build the path until we reach the filename.
	gettoken part rest : fn, parse("/:")
	while "`rest'" != "" {
		local path "`path'`part'"
		gettoken part rest : rest, parse("/:")
	}
	if inlist("`part'", "/", ":") {
		dis as err `"Was expecting a filename: "`fn'""'
		exit 198
	}
	else {
		local fname "`part'"
	}


	// convert partial or relative path to full path by changing the
	// current directory and recovering the full path from there
	if "`path'" != "" {
		local savepwd "`c(pwd)'"
		nobreak {
			capture cd "`path'"
			if _rc {
				dis as err "invalid path or directory does not exist"
				dis as text "path = " as res "`path'"
				exit _rc
			}
			local fullp "`c(pwd)'"
			qui cd "`savepwd'"
		}
	}
	else {
		local fullp "`c(pwd)'"
	}


	// To avoid macro expansion problems
	local fullp: subinstr local fullp "\" "/", all

	display as result "`fullp'/`fname'"
	return local fullpath "`fullp'"
	return local fname "`fname'"
	
	// Check that the file exists
	confirm file "`fullp'/`fname'"
	
end


program define project_setmaster
/*
--------------------------------------------------------------------------------

This command will usually be called from the dialog that is brought up by the
-project, setup- command (see the "project_setup.dlg"). It can also be called
directly with a full or relative path.

The project full path is stored in a Stata dataset that is saved in the
directory that contains the version of -project- that is currently running. 

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build
	
	syntax , setmaster(string) [TEXTlog SMCLlog]
	
	
	// Separate the filename from the file path
	qui project_pathname "`setmaster'"
	local fname "`r(fname)'"
	local fullpath  "`r(fullpath)'"
	local len : length local fullpath
	
	
	// Check that we can store the file path
	if `len' > c(maxstrvarlen) {
		dis as txt "path = " as res `""`fullpath'""'
		dis as err "cannot store path; " ///
			"size = `len', limit = " c(maxstrvarlen)
		exit 1000
	}


	// confirm that this is a do-file
	if regexm("`fname'","(.*)\.do$") local pname = regexs(1)
	else {
		dis as err "master do-file name must end with .do"
		exit 198
	}
	
	
	// confirm that we have a valid project name
	capture confirm name `pname'
	if _rc | strpos("`pname'"," ") {
		dis as err `"Invalid project name: "`pname'""'
		dis as err "A short project name is recommended and it must conform to"
		dis as err "Stata's standard {help [M-1] naming:naming convention} for variables and other objects"
		exit 198
	}

	
	local logtype = cond("`textlog'" == "","SMCL","plain text")
	
	
	preserve
	
	// Search along the ado-path for the dataset of projects
	capture findfile "project.dta"
	if !_rc {
		local projects "`r(fn)'"
	}
	else {
		// if not found, create it in the same directory as -project-
		capture findfile "project.ado"
		local projects "`r(fn)'"
		local projects : subinstr local projects "project.ado" "project.dta"
		
		clear
		gen str pname = ""
		gen str path  = ""
		gen str plog  = ""
		char pname[tname] "Name"
		char path[tname] "Full path to directory"
		char plog[tname] "Log Type"

		cap saveold "`projects'"
		if _rc {
			dis as err "Could not save the database of projects"
			exit _rc
		}
	}
	
	
	// Add the project
	cap use "`projects'", clear
	if _rc {
		dis as err "Could not open the database of projects"
		exit _rc
	}
	cap drop if pname == "`pname'"
	qui set obs `=_N+1'
	qui replace pname = "`pname'" in l
	qui replace path  = "`fullpath'" in l
	
	// new feature; make backward compatible
	cap replace plog = "`logtype'" in l
	if _rc {
		gen str plog  = "SMCL"		// default for all projects
		char plog[tname] "Log Type"
		qui replace plog = "`logtype'" in l
	}
	
	sort pname
	cap saveold "`projects'", replace
	if _rc {
		dis as err "Could not save the dataset of projects"
		exit _rc
	}
	

	// list using our table routines
	qui keep if pname == "`pname'"
	rename path fpath
	rename pname fname
	project_table_setup	fname plog, title1("Project")
	char fname[style] res
	project_table_line fname plog, line(1)
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	
end



program define get_project_directory, rclass
/*
--------------------------------------------------------------------------------

Given a project name, this program retrieves the path to the directory that 
contains the master do-file. The program also returns the default log type
for the project.

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name")
	
	
	// Search along the ado-path for the dataset of projects
	capture findfile "project.dta"
	if _rc {
		dis as err "The dataset of projects was not found."
		dis as err "Use the {bf:{dialog project_setup:setup}} option " ///
			"to define new projects"
		exit _rc
	}

	cap use "`r(fn)'", clear
	if _rc{
		dis as err "Could not open the database of projects"
		exit _rc
	}
	
	cap confirm string variable pname path
	if _rc{
		dis as err "The database of projects is missing the expected variables"
		exit _rc
	}
	
	qui keep if pname == "`pname'"
	if  _N == 1 {
		local projectdir = path
		return local projectdir "`projectdir'"
		return local pfiles "`projectdir'/`pname'_files.dta"
		return local plinks "`projectdir'/`pname'_links.dta"
		cap local plogtype = plog
		if "`plogtype'" == "" local plogtype "SMCL"	
		return local plog "`plogtype'"
	}
	
	if "`projectdir'" == "" {
		dis as err `"project "`pname'" not found"'
		dis as err "Use the {bf:{dialog project_setup:setup}} option " ///
			"to define new projects"
		exit 198
	}
	
end



program define project_plist
/*
--------------------------------------------------------------------------------

List one/all projects in the database of projects.

--------------------------------------------------------------------------------
*/


	// this is not a build directive
	exit_if_in_a_build
	
	syntax [name(name=pname id="Project Name")], plist
	

	// Search along the ado-path for the dataset of projects
	cap findfile "project.dta"
	if _rc {
		dis as err "The dataset of projects was not found."
		dis as err "Use the {bf:{dialog project_setup:setup}} option " ///
			"to define new projects"
		exit _rc
	}
	local projects "`r(fn)'"
	
	preserve
	
	
	use "`projects'", clear
	
	
	if "`pname'" != "" {
		qui keep if pname == "`pname'"
		if !_N {
			dis as err `"project "`pname'" not found"'
			exit 459
		}
	}
	
	if !_N {
		dis as err "no project defined"
		dis as err "Use the {bf:{dialog project_setup:setup}} option " ///
			"to define new projects"
		exit 2000
	}
	
	
	// new feature; make backwards compatible
	cap confirm var plog
	if _rc {
		gen str plog  = "SMCL"		// default for all projects
		char plog[tname] "Log Type"
		sort pname
		cap saveold "`projects'", replace
		if _rc {
			dis as err "Could not save the dataset of projects"
			exit _rc
		}
	}
	
	
	// Adjust variable names and use our table routines
	rename path fpath
	rename pname fname	
	
	if _N == 1 local title "Project"
	else local title "Projects"

	project_table_setup	fname plog, title1("`title'")
	char fname[style] res
	
	sort fname
	forvalues i = 1/`c(N)' {
		project_table_line fname plog, line(`i')
	}
	
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	
end


program define project_pclear
/*
--------------------------------------------------------------------------------

Remove a project in the database of projects.

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build
	
	syntax name(name=pname id="Project Name"), pclear
	
	
	// Search along the ado-path for the dataset of projects
	cap findfile "project.dta"
	if _rc {
		dis as err "The dataset of projects was not found."
		exit _rc
	}
	local projects "`r(fn)'"
	
	
	preserve
	
	
	use "`projects'", clear

	qui count if pname == "`pname'"
	if r(N) == 0 {
		dis as err `"project "`pname'" not found"'
		exit 459
	}
	else {
		qui drop if pname == "`pname'"
	}
	
	sort pname
	cap saveold "`projects'", replace
	if _rc {
		dis as err "Could not save the dataset of projects"
		exit _rc
	}
	
end


program define project_cd, rclass
/*
--------------------------------------------------------------------------------

Change Stata's current working directory to the project's directory

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build
	
	syntax name(name=pname id="Project Name"), cd
	
	
	// Search along the ado-path for the dataset of projects
	cap findfile "project.dta"
	if _rc {
		dis as err "The dataset of projects was not found."
		exit _rc
	}
	local projects "`r(fn)'"
	
	
	preserve
	
	
	use "`projects'", clear

	qui keep if pname == "`pname'"
	if _N == 0 {
		dis as err `"project "`pname'" not found"'
		exit 459
	}
	else {
		cd "`=path'"
		return local pwd "`=path'"
	}
	
end


program define project_build
/*
--------------------------------------------------------------------------------

Build a project. 

--------------------------------------------------------------------------------
*/

	// this is not a build directive; can't build from within a build!
	exit_if_in_a_build
	
	syntax name(name=pname id="Project Name"), build [TEXTlog SMCLlog]
	
	
	// restore to nothing if error/Break
	clear
	preserve
	
		
	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	
	// Check the project's files and links databases and start
	// from clean versions if something's wrong
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		
		// post a warning only if we are overwriting existing files
		cap confirm file "`pfiles'"
		local overwrite = _rc == 0
		cap confirm file "`plinks'"
		if `overwrite' | _rc == 0  dis ///
			as err "Warning: there is a problem with project's database of " ///
			as err "files and links. Starting a new build from scratch"
		
		
		// Create a new database of project files; one obs per file
		clear
		gen long fno = .			// file number
		gen str fname = ""			// file name
		gen str fpath = ""			// file path
		gen byte relpath = .		// flag if path is relative to project directory
		gen long csum = .			// file's checksum (from -checksum-)
		gen double flen = .			// file's length (from -checksum-)
		gen cvs = .					// -checksum- version
		gen int cdate = .			// date of last -checksum- call
		gen str ctime = ""			// time of last -checksum- call
		gen int chngdate = .		// date when added/last changed in project
		gen str chngtime = ""		// time when added/last changed in project
		gen byte archiveflag = .	// true if file should be archived
		
		// store a version in case we change the format in the future
		char _dta[files_version] 1
		
		// labels for our printing routines
		char fname[tname] Filename
		char fpath[tname] "File Path      "
		char csum[tname] Checksum
		char flen[tname] Length
		char chngdate[tname] Chng Date
		char chngtime[tname] ChngTime
		
		// how to convert from numeric to string; for our printing routines
		char flen[numconv] gen sflen = trim(string(flen, "%20.0fc"))
		char chngdate[numconv] gen schngdate = string(chngdate,"%d")
		char csum[numconv] gen scsum = string(csum,"%10.0f")
		
		// list of expected vars; for consistency checks
		char _dta[vlist_files] fno fname fpath relpath csum flen cvs  ///
				cdate ctime chngdate chngtime archiveflag
				
		qui save "`pfiles'", replace emptyok
		
	
		// create a new database of links (dependencies)
		clear
		gen long fdo = .		// fno of do-file
		gen long odo = .		// fno of do-file that originated the link
		gen long flink = .		// fno of the linked to file 
		gen byte linktype = .	// 1 original 2 uses 3 relies_on 4 creates
		gen long lkcsum = .		// linked file's checksum (from -checksum-)
		gen double lkflen = .	// linded file's length (from -checksum-)
		gen lkcvs = .			// -checksum- version
		gen byte newlink = .	// link comes from the current build
		gen int norder = .		// link's order of appearance within the do-file
		gen byte level = .		// nested do-file level
		
		// there are 4 types of links
		label def linktype_l 1 original 2 uses 3 relies_on 4 creates
		label values linktype linktype_l
		
		// label and numeric to string conversion for our printing routines
		char linktype[tname] Linktype
		char linktype[numconv] decode linktype, gen(slinktype)
		
		// list of expected vars; for consistency checks
		char _dta[vlist_links] fdo odo flink linktype lkcsum lkflen lkcvs ///
			newlink norder level

		qui save "`plinks'", replace emptyok
		
	}


	// use the project links dataset to track new links and the state of
	// the build
	qui use "`plinks'", clear
	
	if "`: char _dta[start_date]'" != "" {
		dis as text "Previous build start: " ///
			as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
		dis as text "Previous build end  : " _cont
		if "`: char _dta[end_date]'" == "" {
			dis as err "unsuccessful" as text "" _n
		}
		else {
			dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n(2)
		}
	}

	qui replace newlink = 0
	local bdate "`c(current_date)'" 
	local btime "`c(current_time)'"
	char _dta[start_date] "`bdate'"
	char _dta[start_time] "`btime'"
	char _dta[end_date] ""
	char _dta[end_time] ""
	qui save "`plinks'", replace emptyok
	

	// Create a dataset that we can find at any time and irrespective of the
	// current directory to indicate that we are currently building a project.
	// Put it in the same directory as the program itself.
	clear
	char _dta[pname] "`pname'"
	char _dta[pdir] "`pdir'"
	local d = date("`bdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	char _dta[date] `d'
	char _dta[time] `btime'
	char _dta[plog] "`plog'"

	capture findfile "project.ado"
	local builtemp "`r(fn)'"
	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"
	qui save "`builtemp'", emptyok
	

	// restore the standard ado search path and drop all user programs
	global S_ADO `"`"UPDATES"';`"BASE"';`"SITE"';`"."';`"PERSONAL"';`"PLUS"';`"OLDPLACE"'"'
	program drop _all
	
			
	dis as text "Build start: " ///
		as res  "`bdate', `btime'" as text ""
	dis as text _dup(`c(linesize)') "="
	
	
	restore, not	// cancel break hanling
	
		
	// run the master do-file but capture any error / Break key
	capture noi project_do , do("`pdir'/`pname'.do") `textlog' `smcllog'
	local build_rc = _rc
	
	// erase the build temporary file
	cap erase "`builtemp'"
	
	if `build_rc' {
		exit `build_rc'
	}
	
	
	clear
	preserve	// break handling
	

	// record a successful build
	qui use "`plinks'", clear
	local bdate "`c(current_date)'" 
	local btime "`c(current_time)'"
	char _dta[end_date]  "`bdate'"
	char _dta[end_time]  "`btime'"
	sort fdo norder
	qui save "`plinks'", replace
	

	dis as text _dup(`c(linesize)') "="
	dis as text "Build successfully completed: " ///
		as res  "`bdate'" ///
		as text ", " as res "`btime'" as text ""
	
end


program define project_replicate
/*
--------------------------------------------------------------------------------

Move all files created by the most recent build into a "replicate" directory
within the project directory and run a replication build. Compare the files
created against those in the "replicate" directory.

This can only be done if the previous build was successful.

--------------------------------------------------------------------------------
*/

	// this is not a build directive; can't build from within a build!
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), replicate [TEXTlog SMCLlog]
	
	
	// restore to nothing if error/Break
	clear
	preserve
	
		
	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases and start
	// from clean versions if something's wrong
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}


	// stop if previous build was unsuccessful
	qui use "`plinks'", clear
	if "`: char _dta[end_date]'" == "" {
		dis as err  "Previous build did not terminate normally"
		exit 459
	}
	
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
	

	// The master do-file is lined to all files in the most recent build.
	// The norder variable is kept to track the order in which each file
	// was created.
	qui keep if fdo == 1
	qui keep if linktype == 4
	keep flink norder
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	rename csum csum00
	rename flen flen00
	rename cvs cvs00
	sort fno
	tempfile fcreated
	qui save "`fcreated'"
	

	// Sort files by directory (ignore case)
	qui gen str Ufname = upper(fname)
	qui gen str Ufpath = upper(fpath)
	sort Ufpath Ufname
	
	local repdir "`pdir'/replicate"
	capture mkdir "`repdir'"
	dis _n as text "Backing up `c(N)' files to directory : " ///
		as res "`repdir'" _n
	
	local bpath "`repdir'"

	// move each file to the replicate directory
	forvalues i = 1/`c(N)' {
	
		// Traverse new path and create directories to the file
		if Ufpath[`i'] != Ufpath[`i'-1] {
			local fpath = fpath[`i']
			local bpath "`repdir'"
			
			// File paths that are relative to the project directory follow
			// the same directory structure within the "replicate" directory.
			// Full file paths have to be completely created
			gettoken part fpath : fpath, parse("/:")
			while "`part'" != "" {
				if !inlist("`part'", "/", ":") {
					local bpath "`bpath'/`part'"
					capture mkdir "`bpath'"
				}
				gettoken part fpath : fpath, parse("/:")
			}
		}
		
		local fromp = fpath[`i']
		local fname = fname[`i']
		
		if "`fromp'" == "" local from "`fname'"
		else local from "`fromp'/`fname'"
		
		dis as res "`from'"
		
		if relpath[`i'] local from "`pdir'/`from'"
		
		local to "`bpath'/`fname'"
		
		capture copy "`from'" "`to'", replace
		if _rc {
			dis as err  `"Could not copy "`from'" to "`to'""'
			exit _rc
		}

		qui erase "`from'"
	}


	// Initialize the replicate build. Drop all links to force a complete rebuild. 
	qui use "`plinks'", clear
	qui drop if _n > 0
	local bdate "`c(current_date)'" 
	local btime "`c(current_time)'"
	char _dta[start_date]  "`bdate'"
	char _dta[start_time]  "`btime'"
	char _dta[end_date]  ""
	char _dta[end_time]  ""
	qui save "`plinks'", replace emptyok
	
	
	// Create a dataset that we can find at any time and irrespective of the
	// current directory to indicate that we are currently building a project.
	// Put it in the same directory as the program itself.
	clear
	char _dta[pname] "`pname'"
	char _dta[pdir] "`pdir'"
	local d = date("`bdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	char _dta[date] `d'
	char _dta[time] `btime'
	char _dta[plog] "`plog'"

	capture findfile "project.ado"
	local builtemp "`r(fn)'"
	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"
	qui save "`builtemp'", emptyok	
	
		
	// restore the standard ado search path and drop all user programs
	global S_ADO `"`"UPDATES"';`"BASE"';`"SITE"';`"."';`"PERSONAL"';`"PLUS"';`"OLDPLACE"'"'
	program drop _all
	
	
	dis _n as text "Replicate build start: " ///
		as res  "`bdate', `btime'" as text ""
	dis as text _dup(`c(linesize)') "="


	// run the master do-file but capture any error / Break key
	capture noi project_do , do("`pdir'/`pname'.do") `textlog' `smcllog'
	local build_rc = _rc
	
	// erase the build temporary file
	cap erase "`builtemp'"
	
	if `build_rc' {
		exit `build_rc'
	}
		
	
	qui use "`plinks'", clear	
	local bdate "`c(current_date)'" 
	local btime "`c(current_time)'"
	char _dta[end_date]  "`bdate'"
	char _dta[end_time]  "`btime'"
	sort fdo norder
	qui save "`plinks'", replace
	

	dis as text _dup(`c(linesize)') "="
	dis as text "Replication build successfully completed: " ///
		as res  "`bdate'" ///
		as text ", " as res "`btime'" as text ""


	// Check that files created match exactly the prior build
	qui keep if fdo == 1
	qui keep if linktype == 4
	keep flink norder
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	sort fno
	capture cf fno fpath fname norder using "`fcreated'"
	if _rc {
		dis as err "Files created by the project do no match"
		exit _rc
	}


	// combine post replication file info with pre-replication file info
	// for files created by the project.
	use "`pfiles'", clear
	sort fno
	qui merge fno using "`fcreated'"
	qui keep if _merge == 3
	drop _merge
	
	
	// create a tempfile to save a modified copy of the log file
	tempfile fold
	
	
	// determine the name of Stata's temporary directory;
	// it's anything up to and including the last "/" or "\" character
	if regexm("`fold'","(.*[/\\])") local tempdir = regexs(1) 
	
	
	dis as text _n ///
		"Checking files created vs. those from the previous build... " _n(2)
	gen chng = 0
	sort norder
	tempfile flist
	qui save "`flist'"

	
	local nchng 0
	forvalues i = 1/`c(N)' {
	
		local fpath = fpath[`i']
		
		// determine path to archived file
		if "`fpath'" == "" local old_path "`repdir'"
		else {
			 // full paths start with "/"
			local old_path = regexr("`fpath'","^/","")
			// DOS ":" is replaced with "/"
			local old_path = subinstr("`old_path'", ":","/",.)
			local old_path "`repdir'/`old_path'"
		}
		
		// path to the project file from the replicate build
		if relpath[`i'] local fpath "`pdir'/`fpath'"	
		
		local fname = fname[`i']
		local logsmcl = regexm("`fname'",".smcl$")
		local logtext = regexm("`fname'",".log$")
		
		
		// treat log file differently by ignoring a few things that change;
		// these are usually time stamp, tempfile related, or -save- output
		local chng 0
		if `logsmcl' | `logtext' {
			qui infix str244 s0 1-244 using "`old_path'/`fname'", clear
			qui drop if regexm(s0,"filesig\([0-9]+:[0-9]+\)")
			qui drop if regexm(s0,"file .+ saved")
			qui drop if regexm(s0,"\(note: file .+ not found\)")
			qui replace s0 = subinstr(s0,"`tempdir'","",1)
			qui drop if regexm(s0,"project .+ > Build start :")
			qui drop if strpos(s0,"opened on:  ")
			qui drop if strpos(s0,"closed on:  ")
			qui drop if regexm(s0,"vars:.+[0-9]:[0-9][0-9]$")
			qui drop if regexm(s0,"obs:.+[0-9]:[0-9][0-9]$")
			qui drop if trim(s0) == ""
			qui compress
			qui save "`fold'", replace
			qui infix str244 s 1-244 using "`fpath'/`fname'", clear
			qui drop if regexm(s,"filesig\([0-9]+:[0-9]+\)")				// project 
			qui drop if regexm(s,"file .+ saved")							// save
			qui drop if regexm(s,"\(note: file .+ not found\)")				// save
			qui replace s = subinstr(s,"`tempdir'","",1)					// tempfile name
			qui drop if regexm(s,"project .+ > Build start :")				// project, doinfo
			qui drop if strpos(s,"opened on:  ")							// log open
			qui drop if strpos(s,"closed on:  ")							// log close
			qui drop if regexm(s,"vars:.+[0-9]:[0-9][0-9]$")				// describe date/time
			qui drop if regexm(s,"obs:.+[0-9]:[0-9][0-9]$")					// describe using date/time
			qui drop if trim(s) == ""
			qui compress
			qui merge using "`fold'"
			qui count if s != s0
			local chng = r(N)
		}
		else {
		
			// Stata datasets are checked by data signatures since Stata
			// inserts new time stamps at every save.
			// Other files are compared using -checksum-
			capture use "`fpath'/`fname'", clear
			if _rc {
				use "`flist'", clear
				local chng = csum[`i'] != csum00[`i'] | ///
							flen[`i'] != flen00[`i'] | ///
							cvs[`i'] != cvs00[`i']
			}
			else {
				qui version 9.2: datasignature, fast
				local newsig `r(datasignature)'
				qui use "`old_path'/`fname'", clear
				qui version 9.2: datasignature, fast
				local chng = "`r(datasignature)'" != "`newsig'"
			}
		}
		
		
		// if the created file is different, leave the copy in the replicate dir.
		qui use "`flist'", clear
		if `chng' {
			qui replace chng = 1 in `i'
			local ++nchng
			qui save "`flist'", replace	
		}
		else {
		
			// erase the project file with no difference
			qui erase "`old_path'/`fname'"
			
			
			// remove empty directories
			local old_path : subinstr local old_path "`pdir'/" ""
			capture rmdir "`pdir'/`old_path'"
			while !_rc {
				local old_path = regexr("`old_path'", "/[^/]+$","")
				capture rmdir "`pdir'/`old_path'"
			}
		}
	}


	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"

	// prepare a report
	local d : dis %dCYND date("`bdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`btime'",":","",.)
	local logfile "replication_report_`d'_`t'.`logext'"
	capture mkdir "`repdir'"
	log using "`repdir'/`logfile'", name(replication_report)
	
	
	// capture break key/errors while logging 
	cap noi {
	
	
		dis as txt
		dis as txt "Project name      : " as res "`pname'"
		dis as txt "Project directory : " as res "`pdir'"
		dis as txt "Build completed   : " as res "`bdate' `btime'" _n


		// use our table routines to list results
		qui gen status = cond(chng,"changed","same")
		char status[tname] " Status"
		
		// Setup the table
		local tablevars fname flen csum status chngdate chngtime
		project_table_setup	`tablevars', ///
			title1("Replication Report") ///
			title2("`c(N)' files, in order they are created in the build")
		local tw : char _dta[tablewidth]
		
	
		sort norder
	
		forvalues i = 1/`c(N)' {
		
			local fp = fpath[`i']
			local fn = fname[`i']
			if "`fp'" == "" local ff "`fn'"
			else local ff "`fp'/`fn'"
			if relpath[`i'] local ff "`pdir'/`ff'"
			if chng[`i'] {
				char status[style] err
			}
			else {
				char status[style] txt
			}
	
			project_table_line `tablevars', line(`i')
	
		}
		
		dis "{c BLC}{hline `tw'}{c BRC}"
		
		
		// Final report
		if `nchng' == 0 {
			dis _n as text "No change found, project results are replicated"
		}
		else {
			dis _n as text "Number of differences found = " ///
				   as res `nchng' as text ""
		}

		dis

	}
	
	// handle any error/break key
	local rc = _rc
	log close replication_report
	if `rc' exit `rc'
			
end


program define project_do
/*
--------------------------------------------------------------------------------

Run a do-file from within a build.  The master do-file is called from 
-project_build- or -project_replicate-. Nested do-files are run when a
-project, do()- build directive is encountered.

--------------------------------------------------------------------------------
*/

	syntax , do(string) [preserve TEXTlog SMCLlog]
	
	
	// This is a build directive; check that we are currently running one
	capture findfile "project.ado"
	local builtemp "`r(fn)'"

	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"
	cap describe using "`builtemp'"
	if _rc {
		dis as err "no project being built"
		exit 198
	}
	
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	preserve


	use "`builtemp'", clear
	local pname  : char _dta[pname]
	local pdir   : char _dta[pdir]
	local bdate  : char _dta[date]
	local btime  : char _dta[time]
	local plog   : char _dta[plog]
	
	if "`pname'" == "" | "`pdir'" == "" | "`bdate'" == "" | "`btime'" == "" | "`plog'" == "" {
		dis as err "build parameters corrupted - this should never happen"
		exit 459
	}


	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	local prompt "project `pname' > "	


	// Force the user to run do-files from within the project directory
	qui project_pathname "`do'"
	local dofile "`r(fname)'"
	local fullpath "`r(fullpath)'"
	if "`pdir'" == "`fullpath'" local dopath ""
	else local dopath : subinstr local fullpath "`pdir'/" ""
	local len_full : length local fullpath
	local len_rel  : length local dopath
	if `len_full' == `len_rel' {
		dis as text "`prompt'" ///
			as err "do-file (`dopath'/`dofile') is not within the project directory"
		exit 119
	}
	
	
	// Remove the ".do" file extension
	if regexm("`dofile'","(.*)\.do$") local dofstub = regexs(1)
	else {
		dis as text "`prompt'" ///
			as err "do-file (`dofile') must end with .do"
		exit 198
	}


	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	local logfile = "`dofstub'.`logext'"
	
	
	// Find the do-file in the project files database. If the do-file is not
	// yet in the database, use the next available number; that's the number
	// that will be assigned by the dolink call just before running the do-file
	// for the first time
	qui use "`pfiles'", clear
	gen n = _n
	sum n if upper(fname) == upper("`dofile'") & ///
			upper(fpath) == upper("`dopath'"), meanonly
	if r(N) == 0 {
		sum fno, meanonly
		local fdo = cond(mi(r(max)), 1, r(max) + 1)
	}
	else {
		local fdo = fno[r(max)]
	}
	
	
	// Find the file number of the logfile if it exists
	sum n if upper(fname) == upper("`logfile'") & ///
			upper(fpath) == upper("`dopath'"), meanonly
	local flog = fno[r(max)]


	// Add the do-file to the list of currently active do-files.
	// Get the file number of the enclosing do-file, missing if this is the master
	qui use "`builtemp'", clear
	local dolist : char _dta[dolist]
	gettoken enclosing_do : dolist
	char _dta[dolist]  `fdo' `dolist'
	qui save "`builtemp'", replace emptyok
	

	// Do not run the same do-file more than once.
	qui use "`plinks'", clear
	capture count if fdo == `fdo' & newlink
	if r(N) {
		dis as text "`prompt'" ///
			as err `"Cannot do "`dofile'" more than once per build"'
		exit 119
	}

	
	// Another do-file should not be linked to this one
	qui count if flink == `fdo' & newlink
	if r(N) {
		dis as text "`prompt'" ///
			as err `"Another do-file is linked to "`dofile'""'
		exit 119
	}
	
	
	// If this do-file successfully completed its previous run, it will have a
	// link to its logfile. If that's the case, we may not have to run it again.
	// Save copies of its previous links so that we may check.
	qui keep if fdo == `fdo'
	qui count if flink == `flog'
	local do_it = r(N) == 0
	if !`do_it' {
		tempfile dolinks
		qui save "`dolinks'"
	}


	// Clear the links from the previous build
	qui use "`plinks'", clear
	qui drop if fdo == `fdo'
	qui save "`plinks'", replace emptyok
		
	
	if !`do_it' {
		
		// Check files linked to the do-file.
		qui use "`dolinks'", clear
		sort flink norder
		qui by flink: keep if _n == 1
		keep flink lkcsum lkflen lkcvs
		rename flink fno
		qui merge fno using "`pfiles'"
		qui keep if _merge == 3
		drop _merge
		
		// Any change means we must redo.
		qui count if lkcsum != csum | lkflen != flen | lkcvs != cvs
		local do_it = r(N)
		drop lkcsum lkflen lkcvs
		
		
		if !`do_it' {
		
			// For linked files that haven't been updated since the beginning of the
			// build, we must redo checksums to make sure they haven't changed.
			// Check the do-file first, then from smaller to larger files. 
			// Stop at the first change.
			qui keep if cdate < `bdate' | (cdate == `bdate' & ctime <= "`btime'")
			gen update = 0
			gen notdo = fno != `fdo'
			sort notdo flen
			local i 0
			while !`do_it' & `i' < `c(N)' {	
				local ++i
				local fpath = fpath[`i']
				local fname = fname[`i']
				if "`fpath'" == "" local f "`fname'"
				else local f "`fpath'/`fname'"
				if relpath[`i'] local f "`pdir'/`f'"
				capture checksum "`f'"
				if _rc {
					local do_it 1
				}
				else {
					local d = date("`c(current_date)'","`=cond(c(version) < 10,"dmy","DMY")'")
					local t "`c(current_time)'"
					if csum[`i'] != r(checksum) | ///
					   flen[`i'] != r(filelen) | ///
					   cvs[`i']  != r(version) {
						qui replace chngdate   = `d' in `i'
						qui replace chngtime   = "`t'" in `i'
						qui replace archiveflag = 1 in `i'
						qui replace csum = r(checksum) in `i'
						qui replace flen = r(filelen) in `i'
						qui replace cvs  = r(version) in `i'
						local do_it 1
					}
					qui replace cdate = `d' in `i'
					qui replace ctime = "`t'" in `i'
					qui replace update = 1 in `i'
				}
			}
			
			// Save the updated checksums
			qui keep if update
			drop update notdo
			sort fno
			project_clear_dta_char
			qui merge fno using "`pfiles'"
			drop _merge
			sort fno
			qui save "`pfiles'", replace
		}
	}
	

	if `do_it' {

		// Move to the do-file's directory
		local savepwd "`c(pwd)'"
		qui cd "`fullpath'"
		
		// link the do-file (all all enclosing do-files) to itself
		project_dolink , linktype(1) linkfile("`dofile'")
		
		// Start the do-file with a clean slate
		project_clear_globals
		clear
		mata: mata clear
		timer clear
		program drop _all
		set seed 123456789
		
		// Suspend log of the enclosing do-file and start a new one
		if "`enclosing_do'" != "" qui log off plog_`enclosing_do'
		capture log close plog_`fdo'
		log using "`logfile'", name(plog_`fdo') replace
		
		// cancel break handling, give user control
		if "`preserve'" != "" restore, preserve
		else restore, not

		// run the do-file; close the do-file if a break/error occured
		capture noisily do "`dofile'"
		
		// error/break handling
		local rc = _rc		
		log close plog_`fdo'
		if "`enclosing_do'" != "" qui log on plog_`enclosing_do'
		if `rc' exit `rc'
		
		// link to the log file
		project_dolink , linktype(4) linkfile("`fullpath'/`logfile'")
		
		// restore the enclosing do-file's working directory
		qui cd "`savepwd'"

		
	}
	else {

		// Start from the links of a previous build. Keep only the
		// first instance for each linked file. This will indicate
		// the type of link.
		qui use "`dolinks'", clear
		sort flink norder
		qui by flink: keep if _n == 1
		keep flink linktype
		rename linktype linktype0
		tempfile flinks0
		qui save "`flinks0'"

		qui count
		dis as text "`prompt'Skipping " as res "`dopath'/`dofile';" ///
			as text " no change in the " as res r(N) ///
			as text " files linked to it."
		
		// Since the master do-file is linked at this point to every
		// new link since the start of the build, check the validity
		// of the linktype values.
		qui use "`plinks'", clear
		qui keep if fdo == 1
		if _N {
			sort flink norder
			qui by flink: keep if _n == 1
			keep flink linktype
			sort flink
			qui merge flink using "`flinks0'"
			qui count if (linktype0 == 1 | linktype0 == 3) & linktype == 4
			if r(N) {	
				dis as text "`prompt'" ///
					as err  "skipped do-file (or nested do-file within) contains"
				dis as text "`prompt'" ///
					as err  "a -relies_on()- or -original() build directive but " ///
							"linked file is already created by the project"
				exit 119
			}
			qui count if linktype0 == 2 & linktype != 4
			if r(N) {	
				dis as text "`prompt'" ///
					as err  "skipped do-file (or nested do-file within) contains"
				dis as text "`prompt'" ///
					as err  "a -uses()- build directive but " ///
					"no prior -creates()- build directive found"
				exit 119
			}
			qui count if linktype0 == 4 & linktype != .
			if r(N) {	
				dis as text "`prompt'" ///
					as err  "skipped do-file (or nested do-file within) contains"
				dis as text "`prompt'" ///
					as err  "a -creates()- build directive but"
				dis as text "`prompt'" ///
					as err  "linked file is already in the project"
				exit 119
			}
		}
		
		// Expand the links by the number of do-files currently running (at
		// this point `dolist' includes only enclosing do-files). 
		use "`dolinks'", clear
		local nadd : word count `dolist'
		if `nadd' > 0 {
			gen n = _n
			qui expand `nadd' + 1
			sort n
			qui by n: replace newlink = _n
			local i 1
			foreach fdo in `dolist' {
				local ++i
				qui replace fdo = `fdo' if newlink == `i'
			}
			drop n
		}
		else {
			qui replace newlink = 1
		}
		
		// Add these new links to the database. 
		qui append using "`plinks'"
		
		// When we duplicated links for enclosing do-files, we gave them
		// newlink values of more than one. By sorting, we put them after
		// the current ones and then adjust norder.
		sort fdo newlink norder
		qui by fdo: replace norder = _n if newlink > 1
		qui replace newlink = 1 if newlink > 1
		
		sort fdo norder
		qui save "`plinks'", replace

	}
	
	//  Remove the file number from the dolist
	qui use "`builtemp'", clear
	local dolist : char _dta[dolist]
	gettoken last rest : dolist
	char _dta[dolist]  "`rest'"
	qui save "`builtemp'", replace emptyok
	
end


program define project_original
/*
--------------------------------------------------------------------------------

The original(filename) build directive is used to link the currently running
do-file (and all upstream do-files) to a file that is not created by the 
project. The linked file is used in some way and therefore the results of the 
project could change (including log files) if the linked file changes.
Therefore any change to the linked file will require that the do-file (and
all upstream do-file) be rerun

Because this is typically used just before inputting data (and therefore 
clearing the data in memory), the default is to not to preserve the use data
while this program performs its functions. The -preserve- option can be used
to overide the default behavior.

--------------------------------------------------------------------------------
*/

	syntax , original(string) [preserve]
		
		
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	else {
		tempname hold
		cap estimates store `hold'
	}
	preserve
	
	project_dolink , linktype(1) linkfile("`original'")
	
	if "`preserve'" != "" cap estimates restore `hold'
		
end


program define project_uses
/*
--------------------------------------------------------------------------------

The uses(filename) build directive is used to link the currently running
do-file (and all upstream do-files) to a file that was created by the 
project. The linked file is used in some way and therefore the results of the 
project could change (including log files) if the linked file changes.
Therefore any change to the linked file will require that the do-file (and
all upstream do-file) be rerun 

Note that is it not necessary to declare such a link in the do-file that
actually creates the linked file. This is typically used with files that are
created by a previously run do-file.

Because this is typically used just before loading a Stata dataset (and
therefore clearing the data in memory), the default is to not to preserve the
use data while this program performs its functions. The -preserve- option can be
used to overide the default behavior.

--------------------------------------------------------------------------------
*/

	syntax , uses(string) [preserve]
	
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	else {
		tempname hold
		cap estimates store `hold'
	}
	preserve
	
	project_dolink , linktype(2) linkfile("`uses'")
	
	if "`preserve'" != "" cap estimates restore `hold'
		
end


program define project_relies_on
/*
--------------------------------------------------------------------------------

The relies_on(filename) build directive is used to link the currently running
do-file (and all upstream do-files) to a file that is not created by the
project. The linked file is NOT used by the do-file and therefore changes in the
linked file would not alter results. However, the linked file's content is
relevant to what the do-file does in some way. The linked file could be notes on
how an original file was obtained, documentation about it, the algorithm used by
the code, etc. While such links are strickly speaking not necessary, they are a
good practice. The directive inserts in the log file the checksum of the linked
file. If the linked file changes, this would mean that the do-file's log file
would change and therefore the do-file must be rerun.

An additional incentive/bonus to linking such files is that -project- knows that
they are related to the project. The cleanup task will leave such files in place
instead of moving them to an archive.

Because this is typically used just before inputting data (and therefore 
clearing the data in memory), the default is to not to preserve the use data
while this program performs its functions. The -preserve- option can be used
to overide the default behavior.


--------------------------------------------------------------------------------
*/

	syntax , relies_on(string) [preserve]
		
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	else {
		tempname hold
		cap estimates store `hold'
	}
	preserve
	
	project_dolink , linktype(3) linkfile("`relies_on'")
	
	if "`preserve'" != "" cap estimates restore `hold'

end


program define project_creates
/*
--------------------------------------------------------------------------------

The creates(filename) build directive is used to link the currently running
do-file (and all upstream do-files) to a file that it just created. This can
be a new Stata dataset created by a -save- statement but it is also for any
file created by the project, e.g. -outsheet-, -outfile-, -graph-,
-estimates save-...

The default is to not to preserve the use data while this program performs its
functions. The -preserve- option can be used to overide the default behavior.


--------------------------------------------------------------------------------
*/

	syntax , creates(string) [preserve]
	
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	else {
		tempname hold
		cap estimates store `hold'
	}
	preserve
	
	project_dolink , linktype(4) linkfile("`creates'")
	
	if "`preserve'" != "" cap estimates restore `hold'
	
end


program define project_dolink, rclass
/*
--------------------------------------------------------------------------------

Link the currently running do-file to a file. This program is called from
project_do, project_original, project_uses, project_relies_on, and
project_creates. The calling programs handle -preserve-

--------------------------------------------------------------------------------
*/

	syntax , linktype(integer) linkfile(string) 


	// This is a build directive; check that we are currently running one
	capture findfile "project.ado"
	local builtemp "`r(fn)'"

	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"

	cap describe using "`builtemp'"
	if _rc {
		dis as err "no project being built"
		exit 198
	}
	
	use "`builtemp'", clear
	local pname  : char _dta[pname]
	local pdir   : char _dta[pdir]
	local dolist : char _dta[dolist]
	local bdate  : char _dta[date]
	local btime  : char _dta[time]
	
	if "`pname'" == "" | "`pdir'" == "" | "`bdate'" == "" | "`btime'" == "" {
		dis as err "build parameters corrupted - this should never happen"
		exit 459
	}
	
	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	local prompt "project `pname' > "


	// Separate the filename from the file path
	qui project_pathname "`linkfile'"
	local fname "`r(fname)'"
	local fullpath  "`r(fullpath)'"
	if "`pdir'" == "`fullpath'" local relpath ""
	else local relpath : subinstr local fullpath "`pdir'/" ""
	local len_full : length local fullpath
	local len_rel  : length local relpath
	local use_relpath = `len_full' != `len_rel'

	
	// Check that we can store the file path and file name
	if `len_rel' > c(maxstrvarlen) {
		dis as txt "`prompt'path = " as res `""`relpath'""'
		dis as text "`prompt'" ///
			as err "cannot store path; " ///
			"size = `len_rel', limit = " c(maxstrvarlen)
		exit 1000
	}
	if `: length local fname' > c(maxstrvarlen) {
		dis as txt "`prompt'filename = " as res `""`fname'""'
		dis as text "`prompt'" ///
			as err "cannot store filename; " ///
			"size = `: length local fname', limit = " c(maxstrvarlen)
		exit 1000
	}
	

	// Find the file number of the linked file. If this is the first time, 
	// add the file to the database
	qui use "`pfiles'", clear
	sum fno, meanonly
	local nextfno = cond(mi(r(max)), 1, r(max) + 1)
	gen n = _n
	sum n if upper(fname) == upper("`fname'") & ///
			upper(fpath) == upper("`relpath'"), meanonly
	local nobs = r(max)
	drop n
	local flink = fno[`nobs']
	if mi(`flink') {
		local flink `nextfno'
		local nobs = _N + 1
		qui set obs `nobs'
		qui replace fno	  = `flink' in `nobs'
		qui replace fpath = "`relpath'" in `nobs'
		qui replace fname = "`fname'" in `nobs'
		qui replace cdate = 0 in `nobs'
		qui replace relpath = `use_relpath' in `nobs'
		sort fno
		qui save "`pfiles'", replace
	}
	
	
	// We only need to recompute the checksum if this is a newly created
	// file or if the checksum was last computed before the start of the build
	tempname csum flen cvs
	if `linktype' == 4 | cdate[`nobs'] < `bdate' | ///
			(cdate[`nobs'] == `bdate' & ctime[`nobs'] < "`btime'") {
		qui checksum "`fullpath'/`fname'"
		scalar `csum' = r(checksum)
		scalar `flen' = r(filelen)
		scalar `cvs'  = r(version)
		return add
		local d = date("`c(current_date)'","`=cond(c(version) < 10,"dmy","DMY")'")
		local t "`c(current_time)'"
		if csum[`nobs'] != `csum' | ///
		   flen[`nobs'] != `flen' | ///
		   cvs[`nobs']  != `cvs' {
			qui replace chngdate = `d' in `nobs'
			qui replace chngtime = "`t'" in `nobs'
			qui replace archiveflag = 1 in `nobs'
			qui replace csum     = `csum' in `nobs'
			qui replace flen     = `flen' in `nobs'
			qui replace cvs      = `cvs' in `nobs'
		}
		qui replace cdate   = `d' in `nobs'
		qui replace ctime   = "`t'" in `nobs'
		
		sort fno
		qui save "`pfiles'", replace
	}
	else {
		scalar `csum' = csum[`nobs']
		scalar `flen' = flen[`nobs']
		scalar `cvs'  = cvs[`nobs']
		return scalar checksum = `csum'
		return scalar filelen = `flen'
		return scalar version = `cvs'
	}

	
	// Check against current links to see if it is appropriate to 
	// link to this file. Use the master do-file as it is linked to all
	// files up to this point
	qui use "`plinks'", clear
	qui keep if fdo == 1
	
	if _N {
	
		// If this is a link to an original file, make sure that the current
		// build has not created the file already.
		if `linktype' == 1 | `linktype' == 3 {
			qui count if flink == `flink' & linktype == 4
			if r(N) {	
				dis as text "`prompt'" ///
					as err  "relies_on or original file is " ///
							"created by the project;"
				dis as text "`prompt'" ///
					as err `"try: project , uses(`anything') instead."'
				exit 119
			}
		}
		
		
		// If the do-file uses a file created by the project, make sure that
		// the file has already been created.
		if `linktype' == 2 {
			qui count if flink == `flink' & linktype == 4
			if r(N) == 0 {	
				dis as text "`prompt'" ///
					as err  "cannot link do-file to a file used;"
				dis as text "`prompt'" ///
					as err  "file is not created by the project;"
				dis as text "`prompt'" ///
					as err  `"try: project , original(`anything') instead."'
				exit 119
			}
		}
		
		
		// If the do-file creates a file, make sure that the file is not
		// already in the project. Force a new checksum to be calculated
		// since the file is created after the initial build start.
		if `linktype' == 4 {
			qui count if flink == `flink'
			if r(N) {	
				dis as text "`prompt'" ///
					as err  "cannot link do-file to a file created;"
				dis as text "`prompt'" ///
					as err  "file is already in the project;"
				exit 119
			}
		}

	}

		

	// Add an observation for each do-file in the list. 
	qui use "`plinks'", clear
	local ndo : word count `dolist'
	gettoken odo : dolist
	foreach fdo of numlist `dolist' {
		sum norder if fdo == `fdo', meanonly
		local n = cond(mi(r(max)), 1, r(max) + 1)
		local nobs = _N + 1
		qui set obs `nobs'
		qui replace fdo		 = `fdo' in `nobs'
		qui replace odo      = `odo' in `nobs'
		qui replace flink	 = `flink' in `nobs'
		qui replace linktype = `linktype' in `nobs'
		qui replace lkcsum	 = `csum' in `nobs'
		qui replace lkflen	 = `flen' in `nobs'
		qui replace lkcvs	 = `cvs' in `nobs'
		qui replace newlink  = 1 in `nobs'
		qui replace level    = `ndo' in `nobs'
		qui replace norder   = `n' in `nobs'
	}


	// Save the links to disk. 
	sort fdo norder
	qui save "`plinks'", replace
		

	// Display link info
	local linktype : word `linktype' of uses_original uses relies_on creates
	local linktype : subinstr local linktype "_" " "
	local scsum `: dis %12.0f `csum''
	local sflen `: dis %17.0f `flen''
	if "`relpath'" == "" local f "`fname'"
	else local f "`relpath'/`fname'"
	dis as text "`prompt'do-file `linktype': " as res `""`f'""' ///
		" filesig(`scsum':`sflen')" as text ""

end


program define project_doinfo, rclass
/*
--------------------------------------------------------------------------------

The doinfo build directive is used to get information about the current do-file 
and the status of the build. 

The default is to not to preserve the use data while this program performs its
functions. The -preserve- option can be used to overide the default behavior.

--------------------------------------------------------------------------------
*/

	syntax , doinfo [preserve] 
	
	
	// This is a build directive; check that we are currently running one
	capture findfile "project.ado"
	local builtemp "`r(fn)'"


	local builtemp : subinstr local builtemp "project.ado" "project_`c(username)'_BUILD_TEMPFILE.dta"
	cap describe using "`builtemp'"
	if _rc {
		dis as err "no project being built"
		exit 198
	}
	
	// restore to nothing if error/Break unless user wants its data back
	if "`preserve'" == "" clear
	else {
		tempname hold
		cap estimates store `hold'
	}
	preserve

	use "`builtemp'", clear
	local pname  : char _dta[pname]
	local pdir   : char _dta[pdir]
	local dolist : char _dta[dolist]
	local bdate  : char _dta[date]
	local bdate  : dis %d `bdate'
	local btime  : char _dta[time]
	
	if "`pname'" == "" | "`pdir'" == "" | "`bdate'" == "" | "`btime'" == "" {
		dis as err "build parameters corrupted - this should never happen"
		exit 459
	}
	
	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	local prompt "project `pname' > "


	dis as txt "`prompt'Project Name: " as res "`pname'"
	dis as txt "`prompt'Project Dir.: " as res "`pdir'"
	dis as txt "`prompt'Build start : " ///
		as res  "`bdate', `btime'" as text ""
		

	gettoken current_do other_do : dolist
	
	qui use "`pfiles'", clear
	gen n = _n
	sum n if fno == `current_do', meanonly
	local nobs = r(min)
	local dofile = fname[`nobs']
	if regexm("`dofile'","(.*)\.do$") local dofstub = regexs(1)
	dis as txt "`prompt'Do-file Name: " as res "`dofile'"
	
	if !mi("`other_do'") {
		dis as txt "`prompt'Enclosing do-files:"
		foreach fdo of numlist `other_do' {
			sum n if fno == `fdo', meanonly
			local nobs = r(min)
			local fname = fname[`nobs']
			local fpath = fpath[`nobs']
			dis as txt "`prompt'    " _cont
			if !mi("`fpath'") dis as res "`fpath'/`fname'"
			else dis as res "`fname'"
		}
	}
	
	return local pname "`pname'"
	return local pdir  "`pdir'"
	return local bdate "`bdate'"
	return local btime "`btime'"
	return local dofile "`dofstub'"
	
	if "`preserve'" != "" cap estimates restore `hold'

end


program define check_project_files_links
/*
--------------------------------------------------------------------------------

Perform consistency checks on the project's databases of files and links. Any
problem encountered will require starting from scratch because we can't trust
the information we have. This should never happen unless these files have been
manually changed or if there is a bug in this program.

--------------------------------------------------------------------------------
*/

	args pname pfiles plinks
	
	
	clear
	capture use "`pfiles'"
	if _rc {
		dis as err "`pfiles' not found or not in Stata format"
		exit _rc
	}
	
	if _N == 0 {
		dis as err "`pfiles' is empty"
		exit 2000
	}
	
	if "`: char _dta[files_version]'" != "1" {
		dis as err  "Format of `pfiles' has changed"
		exit 459
	}
	
	local vlist : char _dta[vlist_files]
	unab vfound: *
	if `: list vlist == vfound' == 0 {
		dis as err "Variables in `pfiles' are different"
		exit 459
	}	

	if "`: sortedby'" != "fno" {
		dis as err "`pfiles' is not sorted by fno"
		exit 5
	}	
	
	capture by fno: assert _N == 1
	if _rc {
		dis as err "fno is not unique in `pfiles'"
		exit 459
	}	
	
	sort fno
	if !(fname[1] == "`pname'.do" & fpath == "") | fno[1] != 1 {
		dis as err "bad fno for master do-file in `pfiles'"
		exit 459
	}	

	sort fpath fname
	capture by fpath fname: assert _N == 1
	if _rc {
		dis as err "fpath fname is not unique in `pfiles'"
		exit 459
	}	
		
	clear
	capture use "`plinks'"
	if _rc {
		dis as err "`plinks' not found or not in Stata format"
		exit _rc
	}
	
	if _N == 0 {
		dis as err "`plinks' is empty"
		exit 2000
	}
	
	local vlist : char _dta[vlist_links]
	unab vfound: *
	if !`: list vlist == vfound' {
		dis as err  "Variables in `plinks' are different"
		exit 459
	}	

	if "`: sortedby'" != "fdo norder" {
		dis as err  "`plinks' is not sorted by fdo norder"
		exit 5
	}	
	
	local start_time : char _dta[start_time]
	local badtime 1
	if regexm("`start_time'", "^([0-9][0-9]):([0-9][0-9]):([0-9][0-9])$") {
		local hh = regexs(1)
		local mm = regexs(2)
		local ss = regexs(3)
		local badtime = `hh' > 60 | `mm' > 60 | `ss' > 60
	}
	if `badtime' {
		dis as err  "Bad or missing build start time in `plinks'"
		exit 459
	}	
	
	local start_date = date("`: char _dta[start_date]'","`=cond(c(version) < 10,"dmy","DMY")'")
	if mi(`start_date') {
		dis as err  "Bad or missing build start date in `plinks'"
		exit 459
	}
	
	capture by fdo norder: assert _N == 1
	if _rc {
		dis as err  "fno is not unique in `plinks'"
		exit 459
	}	
	
	if fdo[1] != 1 | flink[1] != 1 {
		dis as err  "master do-file not the first link in `plinks'"
		exit 459
	}	

	// a file is created (4) before it is used (2)
	sort fdo flink norder
	capture by fdo flink: assert _n == 1 if linktype == 4
	local myrc = _rc
	capture by fdo flink: assert linktype == 2 if linktype[1] == 4 & _n > 1
	local myrc = `myrc' + _rc
	if `myrc' {
		dis as err  "Inconsistent linktype"
		exit 459
	}
	
	local end_time : char _dta[end_time]
	local build_ok 0
	if regexm("`end_time'", "^([0-9][0-9]):([0-9][0-9]):([0-9][0-9])$") {
		local hh = regexs(1)
		local mm = regexs(2)
		local ss = regexs(3)
		local build_ok = `hh' <= 60 & `mm' <= 60 & `ss' <= 60
	}
	
	
	local test = date("`: char _dta[end_date]'","`=cond(c(version) < 10,"dmy","DMY")'")
	if mi(`test') local build_ok 0

	
	if `build_ok' {
	
		// The master do-file is linked to all files in the previous build
		qui keep if fdo == 1
		keep flink
		sort flink
		qui by flink: keep if _n == 1
		
		// Ignore old links, i.e. links from do-files that did not run in the most
		// recent build
		rename flink fdo
		qui merge fdo using "`plinks'"
		qui keep if _merge == 3

		sort flink fdo
		
		capture by flink: assert lkcsum == lkcsum[1] & ///
								lkflen == lkflen[1] & lkcvs == lkcvs[1]
		if _rc {
			dis as err  "Successful build but inconsistent checksums"
			exit 459
		}
		
	}
	

	keep flink lkcsum lkflen lkcvs
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	capture assert _merge != 1
	if _rc {
		dis as err  "`pname'_links.dta had links to files not in `pname'_files.dta"
		exit 459
	}
	
	
	if `build_ok' {
		qui keep if _merge == 3
		capture assert cdate > `start_date' | ///
					   (cdate == `start_date' & ctime >= "`start_time'")
		if _rc {
			dis as err  "Build ok but inconsistent dates/times for active files"
			exit 459
		}
		capture assert lkcsum == csum & lkflen == flen & lkcvs == cvs
		if _rc {
			dis as err  "Build ok but `pname'_links.dta and `pname'_files.dta" ///
						" checksums do not match"
			exit 459
		}
	}
	
end



program define project_validate
/*
--------------------------------------------------------------------------------

This project task goes over all project files and checks that they haven't 
changed since the last build. If the previous build successfully terminated and
none of the files have changed, then the build is validated. 

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), validate [TEXTlog SMCLlog]
	
	
	preserve
	

	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}
	

	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
			
	// prepare date and time stamp
	local cdate "`c(current_date)'" 
	local ctime "`c(current_time)'"
	local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`ctime'",":","",.)
	local datetime "`d'_`t'"
	

	// Display the previous build status
	qui use "`plinks'", clear
	dis as text "Build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Build end  : " _cont
	if "`: char _dta[end_date]'" == "" {
		dis as err "Previous build did not terminate normally" as text "" _n
		local buildok 0
	}
	else {
		dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
		local buildok 1
	}
	
	
	// The master do-file is linked to all the files in the project. Use it to
	// identify files in the project.
	qui use "`plinks'", clear
	qui keep if fdo == 1
	keep flink
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui drop if _merge == 2	// inactive files, not in most current build
	drop _merge 

	
	qui gen status = ""
	char status[tname] " Status"
	
	
	// start a log file in the archive directory
	capture mkdir "`pdir'/archive"
	log using "`pdir'/archive/validate_`datetime'.`logext'", name(validate_log)
	
	
	// capture break key/errors while logging 
	cap noi {
	
		
		// Setup the table
		local tablevars fname flen csum status chngdate chngtime
		project_table_setup	`tablevars', ///
			title1("Alphabetical Index (`c(N)' files)")
		local tw : char _dta[tablewidth]
		
	
		// Show files in alphabetical order
		qui gen Ufname = upper(fname)
		qui gen Ufpath = upper(fpath)
		sort Ufname Ufpath
		
		
		// Choose variable styles
		char fname[style] res
		
		local ndif 0
		
	
		forvalues i = 1/`c(N)' {
		
			local fpath = fpath[`i']
			local fname = fname[`i']
			if "`fpath'" == "" local ff "`fname'"
			else local ff "`fpath'/`fname'"
			if relpath[`i'] local ff "`pdir'/`ff'"
			capture checksum "`ff'"
			if _rc {
				qui replace status = "missing" in `i'
				char status[style] err
				local ++ndif
			}
			else if csum0[`i'] != r(checksum) | /// string version created by project_table_setup
			   flen0[`i'] != r(filelen)  | ///
			   cvs[`i']  != r(version) {
				qui replace status = "changed" in `i'
				char status[style] err
				local ++ndif
			}
			else {
				qui replace status = "ok" in `i'
				char status[style] res
			}
	
			project_table_line `tablevars', line(`i')
	
		}
		dis "{c BLC}{hline `tw'}{c BRC}"
		
	
		// Final report
		if `ndif' == 0 & `buildok' {
			dis _n as text "No change found, project results are validated"
		}
		else {
			dis _n as text "Number of differences found = " ///
				   as res `ndif' as text ""
			if !`buildok' dis as err "Incomplete build, results not validated" as text "" _n
		}
		dis

	}
	
	// handle any error/break key
	local rc = _rc
	log close validate_log
	if `rc' exit `rc'


end


program define project_archive
/*
--------------------------------------------------------------------------------

The archive task is used to make copies of all files that have been added to or
have changed since the last time the archive task was performed. The task relies
upon an archive flag to identify if a project file should be archived. 

If the previous build was unsuccessful, then the scope of this task is limited
to files that were linked to at the time the build stopped.

Files created by the project are not archived (under the assumption that they
can be easily recreated). This is a good way to make a quick backup of what has
changed since the last time the archive task was run.

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), archive [TEXTlog SMCLlog]
	
	
	preserve
	

	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}
	

	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
			
	// prepare date and time stamp
	local cdate "`c(current_date)'" 
	local ctime "`c(current_time)'"
	local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`ctime'",":","",.)
	local datetime "`d'_`t'"
	

	// Display the previous build status
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	if "`status'" == "" {
		dis as err "unsuccessful" as text "" _n
	}
	else {
		dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
	}

	
	// The master do-file is linked to all files in the previous build
	qui keep if fdo == 1
	sort flink norder
	qui by flink: keep if _n == 1
	
	// Drop files that are created by the project, these can recreated
	qui drop if linktype == 4
	
	// get file information for files linked to in the most recent build
	keep flink
	rename flink fno
	project_clear_dta_char
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	
	
	// Target files that have changed since the last archive
	qui keep if archiveflag
	if _N {
	
			
		// create the archive directory
		capture mkdir "`pdir'/archive"
		local bdir "`pdir'/archive/archive_`datetime'"
		capture mkdir "`bdir'"
		if _rc {
			dis as err `"Could not create "`bdir'""'
			exit _rc
		}
	
	
		log using "`bdir'.`logext'", name(archive_log)
		
		
		// capture break key/errors while logging 
		cap noi {
		
			local title "`c(N)' files moved to archive/archive_`datetime'"
	
			
			// Setup the table
			local tablevars fname flen csum chngdate chngtime
			project_table_setup	`tablevars', title1("`title'")
	
		
			// Choose variable styles
			char fname[style] res
		
	
			// Sort files by directory (ignore case)
			qui gen Ufname = upper(fname)
			qui gen Ufpath = upper(fpath)
			sort Ufpath Ufname
			
			local bpath "`bdir'"
	
			// archive each file
			forvalues i = 1/`c(N)' {
			
				// Traverse new path and create directories to the file
				if Ufpath[`i'] != Ufpath[`i'-1] {
					local fpath = fpath[`i']
					local bpath "`bdir'"
					
					gettoken part fpath : fpath, parse("/:")
					while "`part'" != "" {
						if !inlist("`part'", "/", ":") {
							local bpath "`bpath'/`part'"
							capture mkdir "`bpath'"
						}
						gettoken part fpath : fpath, parse("/:")
					}
				}
				
				local fromp = fpath[`i']
				local fname = fname[`i']
				
				if "`fromp'" == "" local from "`fname'"
				else local from "`fromp'/`fname'"
				if relpath[`i'] local from "`pdir'/`from'"
				
				local to "`bpath'/`fname'"
				
				capture copy "`from'" "`to'"
				if _rc {
					dis as err  `"Could not copy "`from'" to "`to'""'
					exit _rc
				}
				
				project_table_line `tablevars', line(`i')
	
			}
			
			// Add a warning if the previous build was unsuccessful
			if "`status'" == "" {
				local tw : char _dta[tablewidth]
				dis "{c |}{space `tw'}{c |}"
				dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
			}
			
			dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
		
		}
		
		// handle any error/break key
		local rc = _rc
		log close archive_log
		if `rc' exit `rc'
		

		// Update the file information
		keep fno archiveflag
		qui replace archiveflag = 0
		sort fno
		qui merge fno using "`pfiles'"
		char _dta[archive_date] "`cdate'"
		char _dta[archive_time] "`ctime'"
		drop _merge
		order `: char _dta[vlist_files]'
		sort fno
		qui save "`pfiles'", replace

	}
	else {
		dis as text "No change since last archive" _n
	}

end


program define project_share
/*
--------------------------------------------------------------------------------

The share task is used to make copies of all files that have been added to or
have changed since the last time project files were shared with the same person. 
This is similar to the archive task but is more flexible.

If sharewith is left blank, then it is assumed to we are sharing with "me".

If the previous build was unsuccessful, the date and time shared is not
updated as this could create a situation where some files that are later in 
the build could be skipped the next time around.
--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), share(string) [TEXTlog SMCLlog]
	
	
	// reprocess the call using more specific syntax parsing
	local 0 `share'
	syntax [name(name=sharewith id="Sharing Name")], ///
		[ALLtime noCREated max(string) list]
		
	
	// give a name stub for the archive folder if no name is specified
	if "`sharewith'" == "" local sharewith "me"
	
	// file size max can be expressed in number of bytes, kB, MB, or GB
	local maxsize
	if regexm(trim("`max'"),"^[0-9]+$") local maxsize `max'
	if regexm(upper("`max'"),"([0-9]+) *B") local maxsize = regexs(1)
	if regexm(upper("`max'"),"([0-9]+) *K") local maxsize = regexs(1) + "000"
	if regexm(upper("`max'"),"([0-9]+) *M") local maxsize = regexs(1) + "000000"
	if regexm(upper("`max'"),"([0-9]+) *G") local maxsize = regexs(1) + "000000000"
	if "`maxsize'" == "" & "`max'" != "" {
		dis as err  "invalid value for max(`max')"
		exit 198
	}
	
	
	preserve
	

	get_project_directory `pname'
	local pdir  "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}
	

	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
			
	// prepare date and time stamp
	local cdate "`c(current_date)'" 
	local ctime "`c(current_time)'"
	local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`ctime'",":","",.)
	local datetime "`d'_`t'"
	

	// Display the previous build status
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	if "`status'" == "" {
		dis as err "unsuccessful" as text "" _n
	}
	else {
		dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
	}
	
	
	// The master do-file is linked to all files in the previous build
	qui keep if fdo == 1
	sort flink norder
	qui by flink: keep if _n == 1
	
	// Drop files that are created by the project is requested
	if "`created'" == "nocreated" qui drop if linktype == 4
	
	// get file information for files linked to in the most recent build
	keep flink
	rename flink fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	
	
	if "`maxsize'" != "" {
		qui drop if flen > `maxsize'
	}
	
	
	// get info on previous share
	local sharedate : char _dta[share_`sharewith'_date]
	local sharetime : char _dta[share_`sharewith'_time]
	
	local nsharedate = date("`sharedate'","`=cond(c(version) < 10,"dmy","DMY")'")
	if mi(`nsharedate') | "`alltime'" != "" local nsharedate 0
	
	
	// Display last share time and date unless irrelevant
	if `nsharedate' != 0 & "`sharetime'" != "" & "`alltime'" == "" {
		dis as text "Last time shared with `sharewith' : " ///
			as res  "`sharedate', `sharetime'" _n
	}
	
	
	qui keep if chngdate > `nsharedate' | ///
			(chngdate == `nsharedate' & chngtime > "`sharetime'")
	

	if _N {
	
		// create the archive project directory if it does not exists yet
		capture mkdir "`pdir'/archive"
		
		local bdir "`pdir'/archive/`sharewith'_`datetime'"
		
		if "`list'" == "" {
			capture mkdir "`bdir'"
			if _rc {
				dis as err `"Could not create "`bdir'""'
				exit _rc
			}	
		}
		
		log using "`bdir'.`logext'", name(share_log)
		
		// capture break key/errors while logging 
		cap noi {
		
			if "`list'" == "" local title "`c(N)' files copied to archive/`sharewith'_`datetime'"
			else local title "`c(N)' files to share with `sharewith'"
	
			
			// Setup the table
			local tablevars fname flen csum chngdate chngtime
			project_table_setup	`tablevars', title1("`title'")
	
		
			// Choose variable styles
			char fname[style] res
		
	
			// Sort files by directory (ignore case)
			qui gen Ufname = upper(fname)
			qui gen Ufpath = upper(fpath)
			sort Ufpath Ufname
			
			local bpath "`bdir'"
	
			// archive each file
			forvalues i = 1/`c(N)' {
			
				if "`list'" == "" {
					// Traverse new path and create directories to the file
					if Ufpath[`i'] != Ufpath[`i'-1] {
						local fpath = fpath[`i']
						local bpath "`bdir'"
						
						gettoken part fpath : fpath, parse("/:")
						while "`part'" != "" {
							if !inlist("`part'", "/", ":") {
								local bpath "`bpath'/`part'"
								capture mkdir "`bpath'"
							}
							gettoken part fpath : fpath, parse("/:")
						}
					}
					
					local fromp = fpath[`i']
					local fname = fname[`i']
					
					if "`fromp'" == "" local from "`fname'"
					else local from "`fromp'/`fname'"
					if relpath[`i'] local from "`pdir'/`from'"
					
					local to "`bpath'/`fname'"
					
					capture copy "`from'" "`to'"
					if _rc {
						dis as err  `"Could not copy "`from'" to "`to'""'
						exit _rc
					}
				}
				
				project_table_line `tablevars', line(`i')
	
			}
			
			
			// Add a warning if the previous build was unsuccessful
			if "`status'" == "" {
				local tw : char _dta[tablewidth]
				dis "{c |}{space `tw'}{c |}"
				dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
			}
			
			dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
		
		}
		
		// handle any error/break key
		local rc = _rc
		log close share_log
		if `rc' exit `rc'
		

		// update shared date
		if "`list'" == "" {
		
			if "`status'" == "" {
				dis as err _n "Since the last build is imcomplete, " ///
					`"share date and time with "`sharewith'" not updated"'
			}
			else {
				qui use "`pfiles'", clear
				char _dta[share_`sharewith'_date] "`c(current_date)'" 
				char _dta[share_`sharewith'_time] "`c(current_time)'"
				qui save "`pfiles'", replace
			}
		}

	}
	else {
		dis as text "No change since last share with `sharewith'" _n
	}

end


program define project_cleanup
/*
--------------------------------------------------------------------------------

This program scans all files in the project directory and in all subdirectories
recursively and archives files that are not linked to the project. 

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), cleanup [TEXTlog SMCLlog]
	
	
	preserve
	

	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}
	

	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
			
	// prepare date and time stamp
	local cdate "`c(current_date)'" 
	local ctime "`c(current_time)'"
	local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`ctime'",":","",.)
	local datetime "`d'_`t'"
	

	// Display the previous build status
	qui use "`plinks'", clear
	if "`: char _dta[end_date]'" == "" {
		dis as err  "Previous build did not terminate normally"
		exit 459
	}
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n

	
	// The master do-file is linked to all files in the previous build
	qui keep if fdo == 1
	keep flink
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	project_clear_dta_char
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	
	
	// add the project files and links databases to the list
	local nobs = _N + 1
	qui set obs `nobs'
	qui replace fname = "`pname'_files.dta" in `nobs'
	local nobs = _N + 1
	qui set obs `nobs'
	qui replace fname = "`pname'_links.dta" in `nobs'
	
	
	// Make sure that the archive directory exist
	capture mkdir "`pdir'/archive"
	
	
	local bdir "`pdir'/archive/cleanup_`datetime'"
	capture mkdir "`bdir'"
	if _rc {
		dis as err `"Could not create "`bdir'""'
		exit _rc
	}

	log using "`bdir'.`logext'", name(cleanup_log)
			
	// capture break key/errors while logging 
	cap noi {

		dis as txt _n "List of unused files moved to " ///
			as res "archive/cleanup_`datetime'" _n
		
		// recursively clean-up the project directory and subdirectories
		project_cleanupdir , currentdir(".") pdir("`pdir'") bdir("`bdir'")
		
		dis
	
	}
	
	// handle any error/break key
	local rc = _rc
	log close cleanup_log
	if `rc' exit `rc'
	
	
	// Save the project files database with the inactive files removed
	// Only files that are linked to in the previous build remain.
	qui drop if fname == "`pname'_files.dta"
	qui drop if fname == "`pname'_links.dta"
	sort fno
	qui save "`pfiles'", replace
	
	
	// go back and clean-up old links
	keep fno
	rename fno fdo
	sort fdo
	project_clear_dta_char
	qui merge fdo using "`plinks'"
	qui keep if _merge == 3
	drop _merge
	sort fdo norder
	qui save "`plinks'", replace
	
end


program define project_cleanupdir
/*
--------------------------------------------------------------------------------

This program is called initially with the currentdir set at "." (which indicates
the project's main directory) and travels down each subdirectory recursively to
compare all files against the list of files in the project (dataset in memory).

--------------------------------------------------------------------------------
*/

	syntax , currentdir(string) pdir(string) bdir(string) [list]
	
	
	if "`currentdir'" == "." {
		local currentdir "`pdir'"
		local relpath ""
	}
	else {
		local relpath : subinstr local currentdir "`pdir'/" ""
	}
	
	
	// get a list of all files in the current directory
	local flist: dir "`currentdir'" files "*"
	
	local i 0
	foreach f of local flist {
	
		// Is this file in the project? If not, we'll move it out
		qui count if upper(fname) == upper("`f'") & ///
			upper(fpath) == upper("`relpath'") & relpath
		local doit = r(N) == 0
		
		// ignore OS X's folder attribute hidden file
		if "`f'" == ".DS_Store" local doit 0
		// ignore Excel placeholder
		if "`f'" == "~.xlsx" local doit 0
		

		if `doit' {
		
			local ++i
			
			local from = "`currentdir'/`f'"
			dis as txt "`from'"
			
			if mi("`list'") {
			
				
				// Create the directory if this is the first file
				if `i' == 1 {
					// start at the base backup directory
					local bpath "`bdir'"
					// travel each part of the relative path to create dir
					// note that since we are somewhere within the project
					// directory, all paths are relative to "`pdir'". No
					// need to check for DOS ":" drive character.
					local fpath "`relpath'"
					gettoken part fpath : fpath, parse("/")
					while "`part'" != "" {
						if "`part'" != "/" {
							local bpath "`bpath'/`part'"
							capture mkdir "`bpath'"	
						}
						gettoken part fpath : fpath, parse("/")
					}
				}
				
				local to = "`bpath'/`f'"

				capture copy "`from'" "`to'"
				if _rc {
					dis as err `"Could not copy "`from'" to "`to'""'
					exit _rc
				}
				
				capture erase "`from'"
				if _rc {
					dis as err `"Could not erase "`from'" "'
					exit _rc
				}
			}
		}
	}
	
	
	// get a list of directories in the current directory
	local dlist: dir "`currentdir'" dirs "*"
	
	// remove the archive directory if we are in the project's main directory
	if "`pdir'" == "`currentdir'" ///
		local dlist : subinstr local dlist `""archive""' ""
	
	// continue the cleanup by travelling down each directory
	foreach d of local dlist {
	
		project_cleanupdir , currentdir("`currentdir'/`d'") ///
				pdir("`pdir'") bdir("`bdir'") `list'
				
		if mi("`list'") {
		
			// get a list of all files in the cleaned-up directory
			local flist: dir "`currentdir'/`d'" files "*"
			
			// if all that's left is OS X's folder attribute hidden file
			if `"`flist'"' == `"".DS_Store""' ///
				capture erase "`currentdir'/`d'/.DS_Store"

			// remove an empty directory
			capture rmdir "`currentdir'/`d'"
			if _rc == 0 dis as txt "Removed directory " ///
				as res "`currentdir'/`d'"
		}
		
				
	}
	
end


program define project_rmcreated
/*
--------------------------------------------------------------------------------

This program removes all files created by the project in the previous build.

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), rmcreated [TEXTlog SMCLlog]
	
	
	preserve
	
	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}
	

	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
			
	// prepare date and time stamp
	local cdate "`c(current_date)'" 
	local ctime "`c(current_time)'"
	local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
	local t = subinstr("`ctime'",":","",.)
	local datetime "`d'_`t'"
	

	// Display the previous build status
	qui use "`pdir'/`pname'_links.dta", clear
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	if "`: char _dta[end_date]'" == "" {
		dis as err "unsuccessful" as text "" _n
	}
	else {
		dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
	}
	
	
	// The master do-file is linked to all files in the previous build
	qui use "`plinks'", clear
	qui keep if fdo == 1 & linktype == 4
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	
	
	// Sort files by directory (ignore case)
	qui gen Ufname = upper(fname)
	qui gen Ufpath = upper(fpath)
	sort Ufpath Ufname
	

	if _N {	
	
		// start a log file in the archive directory
		capture mkdir "`pdir'/archive"
		log using "`pdir'/archive/rmcreated_`datetime'.`logext'", name(rmcreated_log)
		
		
		// capture break key/errors while logging 
		cap noi {
		
			dis as text "Erasing `c(N)' files ... "
			forvalues i = 1/`c(N)' {
				local fp = fpath[`i']
				local fn = fname[`i']
				if "`fp'" == "" local f "`fn'"
				else local f "`fp'/`fn'"
				if relpath[`i'] local f "`pdir'/`f'"
				erase "`f'"
				dis as res "`f'"
			}

		}
		
		// handle any error/break key
		local rc = _rc
		log close rmcreated_log
		if `rc' exit `rc'
		
	}
	else {
		dis as text "No file created by the project found"
	}
	
end



program define project_list
/*
--------------------------------------------------------------------------------

List project files in various ways

--------------------------------------------------------------------------------
*/

	// this is not a build directive
	exit_if_in_a_build

	syntax name(name=pname id="Project Name"), list(string) [TEXTlog SMCLlog]
	
	
	// More than one option is ok. Check if option is available.
	local opts build type index directory concordance archive cleanup
	local bad : list list - opts
	if "`bad'" != "" {
		dis as text "project `pname' > " ///
			as err  "Invalid list options = `bad'"
		exit 198
	}
	
	
	preserve

	get_project_directory `pname'
	local pdir   "`r(projectdir)'"
	local pfiles "`r(pfiles)'"
	local plinks "`r(plinks)'"
	local plog   "`r(plog)'"
	dis _n(2) as txt "Project directory : " as res "`pdir'" _n
	
	
	// Check the project's files and links databases
	cap noi check_project_files_links `pname' "`pfiles'" "`plinks'"
	if _rc {
		dis as err  "Problem with `pname'_files.dta or `pname'_links.dta;" ///
					" build project again"
		exit 459
	}


	// Display the previous build status
	qui use "`pdir'/`pname'_links.dta", clear
	dis as text "Previous build start: " ///
		as res  "`: char _dta[start_date]', `: char _dta[start_time]'"
	dis as text "Previous build end  : " _cont
	if "`: char _dta[end_date]'" == "" {
		dis as err "unsuccessful" as text "" _n
	}
	else {
		dis as res  "`: char _dta[end_date]', `: char _dta[end_time]'" _n
	}


	// log type is based on overall project setting and local option
	local logext = cond("`plog'" == "SMCL","smcl","log")
	if "`textlog'" != "" local logext "log"
	if "`smcllog'" != "" local logext "smcl"
	
	local listdir "`pdir'/archive/list"
	

	foreach w in `list' {
		
		// Make sure that the directory exist
		capture mkdir "`pdir'/archive"
		capture mkdir "`listdir'"
				
		// include date and time stamp in log file name
		local cdate "`c(current_date)'" 
		local ctime "`c(current_time)'"
		local d : dis %dCYND date("`cdate'","`=cond(c(version) < 10,"dmy","DMY")'")
		local t = subinstr("`ctime'",":","",.)
		local logfile "`w'_`d'_`t'.`logext'"
		log using "`listdir'/`logfile'", name(list_log)
		
		// capture in case of user break
		cap noi project_list_`w' `pname', pdir("`pdir'")
		
		local rc = _rc
		log close list_log
		if `rc' exit `rc'
			
	}

end


program define project_list_build
/*
--------------------------------------------------------------------------------

List project files, according to the order they appear in the build.

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)
	
	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	
	
	// Identify project do-files 
	qui use "`plinks'", clear
	qui by fdo: keep if _n == 1
	rename fdo fno
	keep fno
	sort fno
	tempfile dofiles
	qui save "`dofiles'"
	
	
	// The master do-file is linked to all the files in the project. Use its
	// links to map-out the build, in the order they added.
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	keep flink linktype norder level
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge 
	

	// Flag do-files
	sort fno
	qui merge fno using "`dofiles'"
	gen dofile  = _merge == 3
	qui drop if _merge == 2	// do-file not included in most recent build
	drop _merge 
	

	// Indent filename by do-file levels
	sum level, meanonly
	local n = r(max)
	local sindent ".     "
	forvalues i = 2/`n' {
		qui replace fname = "`sindent'" + fname if level == `i'
		local sindent  "`sindent'.    "
	}


	// Setup the table
	local tablevars fname flen linktype
	project_table_setup	`tablevars', title1("Build Sequence (`c(N)' links)")
	local tw : char _dta[tablewidth]


	// Show files in the order processed in the build
	sort norder


	// Choose variable styles
	char fname[style] res
	char linktype[style] res


	forvalues i = 1/`c(N)' {
	
		if dofile[`i'] dis "{c |}{space `tw'}{c |}"
		
		project_table_line `tablevars', line(`i')

		if level[`i'] > level[`i'+1] dis "{c |}{space `tw'}{c |}"
	}
	

	// Add a warning if the previous build was unsuccessful
	if "`status'" == "" {
		dis "{c |}{space `tw'}{c |}"
		dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
	}
	
	dis "{c |}{space `tw'}{c |}"
	dis "{c BLC}{hline `tw'}{c BRC}"	

end



program define project_list_type
/*
--------------------------------------------------------------------------------

List project files, according to the type of file. These are do-files,
log files, files linked as originals, files that are relied_on, and files
created.

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	
	
	// Identify project do-files 
	qui use "`plinks'", clear
	qui by fdo: keep if _n == 1
	rename fdo fno
	keep fno
	sort fno
	tempfile dofiles
	qui save "`dofiles'"
	
	
	// The master do-file is linked to all the files in the project. Reduce
	// to one record per file. Files that are created and then used will
	// be represented by the "creates" record.
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	keep flink linktype norder level
	sort flink norder
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge 
	

	// Flag do-files
	sort fno
	qui merge fno using "`dofiles'"
	qui drop if _merge == 2	// do-file not included in most recent build
	qui gen ftype  = 1 if _merge == 3
	drop _merge 
	
	
	// Flag log-files
	qui replace ftype = 2 if (linktype == 4) & ///
		(regexm(fname,".smcl$") | regexm(fname,".log$"))

	
	// Flag other types; type "uses" is always trumped by "creates"
	qui replace ftype  = 3 if mi(ftype) & linktype == 1
	qui replace ftype  = 4 if linktype == 3
	qui replace ftype  = 5 if mi(ftype) & linktype == 4
	
	local title1 Do-Files
	local title2 Log Files
	local title3 Original Files used (except do-files)
	local title4 Original Files that are relied upon
	local title5 Files created (except log files)
	

	tempfile f
	qui save "`f'"
	
	forvalues nt = 1/5 {
		use "`f'", clear
		
		// Setup the table
		local tablevars fname flen csum chngdate chngtime
		qui count if ftype == `nt'
		project_table_setup	`tablevars', title1("`title`nt'' (`r(N)' files)")
	
	
		// Show files in alphabetical order
		qui gen Ufname = upper(fname)
		qui gen Ufpath = upper(fpath)
		sort Ufname Ufpath

		
		// Choose variable styles
		char fname[style] res
	
		qui keep if ftype == `nt'
		
		forvalues i = 1/`c(N)' {
			project_table_line `tablevars', line(`i')
		}
	
	
		// Add a warning if the previous build was unsuccessful
		if "`status'" == "" {
			local tw : char _dta[tablewidth]
			dis "{c |}{space `tw'}{c |}"
			dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
		}
		
		dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	}
	
end


program define project_list_index
/*
--------------------------------------------------------------------------------

List project files alphabetically

--------------------------------------------------------------------------------
*/
	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	
	
	// The master do-file is linked to all the files in the project. Use it to
	// identify files in the project.
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	keep flink
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge 
	
	
	// Setup the table
	local tablevars fname flen csum chngdate chngtime
	project_table_setup	`tablevars', title1("Alphabetical Index (`c(N)' files)")


	// Show files in alphabetical order
	qui gen Ufname = upper(fname)
	qui gen Ufpath = upper(fpath)
	sort Ufname Ufpath
	
	
	// Choose variable styles
	char fname[style] res
	

	forvalues i = 1/`c(N)' {
		project_table_line `tablevars', line(`i')
	}


	// Add a warning if the previous build was unsuccessful
	if "`status'" == "" {
		local tw : char _dta[tablewidth]
		dis "{c |}{space `tw'}{c |}"
		dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
	}
	
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	
end


program define project_list_directory
/*
--------------------------------------------------------------------------------

List project files by directory

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	
	
	// The master do-file is linked to all the files in the project. Reduce
	// to one record per file. Files that are created and then used will
	// be represented by the "creates" record.
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	keep flink linktype norder level
	sort flink norder
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge 
		

	// Setup the table
	local tablevars fname flen csum chngdate chngtime
	project_table_setup	`tablevars', ///
		title1(" Alphabetical Index by Directory (`c(N)' files)")
	local tw : char _dta[tablewidth]


	// Show files in alphabetical order
	qui gen Ufname = upper(fname)
	qui gen Ufpath = upper(fpath)
	sort Ufpath Ufname 
	
	
	// Choose variable styles
	char fname[style] res
	

	forvalues i = 1/`c(N)' {
	
		project_table_line `tablevars', line(`i')
		
		if fpath[`i'] != fpath[`i'+1] & `i' != 1 & `i' != `c(N)' ///
				dis "{c LT}{hline `tw'}{c RT}"
	}


	// Add a warning if the previous build was unsuccessful
	if "`status'" == "" {
		local tw : char _dta[tablewidth]
		dis "{c |}{space `tw'}{c |}"
		dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
	}
	
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	
end



program define project_list_concordance
/*
--------------------------------------------------------------------------------

List project files alphabetically with a list of all do-files that link to them.

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	
	
	// The master do-file is linked to all files in the previous build
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	sort flink norder
	qui by flink: keep if _n == 1
	
	
	// Ignore old links, i.e. links from do-files that did not run in the most
	// recent build
	keep flink
	rename flink fdo
	qui merge fdo using "`plinks'"
	qui keep if _merge == 3
	
	
	// Reduce to link that originated in the do-filem i.e. ignore links 
	// copies made for the enclosing do-file(s)
	qui keep if fdo == odo
	
	
	// Keep only one instance of each linktype
	sort fdo flink linktype norder
	qui by fdo flink linktype: keep if _n == 1
	
	
	// The link to the do-file itself is obvious so we'll skip it.
	qui drop if fdo == flink
	
	
	// This is the main sample of what we want to list.
	tempfile fmain
	qui save "`fmain'"

	
	// Get file info for each link in the main sample. Reduce to one record
	// per linked file. These are the linked files that we want to list.
	keep flink
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	rename fno flink
	tempfile lkname
	qui save "`lkname'"
	
	
	// Get file info on the do-files for the list of linked files in the
	// main sample.
	use "`fmain'"
	keep fdo flink linktype
	rename fdo fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	
	
	// combine with the list of unique linked files
	rename fno fdo
	qui append using "`lkname'"
	
	
	// Sort records by linked file. Put the record that contains the linked
	// file's name first and then the records from do-files that originated
	// the link. Put "uses" link after the "creates" link.
	gen dofile = fdo != .
	gen uses = linktype == 2
	sort flink dofile uses fname fpath
	by flink: gen upfname = upper(fname[1])
	qui by flink: gen upfpath = upper(fpath[1])
	sort upfname upfpath dofile uses fname fpath
	
	
	// Indent the do-file name
	qui replace fname = "-->  " + fname if dofile
	
	
	// Setup the table
	local tablevars fname flen csum linktype chngdate chngtime
	project_table_setup	`tablevars', ///
		title1("Linked File to Do-file Concordance Table")
	local tw : char _dta[tablewidth]
	

	// Choose variable styles
	char fname[style] res


	forvalues i = 1/`c(N)' {
	
		if dofile[`i'] char fname[style] txt
		else char fname[style] res
		
		project_table_line `tablevars', line(`i')

		if flink[`i'] != flink[`i'+1] & `i' != 1 & `i' != `c(N)' ///
			dis "{c LT}{hline `tw'}{c RT}"
	}


	// Add a warning if the previous build was unsuccessful
	if "`status'" == "" {
		local tw : char _dta[tablewidth]
		dis "{c |}{space `tw'}{c |}"
		dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
	}
	
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"
	
end


program define project_list_archive
/*
--------------------------------------------------------------------------------

List the files that would be archived. Files to be archived are tracked using
an archive flag maintained in the project files dataset. This allows each file
to be tracked, irrespective of imcomplete builds or files from do-files that
are moved in and out of the project. 

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	

	// The master do-file is linked to all files in the previous build
	qui use "`plinks'", clear
	local status : char _dta[end_date]
	qui keep if fdo == 1
	sort flink norder
	qui by flink: keep if _n == 1
	
	
	// the archive task does not archive files that are created by the
	// project as these can be easily recreated by rebuilding it.
	qui drop if linktype == 4
	keep flink
	rename flink fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	
	
	if "`: char _dta[archive_date]'" == "" {
	 	local title "No previous archive"
	}
	else {
	 	local title : dis "Status since Archive of " ///
	 	trim("`: char _dta[archive_date]'") " `: char _dta[archive_time]'"
	}
	
	
	// Flag files that have changed since the last archive
	qui gen status = cond(archiveflag,"chng","ok")
	char status[tname] Status
		
	
	// Setup the table
	local tablevars fname flen csum status chngdate chngtime
	project_table_setup	`tablevars', title1("`title' (`c(N)' files)")


	// Show files in order they would be archived
	qui gen Ufname = upper(fname)
	qui gen Ufpath = upper(fpath)
	sort Ufpath Ufname
	
	
	// Choose variable styles
	char fname[style] res
	

	forvalues i = 1/`c(N)' {
	
		if status[`i'] == "ok" char status[style] res
		else char status[style] err
		
		project_table_line `tablevars', line(`i')

	}


	// Add a warning if the previous build was unsuccessful
	if "`status'" == "" {
		local tw : char _dta[tablewidth]
		dis "{c |}{space `tw'}{c |}"
		dis "{c |}" as err %~`tw's ">>> Incomplete Build <<<" as text "{c |}"
	}
	
	dis "{c BLC}{hline `: char _dta[tablewidth]'}{c BRC}"

end



program define project_list_cleanup
/*
--------------------------------------------------------------------------------

List files that are not part of the project (no link to them in the most recent
build) that would be moved to an archive directory.

--------------------------------------------------------------------------------
*/

	syntax name(name=pname id="Project Name"), pdir(string)

	local pfiles "`pdir'/`pname'_files.dta"
	local plinks "`pdir'/`pname'_links.dta"
	

	// Display the previous build status
	qui use "`plinks'", clear
	if "`: char _dta[end_date]'" == "" {
		dis as err  "Previous build did not terminate normally"
		exit 459
	}

	
	// Use the master do-file's links to identify files in the project
	qui keep if fdo == 1
	keep flink
	sort flink
	qui by flink: keep if _n == 1
	rename flink fno
	sort fno
	qui merge fno using "`pfiles'"
	qui keep if _merge == 3
	drop _merge
	
	
	// add the project files and links databases to the list
	local nobs = _N + 1
	qui set obs `nobs'
	qui replace fname = "`pname'_files.dta" in `nobs'
	local nobs = _N + 1
	qui set obs `nobs'
	qui replace fname = "`pname'_links.dta" in `nobs'
	
	
	dis as txt _n "List of unused files that would be archived..." _n
	
	// recursively clean-up the project directory and subdirectories
	project_cleanupdir , currentdir(".") pdir("`pdir'") bdir("irrelevant") list
	
	dis
	
end


program define project_table_setup
/*
--------------------------------------------------------------------------------

This program converts numeric variables to be listed to string, calculates
line lengths. This is a bit tricky because we can have very long file paths
that will have to be wrapped around.

--------------------------------------------------------------------------------
*/

	syntax varlist, title1(string) [title2(string)]
	
	// Convert numeric variables to string
	local numvars flen chngdate csum linktype
	local vlist : list numvars & varlist
	foreach v in `vlist' {
		`: char `v'[numconv]'
		rename `v' `v'0
		rename s`v' `v'
		char rename `v'0 `v'
	}
	
	
	// Find the width of the table. Account for the width of each column title.
	local tw 0
	foreach v of varlist `varlist' fpath {
		local tname : char `v'[tname]
		local minlen : length local tname
		gen n = length(`v')
		sum n, meanonly
		local w = cond(r(max) < `minlen', `minlen',r(max))
		local tw = `tw' + `w' + 2
		char `v'[width] `w'
		char `v'[style] txt
		drop n
	}
	
	
	// Allow fpath to wrap around if the table would be wider than c(linesize).
	// Do not allow the width of fpath to go below 20.
	local cw : char fpath[width]
	local tw = `tw' - `cw'
	local n = `c(linesize)' - (`tw' + 2)
	local cw = min(cond(`n' < 20, 20,`n'),`cw')
	char fpath[width] `cw'
	local tw = `tw' + `cw'
	local nspace = `tw' - `cw' - 1
	
	char _dta[tablewidth] `tw'
	char _dta[tablespace] `nspace'
	char fname[align] -
	char fpath[align] -
	
	dis "{c TLC}{hline `tw'}{c TRC}"
	
	dis "{c |}" as res %~`tw's `"`title1'"' ///
		as text "{c |}"
	if `"`title2'"' != "" dis "{c |}" as res %~`tw's `"`title2'"' ///
		as text "{c |}"

	dis "{c |}{space `tw'}{c |}"
	dis "{c |}" _cont
	foreach v of varlist `varlist' fpath {
		dis as txt " " %`: char `v'[align]'`: char `v'[width]'s ///
			"`: char `v'[tname]'" " "  _cont
	}
	dis "{c |}"
	dis "{c LT}{hline `tw'}{c RT}"

end


program define project_table_line
/*
--------------------------------------------------------------------------------

This program prints one line in the results, wrapping the file path as needed.

--------------------------------------------------------------------------------
*/

	syntax varlist, line(integer)
		
	
	// Recover the widths we need to wrap around file paths
	local wfp : char fpath[width]
	local nspace : char _dta[tablespace]
	

	// Display all variables and the first line of the file path
	dis "{c |}" _cont
	foreach v of varlist `varlist' {
		dis " " as `: char `v'[style]' ///
			%`: char `v'[align]'`: char `v'[width]'s  `v'[`line'] " " _cont
	}
	dis " " as `: char fpath[style]' %-`wfp's ///
		substr(fpath[`line'],1,`wfp') " {c |}"
	
	
	// generate extra lines until all of the file path is displayed
	local slen = length(fpath[`line'])
	local n `wfp'
	while `n' < `slen' {
		dis "{c |}{space `nspace'}" ///
			as `: char fpath[style]' %-`wfp's ///
			substr(fpath[`line'],`n'+1,`wfp') ///
			" {c |}"
		local n = `n' + `wfp'
	}
	
end



program define project_clear_globals
/*
--------------------------------------------------------------------------------

Drop all global macros without loosing local macros

--------------------------------------------------------------------------------
*/

	macro drop _all
	
end




program define project_clear_dta_char
/*
--------------------------------------------------------------------------------

Drop all dataset-level char. This is used to avoid mixing data stored using char
in the project files and links datasets.

--------------------------------------------------------------------------------
*/

	local dtachar : char _dta[]
	foreach c of local dtachar {
		char _dta[`c']
	}
	
end















