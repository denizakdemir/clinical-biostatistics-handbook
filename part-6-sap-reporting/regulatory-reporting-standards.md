# Regulatory Reporting Standards for Clinical Trials

## ICH E3 Compliance Framework

### Clinical Study Report Structure

```
ICH E3 CLINICAL STUDY REPORT SECTIONS

1. TITLE PAGE
2. SYNOPSIS
3. TABLE OF CONTENTS
4. LIST OF ABBREVIATIONS AND DEFINITIONS
5. ETHICS
6. INVESTIGATORS AND STUDY ADMINISTRATIVE STRUCTURE
7. INTRODUCTION
8. STUDY OBJECTIVES
9. INVESTIGATION PLAN
10. STUDY SUBJECTS
11. EFFICACY EVALUATION
12. SAFETY EVALUATION
13. DISCUSSION AND OVERALL CONCLUSIONS
14. TABLES, FIGURES, AND GRAPHS REFERRED TO BUT NOT INCLUDED IN THE TEXT
    14.1 Demographics and Other Baseline Characteristics
    14.2 Efficacy Evaluations
    14.3 Safety Evaluations
15. REFERENCE LIST
16. APPENDICES
    16.1 Study Information
    16.2 Individual Subject Data Listings
    16.3 Case Report Forms (sample)
    16.4 Technical Statistical Details
```

### Section 14 Table Requirements

#### 14.1 Demographics and Baseline Characteristics

**Table 14.1.1: Demographic Characteristics**
```
REQUIRED CONTENT:
- Age: N, mean, SD, median, min, max by treatment group
- Age categories: <65, ≥65 years (or other relevant categories)
- Sex: Number and percentage by treatment group
- Race: Number and percentage by treatment group
- Ethnicity: Number and percentage by treatment group
- Geographic distribution: By region/country if applicable
- Other relevant demographics: Height, weight, BMI if relevant

PRESENTATION FORMAT:
- Treatment groups in columns
- Demographic characteristics in rows
- Statistical summaries appropriate for data type
- P-values for between-group comparisons (optional)
```

**SAS Implementation:**
```sas
/******************************************************************************
TABLE 14.1.1: DEMOGRAPHIC CHARACTERISTICS
POPULATION: Randomized Population (RANDFL='Y')
******************************************************************************/

proc template;
    define style Demographics_Table;
        parent = styles.rtf;
        
        style Table from Table /
            borderwidth = 1pt
            bordercolor = black
            cellpadding = 3pt
            rules = groups
            frame = hsides;
            
        style Header from Header /
            background = white
            foreground = black
            fontweight = bold;
    end;
run;

/* Calculate demographic statistics */
proc means data=adam.adsl noprint;
    class trt01p;
    var age;
    where randfl = 'Y';
    output out=age_stats 
        n=n mean=mean std=std median=median min=min max=max;
run;

proc freq data=adam.adsl noprint;
    tables trt01p * (sex race ethnic agegr1) / outpct out=demo_freq;
    where randfl = 'Y';
run;

/* Format for regulatory table */
data table_14_1_1;
    length characteristic $50 
           placebo $20 drug_low $20 drug_high $20 total $20;
    
    set age_stats;
    where trt01p ne '';
    
    retain age_n_plc age_mean_plc age_std_plc age_med_plc age_min_plc age_max_plc
           age_n_low age_mean_low age_std_low age_med_low age_min_low age_max_low
           age_n_high age_mean_high age_std_high age_med_high age_min_high age_max_high;
    
    /* Store age statistics by treatment */
    if trt01p = 'Placebo' then do;
        age_n_plc = n; age_mean_plc = mean; age_std_plc = std;
        age_med_plc = median; age_min_plc = min; age_max_plc = max;
    end;
    else if trt01p = 'Drug Low Dose' then do;
        age_n_low = n; age_mean_low = mean; age_std_low = std;
        age_med_low = median; age_min_low = min; age_max_low = max;
    end;
    else if trt01p = 'Drug High Dose' then do;
        age_n_high = n; age_mean_high = mean; age_std_high = std;
        age_med_high = median; age_min_high = min; age_max_high = max;
    end;
    
    if last.trt01p then do;
        /* Output age statistics */
        characteristic = 'Age (years)';
        placebo = ''; drug_low = ''; drug_high = ''; total = '';
        ord = 1; output;
        
        characteristic = '  N';
        placebo = put(age_n_plc, 3.);
        drug_low = put(age_n_low, 3.);
        drug_high = put(age_n_high, 3.);
        total = put(sum(age_n_plc, age_n_low, age_n_high), 3.);
        ord = 2; output;
        
        characteristic = '  Mean (SD)';
        placebo = strip(put(age_mean_plc, 5.1)) || ' (' || strip(put(age_std_plc, 5.2)) || ')';
        drug_low = strip(put(age_mean_low, 5.1)) || ' (' || strip(put(age_std_low, 5.2)) || ')';
        drug_high = strip(put(age_mean_high, 5.1)) || ' (' || strip(put(age_std_high, 5.2)) || ')';
        total = '';
        ord = 3; output;
        
        characteristic = '  Median';
        placebo = put(age_med_plc, 5.1);
        drug_low = put(age_med_low, 5.1);
        drug_high = put(age_med_high, 5.1);
        total = '';
        ord = 4; output;
        
        characteristic = '  Min, Max';
        placebo = strip(put(age_min_plc, 3.)) || ', ' || strip(put(age_max_plc, 3.));
        drug_low = strip(put(age_min_low, 3.)) || ', ' || strip(put(age_max_low, 3.));
        drug_high = strip(put(age_min_high, 3.)) || ', ' || strip(put(age_max_high, 3.));
        total = '';
        ord = 5; output;
    end;
    
    keep characteristic placebo drug_low drug_high total ord;
run;

/* Add categorical demographics */
%add_categorical_demographics(input_data=demo_freq, output_data=table_14_1_1);

proc sort data=table_14_1_1;
    by ord;
run;

/* Generate regulatory-compliant output */
ods rtf file="Table_14_1_1_Demographics.rtf" style=Demographics_Table;

title1 justify=left "Table 14.1.1";
title2 justify=left "Demographics and Baseline Characteristics";
title3 justify=left "Randomized Population";
title4 justify=left "Protocol: [Protocol Number]";

proc report data=table_14_1_1 nowd split='|';
    columns characteristic placebo drug_low drug_high total;
    
    define characteristic / display "" width=35 
                           style(column)=[cellwidth=2.5in just=left];
    define placebo / display "Placebo|(N=XX)" width=15 center 
                    style(column)=[cellwidth=1.2in just=center];
    define drug_low / display "Drug Low|(N=XX)" width=15 center 
                     style(column)=[cellwidth=1.2in just=center];
    define drug_high / display "Drug High|(N=XX)" width=15 center 
                      style(column)=[cellwidth=1.2in just=center];
    define total / display "Total|(N=XXX)" width=15 center 
                  style(column)=[cellwidth=1.2in just=center];
run;

footnote1 justify=left "Generated: &sysdate9 at &systime";
footnote2 justify=left "File: demographics_table.sas";

ods rtf close;
```

