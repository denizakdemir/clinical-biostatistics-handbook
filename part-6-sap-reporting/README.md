# Part 6: Statistical Analysis Plans and Reporting
## Comprehensive Guide to SAP Development and Clinical Study Reporting

### Overview

The Statistical Analysis Plan (SAP) is the cornerstone document that defines all statistical methodologies for a clinical trial, ensuring reproducible, transparent, and scientifically sound analyses. This section provides comprehensive guidance on SAP development, regulatory table creation, and clinical study reporting that meets global regulatory standards.

---

## 1. Statistical Analysis Plan (SAP) Framework

### 1.1 SAP Structure and Components

#### Essential SAP Sections
```
STATISTICAL ANALYSIS PLAN STRUCTURE

1. ADMINISTRATIVE INFORMATION
├── Title Page and Version Control
├── Protocol Synopsis
├── SAP Development Team
├── Amendment History
└── Approval Signatures

2. STUDY OVERVIEW
├── Study Objectives (Primary/Secondary/Exploratory)
├── Study Design and Randomization
├── Study Population and Eligibility
├── Treatment Arms and Interventions
└── Study Endpoints Definition

3. STATISTICAL METHODOLOGY
├── General Statistical Principles
├── Hypothesis Testing Framework
├── Sample Size Justification
├── Randomization and Stratification
├── Analysis Populations
├── Handling of Missing Data
├── Multiplicity Considerations
├── Interim Analysis Plans
└── Statistical Software and Version

4. ANALYSIS SPECIFICATIONS
├── Demographic and Baseline Characteristics
├── Primary Efficacy Analysis
├── Secondary Efficacy Analyses
├── Safety Analyses
├── Pharmacokinetic Analyses (if applicable)
├── Subgroup Analyses
├── Sensitivity Analyses
└── Exploratory Analyses

5. DATA PRESENTATION
├── Table, Listing, and Figure Specifications
├── Summary Statistics Definitions
├── Statistical Output Requirements
├── Data Display Conventions
└── Regulatory Submission Requirements

6. QUALITY ASSURANCE
├── Data Management Integration
├── Programming Specifications
├── Validation Requirements
├── Documentation Standards
└── Review and Approval Process
```

#### SAP Development Timeline
```sas
/******************************************************************************
SAP DEVELOPMENT MILESTONES

Protocol Finalization → SAP Draft 1 (4-6 weeks)
├── Statistical methodology review
├── Endpoint definitions finalized
├── Analysis population definitions
└── Sample size calculations confirmed

Database Lock Preparation → SAP Final (2-4 weeks before database lock)
├── Analysis dataset specifications
├── Programming specifications completed
├── Table shells finalized
├── Validation plans established
├── Regulatory review integration
└── Statistical review committee approval

Database Lock → Analysis Execution
├── Analysis dataset creation
├── Statistical analysis execution
├── Quality control and validation
├── Results interpretation
└── Clinical study report integration
******************************************************************************/
```

### 1.2 Analysis Populations Definition

#### Standard Population Definitions
```
ANALYSIS POPULATION HIERARCHY

Screened Population (SCR)
├── All subjects who signed informed consent
├── Baseline: All consented subjects
└── Purpose: Screen failure analysis

Randomized Population (RAND)
├── All subjects who were randomized
├── Baseline: Randomization date
├── Includes: Treatment assignment
└── Purpose: Demographic balance assessment

Safety Population (SAF)
├── All randomized subjects who received ≥1 dose
├── Analysis: As-treated approach
├── Treatment: Based on actual treatment received
└── Purpose: All safety analyses

Intent-to-Treat Population (ITT)
├── All randomized subjects
├── Analysis: Intention-to-treat principle
├── Treatment: Based on randomized treatment
└── Purpose: Primary efficacy analysis

Modified ITT (mITT)
├── ITT population with post-baseline efficacy data
├── Exclusions: No post-baseline assessments
├── Treatment: Based on randomized treatment
└── Purpose: Secondary efficacy analyses

Per-Protocol Population (PP)
├── Subjects without major protocol deviations
├── Compliance: ≥80% drug compliance typical
├── Treatment: Completed per protocol
└── Purpose: Sensitivity analysis for efficacy

Pharmacokinetic Population (PK)
├── Subjects with adequate PK sampling
├── Exclusions: Major PK protocol deviations
├── Requirements: Complete concentration-time profiles
└── Purpose: PK parameter analysis
```

