/*
	Sanity check for evstudy.
	
	We generate random numbers from a normal distribution as function of time
	and then we run evstudy to plot the estimated coefficients
*/

clear all

local obs = 1000

set obs `obs'

set seed 6931

gen date	 	= _n

forvalues i = 1/300 {
	gen z`i'	  		= runiform()
}

reshape long z , i(date) j(id)

gen event = (date == `obs'/2)

tsperiods, bys(id) datevar(date) periods(10) event(event) 

forvalues i = -6(1)12 {
	replace z = z + `i' if epoch == `i'
}

collapse (mean) z , by(id epoch)

gen event = (epoch == 0)
label variable event "t"

evstudy z, leftperiods(6) periods(12) varstem(event) bys(id) ///
datevar(epoch) debug generate basevar(event_f1)