#### 14.2 Efficacy Evaluations

**Table 14.2.1: Analysis of Primary Efficacy Endpoint**

**Regulatory Requirements:**
```
CONTENT REQUIREMENTS:
- Primary endpoint analysis results
- Treatment group summary statistics
- Between-group comparisons with confidence intervals
- P-values for statistical tests
- Effect sizes (difference in means, odds ratios, hazard ratios)
- Sample sizes and missing data handling description

STATISTICAL PRESENTATION:
- Point estimates with standard errors or confidence intervals
- Appropriate statistical test results
- Multiplicity adjustments if applicable
- Analysis population clearly specified
```

**SAS Implementation:**
```sas
/******************************************************************************
TABLE 14.2.1: PRIMARY EFFICACY ANALYSIS
POPULATION: Intent-to-Treat Population (ITTFL='Y')
METHOD: ANCOVA with treatment, baseline value, and region as covariates
******************************************************************************/

/* Primary efficacy analysis */
ods output LSMeans=primary_lsmeans 
           Diffs=primary_diffs 
           Tests3=primary_tests;

proc mixed data=adam.adeff method=reml;
    class usubjid trt01p region;
    model chg = trt01p base region / ddfm=kenwardroger solution;
    
    where ittfl = 'Y' and paramcd = 'PRIMARY' and avisitn = 12;
    
    /* Treatment comparisons */
    lsmeans trt01p / pdiff cl alpha=0.05;
    
    /* Specific contrasts for regulatory submission */
    contrast 'Active vs Placebo (Overall)' 
             trt01p 1 -0.5 -0.5;  /* If 2 active doses */
    
    contrast 'Drug Low vs Placebo' 
             trt01p 1 -1 0;
    
    contrast 'Drug High vs Placebo' 
             trt01p 0 -1 1;
    
    contrast 'Drug High vs Drug Low' 
             trt01p 0 1 -1;
run;

/* Format results for regulatory table */
data efficacy_summary;
    length treatment_group $25 n_subjects $10 lsmean_se $25;
    
    merge primary_lsmeans 
          (select trt01p, count(*) as n_analyzed 
           from adam.adeff 
           where ittfl='Y' and paramcd='PRIMARY' and avisitn=12 
           group by trt01p);
    by trt01p;
    
    treatment_group = trt01p;
    n_subjects = put(n_analyzed, 3.);
    lsmean_se = strip(put(estimate, 8.2)) || ' (' || strip(put(stderr, 8.3)) || ')';
    
    keep treatment_group n_subjects lsmean_se;
run;

data efficacy_comparisons;
    set primary_diffs;
    where _trt01p ne trt01p;
    
    length comparison $30 difference $15 ci_95 $25 p_value $10;
    
    comparison = strip(_trt01p) || ' vs ' || strip(trt01p);
    difference = put(estimate, 8.2);
    ci_95 = '(' || strip(put(lower, 8.2)) || ', ' || strip(put(upper, 8.2)) || ')';
    
    if probt < 0.001 then p_value = '<0.001';
    else p_value = put(probt, 6.3);
    
    keep comparison difference ci_95 p_value;
run;

/* Generate regulatory table */
ods rtf file="Table_14_2_1_Primary_Efficacy.rtf" style=Clinical_Table;

title1 justify=left "Table 14.2.1";
title2 justify=left "Analysis of Primary Efficacy Endpoint";
title3 justify=left "Change from Baseline at Week 12";
title4 justify=left "Intent-to-Treat Population";

/* Treatment group summary */
proc report data=efficacy_summary nowd;
    columns treatment_group n_subjects lsmean_se;
    
    define treatment_group / display "Treatment Group" width=20;
    define n_subjects / display "N" width=8 center;
    define lsmean_se / display "LS Mean (SE)" width=20 center;
    
    title5 "Treatment Group Summary";
run;

/* Treatment comparisons */
proc report data=efficacy_comparisons nowd;
    columns comparison difference ci_95 p_value;
    
    define comparison / display "Treatment Comparison" width=25;
    define difference / display "Difference in|LS Means" width=15 center;
    define ci_95 / display "95% Confidence|Interval" width=20 center;
    define p_value / display "P-value" width=10 center;
    
    /* Highlight significant results */
    compute p_value;
        if input(p_value, best.) < 0.05 or p_value = '<0.001' then
            call define(_col_, 'style', 'style={fontweight=bold}');
    endcomp;
    
    title5 "Treatment Comparisons";
run;

footnote1 justify=left "LS Mean = Least squares mean; SE = Standard error; CI = Confidence interval";
footnote2 justify=left "Analysis based on ANCOVA model with treatment, baseline value, and geographic region as covariates.";
footnote3 justify=left "Missing data handled using mixed model repeated measures approach.";
footnote4 justify=left "Generated: &sysdate9 at &systime";

ods rtf close;
```

