# Short Analysis Plan

## Research question
Among synthetic adults with lung cancer who initiate Treatment A or Treatment B in 2022, what are the cohort characteristics and exploratory overall-survival patterns by initial treatment group?

## Eligibility
Include patients aged 18 or older with lung cancer and at least one Treatment A/B record dated 2022-01-01 through 2022-12-31. The first qualifying treatment record defines the index date. If both treatments appear on the same earliest date, flag the patient for review and exclude from the primary comparison rather than choosing arbitrarily.

## Exposure
Initial qualifying treatment group (Treatment A versus Treatment B).

## Outcome
Overall survival from index date to death or censoring. Censor at the earlier of last known contact and 2024-12-31. Count a death event only when death is on/after index and by the observation end date.

## Analysis
1. Validate IDs, duplicates, dates, and missingness.
2. Summarize cohort attrition.
3. Describe age, sex, death counts, and follow-up by treatment group.
4. Plot Kaplan-Meier curves.
5. Conduct an exploratory log-rank test if there are two groups and at least one event.

## Limitations
Synthetic, small sample; no causal inference; potential confounding; no propensity-score model; results are for programming practice only.
