# The Determinants of Corporate Innovation: A Machine Learning Approach

Research materials on predicting corporate innovation and comparing the relative importance of firm and stakeholder characteristics.

## Research approach

- Construct firm-level variables informed by research literature and a stakeholder framework.
- Compare gradient-boosted regression trees, random forests and an OLS baseline.
- Evaluate out-of-sample performance using expanding training windows and later test years.
- Use SHAP to examine predictive contributions and heterogeneous relationships.

Predictive feature importance is interpreted as a property of the fitted models, not as proof of a causal effect.

## Materials

| Material | Link |
| --- | --- |
| Undergraduate thesis | [Read the thesis PDF](paper/corporate_innovation_thesis.pdf) |
| Working Python notebook | [Models and SHAP analysis](notebooks/corporate_innovation_models.ipynb) |
| Stata preparation scripts | [Data preparation](stata/) |
| Research overview | [Methods and project context](docs/research-overview.md) |
| Selected saved figures | [Figures](figures/) |

## Version context

The undergraduate thesis and working notebook are separate research artifacts. They may reflect different iterations, predictor sets, samples and results. The notebook and earlier notes should not be assumed to reproduce every thesis table. A single reconciled replication release has not yet been prepared.

The notebook is provided as a working code artifact with source-data previews and outputs removed. Selected aggregate figures are preserved separately. Local paths have been changed to relative placeholders; the models have not been rerun for this upload.

## Data availability

The underlying research uses third-party database materials. Raw exports, merged `.dta` files and spreadsheet datasets are not included. Local source data can be stored in the ignored `data` folder using the original authorized access route.

## Attribution

The PDF is the undergraduate thesis supplied by Yunyi Zhang. The wider Corporate Innovation Research Program involved collaborative research; the presence of a file in this repository does not imply sole ownership of every upstream input or research task. The code, methods and thesis are presented with their respective version context.
