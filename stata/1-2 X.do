global Data "./data"
global Odata "./data/raw"

*------------------------------------------
* 基础特征
*------------------------------------------
cd "$Data"
use "基础变量.dta", clear
gen Establishyear=substr(EstablishDate,1,4) 
destring Establishyear, replace
gen Age=2025-Establishyear
drop EstablishDate Establishyear
gen EV1=市值A/TotalAssets
gen EV2=市值B/TotalAssets
replace BondsPayable=0 if missing(BondsPayable) & !missing(IndustryCode)
replace ShortLoan=0 if missing(ShortLoan) & !missing(IndustryCode)
replace LongLoan=0 if missing(LongLoan) & !missing(IndustryCode)
gen BOND_D=0 if !missing(IndustryCode)
replace BOND_D=1 if !missing(BondsPayable) & BondsPayable!=0
gen BOND_P=0 if !missing(IndustryCode)
replace BOND_P=BondsPayable/TotalAssets
label var BOND_D "当企业在第t年末存在应付债券余额，取值为1"
label var BOND_P "应付债券余额/总资产"
drop BondsPayable

* 银行信贷强度
gen TotalLoan = ShortLoan + LongLoan
gen ShortRatio = ShortLoan / TotalAssets
gen LongRatio = LongLoan / TotalAssets
gen TotalRatio = TotalLoan / TotalAssets
bysort IndustryCode_sw year: egen Ind_ShortRatio = mean(ShortRatio)
bysort IndustryCode_sw year: egen Ind_LongRatio = mean(LongRatio)
bysort IndustryCode_sw year: egen Ind_TotalRatio = mean(TotalRatio)
gen ShortCR = ShortRatio - Ind_ShortRatio
gen LongCR = LongRatio - Ind_LongRatio
gen BankCR = TotalRatio - Ind_TotalRatio
label var BankCR "银行信贷强度：公司总借款比例与行业平均差额"
label var ShortCR "短期信贷强度：公司短期借款比例与行业平均差额"
label var LongCR "长期信贷强度：公司长期借款比例与行业平均差额"
drop TotalLoan ShortRatio LongRatio TotalRatio Ind_ShortRatio Ind_LongRatio Ind_TotalRatio ShortLoan LongLoan
xtset stock year

rename TotalAssets TotalAssetsori
gen TotalAssets = ln(TotalAssetsori)
replace Age = ln(Age)
label var TotalAssets "资产总计的对数"
label var Age "企业年龄的自然对数"
label var EV1 "企业价值倍数A：市值A/总资产"
label var EV2 "企业价值倍数B：市值B/总资产"
drop 市值A 市值B
save "基础变量.dta", replace

*并购
**由于有三张表，需要分开处理再合并
cd "$Odata/英文文献-公司层面/并购"
import excel "STK_MA_TRADINGMAIN1.xlsx", firstrow clear
labone, nrow(1)
keep Symbol FirstDeclareDate
drop in 1/2
destring _all, replace
rename Symbol stock
gen year = substr(FirstDeclareDate,1,4)
drop FirstDeclareDate
save "并购.dta", replace
import excel "STK_MA_TRADINGMAIN2.xlsx", cellrange(A4) clear 
keep B C 
rename (B C) (Symbol FirstDeclareDate)
destring _all, replace
rename Symbol stock
gen year = substr(FirstDeclareDate,1,4)
drop FirstDeclareDate
append using "并购.dta"
save "并购.dta", replace
import excel "STK_MA_TRADINGMAIN3.xlsx", cellrange(A4) clear 
keep B C 
rename (B C) (Symbol FirstDeclareDate)
destring _all, replace
rename Symbol stock
gen year = substr(FirstDeclareDate,1,4)
drop FirstDeclareDate
append using "并购.dta"
save "并购.dta", replace
	
use "并购.dta", clear
bysort stock year: gen MA = _N
duplicates drop stock year, force
destring _all, replace
replace MA=ln(MA+1)
label var MA "ln(公司年度并购次数+1)"
cd "$Data"
save "并购.dta", replace

*ESG评级
cd "$Odata/中文文献-公司层面/ESG"
import excel "ESG20250403.xlsx", firstrow clear
gen stock = substr(证券代码,1,6)
gen rating_num = .
replace rating_num = 1 if 华证ESG评级 == "C"
replace rating_num = 2 if 华证ESG评级 == "CC"
replace rating_num = 3 if 华证ESG评级 == "CCC"
replace rating_num = 4 if 华证ESG评级 == "B"
replace rating_num = 5 if 华证ESG评级 == "BB"
replace rating_num = 6 if 华证ESG评级 == "BBB"
replace rating_num = 7 if 华证ESG评级 == "A"
replace rating_num = 8 if 华证ESG评级 == "AA"
replace rating_num = 9 if 华证ESG评级 == "AAA"
destring _all, replace
drop 证券代码 华证ESG评级 证券简称
rename rating_num ESG
label var ESG "华证ESG评级"
cd "$Data"
save "ESG评级.dta", replace

*海外收入占比
cd "$Odata/中文文献-公司层面/海外收入"
import excel "主营构成_海外筛选.xlsx", firstrow clear
keep 证券代码 主营业务收入占比 报告期
gen stock = substr(证券代码,1,6)
gen year = substr(报告期,-4,4)
drop 报告期 证券代码
destring _all, replace
bysort stock year: egen OverseasRev = total(主营业务收入占比)
label var OverseasRev "海外业务收入占比"
drop 主营业务收入占比
duplicates drop stock year, force

cd "$Data"
save "海外业务收入.dta", replace

**由于主营构成_海外筛选.xlsx只筛选了有海外收入的公司-年观测值，会导致观测值大量缺失，所以合并原始数据（主营构成_合并，包含所有披露了主营业务收入的公司-年观测值）的标签变量，如果原始数据中披露了此公司-年观测值且没有海外收入，replace海外收入=0
cd "$Odata/中文文献-公司层面/海外收入"
import excel "主营构成_合并.xlsx", firstrow clear
labone, nrow(1)
keep 证券代码 主营业务收入占比 报告期
gen stock = substr(证券代码,1,6)
gen year = substr(报告期,-4,4)
drop 报告期 证券代码
destring _all, replace
collapse (sum) 海内外业务收入总占比 = 主营业务收入占比, by(stock year)
gen Overseaslabel=1 if !missing(海内外业务收入总占比)
drop 海内外业务收入总占比
cd "$Data"
save "海外业务收入标签.dta", replace

use "海外业务收入.dta", clear
merge 1:1 stock year using "海外业务收入标签.dta"
drop _merge
replace OverseasRev=0 if missing(OverseasRev) & Overseaslabel==1
replace OverseasRev=OverseasRev/100
drop Overseaslabel
save "海外业务收入.dta", replace

*海外参控股公司数量
cd "$Odata/中文文献-公司层面/参控股公司"
**前期通过原始数据中参控股公司的名字，用机器学习识别了每个参控股公司是否为海外公司，如是则label变量为1
import delimited using "带预测结果1.csv", clear encoding("utf-8")
save "带预测结果1.dta", replace
keep scode year label
drop in 1
destring _all, replace
rename scode stock
bysort stock year: egen OverseasInv = total(label)
drop label
duplicates drop stock year, force
save "参控股公司1.dta", replace
import delimited using "带预测结果2.csv", clear encoding("utf-8")
save "带预测结果2.dta", replace
keep scode year label
drop in 1
destring _all, replace
rename scode stock
bysort stock year: egen OverseasInv = total(label)
drop label
duplicates drop stock year, force
save "参控股公司2.dta", replace
import delimited using "带预测结果3.csv", clear encoding("utf-8") bindquote(strict)
save "带预测结果3.dta", replace
describe
keep scode year label
drop in 1
destring _all, replace
rename scode stock
bysort stock year: egen OverseasInv = total(label)
drop label
duplicates drop stock year, force
save "参控股公司3.dta", replace

