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
