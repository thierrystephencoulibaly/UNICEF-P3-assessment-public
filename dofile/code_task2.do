*** clear memory
clear all

*** Maximum number of variables
set maxvar 6000

*** Working directory
cd "C:\Users\ROG ZEPHYRUS\OneDrive\Bureau\UNICEF-P3-assessment-public\results"

*************************************************** Task 2  ************************************************************************

*************** Step 1 : Data preparation

***** 1. Import the zimbabwe MICS dataset
import delimited "C:\Users\ROG ZEPHYRUS\OneDrive\Bureau\UNICEF-P3-assessment-public\01_rawdata\Zimbabwe_children_under5_interview.csv"

***** 2. Explore the variables
codebook
describe
*br if ec6==9

***** 3. Variable and values label
label define yesno 1 "Yes" 2 "No" 8 "DK"
label values ec6-ec15 yesno

***** 4. delete observations
drop if ec6==9

***** 5. literacy-numeracy
*Note : Literacy-numeracy: Children are identified as being developmentally on track based on whether they can identify/name at
*least ten letters of the alphabet, whether they can read at least four simple, popular words, and whether they know the name and
*recognize the symbols of all numbers from 1 to 10. If at least two of these are true, then the child is considered developmentally on track.
gen ec6_bis=ec6
replace ec6_bis=0 if ec6_bis!=1

gen ec7_bis=ec7
replace ec7_bis=0 if ec7_bis!=1

gen ec8_bis=ec8
replace ec8_bis=0 if ec8_bis!=1

egen nb_lit=rsum(ec6_bis ec7_bis ec8_bis)

gen literacy=1 if nb_lit==2 | nb_lit==3
replace literacy=0 if nb_lit==0 | nb_lit==1
*label values literacy yesno

drop ec6_bis ec7_bis ec8_bis nb_lit

***** 6. Physical
*Note : Physical: If the child can pick up a small object with two fingers, like a stick or a rock from the ground
*and/or the mother/caretaker does not indicate that the child is sometimes too sick to play, then the
*child is regarded as being developmentally on track in the physical domain.
gen ec9_bis=ec9
replace ec9_bis=0 if ec9_bis!=1

gen ec10_bis=ec10
replace ec10_bis=0 if ec10_bis!=1

egen nb_phy=rsum(ec9_bis ec10_bis)

gen physical=1 if nb_phy==1 | nb_phy==2
replace physical=0 if nb_phy==0
*label values physical yesno

drop ec9_bis ec10_bis nb_phy

***** 7. Learning
*Note : Learning: If the child follows simple directions on how to do something correctly and/or when given
*something to do, is able to do it independently, then the child is considered to be developmentally on
*track in this domain.
gen ec11_bis=ec11
replace ec11_bis=0 if ec11_bis!=1

gen ec12_bis=ec12
replace ec12_bis=0 if ec12_bis!=1

egen nb_learn=rsum(ec11_bis ec12_bis)

gen learning=1 if nb_learn==1 | nb_learn==2
replace learning=0 if nb_learn==0
*label values learning yesno

drop ec11_bis ec12_bis nb_learn

***** 8. Socio-emotional
*Note : Social-emotional: Children are considered to be developmentally on track if two of the following are
*true: If the child gets along well with other children, if the child does not kick, bite, or hit other children
*and if the child does not get distracted easily.
gen ec13_bis=ec13
replace ec13_bis=0 if ec13_bis!=1

gen ec14_bis=ec14
replace ec14_bis=0 if ec14_bis!=1

gen ec15_bis=ec15
replace ec15_bis=0 if ec15_bis!=1

egen nb_soc=rsum(ec13_bis ec14_bis ec15_bis)

gen socio=1 if nb_soc==2 | nb_soc==3
replace socio=0 if nb_soc==0 | nb_soc==1
*label values socio yesno

drop ec13_bis ec14_bis ec15_bis nb_soc

***** 9. Early child development index ECDI
*Note : ECDI is the percentage of children who are developmentally on track in at least three of these four domains.
egen nb=rsum(literacy physical learning socio)

gen ecdi=1 if nb==3 | nb==4
replace ecdi=0 if nb==0 | nb==1 | nb==2
*label values ecdi yesno

drop nb

***** 10. Defining new variables values label
label define yes_no 1 "Yes" 0 "No"
label values literacy physical learning socio ecdi yes_no


*************** Step 2 : Data analysis

***** 1. Tabulations
tab literacy
tab physical
tab learning
tab socio
tab ecdi


***** 2. Graphs
tab literacy, gen(lit)
graph pie lit1 lit2, ///
    plabel(_all percent) ///
    title("Literacy Distribution for Children Aged 3 or 4") ///
    legend(label(2 "Literate") label(1 "Not Literate"))
graph export "literacy-numeracy.png", as(png) replace

graph bar (percent), ///
    over(ecdi, ///
    label(labsize(medium))) ///
	blabel(bar, format(%9.1f)) ///
    title("ECDI Status for Children Aged 3 or 4") ///
    legend(label(1 "Good ECDI") label(0 "Poor ECDI"))
graph export "ecdi.png", as(png) replace