use "参控股公司1.dta", clear
merge 1:1 stock year using "参控股公司2.dta"
drop _merge
merge 1:1 stock year using "参控股公司3.dta"
drop _merge
replace OverseasInv=ln(OverseasInv+1)
label var OverseasInv "ln(海外参控股公司数量+1)"
cd "$Data"
save "参控股公司_合并.dta", replace

*合并基础特征
cd "$Data"
use "基础变量.dta", clear
merge 1:1 stock year using "并购.dta"
drop _merge
merge 1:1 stock year using "ESG评级.dta"
drop _merge
merge 1:1 stock year using "海外业务收入.dta"
drop _merge
merge 1:1 stock year using "参控股公司_合并.dta"
drop _merge
replace MA=0 if missing(MA)
keep if year>=2012 & year<=2023
save "基础变量.dta", replace

*------------------------------------------
* 战略特征
*------------------------------------------
* 数字化转型
cd "$Odata/中文文献-公司层面/数字化转型"
import excel "上市公司MD&A-数字化转型314个词频统计.xlsx", firstrow clear
labone, nrow(1)

keep 年份 股票代码 数字化转型程度A 人工智能技术A 大数据技术A 数字化应用技术创新C 数字化应用流程创新C 数字化应用业务创新C 
gen stock = substr(股票代码,1,6)
rename (年份 数字化转型程度A 人工智能技术A 大数据技术A 数字化应用技术创新C 数字化应用流程创新C 数字化应用业务创新C) (year DCG AISkill DataSkill DigApplication1 DigApplication2 DigApplication3)
gen DigApplication=DigApplication1+DigApplication2+DigApplication3
destring _all, replace
drop 股票代码 DigApplication1 DigApplication2 DigApplication3
order stock year

foreach var of varlist DCG AISkill DataSkill DigApplication {
    replace `var' = ln(`var' + 1)
}
label var DCG "ln(年报中数字化转型词频+1)"
label var AISkill "ln(人工智能技术相关词频+1)"
label var DataSkill "ln(大数据技术相关词频+1)"
label var DigApplication "ln(年报中数字化应用-技术/流程/业务创新相关词频+1)"

cd "$Data"
save "数字化转型.dta", replace

*合并战略特征
cd "$Data"
use "基础变量.dta", clear
merge 1:1 stock year using "数字化转型.dta"
drop _merge

keep if year>=2012 & year<=2023
save "MERGED_DATA.dta", replace

*------------------------------------------
* 治理特征
*------------------------------------------
* 内部控制水平
cd "$Odata/中文文献-公司层面/内部控制水平/迪博内部控制指数及评级数据（2000-2023年）"
import excel "2000-2023年迪博内部控制指数及评级数据（已处理）.xlsx", firstrow clear

keep 证券代码 报告期 内部控制指数评分
rename (证券代码 报告期 内部控制指数评分) (stock year IntControl)
destring _all, replace
replace IntControl = ln(IntControl)
label var IntControl "迪博内部控制指数的对数"
duplicates drop stock year, force

cd "$Data"
save "内部控制水平.dta", replace

* 内控系统缺陷
cd "$Odata/英文文献-公司层面/内控系统缺陷"
import excel "IC_DeficiencyInfo.xlsx", firstrow clear
labone, nrow(1)
keep Symbol EndDate DeficiencyTypeCode
drop in 1/2
rename (Symbol DeficiencyTypeCode) (stock Deficiency)
gen year = substr(EndDate,1,4)
drop EndDate
destring _all, replace
keep if Deficiency == 1
label var Deficiency "财报重大缺陷：如果当年财务报表有重大缺陷，取1"

cd "$Data"
save "内控系统缺陷.dta", replace

*信息披露质量
cd "$Odata/英文文献-公司层面/信息披露质量/A股上市公司-信息披露质量KV指数（1991-2024年）"
import excel "计算结果.xlsx", firstrow clear
keep stkcd year KV
destring _all, replace
rename stkcd stock
label var KV  "信息披露质量指数：KV指数越高表明上市公司信息披露质量越低。"

cd "$Data"
save "信息披露质量.dta", replace

*真实盈余管理
cd "$Odata/英文文献-公司层面/真实盈余管理"
import excel "处理版.xlsx", firstrow clear
keep Symbol EndDate RealEarningsManage
drop in 1/2
gen year = substr(EndDate,1,4)
drop EndDate
destring _all, replace
rename (Symbol RealEarningsManage) (stock REM)
label var REM  "真实盈余管理"

cd "$Data"
save "真实盈余管理.dta", replace

*合并治理特征
cd "$Data"
use "MERGED_DATA.dta", clear

merge 1:1 stock year using "内部控制水平.dta"
drop _merge

merge 1:1 stock year using "内控系统缺陷.dta"
drop _merge

merge 1:1 stock year using "信息披露质量.dta"
drop _merge

merge 1:1 stock year using "真实盈余管理.dta"
drop _merge

keep if year>=2012 & year<=2023
replace Deficiency=0 if missing(Deficiency)
save "MERGED_DATA.dta", replace

*------------------------------------------
* 股东特征
*------------------------------------------
* 多个大股东
cd "$Odata/中文文献-公司层面/多个大股东/十大股东文件215347344(仅供北洋大学使用)"
import excel "CG_Sharehold.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt S0501b S0301b
gen year    =substr(Reptdt,1,4)
gen quarter2=substr(Reptdt,6,6)
gen quarter="0"
replace quarter="4" if quarter2=="12-31"
replace quarter="3" if quarter2=="09-30"
replace quarter="2" if quarter2=="06-30"
replace quarter="1" if quarter2=="03-31"
drop if quarter=="0"
drop quarter2
keep if quarter=="4"
rename Stkcd stock
destring _all, replace

bysort stock year: egen top1_持股比例 = max((S0501b == 1) * S0301b)
bysort stock year: egen top2_持股比例 = max((S0501b == 2) * S0301b)

gen MajorShareholders = (top1_持股比例 >= 10 & top2_持股比例 >= 10)
bysort stock year: keep if _n == 1
label var MajorShareholders  "多个大股东：若公司第t年存在两个或两个以上持股比例超过 10%的大股东，赋值为 1，否则为 0"
drop Reptdt quarter top1_持股比例 top2_持股比例 S0501b S0301b

cd "$Data"
save "多个大股东.dta", replace

cd "$Odata/中文文献-公司层面/多个大股东/十大股东文件215347344(仅供北洋大学使用)"
import excel "CG_Sharehold1.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt S0501b S0301b
gen year    =substr(Reptdt,1,4)
gen quarter2=substr(Reptdt,6,6)
gen quarter="0"
replace quarter="4" if quarter2=="12-31"
replace quarter="3" if quarter2=="09-30"
replace quarter="2" if quarter2=="06-30"
replace quarter="1" if quarter2=="03-31"
drop if quarter=="0"
drop quarter2
keep if quarter=="4"
rename Stkcd stock
destring _all, replace

bysort stock year: egen top1_持股比例 = max((S0501b == 1) * S0301b)
bysort stock year: egen top2_持股比例 = max((S0501b == 2) * S0301b)

gen MajorShareholders = (top1_持股比例 >= 10 & top2_持股比例 >= 10)
bysort stock year: keep if _n == 1
label var MajorShareholders  "多个大股东：若公司第t年存在两个或两个以上持股比例超过 10%的大股东，赋值为 1，否则为 0"
drop Reptdt quarter top1_持股比例 top2_持股比例 S0501b S0301b

cd "$Data"
save "多个大股东2.dta", replace

* 产权性质、前十大股东持股比例
cd "$Data"
use "MERGED_DATA.dta", clear
rename (EquityNatureID TopTenHoldersRate) (Ownership Ownstructure)
replace Ownership = "0" if Ownership != "1" & !missing(Ownership)
destring Ownership, replace
label var Ownership  "产权性质：国有企业为1，其余为0"
label var Ownstructure  "股权结构：前十大股东持股比例"
replace Ownstructure=Ownstructure/100
save "MERGED_DATA.dta", replace