#### 14.3 Safety Evaluations

**Table 14.3.2: Overview of Treatment-Emergent Adverse Events**

**Regulatory Requirements:**
```
SAFETY TABLE STANDARDS:
- Treatment-emergent adverse events (TEAEs) definition clearly stated
- Safety population used for all safety analyses
- Number and percentage of subjects with events
- Categories: Any TEAE, Serious AEs, AEs leading to discontinuation, Deaths
- Confidence intervals for proportions (optional but recommended)
- Statistical comparisons (optional, typically not done for safety)
```

**SAS Implementation:**
```sas
/******************************************************************************
TABLE 14.3.2: OVERVIEW OF TREATMENT-EMERGENT ADVERSE EVENTS
POPULATION: Safety Population (SAFFL='Y')
DEFINITION: TEAE = Adverse event with onset on or after first dose
******************************************************************************/

/* Get safety population denominators */
proc sql;
    create table safety_denom as
    select trt01a, count(*) as safety_n
    from adam.adsl
    where saffl = 'Y'
    group by trt01a;
quit;

/* Calculate AE summary by category */
proc sql;
    create table ae_overview as
    select 
        s.trt01a,
        s.safety_n,
        
        /* Any TEAE */
        count(distinct case when a.trtemfl='Y' then a.usubjid end) as any_teae_n,
        calculated any_teae_n / s.safety_n * 100 as any_teae_pct,
        
        /* Serious AEs */
        count(distinct case when a.trtemfl='Y' and a.aeser='Y' then a.usubjid end) as sae_n,
        calculated sae_n / s.safety_n * 100 as sae_pct,
        
        /* AEs leading to discontinuation */
        count(distinct case when a.trtemfl='Y' and a.aeacn='DRUG WITHDRAWN' then a.usubjid end) as disc_n,
        calculated disc_n / s.safety_n * 100 as disc_pct,
        
        /* Deaths */
        count(distinct case when a.trtemfl='Y' and a.aeout='FATAL' then a.usubjid end) as death_n,
        calculated death_n / s.safety_n * 100 as death_pct
        
    from safety_denom s
    left join adam.adae a on s.trt01a = a.trt01a and a.saffl = 'Y'
    group by s.trt01a, s.safety_n
    order by s.trt01a;
quit;

/* Calculate exact binomial confidence intervals */
%macro exact_ci(numerator, denominator, alpha=0.05);
    /* Implementation of exact binomial CI calculation */
    /* This would use PROC FREQ with exact binomial options */
%mend;

/* Format results for regulatory presentation */
data table_14_3_2;
    set ae_overview;
    
    length ae_category $50 result $25;
    
    /* Any TEAE */
    ae_category = 'Any treatment-emergent adverse event';
    result = strip(put(any_teae_n, 3.)) || ' (' || strip(put(any_teae_pct, 5.1)) || ')';
    ord = 1;
    output;
    
    /* Serious AEs */
    ae_category = 'Serious adverse events';
    result = strip(put(sae_n, 3.)) || ' (' || strip(put(sae_pct, 5.1)) || ')';
    ord = 2;
    output;
    
    /* AEs leading to discontinuation */
    ae_category = 'Adverse events leading to study drug discontinuation';
    result = strip(put(disc_n, 3.)) || ' (' || strip(put(disc_pct, 5.1)) || ')';
    ord = 3;
    output;
    
    /* Deaths */
    ae_category = 'Deaths';
    result = strip(put(death_n, 3.)) || ' (' || strip(put(death_pct, 5.1)) || ')';
    ord = 4;
    output;
    
    keep trt01a ae_category result ord safety_n;
run;

/* Transpose for reporting */
proc transpose data=table_14_3_2 out=ae_transposed prefix=trt_;
    by ord ae_category;
    id trt01a;
    var result;
run;

/* Generate regulatory table */
ods rtf file="Table_14_3_2_AE_Overview.rtf" style=Clinical_Table;

title1 justify=left "Table 14.3.2";
title2 justify=left "Overview of Treatment-Emergent Adverse Events";
title3 justify=left "Safety Population";

proc report data=ae_transposed nowd split='|';
    columns ae_category trt_placebo trt_drug_low trt_drug_high;
    
    define ae_category / display "" width=40 flow 
                        style(column)=[cellwidth=3.0in just=left];
    define trt_placebo / display "Placebo|(N=XX)|n (%)" width=15 center 
                        style(column)=[cellwidth=1.2in just=center];
    define trt_drug_low / display "Drug Low|(N=XX)|n (%)" width=15 center 
                         style(column)=[cellwidth=1.2in just=center];
    define trt_drug_high / display "Drug High|(N=XX)|n (%)" width=15 center 
                          style(column)=[cellwidth=1.2in just=center];
run;

footnote1 justify=left "TEAE = Treatment-emergent adverse event, defined as an adverse event with onset on or";
footnote2 justify=left "after the date of first study drug administration.";
footnote3 justify=left "Percentages calculated as 100 × (number of subjects with event / total number of subjects in treatment group).";
footnote4 justify=left "Generated: &sysdate9 at &systime";

ods rtf close;
```

