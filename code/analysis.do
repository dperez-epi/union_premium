/* regressions
Note: 5 year runs will not be the match old numbers exactly because state/division coding is fixed here.
single year runs in 2015 or later will match because state coding is only a problem before 2015.
*/
use ${data}union_sample.dta, clear

*MODEL 1: compare 5 year 2016 data with 5 year 2017
local basemodel myunion i._educ exp* i.div i.majind i.majocc i.year i.female i.rc i.nonus
local model_no_occ_ind myunion i._educ exp* i.div i.year i.female i.rc i.nonus
local years_12_16 (year == 2012 | year == 2013 | year == 2014 | year == 2015 | year == 2016)
local years_13_17 (year == 2013 | year == 2014 | year == 2015 | year == 2016 | year == 2017)


*replicate union wage premium from union paper. Includes inds and occs. (2012-2016)
eststo base_16 : reg logwage3 `basemodel' [aw=orgwt] if `years_12_16'

*update with 2013-2017 data, old coding
eststo base_17 : reg logwage3 `basemodel' [aw=orgwt] if `years_13_17'

*no inds and occs
eststo no_oi_16 : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_12_16'
eststo no_oi_17 : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_13_17'

esttab base_16 no_oi_16 base_17 no_oi_17 using ${data}old_coding.csv, keep(myunion) varlabels(myunion "All") plain noobs cells(b) collabels(,none) replace