*女性董事占比、董事会成员数量
cd "$Data"
use "MERGED_DATA.dta", clear
gen FemaleDirector=FemaleDirectorNumber/DirectorNumber
label var FemaleDirector "女性董事占比"
drop FemaleDirectorNumber DirectorNumber
replace Boardsize = ln(Boardsize)
label var Boardsize "董事会成员数的对数"

save "MERGED_DATA.dta", replace

*董监高责任险
cd "$Odata/中文文献-公司层面/董监高责任险/董责险投保公告明细表163121515(仅供耶鲁大学使用)"
import excel "TMTLI_InsAnnDetail.xlsx", firstrow clear
labone, nrow(1)
drop in 1
keep Symbol DeclareDate IsDirectorConsAdopt
destring IsDirectorConsAdopt, replace
keep if IsDirectorConsAdopt == 1
gen year = substr(DeclareDate,1,4)
drop DeclareDate
destring _all, replace
rename (Symbol IsDirectorConsAdopt) (stock DO)
label var DO "董事高管责任保险：企业当年公布董事会责任险，且董事会审议通过，则取1"
duplicates drop stock year, force

cd "$Data"
save "董监高责任险.dta", replace

*总经理董事长政治关联
cd  "$Odata/英文文献-公司层面/与政治家联系/上市公司总经理董事长政治关联数据整理（2008-2020年）附Stata代码/上市公司总经理董事长政治关联数据整理（2008-2020年）附Stata代码"
import excel "结果.xlsx", firstrow clear
keep stkcd year PCLevel
destring _all, replace
rename stkcd stock
label var PCLevel  "政治关联级别：企业董事长、总经理其中任意一人现任或曾任政府官员则PCLevel不为0"
duplicates drop stock year, force
cd "$Data"
save "与政治家联系.dta", replace

*诉讼
cd "$Odata/中文文献-公司层面/诉讼风险"
import excel "诉讼风险.xlsx", firstrow clear
gen stock = substr(证券代码,1,6)
drop 证券代码 证券简称
**由于原表中列变量为年份，故调整表形式
reshape long litigation_, i(stock) j(year)
rename litigation_ Litigation
destring _all, replace
replace Litigation=ln(Litigation+1)
label var Litigation "ln(公司年度诉讼次数+1)"
cd "$Data"
save "诉讼风险.dta", replace

*董事长学术水平
cd "$Odata/英文文献-公司层面/CEO风险偏好"
import excel "TMT_FIGUREINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt Name Degree CTB Academic
destring CTB Degree, replace
keep if CTB == 1
keep if regexm(Reptdt,"-12-31")
gen year = substr(Reptdt,1,4)
drop Reptdt CTB
rename Stkcd stock
gen ChairIsDoctor = 0
replace ChairIsDoctor = 1 if Degree == 5
replace ChairIsDoctor = . if missing(Degree)
gen ChairAcademicBack = 0
replace Academic = subinstr(Academic, ",", "", .) 
destring Academic, replace
replace ChairAcademicBack = 1 if Academic != 4 & !missing(Academic)
replace ChairAcademicBack = . if missing(Academic)
destring _all, replace
bysort stock year Name: keep if _n == 1
* 如果一个公司-年有两条以上观测值（董事长不唯一）先按是否博士、是否学术背景排序，把值为 1 的排在最后，然后取最后一条，即只要有一个人是博士/有学术背景，该年就记为1
bysort stock year (ChairIsDoctor ChairAcademicBack): keep if _n == _N
drop Degree Academic Name 
label var ChairIsDoctor  "董事长是否有博士学历"
label var ChairAcademicBack  "董事长是否有学术背景"
cd "$Data"
save "董事长学术水平.dta", replace

*合并股东特征
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "多个大股东.dta"
drop _merge
merge 1:1 stock year using "多个大股东2.dta"
drop _merge
merge 1:1 stock year using "董监高责任险.dta"
drop _merge
merge 1:1 stock year using "与政治家联系.dta"
drop _merge
merge 1:1 stock year using "诉讼风险.dta"
drop _merge
merge 1:1 stock year using "董事长学术水平.dta"
drop _merge

keep if year>=2012 & year<=2023
replace MajorShareholders = 0 if missing(MajorShareholders)
replace InvestorShare=InvestorShare/100
replace DO=0 if missing(DO)
replace IndDirectorRatio=IndDirectorRatio/100
replace Litigation=0 if missing(Litigation)
save "MERGED_DATA.dta", replace

*------------------------------------------
* 管理层特征
*------------------------------------------
* CEO风险偏好、学历
cd "$Odata/英文文献-公司层面/CEO风险偏好"
import excel "TMT_FIGUREINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt Name Gender Degree TMTP
destring TMTP, replace
keep if TMTP == 1
keep if regexm(Reptdt,"-12-31")
gen year = substr(Reptdt,1,4)
drop Reptdt TMTP
destring _all, replace

rename (Stkcd Name Degree) (stock CEOName CEODegree)
gen CEORisk=1
replace CEORisk=0 if Gender=="女"
destring _all, replace

bysort stock year: egen CEODegree_mean = mean(CEODegree)
bysort stock year: keep if _n == 1

replace CEODegree = CEODegree_mean
drop CEODegree_mean Gender
label var CEORisk  "CEO风险偏好：用性别代表，CEO为男性取1"
label var CEODegree  "CEO学历：1=中专及中专以下，2=大专，3=本科，4=硕士研究生，5=博士研究生，6=其他（以其他形式公布的学历，如荣誉博士、函授等），7=MBA/EMBA"

cd "$Data"
save "CEO风险偏好&学历.dta", replace

*CEO薪酬激励
cd "$Odata/英文文献-公司层面/CEO薪酬中的风险激励"
import excel "CG_Incperson.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Rptdt D0101b Pishrttl
gen year = substr(Rptdt,1,4)
drop Rptdt
rename (Stkcd D0101b) (stock CEOName)
destring _all, replace

bysort stock year CEOName: egen CEOIncentive= total(Pishrttl)
duplicates drop stock year CEOName, force
drop Pishrttl
cd "$Data"
replace CEOIncentive=CEOIncentive/100
save "CEO薪酬激励.dta", replace
**薪酬激励的原始数据包含各董事、高管的激励，且表中没有划分各职位的数值型变量，所以根据CEO风险偏好&学历数据中由职务类别筛选出的CEO名字与薪酬激励表进行匹配
cd "$Data"
use "CEO风险偏好&学历.dta", clear
merge 1:1 stock year CEOName using "CEO薪酬激励.dta", keep(master match) nogen
label var CEOIncentive  "CEO薪酬激励权益占授予时公司总股数的比例(%)"
replace CEOIncentive=0 if missing(CEOIncentive)
drop CEOName
save "CEO风险偏好&学历.dta", replace

