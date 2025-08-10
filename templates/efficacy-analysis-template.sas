/******************************************************************************
PROGRAM: efficacy-analysis-template.sas
PURPOSE: Template for efficacy analysis in clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This template provides a standardized framework for conducting efficacy
analyses in clinical trials, following ICH E9 guidelines and regulatory
best practices.

SECTIONS INCLUDED:
1. Environment Setup
2. Data Preparation
3. Population Definition
4. Primary Endpoint Analysis
5. Secondary Endpoint Analysis
6. Subgroup Analyses
7. Sensitivity Analyses
8. Output Generation
******************************************************************************/

/******************************************************************************
SECTION 1: ENVIRONMENT SETUP
******************************************************************************/

/* Study parameters - MODIFY AS NEEDED */
%let study_id = [STUDY_ID];
%let protocol = [PROTOCOL_NUMBER];
%let data_cutoff = [DATA_CUTOFF_DATE];
%let analysis_date = %sysfunc(today(), date9.);

/* File paths - MODIFY AS NEEDED */
%let adam_path = [ADAM_DATA_PATH];
%let output_path = [OUTPUT_PATH];
%let program_path = [PROGRAM_PATH];

/* Analysis parameters - MODIFY AS NEEDED */
%let primary_endpoint = [PRIMARY_ENDPOINT_PARAMCD];
%let primary_visit = [PRIMARY_ANALYSIS_VISIT];
%let treatment_var = TRT01P;
%let alpha_level = 0.05;
%let power_target = 0.80;

/* Initialize environment */
%include "&program_path/clinical-macros.sas";

%setup_clinical_environment(
    study_id=&study_id,
    protocol=&protocol,
    data_cutoff=&data_cutoff,
    adam_path=&adam_path,
    output_path=&output_path
);

/******************************************************************************
SECTION 2: DATA PREPARATION
******************************************************************************/

/* Load required ADaM datasets */
libname adam "&adam_path";

data work.adsl;
    set adam.adsl;
    /* Add any ADSL derivations needed for analysis */
run;

data work.adeff;
    set adam.adeff; /* or appropriate efficacy dataset */
    /* Add any efficacy-specific derivations */
run;

/* Data integrity checks */
%check_data_integrity(
    data=work.adsl,
    key_vars=USUBJID,
    required_vars=USUBJID SUBJID &treatment_var ITTFL SAFFL,
    date_vars=RFSTDTC RFENDTC,
    numeric_vars=AGE
);

%check_data_integrity(
    data=work.adeff,
    key_vars=USUBJID PARAMCD AVISITN,
    required_vars=USUBJID PARAMCD AVAL ADT &treatment_var,
    date_vars=ADT,
    numeric_vars=AVAL CHG
);

/******************************************************************************
SECTION 3: POPULATION DEFINITION
******************************************************************************/

/* Create analysis populations */
%create_analysis_population(
    data=work.adsl,
    output=work.populations,
    safety_criteria=%str(SAFFL='Y'),
    itt_criteria=%str(ITTFL='Y' and not missing(&treatment_var)),
    pp_criteria=%str(PPROTFL='Y' and COMPLFL='Y')
);

/* Population summary */
proc freq data=work.populations;
    tables (&treatment_var) * (SAFFL ITTFL PPROTFL) / nocol nopercent;
    title1 "Population Summary by Treatment";
    title2 "Study: &study_id Protocol: &protocol";
    title3 "Analysis Date: &analysis_date";
run;

/******************************************************************************
SECTION 4: PRIMARY ENDPOINT ANALYSIS
******************************************************************************/

/* Primary efficacy analysis dataset */
data work.primary_analysis;
    merge work.adsl(keep=USUBJID &treatment_var ITTFL SAFFL AGE SEX RACE
                    where=(ITTFL='Y'))
          work.adeff(keep=USUBJID PARAMCD AVISIT AVISITN AVAL AVALC CHG BASE
                     where=(PARAMCD="&primary_endpoint" and AVISIT="&primary_visit"));
    by USUBJID;
    
    if first.USUBJID and last.USUBJID; /* Ensure one record per subject */
    
    /* Create analysis variables */
    length ANLY01FL $1;
    if not missing(AVAL) and not missing(&treatment_var) then ANLY01FL = 'Y';
    else ANLY01FL = 'N';
    
    /* Treatment groups for analysis */
    length TRT01PN 8;
    select (upcase(&treatment_var));
        when ('PLACEBO') TRT01PN = 0;
        when ('ACTIVE LOW DOSE', 'LOW DOSE') TRT01PN = 1;
        when ('ACTIVE HIGH DOSE', 'HIGH DOSE') TRT01PN = 2;
        when ('ACTIVE', 'TREATMENT') TRT01PN = 1;
        otherwise TRT01PN = .;
    end;