#### Population Definition SAS Code Templates
```sas
/******************************************************************************
ANALYSIS POPULATION DERIVATION
******************************************************************************/

/* Safety Population */
data adsl_safety;
    set adsl;
    
    /* Safety population: randomized + received at least one dose */
    if randfl = 'Y' and (trt01a ^= '' or trtsdt ^= .);
    
    saffl = 'Y';  /* Safety analysis flag */
    
    /* Treatment for safety analysis (as-treated) */
    if trt01a ^= '' then safetrta = trt01a;
    else safetrta = trt01p;  /* Use planned if actual not available */
run;

/* Intent-to-Treat Population */
data adsl_itt;
    set adsl;
    
    /* ITT: All randomized subjects */
    if randfl = 'Y';
    
    ittfl = 'Y';  /* ITT analysis flag */
    
    /* Treatment for efficacy analysis (as-randomized) */
    efftrta = trt01p;  /* Use planned treatment assignment */
run;

/* Modified ITT Population */
data adsl_mitt;
    set adsl;
    
    /* mITT: ITT + post-baseline efficacy data */
    if randfl = 'Y' and effpost = 'Y';
    
    mittfl = 'Y';  /* Modified ITT analysis flag */
    efftrta = trt01p;
run;

/* Per-Protocol Population */
data adsl_pp;
    set adsl;
    
    /* Per-Protocol: ITT without major protocol deviations */
    if randfl = 'Y' and 
       compfl = 'Y' and          /* Completed study */
       complfl = 'Y' and         /* Compliant (≥80% doses) */
       pdv_major = 'N';          /* No major protocol deviations */
    
    pprotfl = 'Y';  /* Per-protocol analysis flag */
    efftrta = trt01p;
run;
```

## 2. Primary Efficacy Analysis Framework

### 2.1 Hypothesis Testing Structure

#### Statistical Hypothesis Framework
```
HYPOTHESIS TESTING HIERARCHY

Primary Hypothesis
├── Null Hypothesis (H₀): No treatment difference
├── Alternative Hypothesis (H₁): Treatment difference exists
├── Type I Error Control: α = 0.05 (two-sided)
├── Power Requirement: 1-β ≥ 0.80 (80% power)
└── Effect Size: Clinically meaningful difference

Secondary Hypotheses
├── Hierarchical Testing Procedure
│   ├── Fixed sequence testing
│   ├── Fallback procedures
│   └── Gatekeeping strategies
├── Multiplicity Adjustment Methods
│   ├── Bonferroni correction
│   ├── Holm-Bonferroni method
│   ├── Hochberg procedure
│   └── False Discovery Rate (FDR)
└── Family-Wise Error Rate Control

Exploratory Analyses
├── No formal hypothesis testing
├── Descriptive statistical approach
├── Point estimates with confidence intervals
└── Generate hypotheses for future studies
```