*管理层质量：管理层MBA学位、金融背景、通才性
cd "$Odata/英文文献-公司层面/CEO风险偏好"
import excel "TMT_FIGUREINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt Name Degree Funback FinBack
keep if regexm(Reptdt,"-12-31")
gen year = substr(Reptdt,1,4)
drop Reptdt
rename Stkcd stock
destring _all, replace
gen IsMBA = 0
replace IsMBA = 1 if Degree == 7
replace IsMBA = . if missing(Degree)
drop Degree
**由于职业背景、学术背景、金融背景均为以逗号分隔的数值形式罗列，故以逗号数量+1来计算管理层担任过的不同职业方向数量（通才性）；以排除【无学术背景】及【无金融背景】对应数值来生成是否有学术/金融背景的0/1变量
gen comma_count = strlen(Funback) - strlen(subinstr(Funback, ",", "", .))
gen 管理层通才性 = comma_count + 1 if !missing(Funback)
drop comma_count Funback
gen 管理层金融背景 = 0
replace 管理层金融背景 = . if missing(FinBack)
replace FinBack = subinstr(FinBack, ",", "", .) 
destring FinBack, replace
replace 管理层金融背景 = 1 if FinBack != 99 & !missing(FinBack)
drop FinBack
destring _all, replace
**按firm、year汇总管理层质量情况
bysort stock year: egen IsMBA_mean = mean(IsMBA)
bysort stock year: egen Versatility = mean(管理层通才性)
bysort stock year: egen FinBack = mean(管理层金融背景)
bysort stock year: keep if _n == 1
replace IsMBA = IsMBA_mean
drop IsMBA_mean
label var IsMBA  "管理层拥有MBA学位比例"
label var Versatility  "管理层平均任职过的领域个数"
label var FinBack  "管理层金融背景比例：有金融背景则取值为1，否则为0。"
drop Name 管理层通才性 管理层金融背景

cd "$Data"
save "管理层质量.dta", replace

*CEO学术水平
cd "$Odata/英文文献-公司层面/CEO风险偏好"
import excel "TMT_FIGUREINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Stkcd Reptdt Name Degree TMTP Academic
destring TMTP Degree, replace
keep if TMTP == 1
keep if regexm(Reptdt,"-12-31")
gen year = substr(Reptdt,1,4)
drop Reptdt TMTP
rename Stkcd stock
gen CEOIsDoctor = 0
replace CEOIsDoctor = 1 if Degree == 5
replace CEOIsDoctor = . if missing(Degree)
gen CEOAcademicBack = 0
replace Academic = subinstr(Academic, ",", "", .) 
destring Academic, replace
replace CEOAcademicBack = 1 if Academic != 4 & !missing(Academic)
replace CEOAcademicBack = . if missing(Academic)
destring _all, replace
bysort stock year Name: keep if _n == 1
* 如果一个公司-年有两条以上观测值（CEO不唯一）先按是否博士、是否学术背景排序，把值为 1 的排在最后，然后取最后一条，即只要有一个人是博士/有学术背景，该年就记为1
bysort stock year (CEOIsDoctor CEOAcademicBack): keep if _n == _N
drop Degree Academic Name
label var CEOIsDoctor  "CEO是否有博士学历"
label var CEOAcademicBack  "CEO是否有学术背景"
cd "$Data"
save "CEO学术水平.dta", replace

*管理层前三名薪酬总额
cd "$Data"
use "MERGED_DATA.dta", clear
replace Top3ManageSumSalary = ln(Top3ManageSumSalary)
label var Top3ManageSumSalary  "管理层前三名薪酬总额的对数"
save "MERGED_DATA.dta", replace

*内部薪酬差距
cd "$Odata/中文文献-公司层面/企业内部薪酬差距"
import excel "最终结果-内部薪酬差距00-23年.xlsx", firstrow clear
labone, nrow(1)
keep id year 内部薪酬差距
rename (id 内部薪酬差距) (stock Paygap)
destring _all, replace
label var Paygap "内部薪酬差距：管理层平均薪酬/员工平均薪酬"

cd "$Data"
save "企业内部薪酬差距.dta", replace

*合并管理层特征
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "CEO风险偏好&学历.dta"
drop _merge
merge 1:1 stock year using "管理层质量.dta"
drop _merge
merge 1:1 stock year using "CEO学术水平.dta"
drop _merge
merge 1:1 stock year using "企业内部薪酬差距.dta"
drop _merge

keep if year>=2012 & year<=2023
save "MERGED_DATA.dta", replace


*------------------------------------------
* 员工特征
*------------------------------------------
*员工流动率
cd "$Data"
use "13_治理综合信息表.dta", clear
tsset stock year
bysort stock: gen EmployeeTurnover = (EmployeeNumber - LEmployeeNumber) / LEmployeeNumber if !missing(LEmployeeNumber)
label var EmployeeTurnover "员工流动率"
drop EmployeeNumber LEmployeeNumber
save "员工流动率.dta", replace

*普通员工工资
cd "$Data"
use "MERGED_DATA.dta", clear
gen EmployeeSalary=(SalaryPayment-ManageSumSalary)/TotalRevenue
drop SalaryPayment ManageSumSalary
label var EmployeeSalary "普通员工工资： (支付给职工以及为职工支付的现金-高管薪酬)/销售收入"
save "MERGED_DATA.dta", replace

*员工社保缴费
cd "$Odata/中文文献-公司层面/社会保险缴费"
import excel "FN_Fn032.xlsx", firstrow clear
labone, nrow(1)
keep Stkcd Accper Typrep Fn03201 Fn03203
drop in 1/2
destring Typrep, replace
keep if Typrep == 1
drop Typrep

gen year    =substr(Accper,1,4)
gen quarter2=substr(Accper,6,6)
gen quarter="0"
replace quarter="4" if quarter2=="12-31"
replace quarter="3" if quarter2=="09-30"
replace quarter="2" if quarter2=="06-30"
replace quarter="1" if quarter2=="03-31"
drop if quarter=="0"
drop quarter2
keep if quarter=="4"
**原始数据为公司为职工支付的各项薪酬，通过项目明细中同时含有“社”和“保”来识别社保缴费项目
gen is_social_insurance = 0
replace is_social_insurance = 1 if strpos(Fn03201, "社") > 0 & strpos(Fn03201, "保") > 0
**公司披露的社保缴费相关项目中，存在披露本年社保缴费的【总体金额】和【分项披露】各项社保缴费的情况。为了不重复计算，将这两类情况分开，如果是披露总体金额则直接使用，如果分项披露金额则使用相加后数值
**识别方法：如果项目明细的最后几个字是社会保险费/社保/社会保险/社会保险金，则为披露总体金额；如果分项披露，项目明细类似“社会保险费其中：工伤保险费”
gen item_type = ""
replace item_type = "total" if regexm(Fn03201, "社会保险费$")   
replace item_type = "total" if regexm(Fn03201, "社保$") 
replace item_type = "total" if regexm(Fn03201, "社会保险$") 
replace item_type = "total" if regexm(Fn03201, "社会保险金$")
replace item_type = "" if is_social_insurance != 1
replace item_type = "detail" if is_social_insurance == 1 & item_type != "total"
**公司在此年份存在分项披露情况时，使用分项数据；不存在分项披露情况时，直接使用总体金额
destring Fn03203, replace
bysort Stkcd year: egen has_detail = max(item_type == "detail")

gen to_sum = 0
replace to_sum = Fn03203 if item_type == "total" & !has_detail 
replace to_sum = Fn03203 if item_type == "detail"             
**按stock-year汇总
collapse (sum) social_insurance = to_sum, by(Stkcd year)
rename Stkcd stock
destring _all, replace

cd "$Data"
save "社保缴费总额.dta", replace

*员工持股计划
cd "$Odata/中文文献-公司层面/员工持股计划"
import excel "员工持股计划.xlsx", firstrow clear
keep 证券代码 董事会预案日 员工持股计划
gen stock = substr(证券代码,1,6)
gen year = year(董事会预案日)
drop 董事会预案日 证券代码
destring _all, replace
rename 员工持股计划 ESOP
duplicates drop stock year, force
label var ESOP "员工持股计划：如果企业当年实施或存在员工持股计划，则 ESOP 取 1，否则取 0"

cd  "$Data" 
save "员工持股计划.dta", replace

*合并员工特征
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "员工流动率.dta"
drop _merge
merge 1:1 stock year using "社保缴费总额.dta"
drop _merge
merge 1:1 stock year using "员工持股计划.dta"
drop _merge
gen SocInsurance=social_insurance/LSalaryPayment
label var SocInsurance "员工社保缴费/企业上年为员工支付的薪酬总额"
replace ESOP=0 if missing(ESOP)
keep if year>=2012 & year<=2023
drop LSalaryPayment social_insurance
save "MERGED_DATA.dta", replace


