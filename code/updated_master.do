cap log close
capture log using updated_master.txt, text replace
/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Author:		Daniel Perez
	Title: 		updated_master.do
	Date: 		07/01/2020
	Created by: Daniel Perez
	
	Purpose:    Update union premium estimates
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

********* Preamble *********
clear all
set more off

********* Directories *********
global data = "../data/"

********* Load 5-year CPS ORG sample *********
load_epiextracts, begin(2015m1) end(2019m12) sample(ORG)

*keep 16+ and employed only in may data as somehow there are unemployed union members
keep if age >= 16
keep if lfstat == 1
keep if union != .

* log wage used in regressions
* exclude all BLS imputations
gen logwage = log(wageotc)
replace logwage = . if paidhre == 1 & a_earnhour == 1
replace logwage = . if paidhre == 0 & a_weekpay == 1

*add labels
numlabel, add

tempfile cps 
save `cps'



* Share union by group
foreach group in wbhao mind03 {
	use `cps', clear
	gcollapse (mean) union [pw=orgwgt], by(`group')
	tempfile shares_`group'
	save `shares_`group''
}
clear
foreach group in wbhao mind03 {
	append using `shares_`group''
}
save ${data}shares_union.dta, replace
export excel "${data}shares_union.xls", firstrow(variable) replace



* Distribution of union members
use `cps', clear 

gen byte poc = wbhao != 1
gen byte fem_or_poc = female == 1 | poc == 1
gen byte assoc_greater = gradeatn >= 11 if gradeatn != .
gen byte ba_greater = gradeatn >= 13 if gradeatn != .

gcollapse (mean) female poc fem_or_poc assoc_greater ba_greater [pw=orgwgt], by(union)
save ${data}dist_union.dta, replace
export excel "${data}dist_union.xls", firstrow(variable) replace



* Union wage premium regressions
use `cps', clear
forvalues i = 1/5 {
	gen age_`i' = age^`i'
}

assert gradeatn != .
gen yrschool = .
replace yrschool = 3 if gradeatn <= 3
replace yrschool = 7 if gradeatn == 4
replace yrschool = 9 if gradeatn == 5
replace yrschool = 10 if gradeatn == 6
replace yrschool = 11 if gradeatn == 7
replace yrschool = 12 if gradeatn == 8 | gradeatn == 9
replace yrschool = 13 if gradeatn == 10
replace yrschool = 14 if gradeatn == 11 | gradeatn == 12
replace yrschool = 16 if gradeatn == 13
replace yrschool = 18 if gradeatn >= 14
gen exp = min(age - 16, age - yrschool - 6)
replace exp = 0 if exp < 0
forvalues i = 1/4 {
	gen exp_`i' = exp^`i'
}

* unconditional
local model1 ""
* last time-ish
local model2 exp_* i.female i.wbhao i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.division
* with age poly instead of exp
local model3 age_* i.female i.wbhao i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.division
* modification with statefips instead
local model4 age_* i.female i.wbhao i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.statefips
* modification with statefips and 5 category educ
local model5 age_* i.female i.wbhao i.educ i.citistat i.mind03 i.mocc03 i.year i.statefips


*Union premium regression models 1-5
postfile wagereg model b se df using ${data}wage_reg_union.dta, replace
forvalues i = 1/5 {
	di _n(2) "working on results for model `i'"
	di "model `i' = `model`i''"
	qui reg logwage union `model`i'' [pw=orgwgt], robust
	lincom union
	post wagereg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
postclose wagereg

*Union wage premium regressions by race
postfile racereg wbhao b se df using ${data}race_reg_union.dta, replace
	forvalues j= 1/5{
		di _n(2) "working on results for for model 5, wbhao == `j'"
		qui reg logwage union `model5' [pw=orgwgt] if wbhao==`j', robust
		lincom union
		post racereg (`j') (`r(estimate)') (`r(se)') (`r(df)')
	}
postclose racereg

*Union wage premium regressions by gender
postfile femreg female b se df using ${data}female_reg_union.dta, replace
	forvalues j = 0/1{
		di _n(2) "working on results for model 5, female == `j'"
		qui reg logwage union `model5' [pw=orgwgt] if female==`j', robust
		lincom union
		post femreg (`j') (`r(estimate)') (`r(se)') (`r(df)')
	}
postclose femreg

*Model 5 regressions by sector

*Union premium regression models 5, by sector 
postfile secreg pubsec b se df using ${data}sector_regs.dta, replace
forvalues i = 0/1 {
	di _n(2) "working on results for pubsec== `i'"
	qui reg logwage union `model5' [pw=orgwgt] if pubsec==`i', robust
	lincom union
	post secreg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
postclose secreg

*Union wage premium regressions by sector and  race
postfile secwbhao pubsec wbhao b se df using ${data}sec_race_regs.dta, replace
forvalues i = 0/1{
	forvalues j= 1/5{
		di _n(2) "working on results for pubsec==`i' and wbhao == `j'"
		qui reg logwage union `model`i'' [pw=orgwgt] if wbhao==`j' & pubsec==`i', robust
		lincom union
		post secwbhao (`i') (`j') (`r(estimate)') (`r(se)') (`r(df)')
	}
}
postclose secwbhao

*Union wage premium regressions by sector and gender
postfile secfemreg pubsec female b se df using ${data}sec_gend_reg.dta, replace
forvalues i = 0/1{

	forvalues j = 0/1{
		di _n(2) "working on results for pubsec==`i' and female == `j'"
		qui reg logwage union `model`i'' [pw=orgwgt] if female==`j' & pubsec==`i', robust
		lincom union
		post secfemreg (`i') (`j') (`r(estimate)') (`r(se)') (`r(df)')
	}
}

*Append regression datasets
use ${data}wage_reg_union, clear
append using ${data}race_reg_union.dta
append using ${data}female_reg_union.dta
append using ${data}sector_regs.dta
append using ${data}sec_race_regs.dta
append using ${data}sec_gend_reg.dta



replace model=5 if model==.
lab def modelnames 1 "Model 1" 2 "Model 2" 3 "Model 3" 4 "Model 4" 5 "Model 5: educ"
label val model modelnames

* race labels have disappeared, so add them back
lab def wbhao 1 "White" 2 "Black" 3 "Hispanic" 4 "Asian" 5 "Other"
lab val wbhao wbhao

rename female gender
label def gender 0 "Male" 1 "Female"
label val gender gender

rename pubsec sector
label def sector 0 "Private" 1 "Public"
label val sector sector

list 

cap log close