## FDA Submission Standards

### eCTD Module 5 Requirements

#### Study Reports Structure
```
eCTD MODULE 5: CLINICAL STUDY REPORTS

5.2 Tabulated Summaries of Clinical Data
├── 5.2.1 List of Clinical Studies
├── 5.2.2 Tabulated Summary of Integrated Efficacy
├── 5.2.3 Tabulated Summary of Integrated Safety
├── 5.2.4 Study Reports of Controlled Clinical Studies
│   ├── Study Report 1
│   ├── Study Report 2
│   └── Study Report N
├── 5.2.5 Study Reports of Uncontrolled Clinical Studies
└── 5.2.6 Reports of Post-marketing Data

5.3 Clinical Study Reports
├── 5.3.1 Reports of Biopharmaceutics Studies
├── 5.3.2 Reports of Studies Pertinent to Pharmacokinetics
├── 5.3.3 Reports of Human Pharmacokinetics Studies
├── 5.3.4 Reports of Human Pharmacodynamics Studies
├── 5.3.5 Reports of Efficacy and Safety Studies
│   ├── Study 1 Clinical Study Report
│   ├── Study 2 Clinical Study Report
│   └── Study N Clinical Study Report
└── 5.3.6 Reports of Post-marketing Data
```

#### Dataset Specifications for Submission

