cap log close
capture log using updated_master.txt, text replace

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Author:		Daniel Perez
	Title: 		updated_master.do
	Date: 		07/01/2020
	Created by: Daniel Perez
	
	Purpose:    Update union premium estimates

    last updated:   7/14/2020 10:37 AM (adding union coverage by race+gender)	
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

********* Preamble *********
clear all
set more off

********* Directories *********
global dir = "/projects/dperez/union_premium"
global data = "${dir}/data/"
global code = "${dir}/code/"

********* Load 5-year CPS ORG sample *********
load_epiextracts, begin(2015m6) end(2020m6) sample(ORG)

*keep 16+ and employed only in may data as somehow there are unemployed union members
keep if age >= 16
keep if lfstat == 1

*add labels
*numlabel, add

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

