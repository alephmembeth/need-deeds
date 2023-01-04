cd "/Users/amb/Desktop/GitHub/need-deeds/analysis"


/* header */
version 14.2

set more off, permanently
set scheme s2mono


/* reshape long */
use "need_deeds_wide.dta", clear

reshape long ///
   allocation_a_low_under_ need_a_low_under_ allocation_b_low_under_ need_b_low_under_ ///
   allocation_a_low_over_ need_a_low_over_ allocation_b_low_over_ need_b_low_over_ ///
   allocation_a_high_under_ need_a_high_under_ allocation_b_high_under_ need_b_high_under_ ///
   allocation_a_high_over_ need_a_high_over_ allocation_b_high_over_ need_b_high_over_ ///
   productivity_a_high_over_ productivity_b_high_over_ ///
   productivity_a_high_under_ productivity_b_high_under_ ///
   productivity_a_low_over_ productivity_b_low_over_ ///
   productivity_a_low_under_ productivity_b_low_under_ ///
   , i(id) j(case)

rename *_ *

reshape long ///
   allocation_a_low_ need_a_low_ allocation_a_high_ need_a_high_ ///
   allocation_b_low_ need_b_low_ allocation_b_high_ need_b_high_ ///
   productivity_a_low_ productivity_a_high_ ///
   productivity_b_low_ productivity_b_high_ ///
   , i(id case) j(supply_situation) string

rename *_ *

replace supply_situation = "Undersupply" if supply_situation == "under"
replace supply_situation = "Oversupply" if supply_situation == "over"

reshape long ///
   allocation_a_ need_a_ productivity_a_ allocation_b_ need_b_ productivity_b_ ///
   , i(id case supply_situation) j(accountability) string

rename *_ *

label variable case           "Case Number"
label variable allocation_a   "Allocation to A"
label variable allocation_b   "Allocation to B"
label variable need_a         "Need of A"
label variable need_b         "Need of B"
label variable productivity_a "Productivity of A"
label variable productivity_b "Productivity of B"

replace accountability = "High Accountability" if accountability == "high"
replace accountability = "Low Accountability" if accountability == "low"

gen need_share_a = need_a / (need_a + need_b)
   label variable need_share_a "Need Share of A"

gen share_a = allocation_a / 1000
   label variable share_a "Share of A"

encode supply_situation, gen(supply)
   drop supply_situation
   ren supply supply_situation
   label variable supply_situation "Supply Situation"

encode accountability, gen(frame)
   drop accountability
   ren frame accountability
   label variable accountability "Accountability"

label variable treatment "Kind of Need"

replace case = case + 5 if supply_situation == 2
replace case = case + 10 if accountability == 2

save "need_deeds_long.dta", replace
export delimited "need_deeds_long.csv", replace


/* quality fails */
use "need_deeds_wide.dta", clear

drop if dropout == 1 | quota_full == 1 | screenout == 1

preserve
   encode checker_justice, generate(justice)

   gen justice_done = .
      replace justice_done = 1 if justice != .

   keep if justice_done == 1

   gen justice_pass = .
      replace justice_pass = 1 if justice == 6
      replace justice_pass = 2 if justice != 6

   tab justice_pass
restore

gen purpose_pass = .
   replace purpose_pass = 1 if checker_winter == 1
   replace purpose_pass = 2 if checker_house == 1
   replace purpose_pass = 2 if checker_drinking == 1
   replace purpose_pass = 2 if checker_mill == 1
   replace purpose_pass = 2 if checker_wheat == 1
   replace purpose_pass = 2 if checker_rye == 1
   replace purpose_pass = 2 if checker_sunflowers == 1

tab purpose_pass

gen number_pass = .
   replace number_pass = 1 if checker_needs == 1800
   replace number_pass = 2 if checker_needs == 500
   replace number_pass = 2 if checker_needs == 1000
   replace number_pass = 2 if checker_needs == 1200
   replace number_pass = 2 if checker_needs == 1500
   replace number_pass = 2 if checker_needs == 3000
   replace number_pass = 2 if checker_needs == 5000

tab number_pass

tab number_of_quality_fails

tab gender quality_fail, chi

gen age_quota = .
   replace age_quota = 1 if age >= 18 & age < 30
   replace age_quota = 2 if age >= 30 & age < 40
   replace age_quota = 3 if age >= 40 & age < 50
   replace age_quota = 4 if age >= 50 & age < 60
   replace age_quota = 5 if age >= 60 & age < 75

label define age_quota_lb 1 "18 – 29" 2 "30 – 39" 3 "40 – 49" 4 "50 – 59" 5 "60 – 74"
   label values age_quota age_quota_lb