*------------------------------------------
* 政府特征
*------------------------------------------
*政府补贴
cd "$Odata/中文文献-公司层面/研发补贴与非研发补贴/CSMAR（全量）"
import excel "FN_FN056.xlsx", firstrow clear
labone, nrow(1)
keep Stkcd Accper Typrep Fn05601 Fn05602
drop in 1/2
destring Typrep, replace
keep if Typrep==1
gen year=substr(Accper,1,4)
drop Accper Typrep
drop if Fn05601=="合计"
rename (Stkcd Fn05602) (stock 政府补贴金额)
destring 政府补贴金额, replace
collapse (sum) GovSub = 政府补贴金额, by(stock year)
keep stock year GovSub
destring _all, replace

cd "$Data"
save "研发与非研发补贴.dta", replace

*排污收费
cd "$Odata/中文文献-公司层面/排污收费"
import excel "上市公司排污环保费用.xlsx", firstrow clear
labone, nrow(1)
keep Scode Date Enrelcost
drop in 1
gen year    =substr(Date,1,4)
drop Date
rename Scode stock
destring _all, replace
collapse (sum) Enrelcost, by(stock year)
destring year, replace
cd "$Data"
save "排污收费.dta", replace

*环境补助
cd "$Odata/中文文献-公司层面/环境补助"
import excel "上市公司环境治理补助.xlsx", firstrow clear
labone, nrow(1)
keep Scode Date Pubsub
drop in 1
gen year    =substr(Date,1,4)
drop Date
rename Scode stock
destring _all, replace
collapse (sum) EnvSubsidy = Pubsub, by(stock year)
destring year, replace
duplicates drop stock year, force

cd "$Data"
save "环境补助.dta", replace

*税费负担、实际税率
cd "$Data"
use "MERGED_DATA.dta", clear
gen TaxBurden=(TaxPayment-TaxRefund)/TotalRevenue
drop TaxPayment TaxRefund
label var TaxBurden "税费负担率：(支付的各项税费-收到的税费返还)/营业总收入"
gen TaxRate=IncomeTax/TotalRevenue
drop IncomeTax
replace TaxRate=0 if TaxRate<0
label var TaxRate "实际所得税税率：所得税费用/营业总收入"
save "MERGED_DATA.dta", replace

*合并政府特征
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "研发与非研发补贴.dta"
drop _merge
merge 1:1 stock year using "排污收费.dta"
drop _merge
merge 1:1 stock year using "环境补助.dta"
drop _merge

replace GovSub=GovSub/TotalRevenue
replace Enrelcost=Enrelcost/TotalRevenue
replace EnvSubsidy=EnvSubsidy/TotalRevenue
foreach var of varlist GovSub Enrelcost EnvSubsidy {
    replace `var' = 0 if missing(`var')
}
label var GovSub "政府补贴/销售额"
label var Enrelcost "排污收费/销售额"
label var EnvSubsidy "环境补助/销售额"
label var EnvSubsidy "环境补助/销售额"
keep if year>=2012 & year<=2023
save "MERGED_DATA.dta", replace

*公共数据资源
cd "$Data"
use "MERGED_DATA.dta", clear
gen Gdatact = 0
* 根据各城市平台上线年份设置Gdatact
replace Gdatact = 1 if year >= 2012 & inlist(CITY, "北京市", "上海市", "湛江市")
replace Gdatact = 1 if year >= 2014 & CITY == "无锡市"
replace Gdatact = 1 if year >= 2015 & inlist(CITY, "青岛市", "武汉市", "东莞市", "肇庆市")
replace Gdatact = 1 if year >= 2016 & inlist(CITY, "广州市", "哈尔滨市", "深圳市")
replace Gdatact = 1 if year >= 2017 & inlist(CITY, "佛山市", "荆门市", "梅州市", "阳江市")
local city2018 "成都市 济南市 南京市 宁波市 滨州市 德州市 东营市 贵阳市 菏泽市 惠州市 济宁市 江门市 聊城市 临沂市 六安市 马鞍山市 日照市 石嘴山市 苏州市 泰安市 铜仁市 威海市 潍坊市 乌海市 宣城市 烟台市 银川市 枣庄市 中山市 珠海市 淄博市"
foreach c of local city2018 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2018
}
local city2019 "扬州市 天津市 厦门市 蚌埠市 常德市 常州市 潮州市 福州市 抚州市 阜阳市 广元市 河源市 湖州市 淮安市 黄冈市 黄山市 佳木斯市 揭阳市 连云港市 六盘水市 泸州市 茂名市 绵阳市 南宁市 南通市 内江市 黔东南州 黔南州 清远市 三亚市 汕头市 汕尾市 韶关市 宿迁市 遂宁市 泰州市 徐州市 雅安市 永州市 云浮市 中卫市 遵义市"
foreach c of local city2019 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2019
}
local city2020 "杭州市 承德市 达州市 防城港市 赣州市 甘孜州 桂林市 衡水市 金华市 九江市 克拉玛依市 拉萨市 乐山市 丽水市 林芝市 柳州市 陇南市 南昌市 南充市 萍乡市 钦州市 衢州市 上饶市 绍兴市 双鸭山市 台州市 铜陵市 温州市 乌鲁木齐市 芜湖市 孝感市 宜宾市 宜昌市 鹰潭市 舟山市 资阳市"
foreach c of local city2020 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2020
}
local city2021 "重庆市 阿坝州 阿拉善盟 巴中市 白城市 亳州市 毕节市 长治市 郴州市 池州市 崇左市 大庆市 大同市 德阳市 鄂州市 恩施州 广安市 贵港市 哈密市 贺州市 河池市 淮北市 吉安市 嘉兴市 景德镇市 荆州市 兰州市 凉山州 娄底市 眉山市 那曲市 攀枝花市 十堰市 宿州市 随州市 梧州市 湘潭市 新余市 盐城市 宜春市 益阳市 玉林市 岳阳市 镇江市 自贡市"
foreach c of local city2021 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2021
}
local city2022 "沈阳市 鄂尔多斯市 鹤壁市 合肥市 晋城市 辽源市 平凉市 黔西南州 朔州市 锡林郭勒盟 阳泉市 运城市 昭通市"
foreach c of local city2022 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2022
}
local city2023 "安顺市 昌吉市 滕州市 呼和浩特市 淮南市 黄石市 吉林市 金昌市 龙岩市 牡丹江市 南平市 宁德市 莆田市 泉州市 三明市 咸宁市 漳州市"
foreach c of local city2023 {
    replace Gdatact = 1 if CITY == "`c'" & year >= 2023
}
label var Gdatact "公司所在市当年是否上线政府数据开放平台"
save "MERGED_DATA.dta", replace

*高新区
cd "$Data"
use "MERGED_DATA.dta", clear
gen HTZone = 0
local ht_cities_2012 "北京市 上海市 天津市 重庆市 广州市 深圳市 武汉市 沈阳市 大连市 长春市 哈尔滨市 南京市 杭州市 合肥市 福州市 厦门市 济南市 威海市 郑州市 长沙市 中山市 桂林市 海口市 成都市 西安市 兰州市 石家庄市 太原市 昆明市 贵阳市 南宁市 保定市 包头市 鞍山市 吉林市 大庆市 苏州市 无锡市 常州市 洛阳市 襄阳市 株洲市 佛山市 惠州市 珠海市 宝鸡市 乌鲁木齐市 绵阳市 杨凌市 宁波市 泰州市 湘潭市 唐山市 三河市 营口市 辽阳市 延吉市 齐齐哈尔市 昆山市 济宁市 烟台市 安阳市 南阳市 宜昌市 柳州市 东莞市 肇庆市 渭南市 白银市 昌吉市 泉州市 新余市 景德镇市 芜湖市 蚌埠市 江门市 西宁市 银川市 绍兴市 江阴市 临沂市 自贡市 益阳市 承德市 本溪市 徐州市 温州市 马鞍山市 莆田市 鹰潭市 泰安市 新乡市 孝感市 乐山市 玉溪市 榆林市 咸阳市 衡阳市"
foreach c of local ht_cities_2012 {
    replace HTZone = 1 if CITY == "`c'" & year >= 2012
}
replace HTZone = 1 if year >= 2013 & inlist(CITY, "呼和浩特市", "阜新市", "通化市", "漳州市", "衢州市", "荆门市", ///
    "石河子市", "石嘴山市", "南通市")
