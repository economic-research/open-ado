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