#### Primary Analysis Statistical Methods
```sas
/******************************************************************************
PRIMARY EFFICACY ANALYSIS TEMPLATES
******************************************************************************/

/* Continuous Primary Endpoint - ANCOVA Model */
proc mixed data=adeff method=reml;
    class usubjid trt01p region;
    model chg = trt01p base region / ddfm=kenwardroger solution;
    repeated / subject=usubjid type=cs;
    
    /* Primary comparison: Treatment vs Placebo */
    contrast 'Treatment vs Placebo' trt01p 1 -1;
    
    /* Least squares means */
    lsmeans trt01p / pdiff cl alpha=0.05;
    
    /* Effect size and confidence interval */
    estimate 'Treatment Effect' trt01p 1 -1 / cl alpha=0.05;
    
    title "Primary Efficacy Analysis - Change from Baseline";
run;

/* Binary Primary Endpoint - Logistic Regression */
proc logistic data=adeff descending;
    class trt01p (ref='Placebo') region;
    model respfl = trt01p base region;
    
    /* Odds ratio and confidence interval */
    oddsratio trt01p / cl=wald alpha=0.05;
    
    /* Response rates by treatment */
    proc freq data=adeff;
        tables trt01p * respfl / chisq riskdiff(cl=wald);
    run;
    
    title "Primary Efficacy Analysis - Response Rate";
run;

/* Time-to-Event Primary Endpoint - Cox Regression */
proc phreg data=adtte;
    class trt01p (ref='Placebo') region;
    model aval*cnsr(1) = trt01p region / rl;
    
    /* Hazard ratio */
    hazardratio trt01p / diff=ref cl=wald alpha=0.05;
    
    /* Kaplan-Meier survival curves */
    proc lifetest data=adtte plots=survival(atrisk);
        time aval*cnsr(1);
        strata trt01p;
    run;
    
    title "Primary Efficacy Analysis - Time to Event";
run;
```

### 2.2 Missing Data Handling Strategy

#### Missing Data Framework
```
MISSING DATA STRATEGY

Missing Data Assessment
├── Pattern Analysis
│   ├── Monotone missing patterns
│   ├── Intermittent missing patterns
│   └── Missing data visualization
├── Mechanism Evaluation
│   ├── Missing Completely at Random (MCAR)
│   ├── Missing at Random (MAR)
│   └── Missing Not at Random (MNAR)
└── Sensitivity Analysis Requirements

Primary Analysis Approach
├── Mixed Model Repeated Measures (MMRM)
│   ├── Uses all available data
│   ├── Valid under MAR assumption
│   ├── No imputation required
│   └── Unstructured covariance matrix
├── Multiple Imputation
│   ├── Create multiple complete datasets
│   ├── Analyze each dataset separately
│   ├── Pool results using Rubin's rules
│   └── Account for imputation uncertainty
└── Complete Case Analysis
    ├── Sensitivity analysis only
    ├── Valid under MCAR assumption
    ├── Potential loss of power
    └── Regulatory acceptability limited

Sensitivity Analyses
├── Tipping Point Analysis
├── Pattern-Mixture Models
├── Control-Based Imputation
├── Jump-to-Reference Imputation
└── Worst-Case/Best-Case Scenarios
```

#### Missing Data Analysis Implementation
```sas
/******************************************************************************
MISSING DATA ANALYSIS IMPLEMENTATION
******************************************************************************/

/* Primary Analysis: MMRM */
proc mixed data=adeff method=reml;
    class usubjid trt01p avisit region;
    model chg = trt01p*avisit base*avisit region / ddfm=kenwardroger;
    repeated avisit / subject=usubjid type=un;
    
    /* Treatment comparison at final visit */
    lsmeans trt01p*avisit / pdiff cl alpha=0.05;
    slice trt01p*avisit / sliceby=avisit diff;
    
    title "Primary Analysis - MMRM (All Available Data)";
run;

/* Sensitivity Analysis: Multiple Imputation */
proc mi data=adeff nimpute=100 out=mi_data seed=12345;
    class trt01p region;
    var chg base age sex region;
    monotone regression;
run;

/* Analysis of imputed datasets */
proc mixed data=mi_data method=reml;
    by _imputation_;
    class trt01p region;
    model chg = trt01p base region;
    lsmeans trt01p / diff cl;
    ods output diffs=mi_results;
run;

/* Pool multiple imputation results */
proc mianalyze data=mi_results;
    modeleffects estimate;
    stderr stderr;
    title "Sensitivity Analysis - Multiple Imputation";
run;

/* Sensitivity Analysis: Complete Case */
proc mixed data=adeff method=reml;
    class trt01p region;
    model chg = trt01p base region / ddfm=kenwardroger;
    where chg ^= .;  /* Complete cases only */
    
    lsmeans trt01p / pdiff cl alpha=0.05;
    title "Sensitivity Analysis - Complete Case Analysis";
run;
```

