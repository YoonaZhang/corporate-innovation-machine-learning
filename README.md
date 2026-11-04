# The Determinants of Corporate Innovation: A Machine Learning Approach

An undergraduate research project integrating innovation determinants from accounting, finance and management within a stakeholder-based framework. The study uses machine learning to compare which firm and stakeholder characteristics are most informative for predicting future R&D investment and invention patent output.

## Project at a glance

| Component | Scope |
| --- | --- |
| Data | CSMAR and CNRDS; Chinese A-share listed companies, 2012-2024 |
| Analytical sample | 13,611 firm-year observations |
| Features | 75 predictors across 11 categories |
| Models | Gradient-boosted regression trees, random forests and OLS |
| Evaluation | Forward-expanding time splits; out-of-sample R², MSE, RMSE and MAE |
| Interpretation | SHAP feature and group importance, dependence patterns, interactions and temporal analysis |

## Main findings

GBRT performed best for both targets, with out-of-sample R² of **0.5428 for R&D investment intensity** and **0.4478 for invention patent output** (thesis, Table 4-2).

The analysis identified different predictive patterns across the innovation process: employee and board characteristics were particularly informative for R&D inputs, while management, stock-market and supply-chain characteristics were more prominent for patent output. Firm fundamentals and government-related features were important across both targets.

See the [research overview](docs/research-overview.md) for the research objectives, methodology, results and figures.

## Materials

| Material | Link |
| --- | --- |
| Undergraduate thesis | [Read the thesis PDF](paper/corporate_innovation_thesis.pdf) |
| Python analysis notebook | [Models and SHAP analysis](notebooks/corporate_innovation_models.ipynb) |
| Stata preparation scripts | [Data preparation](stata/) |
| Research overview | [Objectives, methodology and findings](docs/research-overview.md) |
| Research figures | [Figures](figures/) |

## Data availability

The underlying research uses third-party database materials. Raw exports and merged research datasets are not redistributed in this repository. The thesis and figures present the research findings; the notebook and scripts provide supporting analytical code.

## Author

Yunyi Zhang, Beijing Institute of Technology. Undergraduate thesis, 2026.
