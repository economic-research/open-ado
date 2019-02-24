/*
	This dofile showcases what our ado files can do in a production environment.
	Please note that examples here don't cover all the capabilities supported.
	
	Install first `project` with `ssc install project`
	Point to this masterdofile with:
	
	`project , setup`
	
	Build project with:
	`project example , build`
*/

project , do("source/auto-analysis.do")
