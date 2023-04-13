program define graph2 , rclass
version 14
	syntax , file(string asis) [options(string) debug full]
	
	local pngfile = `file' + ".png"
	local pdffile = `file' + ".pdf"
	
	graph export "`pngfile'" , replace `options'
	graph export "`pdffile'" , replace `options'
	
	if "`full'" == "full" {
		graph save "`file'", replace
		psave, file("`file'") $deb preserve
	}
	
	if "`debug'" == ""{
		project , creates("`pngfile'") preserve
	}
end