replace HTZone = 1 if year >= 2014 & CITY == "镇江市"
local ht_cities_2015 "东营市 长治市 锦州市 抚州市 三明市 龙岩市 平顶山市 郴州市 北海市 杭州市 盐城市 连云港市 枣庄市 吉安市 赣州市 泸州市 攀枝花市 德阳市 安康市 湖州市 嘉兴市 扬州市 常熟市 德州市 济南市 焦作市 仙桃市 随州市 河源市 清远市 璧山区 巴中市 沧州市"
foreach c of local ht_cities_2015 {
    replace HTZone = 1 if CITY == "`c'" & year >= 2015
}
local ht_cities_2017 "鄂尔多斯市 宿迁市 淮安市 常德市 汕头市 内江市 安顺市 黄冈市 咸宁市 铜陵市"
foreach c of local ht_cities_2017 {
    replace HTZone = 1 if CITY == "`c'" & year >= 2017
}
local ht_cities_2018 "淮南市 共青城市 丰城市 荆州市 黄石市 潜江市 怀化市 湛江市 茂名市 荣昌区 永川区 楚雄市 白城市 白山市 毕节市"
foreach c of local ht_cities_2018 {
    replace HTZone = 1 if CITY == "`c'" & year >= 2018
}
local ht_cities_2022 "滁州市 安庆市 信阳市 许昌市 遵义市 克拉玛依市 拉萨市 宁乡市"
foreach c of local ht_cities_2022 {
    replace HTZone = 1 if CITY == "`c'" & year >= 2022
}
replace HTZone = 1 if year >= 2023 & CITY == "阿拉尔市"
label var HTZone "公司所在市当年是否为国家高新区"
save "MERGED_DATA.dta", replace

*人才政策
cd "$Odata/地区层面/城市人才引进强度数据(2005-2024年)"
import excel "基准回归版本.xlsx", firstrow clear
keep 城市 年份 人才引进强度
rename (城市 年份 人才引进强度) (CITY year Talent)
replace Talent=0 if missing(Talent)
replace Talent=Talent*100
duplicates drop CITY year, force
destring _all, replace
cd "$Data"
save "人才政策.dta", replace

use "MERGED_DATA.dta", clear
merge m:1 CITY year using "人才政策.dta"
drop _merge
label var Talent "人才引进强度=加权关键词数/报告总词数"
replace Talent=0 if missing(Talent)
save "MERGED_DATA.dta", replace

*数字经济发展水平
cd "$Odata/地区层面/数字经济水平（省）"
import excel "数字经济数据（2011-2023年）.xlsx", sheet("最终结果") firstrow clear
gen year_num = real(subinstr(year, "年", "", .))
drop id year
rename (year_num 省份 数字经济) (year PROVINCE Dige)
cd "$Data"
save "数字经济水平.dta", replace

use "MERGED_DATA.dta", clear
merge m:1 PROVINCE year using "数字经济水平.dta"
drop _merge
label var Dige "省级数字经济水平"
save "MERGED_DATA.dta", replace

*知识产权保护强度
cd "$Odata/地区层面/知识产权保护水平"
import excel "工作簿1.xlsx", firstrow clear
rename (地区 年份) (CITY year)
cd "$Data"
save "地区知识产权结案数.dta", replace

cd "$Odata/地区层面/知识产权保护水平/分城市国内生产总值234514384(仅供vip使用)"
import excel "CRE_Gdpct.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
rename (Sgnyea Ctnm Ctnm_id) (year CITY CITYCODE)
destring _all, replace
cd "$Data"
save "分地区国内生产总值.dta", replace

use "$Data/地区知识产权结案数.dta", clear

merge m:1 CITY year using "分地区国内生产总值.dta"
keep if _merge==3
drop _merge

label var 知识产权结案数 "此城市人民法院审理的知识产权结案数"
label var Gdpct01 "城市gdp"

gen cityipp=知识产权结案数/Gdpct01
gen gdp=0
label var gdp "当年国家gdp"
replace gdp=538579.95 if year==2012
replace gdp=592963.23 if year==2013
replace gdp=643563.1 if year==2014
replace gdp=688858.22 if year==2015
replace gdp=746395.06 if year==2016
replace gdp=832035.95 if year==2017
replace gdp=919281.13 if year==2018
replace gdp=986515.2 if year==2019
replace gdp=1013567 if year==2020
replace gdp=1149236.98 if year==2021
replace gdp=1204723.95 if year==2022
replace gdp=1260582.07 if year==2023

gen 总知识产权结案数=0
label var 总知识产权结案数 "当年国家整体知识产权审判结案数"
replace 总知识产权结案数=1817 if year==2012
replace 总知识产权结案数=1046 if year==2013
replace 总知识产权结案数=2237 if year==2014
replace 总知识产权结案数=3033 if year==2015
replace 总知识产权结案数=6178 if year==2016
replace 总知识产权结案数=5839 if year==2017
replace 总知识产权结案数=12694 if year==2018
replace 总知识产权结案数=32653 if year==2019
replace 总知识产权结案数=50624 if year==2020
replace 总知识产权结案数=33188 if year==2021
replace 总知识产权结案数=12161 if year==2022
replace 总知识产权结案数=11637 if year==2023

gen countryipp=总知识产权结案数/gdp
gen Ipp=cityipp/countryipp
label var Ipp "地区知识产权保护强度：(本地区人民法院审理知识产权审判结案数/地区GDP)/(中国整体知识产权审判结案数/国家GDP)"
cd "$Data"
save "地区知识产权结案数.dta", replace

use "MERGED_DATA.dta", clear
merge m:1 CITYCODE year using "地区知识产权结案数.dta", keep(match master using) keepusing(CITYCODE year Ipp)
drop _merge
save "MERGED_DATA.dta", replace

