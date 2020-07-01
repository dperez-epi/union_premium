*clean data for Union wage premium
*create state codes tempfile
import delimited using ${data}state_geocodes.csv, clear
tempfile statecodes
save `statecodes'

*create cpi tempfile
import delimited using ${cpi}cpiurs_annual.csv, clear

*Create org files for specified years
local yearlist 2007/2017
local raworgvars hourly month orgwt sex age race hisp region wage* state union* marstat ed majind majocc prcitshp prinusyr aernwk aernhr sector
foreach year of numlist `yearlist' {
	local shortyear = substr("`year'",3,2)
	local filename wage`shortyear'c
	unzipfile ${orgdata}`filename'.dta.zip, replace
	use `raworgvars' using `filename'.dta, clear
	gen year = `year'
	tempfile year`year'
	save `year`year''
	erase `filename'.dta
}
local counter = 0
foreach year of numlist `yearlist' {
	local counter = `counter' + 1
	if `counter' == 1 use `year`year'', clear
	else append using `year`year''
}

* check sample
drop if age == .
*drops 2 obs missing age between 2003 and 2016
assert age >= 18 & age <= 64
assert union != .
assert orgwt != .

* very important- exclude imputed wages
drop if aernwk == 1 | aernhr == 1

*harmonize state codes
gen census = state
gen state_old = state
replace census = . if year >= 2015
replace state = . if year < 2015
merge m:1 census using `statecodes'
replace fips = state if fips == .
drop state_name state_abb division division_name _merge region_name
*merge div codes back in
merge m:1 fips using `statecodes'
assert census == state_old if year < 2015
assert fips == state_old if year >= 2015
drop state _merge
rename division div

*public sector variable
gen pub_sect = (sector == 1 | sector == 2 | sector == 3)
gen state_local = (sector == 3 | sector == 2)
gen federal_gov = sector == 1
* other potential covariates
forvalues i = 2/4 {
	gen age`i' = age^`i'
}
gen byte _educ=1 if 31<=ed & ed<=38
replace _educ=2 if ed == 39
replace _educ=3 if ed == 40
replace _educ=4 if 41<=ed & ed<=42
replace _educ=5 if ed==43
replace _educ=6 if 44<=ed & ed<=46

gen dl_educ = .
replace dl_educ = 1 if ed<=38 /*dl_educ = 1 = less than high school*/
replace dl_educ = 2 if ed==39 /*dl_educ = 2 = high school*/
replace dl_educ = 3 if ed<=42 & ed>=40 /*dl_educ = 3 = some college*/
replace dl_educ = 4 if ed==43 /*dl_educ = 4 = college*/
replace dl_educ = 5 if ed>=44 & ed!=. /*dl_educ = 5 = advanced degree*/

* outcome
gen logwage3 = log(wage3)

* Create female variable
gen female = sex == 2

* create unionization variable
gen myunion = union == 1 | unioncov == 1

* create immigrant variable
/*prcitshp=4 is foreign born, US citizen by naturalization, prcitshp=5 is foreign born, not a citizen of the US*/
gen nonus = prcitshp == 4 | prcitshp == 5

* create new and old immigrant variables
gen newimm=0
replace newimm=1 if nonus == 1 & prinusyr >= 20
gen oldimm=1 if nonus == 1 & prinusyr < 20

* create married variable
gen married = marstat == 1 | marstat == 2

* Create 5-cat race variable where Asian does not incl. PI
gen rc = 5 if race != .
replace rc=1 if race == 1 & hisp == 2
replace rc=2 if race == 2 & hisp == 2
replace rc=3 if hisp == 1
replace rc=4 if race == 4 & hisp == 2

* Create experience variables
gen schyr = 19 if ed != .
replace schyr = 0 if ed==0 | ed==31
replace schyr = 2.5 if ed == 32
replace schyr = 5.5 if ed == 33
replace schyr = 7.5 if ed == 34
replace schyr = 9 if ed == 35
replace schyr = 10 if ed == 36
replace schyr = 11 if ed == 37
replace schyr = 12 if ed == 38 | ed == 39
replace schyr = 14 if ed == 40 | ed == 41 | ed == 42
replace schyr = 16 if ed == 43

gen exp = min(age-18, age-schyr-6)
replace exp = 0 if exp < 0
gen exp2 = exp^2
gen exp3 = exp^3

/* Use CPI to create realwage
*merge in cpi_data
merge m:1 year using `cpiurs'
drop if _merge == 2
drop _merge

/*use 2017 as base */

sum cpiurs if year == 2017
local cpi_base = `r(mean)'

gen realwage = wage3 * `cpi_base'/cpiurs
*/
save ${data}union_sample.dta, replace
