global Data "./data"
global Results "./results"

cd "$Data"
use "MERGED_DATA.dta", clear

* 筛选所有x、y均不为0的观测值
egen complete_obs = rowmiss(TotalAssets Age DebtRatio Cashflow Growth ProfitMargin ROA FixedAssetRatio EV OverseasInv OverseasRev MA ESG CEORisk CEODegree IsMBA FinBack CEOAcademicBack Versatility Top3ManageSumSalary CEOIncentive REM IntControl KV Deficiency EmployeeTurnover ESOP Paygap SocInsurance EmployeeSalary InvestorShare Ownstructure MajorShareholders Ownership Litigation VAM Boardsize IndDirectorRatio FemaleDirector DO DCG AISkill DataSkill ChairAcademicBack FC BOND_D BOND_P BankHHI Top3Bank BankCR AnaAttention FinNews NegFinNews FERR FOPT Financeavailable Shortavailable Liquidity NCSKEW DUVOL SC GovSub Dige Gdatact Ipp HTZone EnvSubsidy Enrelcost TaxRate Talent IP_EncImp HHI Zombie_Ratio CustomerHHI SupplierHHI RDCost_t1 InvPatent_t1)

* winsorize处理
global cont_vars TotalAssets DebtRatio Cashflow Growth Growth2 ProfitMargin ProfitMargin2 ROA ROA2 ROA3 FixedAssetRatio EV EV2 OverseasRev IsMBA FinBack IntControl KV CEOIncentive Versatility Top3ManageSumSalary REM EmployeeTurnover EmployeeSalary SocInsurance Paygap InvestorShare Ownstructure FemaleDirector IndDirectorRatio FC SupDistance CusDistance BOND_P BankHHI Top3Bank Liquidity NCSKEW DUVOL CustomerCT SupplierCT ShortCR LongCR BankCR GovSub EnvSubsidy Enrelcost TaxRate Ipp Talent Dige HHI Zombie_Ratio CustomerHHI SupplierHHI RDCost_t1

foreach var in $cont_vars {
    cap confirm numeric variable `var'
    if !_rc {
        winsor2 `var', cuts(1 99) replace
    }
}

global cat_vars Deficiency DO Boardsize MajorShareholders Ownership DCG AISkill DataSkill Age CEORisk CEODegree CEOAcademicBack ESOP AnaAttention Financeavailable Shortavailable ESG Litigation MA OverseasInv FinNews NegFinNews VAM ChairAcademicBack HTZone Gdatact BOND_D SC Invia_t1 Invja_t1 InvPatent_t1 Sumia_t1 Sumja_t1 SumPatent_t1

cd "$Data"
save "MERGED_DATA_Winsor.dta", replace