*地区产业政策
cd "$Odata/地区层面/省份产业政策"
use "省份产业政策_2006-2025_Y_全(2001和2012年证监会行业分类标准).dta", clear
cd "$Data"
save "省份产业政策.dta", replace
use "MERGED_DATA.dta", clear
merge m:1 year PROVINCE using "省份产业政策.dta", keep(master match) keepusing(IP_Enc_Ind2012 IP_EncImp_Ind2012 IP_EncImpCen_Ind2012 IP_Cen_Ind2012)
foreach policy in IP_Enc IP_EncImp IP_EncImpCen IP_Cen {
    gen `policy' = 0
    replace `policy'_Ind2012 = subinstr(`policy'_Ind2012, " ", "", .)
    replace `policy' = 1 if strpos(";" + `policy'_Ind2012 + ";", ";" + IndustryCode + ";") > 0
    replace `policy' = . if missing(IndustryCode)
    if "`policy'" == "IP_Enc" label var `policy' "若公司当年属于所在省五年规划-鼓励发展产业，取1"
    if "`policy'" == "IP_EncImp" label var `policy' "若公司当年属于所在省五年规划-鼓励且地方重点支持产业，取1"
    if "`policy'" == "IP_EncImpCen" label var `policy' "若公司当年属于所在省五年规划-鼓励且国家地方双重支持产业，取1"
    if "`policy'" == "IP_Cen" label var `policy' "若公司当年属于所在省五年规划-国家重点支持产业 ，取1"
}

drop _merge IP_Enc_Ind2012 IP_EncImp_Ind2012 IP_EncImpCen_Ind2012 IP_Cen_Ind2012
save "MERGED_DATA.dta", replace


*------------------------------------------
* 债权人特征
*------------------------------------------
*银行竞争水平
cd "$Odata/行业层面/银行竞争度/银行业金融机构基本信息表171634625(仅供vip使用)"
import excel "BFI_BFINSTINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep InstituionCode HeadofficeName CityName QuitDate ApprovalDate IssueDate 
gen start_year = real(substr(ApprovalDate, 1, 4))
gen end_year = real(substr(QuitDate, 1, 4))
drop if missing(start_year)
replace end_year = 2023 if missing(end_year)
gen duration = end_year - start_year + 1
expand duration
bysort InstituionCode: gen year = start_year + _n - 1
drop if missing(HeadofficeName) | missing(CityName) 

gen dummy_count = 1
collapse (sum) branch_count = dummy_count, by(CityName year HeadofficeName)
bysort CityName year: egen total_branches = sum(branch_count)
gen share = branch_count / total_branches
gen share_sq = share^2
bysort CityName year: egen BankHHI = sum(share_sq)
gsort CityName year -branch_count
by CityName year: gen rank = _n
gen top3_branch = branch_count if rank <= 3
bysort CityName year: egen top3_sum = sum(top3_branch)
gen BankCR3 = top3_sum / total_branches
collapse (mean) BankHHI BankCR3 total_branches, by(CityName year)
drop total_branches
keep if year>=2012 & year<=2023
rename CityName CITY
label var BankHHI  "地级市银行业赫芬达尔 - 赫希曼指数"
label var BankCR3  "地级市银行业前三大支行占比"
rename BankCR3 Top3Bank
cd "$Data"
save "银行竞争水平.dta", replace

use "MERGED_DATA.dta", clear
merge m:1 CITY year using "银行竞争水平.dta", keep(match master)
drop _merge
duplicates drop stock year, force
xtset stock year
order BOND_D BOND_P, before(BankHHI)
save "MERGED_DATA.dta", replace


*------------------------------------------
* 信息中介 & 股票市场特征
*------------------------------------------
*分析师作用
cd "$Odata/英文文献-公司层面/分析师作用强度"
import excel "AF_CFEATUREPROFILE.xlsx", firstrow clear
labone, nrow(1)
keep Stkcd Accper AnaAttention
drop in 1/2
rename Stkcd stock
gen year = substr(Accper,1,4)
drop Accper
destring _all, replace
replace AnaAttention=ln(AnaAttention+1)
label var AnaAttention "ln(年度分析师数量+1)"

cd "$Data"
save "分析师作用.dta", replace

*融资融券
cd "$Odata/中文文献-公司层面/融资融券"
**有7个表，需要构建文件列表循环合并
local filelist "CHN_Stkmt_dunderlyings.xlsx"
forvalues i=1/6 {
    capture confirm file "CHN_Stkmt_dunderlyings`i'.xlsx"
    if _rc == 0 {
        local filelist `filelist' "CHN_Stkmt_dunderlyings`i'.xlsx"
    }
}
**处理第一个文件（合并用到的主文件)
import excel using "CHN_Stkmt_dunderlyings.xlsx", firstrow clear
labone, nrow(1)
drop in 1/3
destring Financeavailable Shortavailable, replace force
save combined_data.dta, replace
**合并剩下6个文件
local first 1
foreach file of local filelist {
    if `first' {
        local first 0
        continue
    }
    
    import excel using "`file'", cellrange(A4) clear
    rename (A B C D E F) (Exchangecode Mtdate Stockcode Stockname Financeavailable Shortavailable)
    destring Financeavailable Shortavailable, replace force
    append using combined_data.dta
    save combined_data.dta, replace
}
**统一处理合并文件
use combined_data.dta, clear
keep Stockcode Mtdate Financeavailable Shortavailable
rename Stockcode stock
gen year=substr(Mtdate,1,4)
drop Mtdate
bysort stock year: keep if _n == _N
destring _all, replace
label var Financeavailable "可融资标识"
label var Shortavailable "可融券标识"

cd "$Data"
save "融资融券.dta", replace

*对赌
cd "$Odata/中文文献-公司层面/业绩对赌/业绩对赌信息总表161350837(仅供沪江大学使用)"
import excel "VAM_PERFORMMAIN.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
keep Symbol PerformCommitStart
rename Symbol stock
gen year = substr(PerformCommitStart,1,4)
bysort stock year: gen VAM = _N
duplicates drop stock year, force
destring _all, replace
replace VAM=ln(VAM+1)
label var VAM "ln(公司年度对赌协议数量+1)"
drop PerformCommitStart

cd "$Data"
save "业绩对赌.dta", replace

*财经报刊新闻
cd "$Odata/英文文献-公司层面/新闻/CFND_报刊财经新闻量化统计_ALL"
tempfile master
save `master', emptyok
**由于原始数据是按年划分的文件，单独处理第一年，其他年份循环处理后合并
import excel "报刊财经新闻量化统计-2012.xlsx", firstrow clear
labone, nrow(1)
keep Scode Date Newsnum_Cont Negnews_All
drop in 1
rename Scode stock
gen year = substr(Date,1,4)
rename Newsnum_Cont 公司新闻日总数
rename Negnews_All 公司负面新闻日总数
destring _all, replace
drop Date
save "合并中间数据.dta", replace

forvalues y = 2013/2023 {
    capture confirm file "报刊财经新闻量化统计-`y'.xlsx"
    if _rc == 0 {
        import excel "报刊财经新闻量化统计-`y'.xlsx", cellrange(A3) clear
		keep A C H K
        rename (A C H K) (stock Date 公司新闻日总数 公司负面新闻日总数)
        gen year = substr(Date,1,4)
		drop Date
        destring _all, replace

        append using "合并中间数据.dta"
        save "合并中间数据.dta", replace
		 }
}

use "合并中间数据.dta", clear
bysort stock year: egen FinNews = sum(公司新闻日总数)
bysort stock year: egen NegFinNews = sum(公司负面新闻日总数)
replace FinNews=ln(FinNews)
replace NegFinNews=ln(NegFinNews)
label var FinNews "公司财经报刊新闻总数的对数"
label var NegFinNews "公司财经报刊负面新闻总数的对数"
duplicates drop stock year, force
drop 公司新闻日总数 公司负面新闻日总数

cd "$Data"
save "报刊财经新闻合并数据.dta", replace

cd "$Odata/英文文献-公司层面/分析师预测准确度"
use "分析师预测准确度.dta", clear
cd "$Data"
save "分析师预测准确度.dta", replace

*合并
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "分析师作用.dta"
drop _merge
merge 1:1 stock year using "融资融券.dta", keep(match master)
drop _merge
merge 1:1 stock year using "业绩对赌.dta"
drop _merge
merge 1:1 stock year using "报刊财经新闻合并数据.dta"
drop _merge
merge 1:1 stock year using "分析师预测准确度.dta", keep(match master) keepusing(stock year FERR1 FERR2 FOPT1 FOPT2)
drop _merge
label var FERR1 "分析师预测准确度1"
label var FERR2 "分析师预测准确度2"
label var FOPT1 "分析师乐观偏差1"
label var FOPT2 "分析师乐观偏差2"

keep if year>=2012 & year<=2023
replace AnaAttention=0 if missing(AnaAttention) 
replace VAM=0 if missing(VAM) 
replace Financeavailable=0 if missing(Financeavailable)
replace Shortavailable=0 if missing(Shortavailable) 
replace FinNews=0 if missing(FinNews) 
replace NegFinNews=0 if missing(NegFinNews)
replace FERR1=0 if missing(FERR1)
replace FERR2=0 if missing(FERR2)
replace FOPT1=0 if missing(FOPT1)
replace FOPT2=0 if missing(FOPT2)
save "MERGED_DATA.dta", replace