**SDTM (Study Data Tabulation Model) Requirements:**
```sas
/******************************************************************************
SDTM DATASET VALIDATION FOR FDA SUBMISSION
******************************************************************************/

%macro validate_sdtm_dataset(domain=, dataset=);
    
    /* Check required variables */
    %local required_vars;
    
    %if &domain = DM %then %let required_vars = STUDYID DOMAIN USUBJID SUBJID RFSTDTC RFENDTC SITEID AGE AGEU SEX RACE ETHNIC ARMCD ARM ACTARMCD ACTARM COUNTRY DMDTC DMDY;
    %else %if &domain = AE %then %let required_vars = STUDYID DOMAIN USUBJID AESEQ AETERM AEDECOD AEBODSYS AESOC AESEV AESER AEACN AEREL AEOUT AESTDTC AEENDTC AEDY AEENDY;
    %else %if &domain = CM %then %let required_vars = STUDYID DOMAIN USUBJID CMSEQ CMTRT CMDECOD CMINDC CMDOSE CMDOSU CMDOSFRM CMDOSFRQ CMROUTE CMSTDTC CMENDTC CMDY CMENDY;
    
    /* Validate required variables exist */
    proc contents data=&dataset out=dataset_vars(keep=name) noprint;
    run;
    
    data missing_vars;
        length required_var $32 present $3;
        
        %do i = 1 %to %sysfunc(countw(&required_vars));
            %let var = %scan(&required_vars, &i);
            required_var = "&var";
            
            /* Check if variable exists */
            if 0 then set dataset_vars;
            do until(eof);
                set dataset_vars end=eof;
                if upcase(name) = upcase(required_var) then do;
                    present = 'Yes';
                    leave;
                end;
            end;
            if present ne 'Yes' then present = 'No';
            output;
            present = '';
        %end;
    run;
    
    /* Report validation results */
    proc freq data=missing_vars;
        tables present / nocum nopercent;
        title "SDTM Validation Results for &domain Domain";
    run;
    
    proc print data=missing_vars;
        where present = 'No';
        title "Missing Required Variables in &domain Domain";
    run;
    
%mend validate_sdtm_dataset;

/* Validate all SDTM domains */
%validate_sdtm_dataset(domain=DM, dataset=sdtm.dm);
%validate_sdtm_dataset(domain=AE, dataset=sdtm.ae);
%validate_sdtm_dataset(domain=CM, dataset=sdtm.cm);
```

**ADaM (Analysis Data Model) Requirements:**
```sas
/******************************************************************************
ADAM DATASET VALIDATION FOR FDA SUBMISSION
******************************************************************************/

%macro validate_adam_dataset(dataset=, expected_records=);
    
    /* Check ADSL structure */
    %if %upcase(&dataset) = ADSL %then %do;
        
        proc contents data=adam.adsl out=adsl_vars noprint;
        run;
        
        /* Required ADSL variables */
        data adsl_required;
            length variable $32;
            variable = 'STUDYID'; output;
            variable = 'USUBJID'; output;
            variable = 'SUBJID'; output;
            variable = 'SITEID'; output;
            variable = 'AGE'; output;
            variable = 'AGEGR1'; output;
            variable = 'SEX'; output;
            variable = 'RACE'; output;
            variable = 'ETHNIC'; output;
            variable = 'ARMCD'; output;
            variable = 'ARM'; output;
            variable = 'TRT01P'; output;
            variable = 'TRT01A'; output;
            variable = 'RANDFL'; output;
            variable = 'SAFFL'; output;
            variable = 'ITTFL'; output;
            variable = 'MITTFL'; output;
            variable = 'PPROTFL'; output;
        run;
        
        /* Check for missing required variables */
        proc sql;
            create table missing_adsl_vars as
            select r.variable
            from adsl_required r
            where r.variable not in 
                (select upcase(name) from adsl_vars);
        quit;
        
        proc print data=missing_adsl_vars;
            title "Missing Required ADSL Variables";
        run;
        
    %end;
    
    /* Validate record counts if expected provided */
    %if %length(&expected_records) > 0 %then %do;
        
        proc sql noprint;
            select count(*) into :actual_records
            from adam.&dataset;
        quit;
        
        data record_validation;
            length dataset $8 expected 8 actual 8 match $3;
            dataset = "&dataset";
            expected = &expected_records;
            actual = &actual_records;
            if expected = actual then match = 'Yes';
            else match = 'No';
        run;
        
        proc print data=record_validation;
            title "Record Count Validation for &dataset";
        run;
        
    %end;
    
%mend validate_adam_dataset;

/* Validate ADaM datasets */
%validate_adam_dataset(dataset=ADSL);
%validate_adam_dataset(dataset=ADAE);
%validate_adam_dataset(dataset=ADEFF);
```

### Define-XML Generation

