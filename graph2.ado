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
