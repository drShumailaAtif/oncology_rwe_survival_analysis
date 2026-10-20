# Oncology RWE: Treatment Patterns and Overall Survival in Lung Cancer

## Project overview
This portfolio project demonstrates a reproducible R workflow for an observational oncology real-world evidence (RWE) study using **synthetic data only**. It is designed for practice and interview discussion, not clinical decision-making.

## Aim
Construct an eligible lung cancer cohort from a patient registry and longitudinal treatment records, describe baseline characteristics, and explore overall survival by initial treatment group.

## Objectives
- Validate patient-level and longitudinal records.
- Apply eligibility criteria (age >=18, lung cancer, qualifying treatment in 2022).
- Identify each patient's first qualifying treatment and index date.
- Flag same-day ties between treatment groups instead of arbitrarily assigning exposure.
- Link patient-level registry data to treatment records.
- Calculate follow-up, death-event status, and censoring.
- Produce descriptive summaries, Kaplan-Meier curves, and an exploratory log-rank test.
- Document design limitations and potential biases.

## Study design
- Population: adults with lung cancer.
- Exposure: first qualifying Treatment A or Treatment B record in calendar year 2022.
- Index date: date of first qualifying treatment in 2022.
- Outcome: overall survival (OS), from index date to death or censoring.
- Administrative end: 2024-12-31.
- Data: synthetic, created for this portfolio.

## Files
- `data/patient_registry.csv`: one row per synthetic patient.
- `data/treatment_records.csv`: longitudinal treatment records; patients may have multiple rows.
- `R/oncology_rwe_analysis.R`: complete analysis script.
- `outputs/`: generated results after running the script.
- `docs/analysis_plan.md`: short protocol/analysis plan.

## Run the analysis
1. Install R and RStudio.
2. Open the project folder as your working directory.
3. Install required packages once:
   ```r
   install.packages(c("dplyr", "survival", "ggplot2"))
   ```
4. Run:
   ```r
   source("R/oncology_rwe_analysis.R")
   ```
5. Review the generated CSV and PNG files in `outputs/`.

## Key outputs
- `analytic_cohort.csv`: one row per included patient.
- `cohort_attrition.csv`: counts at key cohort-building steps.
- `treatment_tie_review.csv`: patients whose earliest date contains both treatments.
- `baseline_summary.csv`: descriptive summary by treatment group.
- `kaplan_meier_survival.png`: Kaplan-Meier plot when analysis conditions are met.
- `logrank_test.csv`: exploratory log-rank test when conditions are met.

## Interpretation and limitations
- The sample is intentionally small and synthetic.
- Treatment groups are not randomized; measured and unmeasured confounding may affect comparisons.
- A log-rank p-value is not proof of a treatment effect.
- This project does not estimate a causal effect and is not suitable for clinical conclusions.
- Propensity-score modelling is intentionally not included because this small sample is inadequate for a credible model.
- Immortal time bias is reduced by starting follow-up at treatment initiation, but correct alignment of eligibility, exposure assignment, and time zero remains essential.
- Real-world studies also need a prespecified protocol, data provenance, code-list validation, missing-data assessment, and sensitivity analyses.

## CV wording (use only after you run and review the script)
**Oncology RWE Analysis | R, Survival Analysis**
- Built a reproducible R workflow using synthetic patient registry and longitudinal treatment data.
- Applied eligibility criteria, integrated patient-level and longitudinal records, assigned index dates, and derived follow-up and overall survival variables.
- Produced baseline summaries and exploratory Kaplan-Meier survival analysis.
- Documented study-design limitations, including confounding and potential time-related bias.

Portfolio project using synthetic data only; no real patient or Ontario administrative healthcare data were used.
