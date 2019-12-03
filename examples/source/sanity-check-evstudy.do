/*
	Sanity check for evstudy.
	
	We generate random numbers from a normal distribution as function of time
	and then we run evstudy to plot the estimated coefficients
*/

clear all
set obs 100

forvalues i = 1/100{
	gen z`i' = rnormal(`i', 1)
}

gen id = _n

reshape long z , i(id) j(time)

replace time = time - 50

gen dd = td(01Jan2000) + time
format %td dd

drop time

gen event = (dd == td(01Jan2000))
label variable event "t"

evstudy z , basevar(event_f1) bys(id) datevar(dd) debug periods(5) varstem(event) ///
generate leftperiods(7)
