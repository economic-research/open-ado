program msubstitute
	syntax varlist(min=1 max=1), value(string) depvar(varlist(min=1 max=1)) ifvalue(string)
	
	foreach value in `ifvalue' {
		replace `varlist' = `value' if `depvar' == `value'
	}
end