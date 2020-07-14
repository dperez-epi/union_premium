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
*numlabel, add

<<<<<<< HEAD
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



* Distribution of union members
use `cps', clear 

gen byte poc = wbhao != 1
gen byte fem_or_poc = female == 1 | poc == 1
gen byte assoc_greater = gradeatn >= 11 if gradeatn != .
gen byte ba_greater = gradeatn >= 13 if gradeatn != .

gcollapse (mean) female poc fem_or_poc assoc_greater ba_greater [pw=orgwgt], by(union)
save ${data}dist_union.dta, replace



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
local model2 exp_* i.female i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.division
* with age poly instead of exp
local model3 age_* i.female i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.division
* modification with statefips instead
local model4 age_* i.female i.gradeatn i.citistat i.mind03 i.mocc03 i.year i.statefips


postfile wagereg model b se df using ${data}wage_reg_union.dta, replace
forvalues i = 1/4 {
	di _n(2) "working on results for model `i'"
	di "model `i' = `model`i''"
	qui reg logwage union `model`i'' [pw=orgwgt], robust
	lincom union
	post wagereg (`i') (`r(estimate)') (`r(se)') (`r(df)')
}
postclose wagereg
=======
*generate rounded org weight for frequency weighting
gen rndorg = round(orgwgt/60,1)

**************************************************************
* Unions are diverse, just like America
*   -Breakdown of union coverage by race (un/weighted)
*   -Breakdown of union coverage by gender (un/weighted)
**************************************************************

*Tabulate union coverage by race
describe orgwgt union uncov wbhao female
tab wbhao union, row column
tab wbhao union [fw=rndorg], row column

*Tabulate union coverage by gender
describe orgwgt union uncov wbhao female
tab female union, row column
tab female union [fw=rndorg], row column

**************************************************************
*Unions represent workers of all levels of education
*   -Breakdown of union coverage by education level (un/weighted)
**************************************************************

tab educ union, row column
tab educ union [fw=rndorg], row column

**************************************************************
*Union workers hail from a variety of sectors
*   - Five industries with highest shares of 18
*       to-64 year-old workers covered by a union contract
**************************************************************

*unweighted union share by industry
preserve
gcollapse (count) personid, by(mind03 union)
list
keep if union!=.
reshape wide personid, i(mind03) j(union)
rename personid0 non_union
rename personid1 union
list
export excel "${data}union_unwgt.xls", firstrow(variable) replace
restore

*Weighted union share by industry
preserve
gcollapse (count) personid [pw=orgwgt/60], by(mind03 union)
list
keep if union!=.
reshape wide personid, i(mind03) j(union)
rename personid0 non_union
rename personid1 union
format union non_union %9.0f
list
export excel "${data}union_wgt.xls", firstrow(variable) replace
restore

**************************************************************
* Union coverage by race and gender (un/weighted)
**************************************************************

*Weighted union coverage by race/gender
preserve
gcollapse (count) per = personid [pw=orgwgt/60], by(union female wbhao)
keep if union!=.
reshape wide per, i(union wbhao) j(female)
rename per0 m_
rename per1 f_ 
decode(wbhao), gen(wbhaostring)
drop wbhao
reshape wide m_ f_, i(union) j(wbhaostring) string
format m_Asian m_Black m_Hispanic m_White m_Other f_White f_Black f_Hispanic f_Asian f_Other %9.0f 
list
export excel "${data}racegender_wgt.xls", firstrow(variable) replace
restore

*unweighted union coverage by race/gender
preserve
gcollapse (count) per = personid, by(union female wbhao)
keep if union!=.
reshape wide per, i(union wbhao) j(female)
rename per0 m_
rename per1 f_ 
decode(wbhao), gen(wbhaostring)
drop wbhao
reshape wide m_ f_, i(union) j(wbhaostring) string
list
export excel "${data}racegender_unwgt.xls", firstrow(variable) replace
restore

capture log close
>>>>>>> master