run;

/* Primary endpoint descriptive statistics */
proc means data=work.primary_analysis n mean std median q1 q3 min max;
    class &treatment_var;
    var AVAL CHG;
    title4 "Primary Endpoint: &primary_endpoint at &primary_visit";
    title5 "Descriptive Statistics";
run;

/* Primary efficacy analysis - ANCOVA model */
%perform_efficacy_analysis(
    data=work.primary_analysis,
    parameter=&primary_endpoint,
    visit=&primary_visit,
    population=ITT,
    treatment_var=&treatment_var,
    analysis_var=CHG,
    method=ANCOVA
);

/* Alternative: MMRM analysis if longitudinal data */
/*
%perform_efficacy_analysis(
    data=work.adeff,
    parameter=&primary_endpoint,
    visit=ALL,
    population=ITT,
    treatment_var=&treatment_var,
    analysis_var=CHG,
    method=MMRM
);
*/

/******************************************************************************
SECTION 5: SECONDARY ENDPOINT ANALYSIS
******************************************************************************/

/* Define secondary endpoints - MODIFY AS NEEDED */
%let secondary_endpoints = PARAM2 PARAM3 PARAM4;
%let secondary_visits = WEEK12 WEEK24 EOT;

/* Secondary endpoint analyses */
%let endpoint_count = %sysfunc(countw(&secondary_endpoints));
%do i = 1 %to &endpoint_count;
    %let endpoint = %scan(&secondary_endpoints, &i);
    
    %let visit_count = %sysfunc(countw(&secondary_visits));
    %do j = 1 %to &visit_count;
        %let visit = %scan(&secondary_visits, &j);
        
        %perform_efficacy_analysis(
            data=work.adeff,
            parameter=&endpoint,
            visit=&visit,
            population=ITT,
            treatment_var=&treatment_var,
            analysis_var=CHG,
            method=ANCOVA
        );
    %end;
%end;

/* Response rate analysis (if applicable) */
data work.response_analysis;
    set work.adeff;
    where PARAMCD in ('RESPONSE', 'RESPRATE') and AVISIT = "&primary_visit";
    
    /* Binary response variable */
    length RESPFL $1;
    if upcase(AVALC) in ('COMPLETE RESPONSE', 'PARTIAL RESPONSE', 'CR', 'PR') then RESPFL = 'Y';
    else if not missing(AVALC) then RESPFL = 'N';
run;

/* Response rate comparison */
proc freq data=work.response_analysis;
    tables &treatment_var * RESPFL / chisq fisher exact;
    title4 "Response Rate Analysis";
run;

/******************************************************************************
SECTION 6: SUBGROUP ANALYSES
******************************************************************************/

/* Define subgroup variables - MODIFY AS NEEDED */
%let subgroup_vars = SEX AGEGR1 RACEGR1 REGION;

/* Subgroup analysis for primary endpoint */
%let subgroup_count = %sysfunc(countw(&subgroup_vars));
%do i = 1 %to &subgroup_count;
    %let subgroup = %scan(&subgroup_vars, &i);
    
    /* Forest plot data preparation */
    proc mixed data=work.primary_analysis;
        class &treatment_var &subgroup USUBJID;
        model CHG = &treatment_var &subgroup &treatment_var*&subgroup BASE / solution;
        lsmeans &treatment_var*&subgroup / diff cl;
        ods output lsmeans=work.lsmeans_&i diffs=work.diffs_&i;
        title4 "Subgroup Analysis by &subgroup";
    run;
    
    /* Process results for forest plot */
    data work.forest_data_&i;
        set work.diffs_&i;
        where _&treatment_var = 'ACTIVE' and __&treatment_var = 'PLACEBO'; /* Modify as needed */
        
        subgroup_var = "&subgroup";
        subgroup_level = &subgroup;
        treatment_diff = estimate;
        lower_cl = lower;
        upper_cl = upper;
        p_value = probt;
        
        keep subgroup_var subgroup_level treatment_diff lower_cl upper_cl p_value;
    run;
