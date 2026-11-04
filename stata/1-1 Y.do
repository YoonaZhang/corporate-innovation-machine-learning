global Data "./data"
global Odata "./data/raw"

*------------------------------------------
* 研发投入
*------------------------------------------
cd "$Odata/公司研究/研发创新/国泰安/研发投入情况表101014368(仅供上海大学使用)"
import excel "PT_LCRDSPENDING.xlsx", firstrow clear
keep if regexm(EndDate,"-12-31")
keep Symbol EndDate StateTypeCode RDSpendSum
gen year = substr(EndDate,1,4)
drop EndDate
rename Symbol stock
destring _all, replace
keep if StateTypeCode==1
drop if year<2012|year>2023
drop StateTypeCode
cd "$Data"
save "研发投入.dta", replace

cd "$Data"
use "基础变量.dta", clear
merge 1:1 stock year using "研发投入.dta"
drop _merge
gen RDCost=RDSpendSum/TotalRevenue
duplicates drop stock year, force
drop RDSpendSum

*使用t+1期研发投入情况
sort stock year
by stock: gen RDCost_t1 = RDCost[_n+1]
label var RDCost_t1 "t+1期的研发投入/销售额"
drop RDCost
save "基础变量.dta", replace

*单独合并2024年数据
cd "$Odata/公司研究/研发创新/国泰安/研发投入2024"
import excel "PT_LCRDSPENDING.xlsx", firstrow clear
keep if regexm(EndDate,"-12-31")
keep Symbol EndDate StateTypeCode RDSpendSum
gen year = substr(EndDate,1,4)
drop EndDate
rename Symbol stock
destring _all, replace
keep if StateTypeCode==1
drop StateTypeCode
cd "$Data"
save "研发投入2024.dta", replace
merge 1:1 stock year using "03_利润表2024.dta"
drop _merge
gen RDCost2023=RDSpendSum/TotalRevenue
duplicates drop stock year, force
drop RDSpendSum TotalRevenue
replace year=2023
save "研发投入2024.dta", replace

cd "$Data"
use "基础变量.dta", clear
merge 1:1 stock year using "研发投入2024.dta", keep(match master)
drop _merge
replace RDCost_t1=RDCost2023 if year==2023
drop RDCost2023
save "基础变量.dta", replace
*------------------------------------------
* 三类专利数量 & 发明专利数量
*------------------------------------------
cd "$Odata/公司研究/研发创新/专利"
import excel "上市公司专利申请情况.xlsx", firstrow clear
labone, nrow(1)
drop in 1
rename (Scode Year) (stock year)
keep if Ftyp == "上市公司本身" | Ftyp == "子公司"
destring _all, replace
collapse (sum) Invia Umia Desia Invja Umja Desja, by(stock year)

gen InvPatent = Invia + Invja
gen Sumia = Invia + Umia + Desia
gen Sumja = Invja + Umja + Desja
gen SumPatent = Sumia + Sumja
foreach var of varlist Invia Invja InvPatent Sumia Sumja SumPatent {
    replace `var' = ln(`var' + 1)
}
keep stock year Invia Invja InvPatent Sumia Sumja SumPatent
sort stock year
cd "$Data"
save "专利数量.dta", replace

*使用t+1期专利数量情况
by stock: gen Invia_t1 = Invia[_n+1]
by stock: gen Invja_t1 = Invja[_n+1]
by stock: gen InvPatent_t1 = InvPatent[_n+1]
by stock: gen Sumia_t1 = Sumia[_n+1]
by stock: gen Sumja_t1 = Sumja[_n+1]
by stock: gen SumPatent_t1 = SumPatent[_n+1]
label var Invia_t1 "t+1期的ln(上市公司和子公司，独立申请的发明专利数量+1)"
label var Invja_t1 "t+1期的ln(上市公司和子公司，联合申请的发明专利数量+1)"
label var InvPatent_t1 "t+1期的ln(上市公司和子公司，申请的发明专利总数+1)"
label var Sumia_t1 "t+1期的ln(上市公司和子公司，独立申请的三类专利总数+1)"
label var Sumja_t1 "t+1期的ln(上市公司和子公司，联合申请的三类专利总数+1)"
label var SumPatent_t1 "t+1期的ln(上市公司和子公司，申请的三类专利总数+1)"
drop Invia Invja InvPatent Sumia Sumja SumPatent
keep if year>=2012 & year<=2023
save "专利数量.dta", replace

cd "$Data"
use "基础变量.dta", clear
merge 1:1 stock year using "专利数量.dta"
drop _merge

save "基础变量.dta", replace
