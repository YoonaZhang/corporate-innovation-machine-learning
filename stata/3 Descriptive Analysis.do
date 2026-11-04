global Data "./data"
global Results "./results"
cd "$Data"
use "MERGED_DATA_Winsor.dta", clear

cd "$Results"

estpost tabstat TotalAssets Age DebtRatio Cashflow Growth ProfitMargin ROA FixedAssetRatio EV OverseasInv OverseasRev MA ESG CEORisk CEODegree IsMBA FinBack CEOAcademicBack Versatility Top3ManageSumSalary CEOIncentive REM IntControl KV Deficiency EmployeeTurnover ESOP Paygap SocInsurance EmployeeSalary InvestorShare Ownstructure MajorShareholders Ownership Litigation VAM Boardsize IndDirectorRatio FemaleDirector DO DCG AISkill DataSkill ChairAcademicBack FC BOND_D BOND_P BankHHI Top3Bank BankCR AnaAttention FinNews NegFinNews FERR FOPT Financeavailable Shortavailable Liquidity NCSKEW DUVOL SC GovSub Dige Gdatact Ipp HTZone EnvSubsidy Enrelcost TaxRate Talent IP_EncImp HHI Zombie_Ratio CustomerHHI SupplierHHI RDCost_t1 InvPatent_t1 if complete_obs == 0, ///
    stats(count mean min max sd) columns(statistics) listwise

esttab using "描述性统计.rtf", replace ///
    cells("count(fmt(%9.0fc)) mean(fmt(%10.3f)) min(fmt(%10.3f)) max(fmt(%10.3f)) sd(fmt(%10.3f))") ///
    collabels("N" "Mean" "Min" "Max" "SD") ///
    noobs nomtitle nonumber ///
    title("描述性统计分析")