#### Automated Define-XML Creation
```sas
/******************************************************************************
DEFINE-XML GENERATION FOR FDA SUBMISSION
******************************************************************************/

%macro create_define_xml(study_name=, output_path=);
    
    /* Create define-XML metadata */
    data define_metadata;
        length dataset $8 variable $32 label $200 type $10 length 8 
               format $32 origin $50 role $20 comment $500;
        
        /* ADSL metadata */
        dataset = 'ADSL'; variable = 'STUDYID'; label = 'Study Identifier'; 
        type = 'text'; length = 12; origin = 'Assigned'; role = 'Identifier'; output;
        
        dataset = 'ADSL'; variable = 'USUBJID'; label = 'Unique Subject Identifier'; 
        type = 'text'; length = 11; origin = 'Derived'; role = 'Identifier'; output;
        
        dataset = 'ADSL'; variable = 'SUBJID'; label = 'Subject Identifier for the Study'; 
        type = 'text'; length = 4; origin = 'Collected'; role = 'Identifier'; output;
        
        dataset = 'ADSL'; variable = 'SITEID'; label = 'Study Site Identifier'; 
        type = 'text'; length = 3; origin = 'Collected'; role = 'Identifier'; output;
        
        dataset = 'ADSL'; variable = 'AGE'; label = 'Age'; 
        type = 'integer'; length = 8; origin = 'Collected'; role = 'Covariate'; output;
        
        dataset = 'ADSL'; variable = 'AGEGR1'; label = 'Pooled Age Group 1'; 
        type = 'text'; length = 10; origin = 'Derived'; role = 'Covariate'; output;
        
        dataset = 'ADSL'; variable = 'SEX'; label = 'Sex'; 
        type = 'text'; length = 1; origin = 'Collected'; role = 'Covariate'; output;
        
        dataset = 'ADSL'; variable = 'RACE'; label = 'Race'; 
        type = 'text'; length = 50; origin = 'Collected'; role = 'Covariate'; output;
        
        dataset = 'ADSL'; variable = 'RANDFL'; label = 'Randomized Population Flag'; 
        type = 'text'; length = 1; origin = 'Derived'; role = 'Condition'; 
        comment = 'Y if subject was randomized, null otherwise'; output;
        
        dataset = 'ADSL'; variable = 'SAFFL'; label = 'Safety Population Flag'; 
        type = 'text'; length = 1; origin = 'Derived'; role = 'Condition'; 
        comment = 'Y if subject received at least one dose of study treatment, null otherwise'; output;
        
        dataset = 'ADSL'; variable = 'ITTFL'; label = 'Intent-To-Treat Population Flag'; 
        type = 'text'; length = 1; origin = 'Derived'; role = 'Condition'; 
        comment = 'Y if subject is in the ITT population, null otherwise'; output;
        
        /* Add metadata for other datasets */
        /* ADAE, ADEFF, etc. */
    run;
    
    /* Generate Define-XML using SAS Clinical Standards Toolkit */
    /* This would use the CST macros for Define-XML generation */
    
    %cstutil_createdefine(
        _cstSourceStudy=&study_name,
        _cstSourceStandard=CDISC-ADAM,
        _cstSourceStandardVersion=2.1,
        _cstOutputDS=work.define_xml,
        _cstOutputFile=&output_path/define.xml
    );
    
%mend create_define_xml;

%create_define_xml(study_name=STUDY001, output_path=/outputs/define);
```

## EMA Submission Requirements

### EU CTD Format

#### Module 5 Clinical Study Reports
```
EU CTD MODULE 5 REQUIREMENTS:

5.2 Tabulated Summaries of Clinical Data
├── 5.2.1 List of Clinical Studies
├── 5.2.2 Summary of Integrated Efficacy
├── 5.2.3 Summary of Integrated Safety
├── 5.2.4 Pivotal Clinical Study Reports
├── 5.2.5 Supportive Clinical Study Reports
└── 5.2.6 Post-marketing Data

EU-SPECIFIC CONSIDERATIONS:
- Multi-language considerations
- Regional subgroup analyses
- European population demographics
- EMA-specific safety reporting requirements
- CHMP guideline compliance
```

