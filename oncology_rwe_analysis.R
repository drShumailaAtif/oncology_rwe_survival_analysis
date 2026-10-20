# Oncology RWE: Treatment Patterns and Overall Survival in Lung Cancer
# Synthetic portfolio project only. No real patient data are used.
# Run this script from the project root directory.
# 1. Clear environment (fresh start)
rm(list = ls())

# 2. Clear console
cat("\014")

# 3. Set working directory (EDIT THIS PATH)
# Example for Mac:
# setwd("/Users/shumailaatif/Desktop/oncology_rwe_survival_analysis")

# 4. Confirm working directory
getwd()



# 5. Create project folders (if not already created)

folders <- c(
  "data",
  "R",
  "outputs",
  "docs"
)

for (folder in folders) {
  dir.create(folder, showWarnings = FALSE, recursive = TRUE)
}

getwd()
list.files()
list.files("data")
list.files("R")

```r
# 6. Define packages required for this project
packages <- c("dplyr", "survival", "ggplot2")

# 7. Install packages only if they are missing
installed <- rownames(installed.packages())

missing_packages <- packages[!(packages %in% installed)]

if (length(missing_packages) > 0) {
  install.packages(missing_packages)
}

# 8. Load required libraries
invisible(
  lapply(packages, library, character.only = TRUE)
)

# 9. Set seed only if random operations are used
# set.seed(20260422)

# 10. Optional: avoid scientific notation in printed numbers
options(scipen = 999)
```