tab age_quota quality_fail, chi

gen income_quota = .
   replace income_quota = 1 if household_net_income >= 0    & household_net_income < 1500
   replace income_quota = 2 if household_net_income >= 1500 & household_net_income < 2500
   replace income_quota = 3 if household_net_income >= 2500 & household_net_income < 3500
   replace income_quota = 4 if household_net_income >= 3500 & household_net_income < 4500
   replace income_quota = 5 if household_net_income >= 4500

label define income_quota_lb 1 "0 – 1500" 2 "1500 – 2500" 3 "2500 – 3500" 4 "3500 – 4500" 5 "> 4500"
   label values income_quota income_quota_lb

tab income_quota quality_fail, chi


/* figure 1 */
use "need_deeds_long.dta", clear

label define treatment_lb 1 "Survival" 2 "Decency" 3 "Belonging" 4 "Autonomy"
   label value treatment treatment_lb

keep if complete == 1

cibar share_a, over(treatment) ///
   graphopts( ///
      ytitle("Mean of Share Allocated to Person A") ///
      ylabel(.45(.05).75) ///
      graphregion(fcolor(white)) ///
   )
   graph export "figure_1.pdf", as(pdf) replace


/* test actual share versus equal share */
forval treatment = 1/4 {
   preserve
      keep if treatment == `treatment'
      ttest share_a == .5
   restore
}


/* figure 2 */
replace case = case - 10 if accountability == 2
replace case = case - 5 if supply_situation == 2

cibar share_a, over(case supply_situation accountability) ///
   graphopts( ///
      ytitle("Mean of Share Allocated to Person A") ///
      ylabel(.45(.05).75) ///
      graphregion(fcolor(white)) ///
   )
   graph export "figure_2.pdf", as(pdf) replace


/* figure 3 */
cibar share_a, over(supply_situation treatment) ///
   graphopts( ///
      ytitle("Mean of Share Allocated to Person A") ///
      ylabel(.45(.05).75) ///
      graphregion(fcolor(white)) ///
   )
   graph export "figure_3.pdf", as(pdf) replace


/* test supply scenario */
use "need_deeds_wide.dta", clear

keep if complete == 1

reshape long ///
   allocation_a_low_under_ need_a_low_under_ allocation_b_low_under_ need_b_low_under_ ///
   allocation_a_low_over_ need_a_low_over_ allocation_b_low_over_ need_b_low_over_ ///
   allocation_a_high_under_ need_a_high_under_ allocation_b_high_under_ need_b_high_under_ ///
   allocation_a_high_over_ need_a_high_over_ allocation_b_high_over_ need_b_high_over_ ///
   productivity_a_high_over_ productivity_b_high_over_ ///
   productivity_a_high_under_ productivity_b_high_under_ ///
   productivity_a_low_over_ productivity_b_low_over_ ///
   productivity_a_low_under_ productivity_b_low_under_ ///
   , i(id) j(case)

rename *_ *

rename *low_under  *under_low
rename *high_under *under_high
rename *low_over   *over_low
rename *high_over  *over_high

reshape long ///
   allocation_a_under_ need_a_under_ allocation_a_over_ need_a_over_ ///
   allocation_b_under_ need_b_under_ allocation_b_over_ need_b_over_ ///
   productivity_a_under_ productivity_a_over_ ///
   productivity_b_under_ productivity_b_over_ ///
   , i(id case) j(accountability) string

rename *_ *

replace case = case + 5 if accountability == "high"

generate share_a_under = allocation_a_under / 1000
generate share_a_over = allocation_a_over / 1000

forval treatment = 1/4 {
   di "Treatment `treatment'"
   ttest share_a_over == share_a_under if treatment == `treatment'
}

preserve
   keep if accountability == "low"

   forval treatment = 1/4 {
   di "Treatment `treatment'"
   ttest share_a_over == share_a_under if treatment == `treatment'
   }
restore

preserve
   keep if accountability == "high"

   forval treatment = 1/4 {
   di "Treatment `treatment'"
   ttest share_a_over == share_a_under if treatment == `treatment'
   }
restore


/* figure 4 */
use "need_deeds_long.dta", clear

keep if complete == 1

cibar share_a, over(accountability treatment) ///
   graphopts( ///
      ytitle("Mean of Share Allocated to Person A") ///
      ylabel(.45(.05).75) ///
      graphregion(fcolor(white)) ///
   )
   graph export "figure_4.pdf", as(pdf) replace


/* test accountability */
use "need_deeds_wide.dta", clear

keep if complete == 1

reshape long ///
   allocation_a_low_under_ need_a_low_under_ allocation_b_low_under_ need_b_low_under_ ///
   allocation_a_low_over_ need_a_low_over_ allocation_b_low_over_ need_b_low_over_ ///
   allocation_a_high_under_ need_a_high_under_ allocation_b_high_under_ need_b_high_under_ ///
   allocation_a_high_over_ need_a_high_over_ allocation_b_high_over_ need_b_high_over_ ///
   productivity_a_high_over_ productivity_b_high_over_ ///
   productivity_a_high_under_ productivity_b_high_under_ ///
   productivity_a_low_over_ productivity_b_low_over_ ///
   productivity_a_low_under_ productivity_b_low_under_ ///
   , i(id) j(case)

rename *_ *

reshape long ///
   allocation_a_low_ need_a_low_ allocation_a_high_ need_a_high_ ///
   allocation_b_low_ need_b_low_ allocation_b_high_ need_b_high_ ///
   productivity_a_low_ productivity_a_high_ ///
   productivity_b_low_ productivity_b_high_ ///
   , i(id case) j(supply_situation) string

rename *_ *

replace case = case + 5 if supply_situation == "over"

generate share_a_low = allocation_a_low / 1000
generate share_a_high = allocation_a_high / 1000

forvalues treatment = 1/4 {
   di "Treatment `treatment'"
   ttest share_a_low == share_a_high if treatment == `treatment'
}

preserve
   keep if case > 5

   forvalues treatment = 1/4 {
      di "Treatment `treatment' (Undersupply)"
      ttest share_a_low == share_a_high if treatment == `treatment'
   }
restore

preserve
   keep if case < 6

   forvalues treatment = 1/4 {
      di "Treatment `treatment' (Oversupply)"
      ttest share_a_low == share_a_high if treatment == `treatment'
   }
restore

use "need_deeds_long.dta", clear

keep if complete == 1
keep if accountability == 1

forval i = 1/4 {
   preserve
      keep if treatment == `i'
      ttest share_a == .5
   restore
}