## 3. Safety Analysis Framework

### 3.1 Comprehensive Safety Assessment

#### Safety Analysis Categories
```
SAFETY ANALYSIS FRAMEWORK

Adverse Events Analysis
├── Treatment-Emergent Adverse Events (TEAEs)
│   ├── Any TEAE
│   ├── Serious Adverse Events (SAEs)
│   ├── Adverse Events Leading to Discontinuation
│   ├── Deaths
│   └── Adverse Events by Severity
├── Adverse Events by System Organ Class
│   ├── MedDRA preferred terms
│   ├── System organ class grouping
│   ├── Incidence rates by treatment
│   └── Risk differences with confidence intervals
└── Adverse Events of Special Interest
    ├── Pre-defined safety topics
    ├── Adjudicated events
    ├── Standardized case definitions
    └── Detailed safety evaluation

Laboratory Safety Analysis
├── Clinical Chemistry
│   ├── Shift tables (Normal → Abnormal)
│   ├── Notable values (Markedly abnormal)
│   ├── Change from baseline analysis
│   └── Potential clinical significance
├── Hematology Parameters
├── Urinalysis Results
└── Vital Signs Assessment

Special Safety Populations
├── Elderly Subjects (≥65 years)
├── Subjects with Renal Impairment
├── Subjects with Hepatic Impairment
├── Drug-Drug Interaction Subgroups
└── Geographic/Ethnic Subgroups
```

#### Safety Analysis Code Templates
```sas
/******************************************************************************
SAFETY ANALYSIS TEMPLATES
******************************************************************************/

/* Treatment-Emergent Adverse Events Summary */
proc freq data=adae;
    tables trt01a * aeser * aesev / nocol nopercent;
    where trtemfl = 'Y';  /* Treatment-emergent flag */
    title "Summary of Treatment-Emergent Adverse Events";
run;

/* AE Incidence by System Organ Class and Preferred Term */
proc sql;
    create table ae_summary as
    select 
        aesoc,
        aedecod,
        trt01a,
        count(distinct usubjid) as n_subjects,
        count(distinct usubjid) / 
            (select count(distinct usubjid) from adsl where trt01a = a.trt01a and saffl = 'Y') * 100 as pct_subjects
    from adae a
    where trtemfl = 'Y'
    group by aesoc, aedecod, trt01a
    order by aesoc, pct_subjects desc;
quit;

/* Notable Laboratory Values */
data adlb_notable;
    set adlb;
    where paramcd in ('ALT', 'AST', 'BILI', 'CREAT') and 
          trtemfl = 'Y' and 
          anrind in ('H', 'L') and 
          aval >= 3 * anrhi;  /* 3x Upper Limit Normal */
    
    notable_flag = 'Y';
run;

proc freq data=adlb_notable;
    tables paramcd * trt01a / chisq;
    title "Notable Laboratory Abnormalities (≥3x ULN)";
run;

/* Shift Tables - Baseline to Worst Post-Baseline */
proc freq data=adlb;
    tables bnrind * worstnrind * trt01a / norow nocol;
    where paramcd = 'ALT' and trtemfl = 'Y';
    title "Shift Table: ALT Baseline to Worst Post-Baseline";
run;
```

### 3.2 Integrated Safety Assessment

#### Multi-Study Safety Integration
```sas
/******************************************************************************
INTEGRATED SAFETY DATABASE CREATION
******************************************************************************/

/* Combine safety data across multiple studies */
data integrated_safety;
    set 
        study1.adae (in=in1 keep=usubjid trt01a aesoc aedecod trtemfl saffl)
        study2.adae (in=in2 keep=usubjid trt01a aesoc aedecod trtemfl saffl)
        study3.adae (in=in3 keep=usubjid trt01a aesoc aedecod trtemfl saffl);
    
    /* Study identifier */
    if in1 then studyid = 'STUDY001';
    else if in2 then studyid = 'STUDY002';
    else if in3 then studyid = 'STUDY003';
    
    /* Harmonize treatment coding across studies */
    if trt01a in ('Active Drug 100mg', 'Drug 100mg') then trt_pooled = 'Drug 100mg';
    else if trt01a in ('Placebo', 'PBO') then trt_pooled = 'Placebo';
    
    where trtemfl = 'Y' and saffl = 'Y';
run;

/* Integrated safety analysis */
proc freq data=integrated_safety;
    tables aesoc * trt_pooled / chisq;
    title "Integrated Safety Analysis Across Studies";
run;
```