# 1. Import data -------------------------------------------------------------
registry <- read.csv("data/patient_registry.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))
treatments <- read.csv("data/treatment_records.csv", stringsAsFactors = FALSE, na.strings = c("", "NA"))

date_cols_registry <- c("diagnosis_date", "death_date", "last_contact")
registry[date_cols_registry] <- lapply(registry[date_cols_registry], as.Date)
treatments$treatment_date <- as.Date(treatments$treatment_date)

admin_end <- as.Date("2024-12-31")
study_start <- as.Date("2022-01-01")
study_end <- as.Date("2022-12-31")

# 2. Basic data-quality checks ------------------------------------------------
cat("\\n--- Data checks ---\\n")
cat("Registry rows:", nrow(registry), "\\n")
cat("Treatment rows:", nrow(treatments), "\\n")
cat("Duplicate registry patient IDs:", sum(duplicated(registry$patient_id)), "\\n")
cat("Duplicate treatment rows:", sum(duplicated(treatments[c("patient_id", "treatment", "treatment_date")])), "\\n")
cat("Registry patients with missing last contact:", sum(is.na(registry$last_contact)), "\\n")

if (anyDuplicated(registry$patient_id)) {
  stop("Registry must contain one row per patient. Resolve duplicate patient IDs before proceeding.")
}

# Normalize categories (example of a common real-world data-cleaning step).
registry <- registry %>%
  mutate(
    sex = case_when(
      tolower(sex) %in% c("f", "female") ~ "Female",
      tolower(sex) %in% c("m", "male") ~ "Male",
      TRUE ~ "Unknown"
    ),
    cancer_type = trimws(cancer_type)
  )

# 3. Define eligible treatment starts in 2022 --------------------------------
# Inclusion: age >=18, lung cancer, and >=1 Treatment A/B record dated in 2022.
eligible_patients <- registry %>%
  filter(age >= 18, tolower(cancer_type) == "lung") %>%
  select(patient_id, age, sex, cancer_type, diagnosis_date, death_date, last_contact)

qualifying_treatments <- treatments %>%
  filter(
    treatment %in% c("Treatment A", "Treatment B"),
    treatment_date >= study_start,
    treatment_date <= study_end
  ) %>%
  inner_join(eligible_patients %>% select(patient_id), by = "patient_id")

# Identify the earliest qualifying date per patient.
first_date <- qualifying_treatments %>%
  group_by(patient_id) %>%
  summarise(index_date = min(treatment_date), .groups = "drop")

earliest_records <- qualifying_treatments %>%
  inner_join(first_date, by = "patient_id") %>%
  filter(treatment_date == index_date)

# If both treatments start on the same earliest date, don't choose arbitrarily.
tie_review <- earliest_records %>%
  group_by(patient_id, index_date) %>%
  summarise(
    treatments_on_index = paste(sort(unique(treatment)), collapse = " + "),
    n_treatments_on_index = n_distinct(treatment),
    .groups = "drop"
  ) %>%
  filter(n_treatments_on_index > 1)

write.csv(tie_review, "outputs/treatment_tie_review.csv", row.names = FALSE)

unambiguous_index <- earliest_records %>%
  anti_join(tie_review %>% select(patient_id), by = "patient_id") %>%
  distinct(patient_id, index_date, treatment)

cohort <- eligible_patients %>%
  inner_join(unambiguous_index, by = "patient_id") %>%
  mutate(
    treatment_group = factor(treatment, levels = c("Treatment A", "Treatment B")),
    admin_end = admin_end,
    # A death counts as an event only if it occurs on/after index and by the
    # earlier of last contact and administrative end.
    observation_end = pmin(last_contact, admin_end, na.rm = TRUE),
    death_event = !is.na(death_date) &
      death_date >= index_date &
      death_date <= observation_end,
    followup_end = if_else(death_event, death_date, observation_end),
    followup_days = as.numeric(followup_end - index_date),
    followup_months = followup_days / 30.4375,
    event_label = if_else(death_event, "Death", "Censored")
  ) %>%
  filter(!is.na(followup_days), followup_days >= 0)

# 4. Save cohort and summarize attrition --------------------------------------
write.csv(cohort, "outputs/analytic_cohort.csv", row.names = FALSE)

attrition <- data.frame(
  step = c(
    "All registry patients",
    "Adults with lung cancer",
    "Adults with lung cancer with a qualifying 2022 treatment",
    "After excluding ambiguous same-day treatment ties",
    "Final cohort with non-negative follow-up"
  ),
  n = c(
    nrow(registry),
    nrow(eligible_patients),
    n_distinct(qualifying_treatments$patient_id),
    nrow(unambiguous_index),
    nrow(cohort)
  )
)
write.csv(attrition, "outputs/cohort_attrition.csv", row.names = FALSE)

cat("\\n--- Cohort attrition ---\\n")
print(attrition)
cat("\\n--- Treatment groups ---\\n")
print(cohort %>% count(treatment_group, name = "n"))
cat("\\n--- Outcome counts ---\\n")
print(cohort %>% count(treatment_group, event_label, name = "n"))

# 5. Baseline descriptive summary ---------------------------------------------
baseline_summary <- cohort %>%
  group_by(treatment_group) %>%
  summarise(
    n = n(),
    mean_age = round(mean(age, na.rm = TRUE), 1),
    sd_age = round(sd(age, na.rm = TRUE), 1),
    median_age = median(age, na.rm = TRUE),
    female_n = sum(sex == "Female", na.rm = TRUE),
    deaths_n = sum(death_event, na.rm = TRUE),
    median_followup_months = round(median(followup_months, na.rm = TRUE), 1),
    .groups = "drop"
  )
write.csv(baseline_summary, "outputs/baseline_summary.csv", row.names = FALSE)
cat("\\n--- Baseline summary ---\\n")
print(baseline_summary)

# 6. Kaplan-Meier overall survival -------------------------------------------
# OS time starts at the qualifying treatment index date.
# With a small synthetic sample, treat results as exploratory only.
if (nrow(cohort) > 0 && sum(cohort$death_event) > 0 && n_distinct(cohort$treatment_group) > 1) {
  km_fit <- survfit(Surv(followup_days, death_event) ~ treatment_group, data = cohort)

  # Save a simple KM plot with confidence intervals and risk table omitted
  # to keep the output dependable across ggplot2/survival versions.
  km_summary <- summary(km_fit)
  km_points <- data.frame(
    time = km_summary$time,
    surv = km_summary$surv,
    strata = km_summary$strata
  )

  km_plot <- ggplot(km_points, aes(x = time / 30.4375, y = surv, color = strata)) +
    geom_step(linewidth = 0.9) +
    labs(
      title = "Overall survival by initial treatment group",
      subtitle = "Synthetic data; exploratory analysis only",
      x = "Months since index date",
      y = "Overall survival probability",
      color = "Treatment group"
    ) +
    coord_cartesian(ylim = c(0, 1)) +
    theme_minimal(base_size = 12)

  ggsave("outputs/kaplan_meier_survival.png", plot = km_plot, width = 8, height = 5, dpi = 300)

  logrank <- survdiff(Surv(followup_days, death_event) ~ treatment_group, data = cohort)
  logrank_p <- pchisq(logrank$chisq, df = length(logrank$n) - 1, lower.tail = FALSE)
  logrank_results <- data.frame(
    test = "Log-rank test",
    chisq = unname(logrank$chisq),
    df = length(logrank$n) - 1,
    p_value = logrank_p
  )
  write.csv(logrank_results, "outputs/logrank_test.csv", row.names = FALSE)
  cat("\\n--- Log-rank test (exploratory) ---\\n")
  print(logrank_results)
} else {
  message("KM/log-rank not run: cohort needs both treatment groups and at least one death event.")
}

# 7. Reproducibility notes -----------------------------------------------------
cat("\\nAnalysis complete. Outputs saved in the outputs/ folder.\\n")
cat("Important: all data are synthetic. Do not interpret group differences causally.\\n")
