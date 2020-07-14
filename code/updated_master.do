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
load_epiextracts, begin(2015m6) end(2020m6) sample(ORG)

*keep 16+ and employed only in may data as somehow there are unemployed union members
keep if age >= 16
keep if lfstat == 1

*add labels
numlabel, add

*generate rounded org weight for frequency weighting
gen rndorg = round(orgwgt/60,1)

**************************************************************
* Unions are diverse, just like America
*   -Breakdown of union coverage by race (un/weighted)
*   -Breakdown of union coverage by gender (un/weighted)
**************************************************************

describe orgwgt union unmem uncov wbhao

*Tabulate union coverage by race
tab wbhao union, row column
tab wbhao union [fw=rndorg], row column

*Tabulate union coverage by gender
describe orgwgt union uncov wbhao
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

/*Unweighted union share by over time
preserve
gcollapse (count) per = personid [pw=orgwgt/12], by(mind03 union wbhao)
keep if union!=.
list
restore
*/