/* test kind of need */
use "need_deeds_long.dta", clear

keep if complete == 1

xtmixed share_a ib1.treatment || id:, vce(robust) level(90)
   est sto model_1
   estat ic
   mltrsq

xtmixed share_a ib1.treatment need_share_a i1.accountability i1.supply_situation || id:, vce(robust) level(90)
   est sto model_2
   estat ic
   mltrsq

xtmixed share_a ib1.treatment need_share_a i1.accountability i1.supply_situation ///
   age gender household_net_income criteria_need criteria_productivity criteria_equality || ///
   id:, vce(robust) level(90)
   est sto model_3
   estat ic
   mltrsq

xtmixed share_a ib1.treatment##i1.accountability ib1.treatment##i1.supply_situation ///
   need_share_a age gender household_net_income criteria_need criteria_productivity criteria_equality || ///
   id:, vce(robust) level(90)
   est sto model_4
   estat ic
   mltrsq


/* test effect of interaction terms */
xtmixed share_a ib1.treatment i1.accountability || id:, vce(robust) level(90)
   est sto model_5
   estat ic
   mltrsq

xtmixed share_a ib1.treatment##i1.accountability || id:, vce(robust) level(90)
   est sto model_6
   estat ic
   mltrsq

lrtest model_5 model_6, force

xtmixed share_a ib1.treatment i1.supply_situation || id:, vce(robust) level(90)
   est sto model_7
   estat ic
   mltrsq

xtmixed share_a ib1.treatment##i1.supply_situation || id:, vce(robust) level(90)
   est sto model_8
   estat ic
   mltrsq

lrtest model_7 model_8, force


/* figure 5 */
use "need_deeds_wide.dta", clear

keep if complete == 1

drop if need_type_survival == .
drop if need_type_decency == .
drop if need_type_belonging == .
drop if need_type_autonomy == .

ren need_type_survival eval1
ren need_type_decency eval2
ren need_type_belonging eval3
ren need_type_autonomy eval4

reshape long eval, i(id) j(kindofneed)

label define kindofneed_lb 1 "Survival" 2 "Decency" 3 "Belonging" 4 "Autonomy"
   label value kindofneed kindofneed_lb

cibar eval, over(kindofneed) ///
   graphopts( ///
      ytitle("Mean of Ascribed Importance") ///
      graphregion(fcolor(white)) ///
   )
   graph export "figure_5.pdf", as(pdf) replace


/* test evaluations */
oneway eval kindofneed, bonferroni tabulate


exit