*股票流动性
cd "$Odata/公司研究/股票/个股Amihud指标表(年)142733464(仅供浙江工商大学使用)"
import excel "LIQ_AMIHUD_Y.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
drop if Status!="A"
keep Stkcd Trdynt ILLIQ_Y
rename (Stkcd Trdynt ILLIQ_Y) (stock year Liquidity)
label var Liquidity "股票流动性：个股Amihud指标"
destring _all, replace
duplicates drop stock year, force

cd "$Data"
save "股票流动性.dta", replace

*股价崩盘风险
cd "$Odata/公司研究/股票/股价崩盘指标表(年)150135525(仅供浙江工商大学使用)"
import excel "BF_CRASHRISK.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
drop if Status!="A"
keep Stkcd Trdynt NCSKEW_Cmdos DUVOL_Cmdos
rename (Stkcd Trdynt NCSKEW_Cmdos DUVOL_Cmdos) (stock year NCSKEW DUVOL)
label var NCSKEW "股票崩盘风险：NCSKEW指标"
label var DUVOL "股票崩盘风险：DUVOL指标"
destring _all, replace
duplicates drop stock year, force

cd "$Data"
save "股价崩盘风险.dta", replace

*沪港通/深港通标的
cd "$Odata/公司研究/股票/沪港通与深港通标的证券基本信息表142924697(仅供浙江工商大学使用)"
import excel "STK_MKTLINK_STOCKINFO.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
drop if ExchangeCode=="HKEX"
gen abs_date = date(AbsorbedDate, "YMD")
gen rem_date = date(RemovedDate, "YMD")
format abs_date rem_date %td
gen start_year = year(abs_date)
gen end_year = 2023
* 如果存在调出日期，按年末节点判断当年是否还在名单中
replace end_year = year(rem_date) - 1 if !missing(rem_date) & rem_date < mdy(12, 31, year(rem_date))
replace end_year = year(rem_date) if !missing(rem_date) & rem_date == mdy(12, 31, year(rem_date))
drop if start_year > end_year
gen span = end_year - start_year + 1
expand span
bysort Symbol AbsorbedDate: gen year = start_year + _n - 1
gen SC = 1
rename Symbol stock
keep stock year SC
duplicates drop stock year, force
destring _all, replace
keep if year>=2012 & year<=2023
label var SC "若股票在当年底为深港通/沪港通标的股票，取1"
sort stock year

cd "$Data"
save "沪港通深港通标的股票.dta", replace

*合并
cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "股票流动性.dta", keep(match master)
drop _merge
merge 1:1 stock year using "股价崩盘风险.dta"
drop _merge
merge 1:1 stock year using "沪港通深港通标的股票.dta", keep(match master)
drop _merge
replace SC=0 if missing(SC) & !missing(IndustryCode)
save "MERGED_DATA.dta", replace

*------------------------------------------
* 上下游特征
*------------------------------------------ 
*供应链集中度
cd "$Odata/中文文献-公司层面/供应链集中度/供应链集中度指标表152539327(仅供天津财经大学使用)"
import excel "SC_ConcentrationIndex.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
gen year = substr(EndDate,1,4)
destring _all, replace
drop if StateTypeCode!=1
rename Symbol stock
keep stock year TopCustomerToTotalRatio TopPurchaseToTotalRatio CustomerConcentration PurchaseConcentration CustomerConcentrationHHI PurchaseConcentrationHHI
rename (TopCustomerToTotalRatio TopPurchaseToTotalRatio CustomerConcentration PurchaseConcentration CustomerConcentrationHHI PurchaseConcentrationHHI) (Big1Customer Big1Supplier CustomerCT SupplierCT CustomerHHI SupplierHHI)
duplicates drop stock year, force
keep if year>=2012 & year<=2023

cd "$Data"
save "供应链集中度.dta", replace

cd "$Data"
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "供应链集中度.dta", keep(match master)
drop _merge
save "MERGED_DATA.dta", replace

*供应链地理临近性
cd "$Odata/英文文献-公司层面/与供应商、客户的临近性"
import excel "与供应商临近性.xlsx", firstrow clear
keep Symbol EndDate Distance
drop in 1/2
rename (Symbol Distance) (stock SupDistance)
label var SupDistance  "与供应商距离：上市公司与其客户/供应商空间距离加1的自然对数，再取其相反数。"
gen year = substr(EndDate,1,4)
drop EndDate
destring _all, replace
cd "$Data"
save "与供应商临近性.dta", replace

cd "$Odata/英文文献-公司层面/与供应商、客户的临近性"
import excel "与客户临近性.xlsx", firstrow clear
keep Symbol EndDate Distance
drop in 1/2
rename (Symbol Distance) (stock CusDistance)
label var CusDistance  "与客户距离：上市公司与其客户/供应商空间距离加1的自然对数，再取其相反数。"
gen year = substr(EndDate,1,4)
drop EndDate
destring _all, replace
cd "$Data"
save "与客户临近性.dta", replace

cd "$Data"
use "MERGED_DATA.dta", clear
duplicates drop stock year, force
merge 1:1 stock year using "与供应商临近性.dta"
drop _merge
merge 1:1 stock year using "与客户临近性.dta"
drop _merge

keep if year>=2012 & year<=2023
save "MERGED_DATA.dta", replace

*------------------------------------------
* 行业特征
*------------------------------------------ 

*行业僵尸企业比例
cd "$Odata/行业层面/僵尸企业"
use "僵尸企业结果.dta", clear
cd "$Data"
save "僵尸企业结果.dta", replace
use "MERGED_DATA.dta", clear
merge 1:1 stock year using "僵尸企业结果.dta", keep(match master) keepusing(stock year 僵尸企业)
gen Zombie_Assets = 僵尸企业 * TotalAssetsori
bysort IndustryCode_sw year: egen Ind_Zombie_Assets = sum(Zombie_Assets)
bysort IndustryCode_sw year: egen Ind_Total_Assets = sum(TotalAssetsori)
gen Zombie_Ratio = Ind_Zombie_Assets / Ind_Total_Assets
drop Zombie_Assets Ind_Zombie_Assets Ind_Total_Assets 僵尸企业
label var Zombie_Ratio "本年公司所在行业的僵尸企业比例(资产加权)"
drop _merge
xtset stock year
save "MERGED_DATA.dta", replace

*行业赫芬达尔指数
cd "$Odata/行业层面/赫芬达尔指数表141444580(仅供vip使用)"
import excel "INDFI_HHI.xlsx", firstrow clear
labone, nrow(1)
drop in 1/2
destring Markettype ST IsNewOrSuspend, replace
keep if regexm(EndDate,"-12-31") & Markettype==117 & ST==1 & IsNewOrSuspend==1
gen year = substr(EndDate,1,4)
duplicates drop IndustryCode year, force
keep IndustryCode year HHI_A HHI_B HHI_C HHI_D
destring _all, replace
label var HHI_A "行业赫芬达尔指数A"
label var HHI_B "行业赫芬达尔指数B"
label var HHI_C "行业赫芬达尔指数C"
label var HHI_D "行业赫芬达尔指数D"
cd "$Data"
save "行业赫芬达尔指数.dta", replace

use "MERGED_DATA.dta", clear
merge m:1 IndustryCode year using "行业赫芬达尔指数.dta", keep(match master)
drop _merge
sort stock year
save "MERGED_DATA.dta", replace

use "MERGED_DATA.dta", clear
drop PurchasePayment
order stock year
order TotalAssets, after(year)
order IndustryName IndustryCode IndustryCode_sw Lng Lat LISTINGDATE PROVINCECODE PROVINCE CITYCODE CITY TotalRevenue TotalAssetsori, after(HHI_D)
drop if year<2012|year>2023
rename(ROA1 ProfitMargin1 Growth1 EV1 FERR1 FOPT1 HHI_D) (ROA ProfitMargin Growth EV FERR FOPT HHI)
save "MERGED_DATA.dta", replace
