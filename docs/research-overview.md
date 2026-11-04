# Research overview

## Objective

Research on corporate innovation is spread across accounting, finance and management, with many studies examining individual factors through a single theoretical perspective. This study integrates those perspectives within a unified stakeholder-based framework to answer a broader question: **which firm characteristics and stakeholder groups are most informative for predicting future corporate innovation, and how does their importance differ between innovation inputs and outputs?**

The study combines a systematic review of innovation determinants with tree-based machine learning and SHAP analysis. Its objectives are to:

1. **Build a comprehensive analytical framework** that brings firm fundamentals and internal and external stakeholder characteristics into a common feature set.
2. **Compare predictive contributions** across individual features and stakeholder groups, examining the information they provide for future R&D investment and invention patent output alongside the firm's underlying resource base.
3. **Translate model findings into practical priorities** by examining nonlinear patterns, interactions and changes in feature importance over time, informing innovation resource allocation, corporate governance and policy design.

## Data and measures

| Component | Definition |
| --- | --- |
| Data sources | CSMAR and CNRDS |
| Source sample | Chinese A-share listed companies, 2012-2024 |
| Final analytical sample | 13,611 firm-year observations |
| Predictors | 75 variables organized into 11 categories |
| Innovation input | Next-year R&D expenditure divided by sales |
| Innovation output | Natural logarithm of next-year invention patent applications plus one |

The feature categories cover firm fundamentals; management, employees, shareholders and boards; and creditors, stock markets, information intermediaries, industry, supply chains and government. Observations with missing predictor or target values are excluded, and continuous variables are winsorized at the 1st and 99th percentiles.

## Analytical workflow

1. **Literature review and feature construction.** Synthesize innovation determinants across disciplines, organize them within the stakeholder framework, and construct the corresponding firm-year variables.
2. **Predictive modeling.** Compare gradient-boosted regression trees (GBRT), random forests (RF) and an ordinary least squares (OLS) baseline. Tune tree-model hyperparameters using grid search.
3. **Time-based evaluation.** Use a forward-expanding training window with later-year test samples. The first split trains on 2012-2014 and tests on 2016, retaining a one-year gap to separate the next-year training outcomes from the test-period features. Report out-of-sample R², MSE, RMSE and MAE.
4. **Model interpretation.** Use SHAP-based relative importance scores to compare individual features and feature groups. Examine SHAP dependence patterns, feature interactions and the evolution of importance across test years.

## Key findings

### Predictive performance

GBRT achieved the highest out-of-sample R² and the lowest prediction errors for both targets, followed by RF and then OLS.

| Target | GBRT R² | RF R² | OLS R² |
| --- | ---: | ---: | ---: |
| R&D investment intensity | 0.5428 | 0.5227 | 0.4761 |
| Invention patent output | 0.4478 | 0.4338 | 0.3541 |

*Source: thesis, Table 4-2. The table reports MSE, RMSE and MAE alongside R².*

### Differences between innovation inputs and outputs

- **Firm fundamentals and government-related features** were the two leading feature groups. Government subsidies and effective tax rates were informative for both innovation inputs and outputs.
- **Employees and boards were particularly important for R&D inputs.** Employee compensation and turnover, together with board-level digital strategy, contributed useful predictive information.
- **Management characteristics were more prominent for invention patent output.** Executive compensation incentives and managerial versatility ranked among the important predictors, alongside stock liquidity and supplier concentration.
- **Feature relationships were often nonlinear.** SHAP analysis highlighted thresholds and changing marginal prediction contributions for subsidies, digital transformation, industry concentration and other features. The temporal analysis also examined the growing predictive relevance of executive capabilities, AI-related skills, capital-market features and ESG practices.

These findings help distinguish factors associated with committing resources to innovation from those associated with generating invention patent output. They provide a basis for prioritizing further analysis and considering targeted resource-allocation and governance decisions. SHAP contributions describe the fitted models' predictions; they do not establish causal effects.

## Research figures

### Research contribution

![Research contribution](../figures/1%20research_contribution.png)

### Research methodology

![Research methodology](../figures/2%20research_methodology.png)

### Training and testing sample split

![Training and testing sample split](../figures/3%20training_testing_sample_split.jpg)

### Feature-group importance: figure 1

![Feature-group importance: figure 1](../figures/4%20feature_group_importance_1.jpg)

### Feature-group importance: figure 2

![Feature-group importance: figure 2](../figures/5%20feature_group_importance_2.jpg)

### Individual feature importance

![Individual feature importance](../figures/6%20individual_feature_importance.png)

### Feature SHAP values: figure 1

![Feature SHAP values: figure 1](../figures/7%20feature_shap_value_1.jpg)

### Feature SHAP values: figure 2

![Feature SHAP values: figure 2](../figures/8%20feature_shap_value_2.jpg)

