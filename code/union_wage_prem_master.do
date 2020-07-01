set more off
clear all

global orgdata /data/cps/org/epi/stata/
global base /home/zmokhiber/projects/union_wage_premium/
global cpi /home/zmokhiber/projects/cpi/output/
global code ${base}code/
global data ${base}data/

do ${code}clean_org_data.do
do ${code}analysis.do
