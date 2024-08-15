*** clear memory
clear all

*** Maximum number of variables
set maxvar 6000

*************************************************** Task 1  ************************************************************************

*************** Step 1 : Data Preparation

***** 1. Download ANC4 and SAB data from UNCICEF Global Data repository

***** 2. Import the downloaded file in Stata
import excel "https://bit.ly/4dLIhWg", sheet("Unicef data") firstrow clear

***** 3. Cleaning the imported dataset

*** 3.1. delete empty rows 
egen missrow= rowmiss(_all) //create a new variable that count the number of missing column in the row
drop if missrow==c(k)-1 //c(k) give the total number of variables, -1 because the new variable missrow shouldn't be consider
drop missrow // delete the variable no more needed

keep Geographicarea Indicator TIME_PERIOD OBS_VALUE //keep only the variables we need

*** 3.2. Create two variables ANC4 and SAB from OBS_VALUE
gen ANC4=OBS_VALUE if Indicator=="Antenatal care 4+ visits - percentage of women (aged 15-49 years) attended at least four times during pregnancy by any provider"
label variable ANC4 "Antenatal care 4+ visits (ANC4)"
gen SAB=OBS_VALUE if Indicator=="Skilled birth attendant - percentage of deliveries attended by skilled health personnel"
label var SAB "Skilled birth attendant (SAB)"

destring ANC4 SAB, replace

*** 3.3. create SAB dataset
preserve
keep if SAB!=.
keep Geographicarea TIME_PERIOD SAB
duplicates list Geographicarea TIME_PERIOD
duplicates drop Geographicarea TIME_PERIOD, force

sort Geographicarea TIME_PERIOD
by Geographicarea (TIME_PERIOD), sort: gen most_recent = _n == _N

keep if most_recent==1
drop most_recent

rename TIME_PERIOD SAB_PERIOD
label var SAB_PERIOD "Most recent SAB coverage period"

sort Geographicarea

save sab_dataset.dta, replace
restore

*** 3.4. create ANC4 dataset
keep if ANC4!=.
keep Geographicarea TIME_PERIOD ANC4
duplicates list Geographicarea TIME_PERIOD
duplicates drop Geographicarea TIME_PERIOD, force

sort Geographicarea TIME_PERIOD
by Geographicarea (TIME_PERIOD), sort: gen most_recent = _n == _N

keep if most_recent==1
drop most_recent

rename TIME_PERIOD ANC_PERIOD
label var ANC_PERIOD "Most recent ANC4 coverage period"

sort Geographicarea

save anc4_dataset.dta, replace

*** 3.5. Merging ANC4 and SAB datatset
merge 1:1 Geographicarea using sab_dataset.dta
drop _merge

sort Geographicarea

save anc4_sab_dataset.dta, replace

***** 4. Import the on-track and off-track dataset
import excel "https://bit.ly/46QEtALed", sheet("Sheet1") firstrow clear


***** 5. Cleaning on-track and off-track dataset

*** 5.1. rename the country identification variable 
rename OfficialName Geographicarea

sort Geographicarea

*** 5.2. Creation of on-track and off-track variable 
encode StatusU5MR, gen(Status)
drop StatusU5MR
replace Status=2 if Status==3
label define statut 1 "off-track" 2 "on-track"
label val Status statut

***** 6. Merging on-track and off-track dataset with ANC4 and SAB dataset
merge 1:1 Geographicarea using anc4_sab_dataset.dta

drop if _merge==2
drop _merge

sort ISO3Code

save anc4_sab_ontrack_dataset.dta, replace

***** 7. Import the demographics dataset
import excel "https://bit.ly/46MyJYS", ///
sheet("Projections") cellrange(A17:BM22615) firstrow clear //import projections sheet

replace Birthsthousands="" if Birthsthousands=="..."
destring Birthsthousands, replace

save demographic_projections.dta, replace

***** 8. Cleaning demographic_projections dataset

*** 8.1. Keep only 2022 projections 
keep if Year==2022

*** 8.2. rename the ID variable (same as on-track, off-track, ANC4 and SAB dataset)
rename ISO3Alphacode ISO3Code

*** 8.3. drop missing values in the ID variable
drop if ISO3Code==""

sort ISO3Code

*** 8.4. save the dataset with 2022 data projections
save demographic_projections_2022.dta, replace


***** 9. Merging of 2022 demographic projections dataset with on-track, off-track, ANC4 and SAB dataset
merge 1:1 ISO3Code using anc4_sab_ontrack_dataset.dta

keep ISO3Code Regionsubregioncountryorar Geographicarea Birthsthousands Status ANC_PERIOD ANC4 SAB_PERIOD SAB 

save final_dataset.dta, replace


*************** Step 2 : Calculate weighted averages for on-track and off-track countries

***** 1. Calculate of ANC4 weighted coverage for on-track countries
egen Births_total1=total(Birthsthousands) if ANC4!=. & Status==2
gen ANC4_w1=(ANC4 * Birthsthousands)/Births_total1
egen ANC4_w_on=total(ANC4_w1)

***** 2. Calculate of ANC4 weighted coverage for off-track countries
egen Births_total2=total(Birthsthousands) if ANC4!=. & Status==1
gen ANC4_w2=(ANC4 * Birthsthousands)/Births_total2
egen ANC4_w_off=total(ANC4_w2)

***** 3. Creating a ANC4 weighted coverage variables
gen ANC4_weighted=ANC4_w_on if ANC4!=. & Status==2
replace ANC4_weighted=ANC4_w_off if ANC4!=. & Status==1

***** 4. Calculate of SAB weighted coverage for on-track countries
egen Births_total3=total(Birthsthousands) if SAB!=. & Status==2
gen SAB_w1=(SAB * Birthsthousands)/Births_total3
egen SAB_w_on=total(SAB_w1)

***** 5. Calculate of SAB weighted coverage for off-track countries
egen Births_total4=total(Birthsthousands) if SAB!=. & Status==1
gen SAB_w2=(SAB * Birthsthousands)/Births_total4
egen SAB_w_off=total(SAB_w2)

***** 6. Creating a SAB weighted coverage variables
gen SAB_weighted=SAB_w_on if SAB!=. & Status==2
replace SAB_weighted=SAB_w_off if SAB!=. & Status==1

***** 7. Visualization
preserve
collapse (mean) ANC4_weighted, by(Status)
graph bar ANC4_weighted, over(Status) ///
    bar(1, color(blue)) ///
	blabel(bar, format(%9.1f)) ///
    title("Antenatal care 4+ visits-Weighted Coverage by Country Status") ///
    ytitle("Antenatal care 4+ visits-Weighted Coverage (%)")
graph export "ANC4_weighted_coverage.png", as(png) replace
restore

preserve
collapse (mean) SAB_weighted, by(Status)
graph bar SAB_weighted, over(Status) ///
    bar(1, color(blue)) ///
	blabel(bar, format(%9.1f)) ///
    title("Skilled birth attendant-Weighted Coverage by Country Status") ///
    ytitle("Skilled birth attendant-Weighted Coverage (%)")
graph export "SAB_weighted_coverage.png", as(png) replace
restore

