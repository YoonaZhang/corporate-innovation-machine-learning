global Data "./data"
global Odata "./data/raw"

*------------------------------------------
* 上市公司基本信息
*------------------------------------------
cd "$Odata/公司研究/基本信息/上市公司基本信息年度表102120374(仅供沪江大学使用)"
import excel "STK_LISTEDCOINFOANL.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2

keep Symbol EndDate IndustryName IndustryCode Lng Lat EstablishDate LISTINGDATE PROVINCECODE PROVINCE CITYCODE CITY

gen year = substr(EndDate,1,4)
destring _all, replace
duplicates drop Symbol year, force
drop EndDate

rename Symbol stock

cd "$Data"
save "01_上市公司基本信息.dta", replace

cd "$Odata/行业层面"
import excel "申万行业分类_包含历史_2007_2024_Wind.xlsx", firstrow clear
drop in 1
gen str6 code_str = substr(证券代码, 1, 6)
destring code_str, generate(stock) force
drop code_str
reshape long swind, i(stock) j(year)
drop if missing(swind) | swind == "------"
* 提取申万一级行业
split swind, parse("--") generate(ind_split)
rename ind_split1 IndustryCode_sw
drop ind_split*
keep stock year IndustryCode_sw
keep if year>=2012 & year<=2023
cd "$Data"
save "申万行业分类.dta", replace

*------------------------------------------
* 资产负债表（年度数据）
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务报表/资产负债表103955243(仅供沪江大学使用)"
import excel "FS_Combas.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper A001000000 A002203000 A002101000 A002201000

gen year = substr(Accper,1,4)
rename (Stkcd A001000000 A002203000 A002101000 A002201000) (stock TotalAssets BondsPayable ShortLoan LongLoan)
destring _all, replace
drop Accper

cd "$Data"
save "02_资产负债表.dta", replace

*------------------------------------------
* 利润表（年度数据）
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务报表/利润表103617603(仅供沪江大学使用)"
import excel "FS_Comins.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper B001100000 B001101000 B001000000 B002100000

gen year = substr(Accper,1,4)
rename (Stkcd B001100000 B001101000 B001000000 B002100000) (stock TotalRevenue OperatingRevenue TotalProfit IncomeTax)
destring _all, replace
drop Accper

cd "$Data"
save "03_利润表.dta", replace

cd "$Odata/公司研究/财务数据/财务报表/利润表2024"
import excel "FS_Comins.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper B001100000

gen year = substr(Accper,1,4)
rename (Stkcd B001100000) (stock TotalRevenue)
destring _all, replace
drop Accper

cd "$Data"
save "03_利润表2024.dta", replace

*------------------------------------------
* 现金流量表（年度数据）
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务报表/现金流量表(直接法)103819337(仅供沪江大学使用)"
import excel "FS_Comscfd.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper C001014000 C001021000 C001012000 C001020000

gen year = substr(Accper,1,4)
rename (Stkcd C001014000 C001021000 C001012000 C001020000) (stock PurchasePayment TaxPayment TaxRefund SalaryPayment)
destring _all, replace
replace TaxRefund=0 if !missing(TaxPayment) & missing(TaxRefund)
xtset stock year
bysort stock: gen LSalaryPayment = L.SalaryPayment
drop Accper

cd "$Data"
save "04_现金流量表.dta", replace

**由于后面有变量需要前一年为员工支付的薪酬总额，故在此单独合并2011年为员工支付的薪酬总额情况
cd "$Odata/公司研究/财务数据/财务报表/现金流量表(直接法)103819337(仅供沪江大学使用)"
import excel "FS_Comscfd2011.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper C001020000

gen year = 2012
rename (Stkcd C001020000) (stock LSalaryPayment2012)
destring _all, replace
drop Accper

cd "$Data"
save "04_现金流量表2.dta", replace

*------------------------------------------
* 偿债能力表
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务指标分析/偿债能力105114323(仅供沪江大学使用)"
import excel "FI_T1.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper F011201A

