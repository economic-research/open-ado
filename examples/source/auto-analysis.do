init , hard
init , proj(example) route("..") // add `debug` to run in debug mode!. 
				// Note that `project` automatically switches WD to current dofile, route() points back to the original root folder

program main
	sysuse auto
	
	check_data
	make_graphs
	explore_data
end

program check_data
	// Count missing values jointly for 3 variables
	mcompare make foreign rep78 
	
	// Replace missing values with zeros in rep78
	missing2zero rep78
end

program make_graphs
	// Plot prices, mpg of cars and weight in a scatter
	twowayscatter price mpg weight , $deb ///
		file("./publishables/figures/prices_mpgs_weight")
		
		
	// We can also use normal STATA graphs with project functionality
	histogram price
	graph2 , file("./publishables/figures/hist_price") $deb
	
end

program explore_data
	// Tabulate 2 variables according to the values of a third (foreign)
	sumby make gear_ratio , by(foreign)
	
	// Count number of distinct values for 3 variables
	uniquevals make gear_ratio foreign
end

main

exit