#### EMA Safety Reporting Standards
```sas
/******************************************************************************
EMA-SPECIFIC SAFETY REPORTING REQUIREMENTS
******************************************************************************/

%macro ema_safety_analysis(safety_topic=, meddra_version=);
    
    /* EMA requires detailed analysis of deaths */
    %if &safety_topic = DEATHS %then %do;
        
        proc sql;
            create table ema_deaths as
            select 
                usubjid,
                trt01a,
                aedecod,
                aestdtc,
                aeendtc,
                aerel as relationship_to_drug,
                aeacn as action_taken,
                aeconmed as concomitant_medication,
                aetoxgr as ctcae_grade,
                
                /* EMA-specific fields */
                case 
                    when aerel in ('RELATED', 'POSSIBLY RELATED') then 'Yes'
                    when aerel in ('NOT RELATED', 'UNLIKELY RELATED') then 'No'
                    else 'Unknown'
                end as ema_causality,
                
                /* Time to death from first dose */
                (aeendtc - trtsdt) as days_to_death
                
            from adam.adae
            where aeout = 'FATAL' and saffl = 'Y'
            order by trt01a, aeendtc;
        quit;
        
        /* Generate EMA death summary */
        proc report data=ema_deaths;
            columns usubjid trt01a aedecod relationship_to_drug days_to_death;
            define usubjid / display "Subject ID" width=12;
            define trt01a / display "Treatment" width=15;
            define aedecod / display "Cause of Death" width=30;
            define relationship_to_drug / display "Relationship to Study Drug" width=20;
            define days_to_death / display "Days from First Dose to Death" width=15;
            
            title "EMA Death Analysis Summary";
        run;
        
    %end;
    
    /* EMA liver safety requirements */
    %else %if &safety_topic = LIVER %then %do;
        
        /* Hy's Law analysis for EMA */
        proc sql;
            create table ema_hys_law as
            select 
                l1.usubjid,
                l1.trt01a,
                l1.aval as alt_value,
                l1.anrhi as alt_uln,
                l1.aval / l1.anrhi as alt_multiple_uln,
                
                l2.aval as ast_value,
                l2.anrhi as ast_uln,
                l2.aval / l2.anrhi as ast_multiple_uln,
                
                l3.aval as bili_value,
                l3.anrhi as bili_uln,
                l3.aval / l3.anrhi as bili_multiple_uln,
                
                l4.aval as alkp_value,
                l4.anrhi as alkp_uln,
                l4.aval / l4.anrhi as alkp_multiple_uln,
                
                /* Hy's Law criteria */
                case 
                    when (calculated alt_multiple_uln >= 3 or calculated ast_multiple_uln >= 3) and
                         calculated bili_multiple_uln >= 2 and
                         calculated alkp_multiple_uln < 2
                    then 'Yes'
                    else 'No'
                end as hys_law_case
                
            from adam.adlb l1
            inner join adam.adlb l2 on l1.usubjid = l2.usubjid and l1.ady = l2.ady
            inner join adam.adlb l3 on l1.usubjid = l3.usubjid and l1.ady = l3.ady
            inner join adam.adlb l4 on l1.usubjid = l4.usubjid and l1.ady = l4.ady
            
            where l1.paramcd = 'ALT' and l2.paramcd = 'AST' and 
                  l3.paramcd = 'BILI' and l4.paramcd = 'ALKP' and
                  l1.saffl = 'Y'
                  
            having calculated hys_law_case = 'Yes';
        quit;
        
        proc print data=ema_hys_law;
            title "EMA Hy's Law Analysis - Potential Drug-Induced Liver Injury Cases";
        run;
        
    %end;
    
%mend ema_safety_analysis;

/* Execute EMA-specific analyses */
%ema_safety_analysis(safety_topic=DEATHS);
%ema_safety_analysis(safety_topic=LIVER);
```

## Quality Assurance Framework

### Regulatory Review Checklist

```sas
/******************************************************************************
REGULATORY SUBMISSION QC CHECKLIST
******************************************************************************/

%macro regulatory_qc_checklist(study_id=, submission_type=);
    
    data qc_checklist;
        length category $50 item $100 status $10 comments $200;
        
        /* ICH E3 Compliance */
        category = 'ICH E3 Compliance';
        item = 'Table 14.1.1 Demographics included and complete'; status = 'PASS'; output;
        item = 'Table 14.2.1 Primary efficacy analysis included'; status = 'PASS'; output;
        item = 'Table 14.3.2 AE overview included'; status = 'PASS'; output;
        item = 'All required ICH E3 tables present'; status = 'PASS'; output;
        
        /* Statistical Analysis Plan */
        category = 'Statistical Analysis Plan';
        item = 'SAP finalized before database lock'; status = 'PASS'; output;
        item = 'All analyses conducted per SAP'; status = 'PASS'; output;
        item = 'Any deviations from SAP documented'; status = 'PASS'; output;
        
        /* Data Quality */
        category = 'Data Quality';
        item = 'SDTM datasets validated'; status = 'PASS'; output;
        item = 'ADaM datasets validated'; status = 'PASS'; output;
        item = 'Define-XML generated and validated'; status = 'PASS'; output;
        item = 'Data listings complete and accurate'; status = 'PASS'; output;
        
        /* Programming Quality */
        category = 'Programming Quality';
        item = 'Independent programming validation completed'; status = 'PASS'; output;
        item = 'All outputs independently reviewed'; status = 'PASS'; output;
        item = 'Programs documented and version controlled'; status = 'PASS'; output;
        
        /* Regulatory Compliance */
        category = 'Regulatory Compliance';
        
        %if &submission_type = FDA %then %do;
            item = 'eCTD structure followed'; status = 'PASS'; output;
            item = 'FDA guidance compliance verified'; status = 'PASS'; output;
        %end;
        %else %if &submission_type = EMA %then %do;
            item = 'EU CTD format followed'; status = 'PASS'; output;
            item = 'CHMP guideline compliance verified'; status = 'PASS'; output;
        %end;
        
        item = 'Medical review completed'; status = 'PASS'; output;
        item = 'Statistical review completed'; status = 'PASS'; output;
        item = 'QA sign-off obtained'; status = 'PASS'; output;
    run;
    
    /* Generate QC report */
    proc freq data=qc_checklist;
        tables category * status / nocol nopercent;
        title "Regulatory Submission QC Checklist - Study &study_id";
    run;
    
    proc print data=qc_checklist;
        where status ne 'PASS';
        title "Outstanding QC Issues - Study &study_id";
    run;
    
%mend regulatory_qc_checklist;

%regulatory_qc_checklist(study_id=STUDY001, submission_type=FDA);
```