gen year = substr(Accper,1,4)
rename (Stkcd F011201A) (stock DebtRatio)
destring _all, replace
drop Accper

cd "$Data"
save "05_偿债能力表.dta", replace

*------------------------------------------
* 比率结构表
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务指标分析/比率结构105159041(仅供沪江大学使用)"
import excel "FI_T3.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper F030201A F030801A

gen year = substr(Accper,1,4)
rename (Stkcd F030201A F030801A) (stock Cashflow FixedAssetRatio)
destring _all, replace
drop Accper

cd "$Data"
save "06_比率结构表.dta", replace

*------------------------------------------
* 盈利能力表
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务指标分析/盈利能力105429681(仅供沪江大学使用)"
import excel "FI_T5.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper F050201B F050202B F050203B F051401B F051501B

gen year = substr(Accper,1,4)
rename (Stkcd F050201B F050202B F050203B F051401B F051501B) (stock ROA1 ROA2 ROA3 ProfitMargin1 ProfitMargin2) 
destring _all, replace
drop Accper

cd "$Data"
save "07_盈利能力表.dta", replace

*------------------------------------------
* 发展能力表
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务指标分析/发展能力110954618(仅供沪江大学使用)"
import excel "FI_T8.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31") & Typrep == "A"
keep Stkcd Accper F081601B F081602C

gen year = substr(Accper,1,4)
rename (Stkcd F081601B F081602C) (stock Growth1 Growth2)
destring _all, replace
drop Accper

cd "$Data"
save "08_发展能力表.dta", replace

*------------------------------------------
* 相对价值指标表
*------------------------------------------
cd "$Odata/公司研究/财务数据/财务指标分析/相对价值指标111010091(仅供沪江大学使用)"
import excel "FI_T10.xlsx", firstrow clear
labone, nrow(1)

keep if regexm(Accper,"-12-31")
keep Stkcd Accper F100801A F100802A

gen year = substr(Accper,1,4)
rename (Stkcd F100801A F100802A) (stock 市值A 市值B)
destring _all, replace
drop Accper

cd "$Data"
save "09_相对价值指标表.dta", replace

*------------------------------------------
* 治理能力表
*------------------------------------------
cd "$Odata/公司研究/财务数据/经营困境/管理层治理能力153750919(仅供耶鲁大学使用)"
import excel "BDT_ManaGovAbil.xlsx", firstrow clear
labone, nrow(1)

keep Symbol Enddate Boardsize IndDirectorRatio InsInvestorProp
drop in 1/2

gen year = substr(Enddate,1,4)
rename (Symbol InsInvestorProp) (stock InvestorShare)
destring _all, replace
drop Enddate
duplicates drop stock year, force

cd "$Data"
save "10_治理能力表.dta", replace

*------------------------------------------
* 融资约束表
*------------------------------------------
cd "$Odata/公司研究/财务数据/经营困境/融资约束/FC"
import excel "BDT_FinConstFC.xlsx", firstrow clear
drop in 1

    destring STPT, replace
    destring IsNewOrSuspend, replace
    destring ISBSE, replace

keep if STPT == 1 & IsNewOrSuspend == 1 & ISBSE == 1
keep Symbol Enddate FC

gen year = substr(Enddate,1,4)
rename Symbol stock
duplicates drop stock year, force
destring _all, replace
drop Enddate

label var FC "融资约束指数"

cd "$Data"
save "11_融资约束表.dta", replace

*------------------------------------------
* 高管薪酬表
*------------------------------------------
cd "$Odata/公司研究/股权与治理/治理结构/高管人数、持股及薪酬情况表154622330(仅供沪江大学使用)"
import excel "CG_ManagerShareSalary.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2

destring StatisticalCaliber, replace
keep if StatisticalCaliber == 1
keep Symbol Enddate DirectorNumber FemaleDirectorNumber Top3ManageSumSalary ManageSumSalary