forvalues i = 1/2 {
	eststo base_16_s`i' : reg logwage3 `basemodel' [aw=orgwt] if `years_12_16' & sex == `i'
	eststo base_17_s`i' : reg logwage3 `basemodel' [aw=orgwt] if `years_13_17' & sex == `i'
	eststo no_oi_16_s`i' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_12_16' & sex == `i'
	eststo no_oi_17_s`i' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_13_17' & sex == `i'
	forvalues j = 1/4 {
		if `i' == 1 {
			eststo base_16_r`j' : reg logwage3 `basemodel' [aw=orgwt] if `years_12_16' & rc == `j'
			eststo base_17_r`j' : reg logwage3 `basemodel' [aw=orgwt] if `years_13_17' & rc == `j'
			eststo no_oi_16_r`j' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_12_16' & rc == `j'
			eststo no_oi_17_r`j' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_13_17' & rc == `j'
		}
		eststo base_16_s`i'_r`j' : reg logwage3 `basemodel' [aw=orgwt] if `years_12_16' & sex == `i' & rc == `j'
		eststo base_17_s`i'_r`j' : reg logwage3 `basemodel' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
		eststo no_oi_16_s`i'_r`j' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_12_16' & sex == `i' & rc == `j'
		eststo no_oi_17_s`i'_r`j' : reg logwage3 `model_no_occ_ind' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
	}
}

foreach group in s1 s2 r1 s1_r1 s2_r1 r2 s1_r2 s2_r2 r3 s1_r3 s2_r3 r4 s1_r4 s2_r4 {
	esttab base_16_`group' no_oi_16_`group' base_17_`group' no_oi_17_`group' using ${data}old_coding.csv, keep(myunion) varlabels(myunion "`group'") collabels(,none) plain noobs nomtitle cells(b) append
}

* create new variables to have coding more consistant with data library coding
/* Ed coding 1992-present, consistant with data library coding.
   Only changes some college group associate degree holders with some college
	 and no degree. */
gen dl_educ = .
replace dl_educ = 1 if ed<=38 /*dl_educ = 1 = less than high school*/
replace dl_educ = 2 if ed==39 /*dl_educ = 2 = high school*/
replace dl_educ = 3 if ed<=42 & ed>=40 /*dl_educ = 3 = some college*/
replace dl_educ = 4 if ed==43 /*dl_educ = 4 = college*/
replace dl_educ = 5 if ed>=44 & ed!=. /*dl_educ = 5 = advanced degree*/

*include pacific islanders?
/*
replace rc=4 if (race == 4 | race == 5) & hisp == 2
*/

*MODEL 2
*use new educ variable
local new_ed_model myunion i.dl_educ exp* i.div i.majind i.majocc i.year i.female i.rc i.nonus
local new_ed_no_oi myunion i.dl_educ exp* i.div i.year i.female i.rc i.nonus

* update with 2013-2017 data, new edu coding
eststo new_ed : reg logwage3 `new_ed_model' [aw=orgwt] if `years_13_17'

*no inds or occs
eststo new_ed_no_oi : reg logwage3 `new_ed_no_oi ' [aw=orgwt] if `years_13_17'

esttab new_ed new_ed_no_oi using ${data}new_ed.csv, keep(myunion) plain noobs cells(b) collabels(,none) replace

forvalues i = 1/2 {
	eststo new_ed_s`i' : reg logwage3 `new_ed_model' [aw=orgwt] if `years_13_17' & sex == `i'
	eststo new_ed_no_oi_s`i' : reg logwage3 `new_ed_no_oi' [aw=orgwt] if `years_13_17' & sex == `i'
	forvalues j = 1/4 {
		if `i' == 1 {
			eststo new_ed_r`j' : reg logwage3 `new_ed_model' [aw=orgwt] if `years_13_17' & rc == `j'
			eststo new_ed_no_oi_r`j' : reg logwage3 `new_ed_no_oi' [aw=orgwt] if `years_13_17' & rc == `j'
		}
		eststo new_ed_s`i'_r`j' : reg logwage3 `new_ed_model' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
		eststo new_ed_no_oi_s`i'_r`j' : reg logwage3 `new_ed_no_oi' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
	}
}

foreach group in s1 s2 r1 s1_r1 s2_r1 r2 s1_r2 s2_r2 r3 s1_r3 s2_r3 r4 s1_r4 s2_r4 {
	esttab new_ed_`group' new_ed_no_oi_`group' using ${data}new_ed.csv, keep(myunion) varlabels(myunion "`group'") collabels(,none) plain noobs nomtitle cells(b) append
}

* MODEL 3
local ed_age_model myunion i.dl_educ age age2 i.div i.majind i.majocc i.year i.female i.rc i.nonus
local ed_age_no_oi myunion i.dl_educ age age2 i.div i.year i.female i.rc i.nonus

* update with 2013-2017 data, new edu coding and using age instead of experience
eststo ed_age : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17'

*no inds or occs
eststo ed_age_no_oi : reg logwage3 `ed_age_no_oi ' [aw=orgwt] if `years_13_17'

esttab ed_age ed_age_no_oi using ${data}ed_age.csv, keep(myunion) plain cells(b) collabels(,none) noobs replace

forvalues i = 1/2 {
	eststo ed_age_s`i' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & sex == `i'
	eststo ed_age_no_oi_s`i' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & sex == `i'
	forvalues j = 1/4 {
		if `i' == 1 {
			eststo ed_age_r`j' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & rc == `j'
			eststo ed_age_no_oi_r`j' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & rc == `j'
		}
		eststo ed_age_s`i'_r`j' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
		eststo ed_age_no_oi_s`i'_r`j' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
	}
}

foreach group in s1 s2 r1 s1_r1 s2_r1 r2 s1_r2 s2_r2 r3 s1_r3 s2_r3 r4 s1_r4 s2_r4 {
	esttab ed_age_`group' ed_age_no_oi_`group' using ${data}ed_age.csv, keep(myunion) varlabels(myunion "`group'") collabels(,none) noobs plain nomtitle cells(b) append
}



preserve
keep if pub_sect == 1

* update with 2013-2017 data, new edu coding and using age instead of experience
eststo ed_age : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17'

*no inds or occs
eststo ed_age_no_oi : reg logwage3 `ed_age_no_oi ' [aw=orgwt] if `years_13_17'

esttab ed_age ed_age_no_oi using ${data}ed_age_public_sector.csv, keep(myunion) plain cells(b) collabels(,none) noobs replace

forvalues i = 1/2 {
	eststo ed_age_s`i' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & sex == `i'
	eststo ed_age_no_oi_s`i' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & sex == `i'
	forvalues j = 1/4 {
		if `i' == 1 {
			eststo ed_age_r`j' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & rc == `j'
			eststo ed_age_no_oi_r`j' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & rc == `j'
		}
		eststo ed_age_s`i'_r`j' : reg logwage3 `ed_age_model' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
		eststo ed_age_no_oi_s`i'_r`j' : reg logwage3 `ed_age_no_oi' [aw=orgwt] if `years_13_17' & sex == `i' & rc == `j'
	}
}

foreach group in s1 s2 r1 s1_r1 s2_r1 r2 s1_r2 s2_r2 r3 s1_r3 s2_r3 r4 s1_r4 s2_r4 {
	esttab ed_age_`group' ed_age_no_oi_`group' using ${data}ed_age_public_sector.csv, keep(myunion) varlabels(myunion "`group'") collabels(,none) noobs plain nomtitle cells(b) append
}
