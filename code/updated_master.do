cap log close
capture log using updated_master.txt, text replace

/*~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
	Author:		Daniel Perez
	Title: 		updated_master.do
	Date: 		07/01/2020
	Created by: Daniel Perez
	
	Purpose:    Update union premium estimates

    last updated:   7/2/2020 12:02 PM	
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~*/

********* Preamble *********
clear all
set more off

********* Directories *********
global dir = "/projects/dperez/union_premium"
global data = "${dir}/data/"
global code = "${dir}/code/"

I
********* Load 5-year CPS ORG sample *********
load_epiextracts, begin(2015m5) end(2020m5) sample(ORG)

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

describe orgwgt union unmem uncov wbho

*Tabulate union coverage by race
tab wbho union, row column
tab wbho union [fw=rndorg], row column

*Tabulate union coverage by gender
describe orgwgt uncov wbho
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


capture log close