gen year = substr(Enddate,1,4)
rename Symbol stock
drop Enddate
duplicates drop stock year, force
destring _all, replace

cd "$Data"
save "12_高管薪酬表.dta", replace

*------------------------------------------
* 治理综合信息表
*------------------------------------------
cd "$Odata/公司研究/股权与治理/治理结构/治理综合信息文件154647264(仅供沪江大学使用)"
import excel "CG_Ybasic.xlsx", firstrow clear
keep Stkcd Reptdt Y0601b
labone, nrow(1)
drop in 1/2

gen year = substr(Reptdt,1,4)
rename (Stkcd Y0601b) (stock EmployeeNumber)
destring _all, replace
drop Reptdt
tsset stock year
gen LEmployeeNumber=L.EmployeeNumber
cd "$Data"
save "13_治理综合信息表.dta", replace

**由于后面有变量需要前一年为员工支付的薪酬总额，故在此单独合并2011年为员工支付的薪酬总额情况
cd "$Odata/公司研究/股权与治理/治理结构/治理综合信息文件154647264(仅供沪江大学使用)"
import excel "CG_Ybasic2011.xlsx", firstrow clear
keep Stkcd Y0601b
labone, nrow(1)
drop in 1/2

gen year = 2012
rename (Stkcd Y0601b) (stock LEmployeeNumber2012)
destring _all, replace

cd "$Data"
save "13_治理综合信息表2.dta", replace

use "13_治理综合信息表.dta", clear
merge 1:1 stock year using "13_治理综合信息表2.dta"
drop _merge
replace LEmployeeNumber=LEmployeeNumber2012 if !missing(LEmployeeNumber2012)
drop LEmployeeNumber2012
save "13_治理综合信息表.dta", replace

*------------------------------------------
* 股权性质表
*------------------------------------------
cd "$Odata/公司研究/股权与治理/股权性质/中国上市公司股权性质文件154916007(仅供沪江大学使用)"
import excel "EN_EquityNatureAll.xlsx", firstrow clear
keep Symbol EndDate TopTenHoldersRate EquityNatureID
labone, nrow(1)
drop in 1/2

gen year = substr(EndDate,1,4)
rename Symbol stock 
destring _all, replace
drop EndDate

cd "$Data"
save "14_股权性质表.dta", replace


/*==========================================
合并基础特征表格
===========================================*/

use "$Data/01_上市公司基本信息.dta", clear

duplicates drop stock year, force
merge 1:1 stock year using "02_资产负债表.dta"
drop _merge

merge 1:1 stock year using "03_利润表.dta"
drop _merge

merge 1:1 stock year using "03_利润表2024.dta"
drop _merge

merge 1:1 stock year using "04_现金流量表.dta"
drop _merge

merge 1:1 stock year using "04_现金流量表2.dta"
drop _merge

merge 1:1 stock year using "05_偿债能力表.dta"
drop _merge

merge 1:1 stock year using "06_比率结构表.dta"
drop _merge

merge 1:1 stock year using "07_盈利能力表.dta"
drop _merge

merge 1:1 stock year using "08_发展能力表.dta"
drop _merge

merge 1:1 stock year using "09_相对价值指标表.dta"
drop _merge

merge 1:1 stock year using "10_治理能力表.dta"
drop _merge

merge 1:1 stock year using "11_融资约束表.dta"
drop _merge

merge 1:1 stock year using "12_高管薪酬表.dta"
drop _merge

merge 1:1 stock year using "13_治理综合信息表.dta"
drop _merge

merge 1:1 stock year using "14_股权性质表.dta"
drop _merge

merge 1:1 stock year using "申万行业分类.dta", keep(match master)
drop _merge

keep if year>=2012 & year<=2023
replace LSalaryPayment=LSalaryPayment2012 if !missing(LSalaryPayment2012)
drop LSalaryPayment2012

save "$Data/基础变量.dta", replace



