version 18
set linesize 120
clear all
set more off

capture log close
log using log/20240113_cov_imc-icu_nbreg.log, text replace
set scheme s1mono

** program: 01/13/2014 Perform Negative Binomial Analysis of LPV Hours for COVID IMC-ICU Study
** author:  Chad Hochberg
**************************************************************************
** tasks
** #1 Load Data and Clean for Stata Analysis
** #2 Univariable Analysis
** #3 Multiviariabl Analysis
** #4 Model Checking

*****************************************
*** 1 Import the Data and Final Cleaning
*****************************************
*1.0 Use Dataset that Is Formated for Stata
use data/covid_imc_icu_nb.dta 

*1.1 Make Male Female a Factor Var
gen temp = 0 if gender == "Female"
replace temp = 1 if gender == "Male"
destring gender, replace force
replace gender = temp
label define lgender 0 "Female" 1 "Male"
label values gender lgender

*Split Time Period into 2 Reflecting 1st and Second Waves (March-September, October20-May 21)
gen covid_period=(study_month>7)
label def lperiod 0 "1st Wave" 1 "2nd Wave"
label val covid_period lperiod

*************************************
*** 2 NBReg
*************************************
**Univariable for Both STandard and Expanded Definitions
foreach x in lpv_nb lpv_nb_ex {
	nbreg `x' imc_icu, exposure(total_lpv_time) irr
}

**By Covid Period
foreach x in lpv_nb lpv_nb_ex {
	nbreg `x' imc_icu i.covid_period, exposure(total_lpv_time) irr
	nbreg `x' i.imc_icu#i.covid_period, exposure(total_lpv_time) irr 
	*Comparing Period 2 IMC vs Period 2 ICU
	lincom 2.imc_icu#1.covid_period-1b.imc_icu#1.covid_period, rr
	*Comparing Period 2 IMC to Period 1 IMCU
	lincom 2.imc_icu#1.covid_period-2.imc_icu#0.covid_period, rr
	nbreg `x' i.imc_icu##i.covid_period, exposure(total_lpv_time) irr
}

**Full Multivariable Model WITHOUT PERIOD
foreach x in lpv_nb lpv_nb_ex {
	nbreg `x' i.imc_icu age gender nonwhite height_cm weight_kg charlson nr_sofa_score pf_ratio_qualifying ///
	nmb_use compliance_baseline proned48, exposure(total_lpv_time) irr
}

**Full Multivariable Model WITH PERIOD
foreach x in lpv_nb lpv_nb_ex {
	nbreg `x' i.imc_icu#i.covid_period age gender nonwhite height_cm weight_kg charlson nr_sofa_score pf_ratio_qualifying ///
	nmb_use compliance_baseline proned48, exposure(total_lpv_time) irr
	*Comparing Period 2 IMC vs Period 2 ICU
	lincom 2.imc_icu#1.covid_period-1b.imc_icu#1.covid_period, rr
	*Comparing Period 2 IMC to Period 1 IMCU
	lincom 2.imc_icu#1.covid_period-2.imc_icu#0.covid_period, rr
}

**Get P for Interaction Term
foreach x in lpv_nb lpv_nb_ex {
	nbreg `x' i.imc_icu##i.covid_period age gender nonwhite height_cm weight_kg charlson nr_sofa_score pf_ratio_qualifying ///
	nmb_use compliance_baseline proned48, exposure(total_lpv_time) irr
}

