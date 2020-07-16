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

*Union wage premium by race

postfile racereg model b se df using ${data}race_reg_union.dta, replace
*Union premium regression model 4
forvalues i = 1/5{
	di _n(2) "working on results for model 4 wbhao == `i'"
	qui reg logwage union `model4' [pw=orgwgt] if wbhao==`i', robust
	lincom union
	post racereg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
*Union premium regression model 5
forvalues i = 1/5{
	di _n(2) "working on results for model 5 wbhao == `i'"
	qui reg logwage union `model5' [pw=orgwgt] if wbhao==`i', robust
	lincom union
	post racereg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
postclose racereg

*Union wage premium by gender

postfile gendreg model b se df using ${data}gend_reg_union.dta, replace
*Union premium regression model 4
forvalues i = 0/1{
	di _n(2) "working on results for model 4 female == `i'"
	qui reg logwage union `model4' [pw=orgwgt] if female==`i', robust
	lincom union
	post gendreg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
*Union premium regression model 5
forvalues i = 0/1{
	di _n(2) "working on results for model 5 female == `i'"
	qui reg logwage union `model5' [pw=orgwgt] if female==`i', robust
	lincom union
	post gendreg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
postclose gendreg