## 4. Regulatory Table Specifications

### 4.1 ICH E3 Table Standards

#### Standard Table Catalog
```
REGULATORY TABLE REQUIREMENTS (ICH E3)

Demographics and Baseline Characteristics
├── Table 14.1.1: Demographic Characteristics
├── Table 14.1.2: Medical History
├── Table 14.1.3: Prior and Concomitant Medications
├── Table 14.1.4: Baseline Disease Characteristics
└── Table 14.1.5: Treatment Compliance

Efficacy Results
├── Table 14.2.1: Primary Efficacy Analysis
├── Table 14.2.2: Secondary Efficacy Endpoints
├── Table 14.2.3: Subgroup Analyses
├── Table 14.2.4: Time-Course Analysis
└── Table 14.2.5: Sensitivity Analyses

Safety Results
├── Table 14.3.1: Exposure to Study Treatment
├── Table 14.3.2: Adverse Events Overview
├── Table 14.3.3: Most Frequent Adverse Events
├── Table 14.3.4: Serious Adverse Events
├── Table 14.3.5: Deaths and Other Significant Events
├── Table 14.3.6: Clinical Laboratory Evaluations
├── Table 14.3.7: Vital Signs
└── Table 14.3.8: ECG Results

Pharmacokinetic Results (if applicable)
├── Table 14.4.1: PK Parameters Summary
├── Table 14.4.2: Dose Proportionality
└── Table 14.4.3: Drug-Drug Interactions
```

#### Table Shell Creation Framework
```sas
/******************************************************************************
TABLE SHELL TEMPLATE - DEMOGRAPHIC CHARACTERISTICS
******************************************************************************/

/* Table 14.1.1 Shell */
data table_14_1_1_shell;
    length characteristic $50 
           placebo_n50 $20 
           drug_100mg_n50 $20 
           drug_200mg_n50 $20 
           total_n150 $20;
    
    /* Age statistics */
    characteristic = 'Age (years)';
    placebo_n50 = '';
    drug_100mg_n50 = '';
    drug_200mg_n50 = '';
    total_n150 = '';
    output;
    
    characteristic = '  N';
    output;
    
    characteristic = '  Mean (SD)';
    output;
    
    characteristic = '  Median';
    output;
    
    characteristic = '  Min, Max';
    output;
    
    /* Age groups */
    characteristic = 'Age group, n (%)';
    output;
    
    characteristic = '  <65 years';
    output;
    
    characteristic = '  ≥65 years';
    output;
    
    /* Sex */
    characteristic = 'Sex, n (%)';
    output;
    
    characteristic = '  Male';
    output;
    
    characteristic = '  Female';
    output;
    
    /* Race */
    characteristic = 'Race, n (%)';
    output;
    
    characteristic = '  White';
    output;
    
    characteristic = '  Black or African American';
    output;
    
    characteristic = '  Asian';
    output;
    
    characteristic = '  Other';
    output;
run;

/* Generate actual demographics table */
%include "demographics_table_program.sas";
```

### 4.2 Table Production Framework

