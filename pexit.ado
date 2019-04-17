program define pexit , rclass
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
