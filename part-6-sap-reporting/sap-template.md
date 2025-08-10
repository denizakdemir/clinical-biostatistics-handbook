# Statistical Analysis Plan Template

## Document Control Information

**Statistical Analysis Plan for:**  
**Study Title:** [Full Study Title]  
**Protocol Number:** [Protocol ID]  
**Sponsor:** [Sponsor Name]  
**SAP Version:** [X.X]  
**SAP Date:** [DD-MMM-YYYY]  

---

## Table of Contents

1. [Administrative Information](#1-administrative-information)
2. [Study Overview](#2-study-overview)
3. [Study Objectives and Endpoints](#3-study-objectives-and-endpoints)
4. [Study Design](#4-study-design)
5. [Statistical Methodology](#5-statistical-methodology)
6. [Analysis Populations](#6-analysis-populations)
7. [Statistical Analysis Methods](#7-statistical-analysis-methods)
8. [Missing Data Handling](#8-missing-data-handling)
9. [Safety Analyses](#9-safety-analyses)
10. [Data Presentation](#10-data-presentation)
11. [Quality Assurance](#11-quality-assurance)
12. [References](#12-references)
13. [Appendices](#13-appendices)

---

## 1. Administrative Information

### 1.1 Document Information

| Item | Details |
|------|----------|
| **Protocol Title** | [Insert full protocol title] |
| **Protocol Number** | [Insert protocol number/identifier] |
| **Protocol Version** | [Version X.X dated DD-MMM-YYYY] |
| **SAP Version** | [Version X.X] |
| **SAP Date** | [DD-MMM-YYYY] |
| **Sponsor** | [Sponsor company name] |
| **CRO** | [Contract research organization if applicable] |
| **Regulatory Status** | [Phase of development] |
| **GCP Compliance** | This study will be conducted in compliance with ICH-GCP |

### 1.2 SAP Development Team

| Role | Name | Affiliation | Signature | Date |
|------|------|-------------|-----------|------|
| **Lead Statistician** | [Name] | [Company] | | |
| **Statistical Programmer** | [Name] | [Company] | | |
| **Clinical Lead** | [Name] | [Company] | | |
| **Data Management Lead** | [Name] | [Company] | | |
| **Regulatory Affairs** | [Name] | [Company] | | |
| **Quality Assurance** | [Name] | [Company] | | |

### 1.3 Amendment History

| Version | Date | Description of Changes | Reason for Change |
|---------|------|----------------------|-------------------|
| 1.0 | DD-MMM-YYYY | Initial version | Original SAP |
| 1.1 | DD-MMM-YYYY | [Describe changes] | [Rationale] |
| 1.2 | DD-MMM-YYYY | [Describe changes] | [Rationale] |

### 1.4 Key Milestones

| Milestone | Planned Date | Actual Date | Comments |
|-----------|--------------|-------------|----------|
| First Subject Screened | DD-MMM-YYYY | | |
| First Subject Randomized | DD-MMM-YYYY | | |
| Last Subject Randomized | DD-MMM-YYYY | | |
| Last Subject Last Visit | DD-MMM-YYYY | | |
| Database Lock | DD-MMM-YYYY | | |
| SAP Finalization | DD-MMM-YYYY | | |
| Statistical Analysis Completion | DD-MMM-YYYY | | |
| Clinical Study Report | DD-MMM-YYYY | | |

---

## 2. Study Overview

### 2.1 Study Background and Rationale

[Provide brief background on the therapeutic area, unmet medical need, and rationale for the current study. Include relevant information about the investigational product and target indication.]

**Key Background Points:**
- Disease background and epidemiology
- Current treatment landscape
- Investigational product mechanism of action
- Previous clinical experience
- Regulatory guidance considerations

### 2.2 Study Design Summary

**Study Type:** [e.g., Randomized, double-blind, placebo-controlled, parallel-group study]

**Study Phase:** [Phase I/II/III/IV]

**Study Population:** [Brief description of target population]

**Sample Size:** [Planned number of subjects]

**Study Duration:** 
- Screening Period: [X weeks]
- Treatment Period: [X weeks/months]
- Follow-up Period: [X weeks/months]
- Total Study Duration: [X months/years]

**Randomization:** [Description of randomization scheme]

**Blinding:** [Description of blinding procedures]

### 2.3 Investigational Products

| Treatment Arm | Description | Dose/Regimen | Route | Frequency |
|---------------|-------------|--------------|-------|----------|
| **Active Treatment** | [Drug name] | [Dose] | [Route] | [Frequency] |
| **Control/Placebo** | [Control description] | [Dose if applicable] | [Route] | [Frequency] |
| **Comparator** | [If applicable] | [Dose] | [Route] | [Frequency] |

---

## 3. Study Objectives and Endpoints

### 3.1 Primary Objective

**Objective:** [State the primary study objective clearly and concisely]

**Primary Endpoint:**
- **Variable:** [Specify the primary endpoint variable]
- **Timing:** [When the endpoint is assessed]
- **Population:** [Analysis population for primary analysis]
- **Method:** [Statistical method to be used]

**Example:**
```
Objective: To evaluate the efficacy of [Drug X] compared to placebo in reducing 
[specific outcome] in patients with [indication].

Primary Endpoint: Change from baseline in [specific measure] at Week 12 in the 
Intent-to-Treat (ITT) population.
```

### 3.2 Secondary Objectives

**Secondary Objective 1:** [State objective]
- **Endpoint:** [Specific endpoint description]
- **Timing:** [Assessment timing]
- **Analysis:** [Statistical approach]

**Secondary Objective 2:** [State objective]
- **Endpoint:** [Specific endpoint description] 
- **Timing:** [Assessment timing]
- **Analysis:** [Statistical approach]

**[Continue for all secondary objectives]**

### 3.3 Exploratory Objectives

**Exploratory Objective 1:** [State objective]
- **Endpoint:** [Specific endpoint description]
- **Analysis:** [Descriptive or exploratory approach]

**Exploratory Objective 2:** [State objective]
- **Endpoint:** [Specific endpoint description]
- **Analysis:** [Descriptive or exploratory approach]

### 3.4 Safety Objectives

**Safety Objective:** To evaluate the safety and tolerability of [Drug X] in the study population

**Safety Endpoints:**
- Treatment-emergent adverse events (TEAEs)
- Serious adverse events (SAEs)
- Adverse events leading to study drug discontinuation
- Deaths
- Clinical laboratory assessments
- Vital signs
- Physical examinations
- [Other safety assessments as applicable]

---

## 4. Study Design

### 4.1 Study Schema

```
                    SCREENING           TREATMENT PERIOD              FOLLOW-UP
                   (up to 4 weeks)        (12 weeks)                 (4 weeks)
                         │                    │                        │
Subjects    ──────────→  │  ──────────────→  │  ──────────────────→   │
Screened                 │                   │                        │
                         │                   │                        │
            Eligibility  │   Randomization   │    Safety Follow-up    │
            Assessment   │   (1:1:1 ratio)   │                        │
                         │                   │                        │
                         │   ┌─ Placebo      │                        │
                         │   │               │                        │
                         │   ├─ Drug 5mg     │                        │
                         │   │               │                        │
                         │   └─ Drug 10mg    │                        │
                         │                   │                        │
            Visits:   V1 │ V2              V3 │ V4    V5    V6        │ V7
                    Day: -28│ 1            14 │ 28    56    84        │ 112
```

### 4.2 Study Population

#### 4.2.1 Target Population
[Describe the target population for the study]

#### 4.2.2 Key Inclusion Criteria
1. [Inclusion criterion 1]
2. [Inclusion criterion 2]
3. [Inclusion criterion 3]
4. [Continue as needed]

#### 4.2.3 Key Exclusion Criteria
1. [Exclusion criterion 1]
2. [Exclusion criterion 2] 
3. [Exclusion criterion 3]
4. [Continue as needed]

### 4.3 Randomization and Blinding

#### 4.3.1 Randomization Method
- **Randomization Ratio:** [e.g., 1:1:1 for three arms]
- **Randomization Method:** [e.g., Permuted block randomization]
- **Block Size:** [If applicable]
- **Stratification Factors:** [List stratification factors]
  - Factor 1: [e.g., Geographic region (US vs. Non-US)]
  - Factor 2: [e.g., Disease severity (Mild vs. Moderate/Severe)]

#### 4.3.2 Blinding Procedures
- **Blinding Level:** [e.g., Double-blind]
- **Blinded Parties:** [Subjects, investigators, sponsor personnel, etc.]
- **Unblinding Procedures:** [Emergency unblinding procedures]

### 4.4 Sample Size Determination

#### 4.4.1 Sample Size Calculation

**Primary Endpoint Sample Size:**

**Assumptions:**
- Primary endpoint: [Specify endpoint]
- Expected difference: [Effect size]
- Standard deviation: [SD estimate]
- Power: [e.g., 80% or 90%]
- Type I error rate: [e.g., 0.05 two-sided]
- Statistical test: [e.g., Two-sample t-test]

**Calculation:**
```
Sample size per arm: N = 2 × (Z_α/2 + Z_β)² × σ² / δ²

Where:
- Z_α/2 = [value] for α = 0.05 two-sided
- Z_β = [value] for β = 0.20 (80% power)
- σ = [standard deviation]
- δ = [clinically meaningful difference]

Result: N = [calculated sample size] per arm
```

**Accounting for Dropouts:**
- Expected dropout rate: [%]
- Inflated sample size: N / (1 - dropout rate) = [final sample size] per arm
- **Total sample size: [total subjects across all arms]**

#### 4.4.2 Sample Size Justification
[Provide justification for the assumptions used in sample size calculation, including references to literature or previous studies]

---

## 5. Statistical Methodology

### 5.1 General Statistical Principles

#### 5.1.1 Statistical Philosophy
This statistical analysis plan follows the International Conference on Harmonisation (ICH) guidelines, particularly ICH E9 "Statistical Principles for Clinical Trials," and adheres to regulatory guidance from relevant agencies.

#### 5.1.2 Type I and Type II Error Rates
- **Type I Error (α):** 0.05 (two-sided) for primary endpoint
- **Type II Error (β):** 0.20 (Power = 80%) for primary endpoint

#### 5.1.3 Statistical Software
- **Primary Analysis Software:** SAS® Version [X.X] or higher
- **Secondary Software:** R Version [X.X] (if applicable)
- **Graphics Software:** [Specify software for figures]

#### 5.1.4 Missing Data Philosophy
The analysis will follow the principles outlined in the ICH E9(R1) addendum on estimands and sensitivity analysis. The primary analysis will use a likelihood-based approach that provides valid inference under the Missing at Random (MAR) assumption.

### 5.2 Statistical Hypothesis Testing

#### 5.2.1 Primary Hypothesis

**Null Hypothesis (H₀):** [State null hypothesis]  
**Alternative Hypothesis (H₁):** [State alternative hypothesis]  

**Example:**
```
H₀: μ_treatment - μ_control = 0
H₁: μ_treatment - μ_control ≠ 0

Where μ represents the population mean change from baseline in [endpoint] 
at Week 12.
```

#### 5.2.2 Secondary Hypotheses
[List secondary hypotheses in order of importance]

**Secondary Hypothesis 1:**
- H₀: [State null hypothesis]
- H₁: [State alternative hypothesis]

**Secondary Hypothesis 2:**
- H₀: [State null hypothesis] 
- H₁: [State alternative hypothesis]

### 5.3 Multiplicity Considerations

#### 5.3.1 Multiple Comparisons Strategy

**Primary Endpoint:** No adjustment needed as there is a single primary comparison.

**Secondary Endpoints:** [Describe multiplicity adjustment strategy]

**Options:**
1. **Hierarchical Testing:** Test secondary endpoints in pre-specified order, stopping at first non-significant result
2. **Bonferroni Adjustment:** Adjust α level by dividing by number of tests
3. **Holm-Bonferroni Method:** Step-down procedure
4. **False Discovery Rate (FDR):** Control expected proportion of false discoveries

**Selected Strategy:** [Specify chosen method and rationale]

#### 5.3.2 Interim Analysis Considerations
[If applicable, describe interim analysis plans and associated Type I error spending]

---

## 6. Analysis Populations

### 6.1 Population Definitions

#### 6.1.1 Screened Population (SCR)
**Definition:** All subjects who provided informed consent and underwent at least one screening procedure.

**Purpose:** Assess screen failure rates and reasons for screening failures.

#### 6.1.2 Randomized Population (RAND)
**Definition:** All subjects who were randomized to study treatment.

**Inclusion Criteria:** Subject has been assigned a randomization number.

**Purpose:** Baseline demographic and disease characteristic summaries.

#### 6.1.3 Safety Population (SAF) 
**Definition:** All randomized subjects who received at least one dose of study treatment.

**Inclusion Criteria:** 
- Subject was randomized (RANDFL = 'Y')
- Subject received at least one dose of study treatment

**Treatment Assignment:** Based on actual treatment received (as-treated principle)

**Purpose:** All safety analyses.

#### 6.1.4 Intent-to-Treat Population (ITT)
**Definition:** All randomized subjects.

**Inclusion Criteria:**
- Subject was randomized (RANDFL = 'Y')

**Treatment Assignment:** Based on randomized treatment assignment

**Purpose:** Primary efficacy analysis and key secondary efficacy analyses.

#### 6.1.5 Modified Intent-to-Treat Population (mITT)
**Definition:** All randomized subjects with at least one post-baseline efficacy assessment.

**Inclusion Criteria:**
- Subject was randomized (RANDFL = 'Y')
- Subject has at least one post-baseline efficacy measurement

**Treatment Assignment:** Based on randomized treatment assignment

**Purpose:** Supportive efficacy analyses.

#### 6.1.6 Per-Protocol Population (PP)
**Definition:** Subset of ITT population without major protocol deviations.

**Inclusion Criteria:**
- Subject is in ITT population
- No major protocol deviations affecting efficacy evaluation
- Adequate compliance with study treatment (≥80% of planned doses)
- Completed study through Week 12 or discontinued for pre-specified reasons

**Exclusion Criteria:**
- Major inclusion/exclusion criteria violations
- Prohibited concomitant medication use
- <80% treatment compliance
- Poor adherence to study procedures

**Purpose:** Sensitivity analysis for primary efficacy endpoint.

### 6.2 Population Summary

| Population | Primary Use | Treatment Assignment | Key Criteria |
|------------|-------------|---------------------|-------------|
| **ITT** | Primary efficacy | Randomized treatment | All randomized subjects |
| **mITT** | Secondary efficacy | Randomized treatment | ITT + post-baseline data |
| **PP** | Sensitivity analysis | Randomized treatment | ITT + no major deviations |
| **Safety** | Safety analyses | Actual treatment received | Randomized + ≥1 dose |

---

## 7. Statistical Analysis Methods

### 7.1 Demographics and Baseline Characteristics

#### 7.1.1 Analysis Population
**Primary Population:** Randomized Population (RAND)
**Secondary Population:** Safety Population (SAF) for safety-relevant characteristics

#### 7.1.2 Statistical Methods

**Continuous Variables:**
- Descriptive statistics: N, mean, standard deviation, median, quartiles (Q1, Q3), minimum, maximum
- Between-group comparisons: ANOVA or Kruskal-Wallis test (if non-normal)

**Categorical Variables:**
- Frequency counts and percentages
- Between-group comparisons: Chi-square test or Fisher's exact test

**Example SAS Code Structure:**
```sas
/* Continuous variables */
proc means data=adsl n mean std median q1 q3 min max;
    class trt01p;
    var age height weight;
    where randfl = 'Y';
run;

/* Categorical variables */
proc freq data=adsl;
    tables trt01p * (sex race) / chisq;
    where randfl = 'Y';
run;
```

### 7.2 Primary Efficacy Analysis

#### 7.2.1 Primary Endpoint Analysis

**Endpoint:** [Specify primary endpoint]
**Population:** Intent-to-Treat (ITT)
**Timing:** [Assessment timepoint]

**Statistical Model:**

**Analysis of Covariance (ANCOVA) Model:**
```
Y_ijk = μ + τ_i + β₁X_ijk + β₂S_jk + ε_ijk

Where:
- Y_ijk = Primary endpoint value for subject k in treatment i and stratum j
- μ = Overall mean
- τ_i = Treatment effect for treatment i
- β₁ = Coefficient for baseline value (X_ijk)
- β₂ = Coefficient for stratification factor (S_jk) 
- ε_ijk = Random error term
```

**Model Components:**
- **Dependent Variable:** Change from baseline in [primary endpoint]
- **Fixed Effects:** 
  - Treatment group (3 levels: Placebo, Drug 5mg, Drug 10mg)
  - Baseline value of primary endpoint (continuous covariate)
  - Stratification factors: [list factors]
- **Random Effects:** None (fixed effects model)

**Primary Comparisons:**
1. Drug 5mg vs. Placebo
2. Drug 10mg vs. Placebo

**Statistical Inference:**
- Point estimates and 95% confidence intervals for treatment differences
- Two-sided p-values for treatment comparisons
- Overall F-test for treatment effect

**Example SAS Code:**
```sas
proc mixed data=adeff method=reml;
    class usubjid trt01p region;
    model chg = trt01p base region / ddfm=kenwardroger solution;
    
    /* Primary comparisons */
    lsmeans trt01p / pdiff cl alpha=0.05;
    
    /* Specific contrasts */
    contrast 'Drug 5mg vs Placebo' trt01p 1 -1 0;
    contrast 'Drug 10mg vs Placebo' trt01p 0 -1 1;
    
    where ittfl = 'Y' and avisitn = 12;  /* Week 12 analysis */
run;
```

#### 7.2.2 Additional Primary Endpoint Analyses

**Responder Analysis:**
If applicable, define response criteria and analyze proportion of responders using logistic regression.

**Time-to-Event Analysis:**
If primary endpoint is time-to-event, use Kaplan-Meier estimation and Cox proportional hazards model.

### 7.3 Secondary Efficacy Analyses

#### 7.3.1 Secondary Endpoint 1: [Specify endpoint]

**Analysis Population:** [ITT/mITT/PP]
**Statistical Method:** [Specify method]
**Model:** [Describe statistical model]

#### 7.3.2 Secondary Endpoint 2: [Specify endpoint]

**Analysis Population:** [ITT/mITT/PP]
**Statistical Method:** [Specify method]
**Model:** [Describe statistical model]

#### 7.3.3 Longitudinal Analysis

For endpoints measured repeatedly over time:

**Mixed Model for Repeated Measures (MMRM):**
```sas
proc mixed data=adeff method=reml;
    class usubjid trt01p avisit region;
    model chg = trt01p*avisit base*avisit region / ddfm=kenwardroger;
    repeated avisit / subject=usubjid type=un;
    
    /* Treatment comparisons at each visit */
    lsmeans trt01p*avisit / pdiff cl;
    slice trt01p*avisit / sliceby=avisit diff;
run;
```

### 7.4 Subgroup Analyses

#### 7.4.1 Pre-specified Subgroups

Subgroup analyses will be performed for the primary endpoint in the following pre-defined subgroups:

1. **Age Group:** <65 years vs. ≥65 years
2. **Sex:** Male vs. Female  
3. **Geographic Region:** [Define regions]
4. **Disease Severity:** [Define categories]
5. **Baseline [relevant biomarker]:** Above vs. below median

#### 7.4.2 Subgroup Analysis Method

**Statistical Approach:**
- Primary analysis model with subgroup and treatment-by-subgroup interaction terms
- Forest plot presentation of treatment effects by subgroup
- Test for treatment-by-subgroup interaction

**Interpretation:**
- Subgroup analyses are exploratory and descriptive
- No formal statistical testing for multiple subgroups
- Clinical interpretation emphasized over statistical significance

**Example Model:**
```sas
proc mixed data=adeff method=reml;
    class usubjid trt01p region agegroup;
    model chg = trt01p agegroup trt01p*agegroup base region / ddfm=kenwardroger;
    
    /* Test for interaction */
    contrast 'Treatment by Age Interaction' trt01p*agegroup 1 -1 -1 1;
    
    /* Treatment effects by subgroup */
    lsmeans trt01p*agegroup / pdiff cl;
run;
```

### 7.5 Sensitivity Analyses

#### 7.5.1 Per-Protocol Analysis
Repeat primary analysis using Per-Protocol population to assess robustness to protocol deviations.

#### 7.5.2 Complete Case Analysis
Analyze only subjects with complete primary endpoint data at Week 12.

#### 7.5.3 Alternative Imputation Methods
Explore alternative approaches to handling missing data:
- Last Observation Carried Forward (LOCF)
- Multiple imputation with different assumptions
- Pattern-mixture models

#### 7.5.4 Outlier Analysis
Assess impact of extreme values:
- Identify outliers using statistical criteria (e.g., >3 SD from mean)
- Repeat analysis excluding outliers
- Use robust statistical methods (e.g., Wilcoxon rank-sum test)

---

## 8. Missing Data Handling

### 8.1 Missing Data Strategy

#### 8.1.1 Missing Data Assumptions
The primary analysis will assume that missing data are Missing at Random (MAR), meaning that the probability of missing data may depend on observed data but not on unobserved values.

#### 8.1.2 Primary Analysis Approach

**Mixed Model for Repeated Measures (MMRM):**
- Uses all available data without imputation
- Valid under MAR assumption
- Provides appropriate standard errors
- Recommended by regulatory guidelines

#### 8.1.3 Missing Data Assessment

**Missing Data Pattern Analysis:**
- Tabulate patterns of missing data by treatment group
- Assess whether missingness is related to treatment assignment
- Evaluate potential predictors of missing data

**Missing Data Visualization:**
- Missing data pattern plots
- Time-course of dropout rates by treatment
- Reasons for missing data summaries

### 8.2 Sensitivity Analysis for Missing Data

#### 8.2.1 Multiple Imputation

**Multiple Imputation Strategy:**
```sas
/* Multiple imputation */
proc mi data=adeff nimpute=100 seed=54321 out=mi_data;
    class trt01p region sex;
    var chg base age sex region trt01p;
    monotone regression;
run;

/* Analyze each imputed dataset */
proc mixed data=mi_data method=reml;
    by _imputation_;
    class trt01p region;
    model chg = trt01p base region;
    lsmeans trt01p / diff cl;
    ods output diffs=mi_results;
run;

/* Pool results */
proc mianalyze data=mi_results;
    modeleffects estimate;
    stderr stderr;
run;
```

#### 8.2.2 Missing Not at Random (MNAR) Sensitivity Analysis

**Control-Based Imputation:**
Impute missing values assuming subjects behave like control group subjects.

**Jump-to-Reference:**
Assume subjects who discontinue "jump" to reference (placebo) trajectory.

**Tipping Point Analysis:**
Explore range of assumptions about missing data to determine when conclusions would change.

### 8.3 Handling of Specific Missing Data Scenarios

#### 8.3.1 Intermittent Missing Data
- Use MMRM approach which handles intermittent missingness naturally
- Do not impute intermittent missing values

#### 8.3.2 Monotone Missing Data (Dropout)
- Primary analysis uses MMRM (no imputation needed)
- Sensitivity analyses explore different assumptions about post-dropout values

#### 8.3.3 Missing Baseline Values
- Exclude from primary analysis if baseline required as covariate
- Conduct sensitivity analysis including these subjects without baseline adjustment

---

## 9. Safety Analyses

### 9.1 Safety Analysis Population

**Primary Safety Population:** Safety Population (SAF)
- All randomized subjects who received at least one dose of study treatment
- Treatment assignment based on actual treatment received

### 9.2 Safety Analysis Methods

#### 9.2.1 General Approach
- Descriptive statistical summaries
- No formal hypothesis testing (safety analyses are descriptive)
- Focus on clinical relevance rather than statistical significance
- Present point estimates with confidence intervals where appropriate

#### 9.2.2 Statistical Methods for Safety Data

**Binary Safety Outcomes:**
- Frequency counts and percentages
- Risk differences with 95% confidence intervals
- Number needed to harm (NNH) where applicable

**Continuous Safety Parameters:**
- Descriptive statistics (N, mean, SD, median, range)
- Change from baseline analysis
- Shift tables for laboratory parameters

### 9.3 Adverse Events Analysis

#### 9.3.1 Treatment-Emergent Adverse Events (TEAEs)

**Definition:** Adverse events with onset on or after first dose of study treatment and up to [X] days after last dose.

**Analysis Categories:**
- Any TEAE
- TEAEs by severity (mild, moderate, severe)
- TEAEs by relationship to study drug
- Serious adverse events (SAEs)
- TEAEs leading to study drug discontinuation
- TEAEs leading to dose reduction/interruption
- Deaths

#### 9.3.2 Adverse Events by System Organ Class

**MedDRA Coding:**
- System Organ Class (SOC) level analysis
- Preferred Term (PT) level analysis
- Present events occurring in ≥[X]% of subjects in any treatment group

**Statistical Presentation:**
```
Example AE Table Structure:

System Organ Class       Placebo    Drug 5mg   Drug 10mg
Preferred Term           (N=XX)     (N=XX)     (N=XX)
                        n (%)      n (%)      n (%)

Any TEAE                XX (XX.X)  XX (XX.X)  XX (XX.X)

Cardiac disorders       XX (XX.X)  XX (XX.X)  XX (XX.X)
  Palpitations          XX (XX.X)  XX (XX.X)  XX (XX.X)
  Tachycardia          XX (XX.X)  XX (XX.X)  XX (XX.X)

Gastrointestinal disorders XX (XX.X) XX (XX.X) XX (XX.X)
  Nausea               XX (XX.X)  XX (XX.X)  XX (XX.X)
  Diarrhea             XX (XX.X)  XX (XX.X)  XX (XX.X)
```

#### 9.3.3 Adverse Events of Special Interest (AESI)

[Define specific safety topics of interest for the investigational product]

**Pre-defined AESI:**
1. [AESI Category 1]: [Definition and criteria]
2. [AESI Category 2]: [Definition and criteria] 
3. [AESI Category 3]: [Definition and criteria]

**AESI Analysis:**
- Detailed case-by-case review
- Time-to-onset analysis
- Dose-relationship assessment
- Adjudication results (if applicable)

### 9.4 Laboratory Safety Analysis

#### 9.4.1 Clinical Laboratory Parameters

**Analysis Categories:**
- Hematology parameters
- Clinical chemistry parameters  
- Urinalysis parameters
- [Other specialized laboratory assessments]

#### 9.4.2 Laboratory Analysis Methods

**Shift Table Analysis:**
Analyze shifts from baseline normal/abnormal status to post-baseline normal/abnormal status.

**Example Shift Table:**
```
Baseline    Post-baseline Normal Values    Post-baseline Abnormal Values
Status      n (%)                         n (%)

Normal      XX (XX.X)                     XX (XX.X)
Abnormal    XX (XX.X)                     XX (XX.X)
```

**Notable Laboratory Values:**
Identify values meeting pre-defined criteria for clinical concern:
- Values >3× Upper Limit of Normal (ULN)
- Values <0.5× Lower Limit of Normal (LLN)
- Clinically significant changes as defined by investigator

**Change from Baseline Analysis:**
```sas
proc mixed data=adlb method=reml;
    class usubjid trt01a avisit paramcd;
    model chg = trt01a avisit trt01a*avisit base / ddfm=kenwardroger;
    repeated avisit / subject=usubjid type=cs;
    by paramcd;
    
    lsmeans trt01a*avisit / pdiff cl;
run;
```

#### 9.4.3 Liver Safety Assessment

**Hy's Law Criteria:**
Monitor for potential drug-induced liver injury using Hy's Law criteria:
- ALT or AST >3× ULN, AND
- Total bilirubin >2× ULN, AND
- Alkaline phosphatase <2× ULN

### 9.5 Vital Signs and Physical Examinations

#### 9.5.1 Vital Signs Analysis

**Parameters:**
- Systolic and diastolic blood pressure
- Heart rate
- Respiratory rate
- Body temperature
- Body weight

**Statistical Methods:**
- Descriptive statistics by visit and treatment
- Change from baseline analysis
- Categorical analysis of potentially clinically significant changes

#### 9.5.2 Physical Examination
- Summary of abnormal findings by treatment group
- New or worsening abnormalities

### 9.6 Deaths and Other Significant Adverse Events

#### 9.6.1 Deaths
- Individual case narratives
- Summary by treatment group and primary cause
- Time-to-death analysis if applicable
- Relationship to study treatment assessment

#### 9.6.2 Serious Adverse Events
- Detailed listings by treatment group
- Summary by SOC and PT
- Time-to-onset analysis
- Relationship and outcome summaries

---

## 10. Data Presentation

### 10.1 Summary Tables, Listings, and Figures (TLFs)

#### 10.1.1 Table Specifications

All summary tables will follow these general principles:
- Present data by treatment group in columns
- Include appropriate population descriptors in table titles
- Provide footnotes explaining abbreviations and analysis methods
- Use consistent formatting and precision rules

**Precision Rules:**
- Percentages: 1 decimal place (X.X%)
- Means and standard deviations: appropriate precision based on measurement scale
- P-values: 3 decimal places, report as "<0.001" if p<0.001
- Confidence intervals: same precision as point estimates

#### 10.1.2 Demographics and Baseline Tables

**Table 14.1.1: Demographic and Baseline Characteristics**
- Analysis Population: Randomized Population  
- Content: Age, sex, race, ethnicity, geographic region
- Statistics: N, mean (SD), median, range for continuous; n (%) for categorical

**Table 14.1.2: Medical History and Baseline Disease Characteristics**
- Analysis Population: Randomized Population
- Content: Disease duration, severity measures, relevant medical history
- Statistics: Appropriate descriptive statistics by data type

**Table 14.1.3: Prior and Concomitant Medications**
- Analysis Population: Safety Population
- Content: Prior medications by therapeutic class, concomitant medications
- Statistics: n (%) of subjects

#### 10.1.3 Efficacy Tables

**Table 14.2.1: Analysis of Primary Efficacy Endpoint**
- Analysis Population: ITT Population
- Content: LSMEANS, differences, 95% CI, p-values
- Model: ANCOVA with treatment, baseline, and stratification factors

**Table 14.2.2: Analysis of Secondary Efficacy Endpoints**
- Analysis Population: ITT Population (unless otherwise specified)
- Content: Results for each secondary endpoint
- Statistics: Appropriate for endpoint type

**Table 14.2.3: Subgroup Analysis of Primary Efficacy Endpoint**
- Analysis Population: ITT Population
- Content: Treatment effects by pre-defined subgroups
- Presentation: Forest plot format with interaction p-values

#### 10.1.4 Safety Tables

**Table 14.3.1: Treatment Exposure**
- Analysis Population: Safety Population
- Content: Duration of exposure, dose interruptions, compliance
- Statistics: Descriptive summaries

**Table 14.3.2: Overview of Treatment-Emergent Adverse Events**
- Analysis Population: Safety Population
- Content: Any TEAE, severe TEAEs, SAEs, TEAEs leading to discontinuation, deaths
- Statistics: n (%) with 95% confidence intervals

**Table 14.3.3: Treatment-Emergent Adverse Events by System Organ Class**
- Analysis Population: Safety Population
- Content: TEAEs by SOC and PT (events in ≥5% of any treatment group)
- Statistics: n (%) of subjects with events

**Table 14.3.4: Serious Adverse Events**
- Analysis Population: Safety Population
- Content: SAEs by SOC and PT
- Statistics: n (%) of subjects with events

**Table 14.3.5: Clinical Laboratory Parameters - Summary Statistics**
- Analysis Population: Safety Population
- Content: Laboratory parameters by visit
- Statistics: N, mean, SD, median, range

**Table 14.3.6: Clinical Laboratory Parameters - Shift Tables**
- Analysis Population: Safety Population
- Content: Shifts from baseline to worst post-baseline
- Presentation: Normal/abnormal shifts by treatment

#### 10.1.5 Listings

**Listing 16.1.1: Subject Disposition**
- All randomized subjects with study completion status

**Listing 16.1.2: Protocol Deviations**
- All subjects with protocol deviations

**Listing 16.1.3: Demographics and Baseline Characteristics**
- Individual subject data for key demographics

**Listing 16.2.1: Efficacy Data**
- Individual subject efficacy measurements

**Listing 16.2.2: Adverse Events**
- All adverse events by subject

**Listing 16.2.3: Serious Adverse Events**
- Detailed SAE information

**Listing 16.2.4: Deaths**
- Detailed information for all deaths

**Listing 16.2.5: Laboratory Data**
- Laboratory values by subject and visit

#### 10.1.6 Figures

**Figure 14.1: Subject Disposition**
- CONSORT-style flow diagram

**Figure 14.2: Primary Efficacy Endpoint Over Time**
- Mean (±SE) by treatment group and visit

**Figure 14.3: Subgroup Analysis Forest Plot**
- Treatment effects by subgroup with confidence intervals

**Figure 14.4: Kaplan-Meier Plot** (if applicable)
- Survival curves by treatment group

### 10.2 Data Display Conventions

#### 10.2.1 Treatment Group Ordering
Treatment groups will be presented in the following order:
1. Placebo/Control
2. Drug Low Dose
3. Drug High Dose
4. Active Comparator (if applicable)

#### 10.2.2 Missing Data Display
- Missing categorical data: Not reported in denominators
- Missing continuous data: Excluded from statistical calculations, noted in footnotes
- Use "N/A" for not applicable values
- Use "NE" for not estimable values

#### 10.2.3 Statistical Notation
- Use "NS" for not significant (p≥0.05)
- Report exact p-values to 3 decimal places
- Use "<0.001" for very small p-values
- Include 95% confidence intervals where appropriate

---

## 11. Quality Assurance

### 11.1 Data Management Integration

#### 11.1.1 Analysis Dataset Specifications
- Analysis datasets will follow CDISC ADaM standards
- Dataset specifications document will be maintained
- Traceability from SDTM to ADaM will be documented
- Analysis flag derivations will be clearly specified

#### 11.1.2 Database Lock Procedures
- Database lock will occur after data review and query resolution
- Analysis dataset creation will begin after database lock
- Any post-lock changes will be documented and approved

### 11.2 Programming and Validation

#### 11.2.1 Programming Standards
- All programming will follow company standards
- SAS programs will be self-documenting with appropriate comments
- Programs will include headers with purpose, input, output, and modifications
- Version control will be maintained for all programs

#### 11.2.2 Validation Procedures
- Independent programming validation for key analyses
- Code review by qualified statistician
- Output review against table specifications
- Validation documentation will be maintained

#### 11.2.3 Interim Analysis Programming
[If applicable, describe programming procedures for interim analyses]

### 11.3 Review and Approval Process

#### 11.3.1 SAP Review
- Statistical review by lead statistician
- Clinical review by study physician
- Data management review for feasibility
- Regulatory review (if required)
- Final approval by appropriate authorities

#### 11.3.2 Analysis Results Review
- Statistical review of all outputs
- Clinical interpretation review
- Quality control of tables, listings, and figures
- Medical writing review for CSR integration

#### 11.3.3 Documentation Standards
- All analyses will be documented in analysis programs
- Deviations from SAP will be documented and justified
- Analysis assumptions will be clearly stated
- Limitations will be acknowledged

---

## 12. References

1. International Conference on Harmonisation of Technical Requirements for Registration of Pharmaceuticals for Human Use. ICH Harmonised Tripartite Guideline: Statistical Principles for Clinical Trials E9. Current Step 4 version dated 5 February 1998.

2. International Conference on Harmonisation of Technical Requirements for Registration of Pharmaceuticals for Human Use. ICH E9(R1): Addendum on Estimands and Sensitivity Analysis in Clinical Trials to the Guideline on Statistical Principles for Clinical Trials. Step 4 version dated 20 November 2019.

3. International Conference on Harmonisation of Technical Requirements for Registration of Pharmaceuticals for Human Use. ICH Harmonised Tripartite Guideline: Structure and Content of Clinical Study Reports E3. Current Step 4 version dated 30 November 1995.

4. Food and Drug Administration. Guidance for Industry: Statistical Principles for Clinical Trials. September 2019.

5. European Medicines Agency. Guideline on Missing Data in Confirmatory Clinical Trials. EMA/CPMP/EWP/1776/99 Rev. 1. 2 July 2010.

6. [Add additional references specific to therapeutic area, statistical methods, or regulatory guidance]

---

## 13. Appendices

### Appendix A: Analysis Population Flow Chart

```
                    SCREENED SUBJECTS
                         (N=XXX)
                            │
                            ▼
                    ┌───────────────────┐
                    │   Screen Failures │
                    │      (N=XX)       │
                    └───────────────────┘
                            │
                            ▼
                   RANDOMIZED SUBJECTS
                        (N=XXX)
            ┌─────────────────┼─────────────────┐
            ▼                 ▼                 ▼
        Placebo          Drug 5mg          Drug 10mg
        (N=XX)           (N=XX)            (N=XX)
            │                 │                 │
            ▼                 ▼                 ▼
    ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
    │ Received ≥1   │ │ Received ≥1   │ │ Received ≥1   │
    │ dose: N=XX    │ │ dose: N=XX    │ │ dose: N=XX    │
    │               │ │               │ │               │
    │ Never dosed:  │ │ Never dosed:  │ │ Never dosed:  │
    │ N=XX          │ │ N=XX          │ │ N=XX          │
    └───────────────┘ └───────────────┘ └───────────────┘
                            │
                            ▼
                    SAFETY POPULATION
                         (N=XXX)
                            │
                            ▼
               ┌─────────────────────────────┐
               │    Post-baseline data       │
               │         N=XXX               │
               │                             │
               │  No post-baseline data      │
               │         N=XX                │
               └─────────────────────────────┘
                            │
                            ▼
                  MODIFIED ITT POPULATION
                         (N=XXX)
```

### Appendix B: Sample Size Calculation Details

[Provide detailed sample size calculations with all assumptions and formulas]

### Appendix C: Planned Analysis Programs

| Program | Purpose | Input Data | Output |
|---------|---------|------------|--------|
| dem01.sas | Demographics table | ADSL | Table 14.1.1 |
| eff01.sas | Primary efficacy analysis | ADEFF | Table 14.2.1 |
| saf01.sas | AE overview | ADAE | Table 14.3.2 |
| [Continue for all programs] | | | |

### Appendix D: Definition of Analysis Flags

| Flag | Definition | Derivation Logic |
|------|------------|------------------|
| RANDFL | Randomized Flag | 'Y' if RANDDT ≠ missing |
| SAFFL | Safety Flag | 'Y' if RANDFL='Y' and received ≥1 dose |
| ITTFL | ITT Flag | 'Y' if RANDFL='Y' |
| MITTFL | Modified ITT Flag | 'Y' if ITTFL='Y' and post-baseline efficacy data available |
| PPROTFL | Per-Protocol Flag | 'Y' if ITTFL='Y' and no major protocol deviations |

### Appendix E: Handling of Special Scenarios

#### E.1 Unblinding Procedures
[Describe procedures for emergency unblinding and impact on analysis]

#### E.2 Interim Analysis Procedures
[If applicable, describe interim analysis procedures and stopping rules]

#### E.3 Post-hoc Analyses
[Describe procedures for requesting and conducting post-hoc analyses]

---

**End of Statistical Analysis Plan**

---

**Document Approval Signatures:**

| Role | Name | Signature | Date |
|------|------|-----------|------|
| **Lead Statistician** | [Name] | | |
| **Clinical Lead** | [Name] | | |
| **Study Director** | [Name] | | |
| **Quality Assurance** | [Name] | | |

**Final Approval Date:** _______________

*This Statistical Analysis Plan should be finalized before database lock and any changes after finalization should be documented as amendments with appropriate justification.*