#### Automated Table Generation System
```sas
/******************************************************************************
AUTOMATED TABLE GENERATION FRAMEWORK
******************************************************************************/

%macro generate_regulatory_tables(
    study_data=,
    output_path=,
    table_specs=
);
    
    /* Initialize table production environment */
    %global table_date table_time;
    %let table_date = %sysfunc(today(), date9.);
    %let table_time = %sysfunc(time(), time8.);
    
    /* Set output destination */
    ods path(prepend) work.templat(update);
    
    /* Generate each table from specifications */
    data table_list;
        set &table_specs;
    run;
    
    data _null_;
        set table_list;
        call execute('%include "' || trim(table_program) || '";');
    run;
    
    /* Create table of contents */
    %create_table_index(path=&output_path);
    
%mend generate_regulatory_tables;

%macro create_demographic_table(population=SAFFL, output_table=);
    
    /* Calculate demographic statistics */
    proc means data=adsl noprint;
        class trt01p;
        var age;
        where &population = 'Y';
        output out=age_stats n=n mean=mean std=std median=median min=min max=max;
    run;
    
    proc freq data=adsl noprint;
        tables trt01p * sex / out=sex_freq;
        tables trt01p * race / out=race_freq;
        tables trt01p * agegr1 / out=age_group_freq;
        where &population = 'Y';
    run;
    
    /* Format results for table */
    data demographic_table;
        length row_label $50 
               col1_placebo $20 col2_drug_100 $20 col3_drug_200 $20 col4_total $20;
        
        /* Age statistics */
        set age_stats;
        if trt01p = 'Placebo' then do;
            row_label = 'Age (years)';
            col1_placebo = put(n, 3.);
            output;
            
            row_label = '  Mean (SD)';
            col1_placebo = strip(put(mean, 5.1)) || ' (' || strip(put(std, 5.2)) || ')';
            output;
            
            row_label = '  Median';
            col1_placebo = put(median, 5.1);
            output;
            
            row_label = '  Min, Max';
            col1_placebo = strip(put(min, 3.)) || ', ' || strip(put(max, 3.));
            output;
        end;
        
        /* Continue with other treatments and demographics */
    run;
    
    /* Output formatted table */
    proc report data=demographic_table nowd;
        columns row_label col1_placebo col2_drug_100 col3_drug_200 col4_total;
        define row_label / display 'Characteristic' width=30;
        define col1_placebo / display 'Placebo|(N=50)' width=15 center;
        define col2_drug_100 / display 'Drug 100mg|(N=50)' width=15 center;
        define col3_drug_200 / display 'Drug 200mg|(N=50)' width=15 center;
        define col4_total / display 'Total|(N=150)' width=15 center;
        
        title1 "Table 14.1.1";
        title2 "Demographic and Baseline Characteristics";
        title3 "Safety Population";
        
        footnote1 "Generated: &table_date at &table_time";
        footnote2 "Program: demographics_table.sas";
    run;
    
%mend create_demographic_table;
```

## 5. Advanced Reporting Techniques

### 5.1 Publication-Quality Output

#### ODS Excellence for Clinical Tables
```sas
/******************************************************************************
PUBLICATION-QUALITY TABLE FORMATTING
******************************************************************************/

/* Define custom table style */
proc template;
    define style clinical_table_style;
        parent = styles.rtf;
        
        /* Table formatting */
        style table from table /
            borderwidth=1pt
            bordercolor=black
            cellpadding=3pt
            cellspacing=0pt
            frame=hsides
            rules=groups;
            
        /* Header formatting */
        style header from header /
            background=white
            foreground=black
            fontweight=bold
            borderwidth=1pt
            bordercolor=black;
            
        /* Data formatting */
        style data from data /
            background=white
            foreground=black
            borderwidth=0.5pt
            bordercolor=gray;
            
        /* Footer formatting */
        style systemfooter from systemfooter /
            fontsize=8pt
            fontstyle=italic;
    end;
run;

/* Enhanced table with clinical styling */
ods rtf file="efficacy_table.rtf" style=clinical_table_style;

proc report data=efficacy_results nowd;
    columns endpoint 
           ('Treatment Groups' trt_a trt_b trt_c)
           ('Statistical Test' pvalue ci);
    
    define endpoint / display 'Primary Endpoint' width=25 
                     style(column)={borderleftwidth=2pt borderleftcolor=black};
    define trt_a / display 'Placebo|(N=150)' width=15 center
                  format=best8.;
    define trt_b / display 'Drug 5mg|(N=148)' width=15 center
                  format=best8.;
    define trt_c / display 'Drug 10mg|(N=152)' width=15 center
                  format=best8.;
    define pvalue / display 'P-value' width=12 center
                   format=pvalue6.4;
    define ci / display '95% CI' width=20 center;
    
    /* Conditional formatting for p-values */
    compute pvalue;
        if pvalue < 0.001 then call define(_col_, 'style', 'style={fontweight=bold}');
        else if pvalue < 0.05 then call define(_col_, 'style', 'style={fontweight=bold color=red}');
    endcomp;
    
    title justify=left 'Table 14.2.1';
    title2 justify=left 'Analysis of Primary Efficacy Endpoint';
    title3 justify=left 'Intent-to-Treat Population';
    
    footnote1 justify=left 'CI = Confidence Interval';
    footnote2 justify=left 'Analysis based on ANCOVA model with treatment, region, and baseline value as covariates';
    footnote3 justify=left 'Generated: ' "&sysdate9" ' at ' "&systime";
run;

ods rtf close;
```

