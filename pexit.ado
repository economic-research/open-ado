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