%end;

/* Combine subgroup results */
data work.all_subgroups;
    set work.forest_data_1 - work.forest_data_&subgroup_count;
run;

/* Forest plot */
proc sgplot data=work.all_subgroups;
    scatter x=treatment_diff y=subgroup_level / xerrorlower=lower_cl xerrorupper=upper_cl;
    refline 0 / axis=x;
    title4 "Forest Plot - Treatment Effect by Subgroup";
    xaxis label="Treatment Difference (95% CI)";
    yaxis label="Subgroup";
run;

/******************************************************************************
SECTION 7: SENSITIVITY ANALYSES
******************************************************************************/

/* Sensitivity Analysis 1: Per-Protocol Population */
data work.pp_analysis;
    merge work.adsl(keep=USUBJID &treatment_var PPROTFL
                    where=(PPROTFL='Y'))
          work.adeff(keep=USUBJID PARAMCD AVISIT AVAL CHG BASE
                     where=(PARAMCD="&primary_endpoint" and AVISIT="&primary_visit"));
    by USUBJID;
    
    if not missing(AVAL) and not missing(&treatment_var);
run;

%perform_efficacy_analysis(
    data=work.pp_analysis,
    parameter=&primary_endpoint,
    visit=&primary_visit,
    population=PP,
    treatment_var=&treatment_var,
    analysis_var=CHG,
    method=ANCOVA
);

/* Sensitivity Analysis 2: Missing Data Handling */
/* Worst case imputation */
data work.worst_case;
    set work.primary_analysis;
    
    /* Impute missing efficacy values with worst outcome */
    if missing(CHG) then do;
        if &treatment_var = 'PLACEBO' then CHG = 0; /* No improvement */
        else CHG = -10; /* Worsening for active treatment */
    end;
run;

%perform_efficacy_analysis(
    data=work.worst_case,
    parameter=&primary_endpoint,
    visit=&primary_visit,
    population=ITT_WORST,
    treatment_var=&treatment_var,
    analysis_var=CHG,
    method=ANCOVA
);

/* Sensitivity Analysis 3: Outlier Analysis */
proc univariate data=work.primary_analysis;
    var CHG;
    output out=work.outlier_bounds p5=p5 p95=p95;
run;

data work.no_outliers;
    set work.primary_analysis;
    
    if _n_ = 1 then set work.outlier_bounds;
    
    /* Flag and exclude extreme outliers */
    if CHG < p5 or CHG > p95 then delete;
run;

%perform_efficacy_analysis(
    data=work.no_outliers,
    parameter=&primary_endpoint,
    visit=&primary_visit,
    population=ITT_NO_OUTLIERS,
    treatment_var=&treatment_var,
    analysis_var=CHG,
    method=ANCOVA
);

/******************************************************************************
SECTION 8: OUTPUT GENERATION
******************************************************************************/

/* Create final efficacy tables */
%generate_efficacy_table(
    data=work.primary_analysis,
    parameter=&primary_endpoint,
    treatment_var=&treatment_var,
    output_file=&output_path/Table_Primary_Efficacy,
    title=Primary Efficacy Analysis
);

/* Generate figures */
proc sgplot data=work.primary_analysis;
    vbox CHG / category=&treatment_var;
    title4 "Primary Endpoint Distribution by Treatment";
run;

/* Summary of all analyses */
ods rtf file="&output_path/Efficacy_Analysis_Summary.rtf";

title1 "Efficacy Analysis Summary";
title2 "Study: &study_id Protocol: &protocol";
title3 "Data Cutoff: &data_cutoff Analysis Date: &analysis_date";

proc print data=work.analysis_summary label;
    title4 "Summary of All Efficacy Analyses";
run;

ods rtf close;

/******************************************************************************
TEMPLATE COMPLETION
******************************************************************************/

%put NOTE: Efficacy analysis template completed;
%put NOTE: Review all [PLACEHOLDER] values and modify as needed for your study;
%put NOTE: Key areas to customize:;
%put NOTE: - Study parameters (lines 15-25);
%put NOTE: - File paths (lines 27-31);
%put NOTE: - Analysis parameters (lines 33-39);
%put NOTE: - Primary/secondary endpoints (lines 89, 180);
%put NOTE: - Subgroup variables (line 226);
%put NOTE: - Population criteria (line 73);

/* Log completion */
%put NOTE: Template execution completed at %sysfunc(datetime(), datetime20.);