### 5.2 Interactive Dashboard Creation

#### Clinical Trial Dashboard Framework
```sas
/******************************************************************************
INTERACTIVE CLINICAL TRIAL DASHBOARD
******************************************************************************/

/* Create dashboard data */
proc sql;
    create table dashboard_data as
    select 
        'Enrollment' as metric_category,
        'Screened' as metric_name,
        count(*) as metric_value,
        today() as report_date
    from adsl
    where scrfl = 'Y'
    
    union
    
    select 
        'Enrollment' as metric_category,
        'Randomized' as metric_name,
        count(*) as metric_value,
        today() as report_date
    from adsl
    where randfl = 'Y'
    
    union
    
    select 
        'Safety' as metric_category,
        'Any TEAE' as metric_name,
        count(distinct usubjid) as metric_value,
        today() as report_date
    from adae
    where trtemfl = 'Y'
    
    union
    
    select 
        'Safety' as metric_category,
        'Serious AEs' as metric_name,
        count(distinct usubjid) as metric_value,
        today() as report_date
    from adae
    where trtemfl = 'Y' and aeser = 'Y';
quit;

/* Generate interactive dashboard */
ods html5(id=dashboard) file="clinical_dashboard.html" 
    options(svg_mode="inline");

proc sgpanel data=dashboard_data;
    panelby metric_category / columns=2 spacing=10;
    vbar metric_name / response=metric_value 
                      fillattrs=(color=lightblue)
                      datalabel;
    rowaxis label="Count";
    colaxis label="Metric" fitpolicy=rotate;
    title "Clinical Trial Dashboard";
    title2 "Updated: %sysfunc(today(), weekdate.)";
run;

ods html5(id=dashboard) close;
```

---

## Key Features of This SAP and Reporting Framework

### Comprehensive Coverage
- **Complete SAP Structure**: From administrative information to quality assurance
- **Analysis Population Definitions**: Standard and customizable population criteria
- **Statistical Method Templates**: Ready-to-use code for all major analysis types
- **Missing Data Strategy**: Comprehensive framework with sensitivity analyses
- **Safety Analysis Framework**: Complete safety assessment methodology
- **Regulatory Table Standards**: ICH E3 compliant table specifications
- **Publication-Quality Output**: Professional formatting and presentation

### Regulatory Compliance
- **ICH Guidelines Integration**: E3, E6, E9 alignment
- **FDA Guidance Compliance**: Statistical principles and submission standards
- **Global Regulatory Harmonization**: Multi-regional submission requirements
- **Quality Assurance Framework**: Validation and review processes

### Practical Implementation
- **SAS Code Templates**: Production-ready statistical programs
- **Automation Framework**: Efficient table generation system
- **Validation Requirements**: Quality control and verification procedures
- **Documentation Standards**: Comprehensive record-keeping

*This framework provides the foundation for developing robust Statistical Analysis Plans and producing high-quality clinical study reports that meet global regulatory standards.*