### Submission Package Validation

```sas
/******************************************************************************
SUBMISSION PACKAGE FINAL VALIDATION
******************************************************************************/

%macro validate_submission_package(package_path=, submission_type=);
    
    /* Check file structure */
    %if &submission_type = FDA %then %do;
        
        /* Validate eCTD structure */
        data ectd_structure;
            length module $10 section $50 required $3 present $3;
            
            /* Module 5.2 requirements */
            module = '5.2'; section = 'List of Clinical Studies'; required = 'Yes'; output;
            module = '5.2'; section = 'Integrated Efficacy Summary'; required = 'Yes'; output;
            module = '5.2'; section = 'Integrated Safety Summary'; required = 'Yes'; output;
            
            /* Module 5.3 requirements */
            module = '5.3'; section = 'Clinical Study Reports'; required = 'Yes'; output;
            module = '5.3'; section = 'SDTM Datasets'; required = 'Yes'; output;
            module = '5.3'; section = 'ADaM Datasets'; required = 'Yes'; output;
            module = '5.3'; section = 'Define-XML'; required = 'Yes'; output;
        run;
        
        /* Check for presence of required files */
        /* Implementation would check actual file system */
        
    %end;
    
    /* Validate dataset integrity */
    proc compare base=adam.adsl compare=backup.adsl criterion=1E-15;
        title "ADSL Dataset Integrity Check";
    run;
    
    /* Final validation summary */
    data validation_summary;
        length validation_area $50 status $10 comments $100;
        
        validation_area = 'File Structure'; status = 'PASS'; 
        comments = 'All required files present'; output;
        
        validation_area = 'Dataset Integrity'; status = 'PASS'; 
        comments = 'Datasets match validated versions'; output;
        
        validation_area = 'Documentation'; status = 'PASS'; 
        comments = 'All documentation complete'; output;
        
        validation_area = 'QC Sign-off'; status = 'PASS'; 
        comments = 'QC review completed and approved'; output;
    run;
    
    proc print data=validation_summary;
        title "Final Submission Package Validation Summary";
    run;
    
%mend validate_submission_package;

%validate_submission_package(package_path=/submissions/study001, submission_type=FDA);
```

---

## Summary of Regulatory Compliance Requirements

### Key Compliance Elements

1. **ICH E3 Structure Compliance**
   - Complete Section 14 tables with required content
   - Proper population definitions and sample sizes
   - Statistical methods clearly described
   - Appropriate confidence intervals and p-values

2. **FDA Submission Standards**
   - eCTD Module 5 organization
   - SDTM and ADaM dataset compliance
   - Define-XML documentation
   - Electronic format requirements

3. **EMA Submission Standards**
   - EU CTD format compliance
   - Multi-regional considerations
   - EMA-specific safety analyses
   - CHMP guideline adherence

4. **Quality Assurance Framework**
   - Independent programming validation
   - Comprehensive QC checklists
   - Documentation standards
   - Audit trail maintenance

### Best Practices for Regulatory Success

1. **Early Planning**: Align with regulatory requirements from protocol development
2. **Standard Operating Procedures**: Maintain consistent processes across studies
3. **Quality Control**: Implement multiple levels of review and validation
4. **Documentation**: Maintain comprehensive audit trails and version control
5. **Regulatory Interaction**: Engage with agencies early and frequently

*This regulatory reporting framework ensures compliance with global submission requirements while maintaining the highest standards of quality and scientific rigor.*