/******************************************************************************
PROGRAM: safety-analysis-template.sas
PURPOSE: Template for safety analysis in clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This template provides a standardized framework for conducting safety
analyses in clinical trials, following ICH E3 and regulatory guidelines
for adverse event reporting and analysis.

SECTIONS INCLUDED:
1. Environment Setup
2. Data Preparation
3. Safety Population Definition
4. Adverse Event Analysis
5. Laboratory Safety Analysis
6. Vital Signs Safety Analysis
7. Deaths, SAEs, and AEs Leading to Discontinuation
8. Safety Tables Generation
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
%let treatment_var = TRT01A; /* Actual treatment variable for safety */
%let safety_cutoff_days = 30; /* Days after last dose for AE attribution */

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

/* Subject-level analysis dataset */
data work.adsl;
    set adam.adsl;
    
    /* Calculate exposure duration */
    if not missing(TRTSDT) and not missing(TRTEDT) then do;
        EXPDUR = TRTEDT - TRTSDT + 1;
        EXPDURC = put(EXPDUR, best.);
    end;
    
    /* Exposure categories */
    length EXPDURGR1 $20;
    if not missing(EXPDUR) then do;
        if EXPDUR < 30 then EXPDURGR1 = '<30 days';
        else if EXPDUR < 90 then EXPDURGR1 = '30-89 days';  
        else if EXPDUR < 180 then EXPDURGR1 = '90-179 days';
        else EXPDURGR1 = '>=180 days';
    end;
run;

/* Adverse events analysis dataset */
data work.adae;
    set adam.adae;
    
    /* Treatment-emergent adverse events flag */
    if not missing(ASTDT) and not missing(TRTSDT) then do;
        if ASTDT >= TRTSDT then do;
            if missing(TRTEDT) or ASTDT <= TRTEDT + &safety_cutoff_days then
                TEAEFL = 'Y';
            else TEAEFL = 'N';
        end;
        else TEAEFL = 'N';
    end;
    
    /* Severity categories */
    length ASEVGR1N 8;
    select (upcase(ASEV));
        when ('MILD') ASEVGR1N = 1;
        when ('MODERATE') ASEVGR1N = 2;
        when ('SEVERE') ASEVGR1N = 3;
        otherwise ASEVGR1N = .;
    end;
    
    /* Relationship categories */
    length ARELGR1N 8;
    select (upcase(AREL));
        when ('NOT RELATED') ARELGR1N = 1;
        when ('UNLIKELY RELATED') ARELGR1N = 2;
        when ('POSSIBLY RELATED', 'PROBABLY RELATED', 'RELATED') ARELGR1N = 3;
        otherwise ARELGR1N = .;
    end;
run;

/* Laboratory analysis dataset */
data work.adlb;
    set adam.adlb;
    where SAFFL = 'Y'; /* Safety population only */
    
    /* Shift from baseline to worst post-baseline */
    if BNRIND ne '' and ANRIND ne '' then do;
        length BNRANRIND $20;
        BNRANRIND = cats(BNRIND, ' to ', ANRIND);
    end;
    
    /* Potentially clinically significant values */
    length PCSIFL $1;
    if upcase(PARAMCD) in ('ALT', 'AST') and AVAL > 3 * ANRHI then PCSIFL = 'Y';
    else if upcase(PARAMCD) = 'BILI' and AVAL > 2 * ANRHI then PCSIFL = 'Y';
    else if upcase(PARAMCD) in ('CREAT', 'BUN') and AVAL > 1.5 * ANRHI then PCSIFL = 'Y';
    else PCSIFL = 'N';
run;

/* Vital signs analysis dataset */
data work.advs;
    set adam.advs;
    where SAFFL = 'Y'; /* Safety population only */
    
    /* Potentially clinically significant vital signs */
    length PCSIFL $1 PCSICAT $50;
    PCSIFL = 'N';
    
    if upcase(PARAMCD) = 'SYSBP' then do;
        if AVAL >= 180 or AVAL <= 90 then do;
            PCSIFL = 'Y';
            if AVAL >= 180 then PCSICAT = 'Hypertension';
            else PCSICAT = 'Hypotension';
        end;
    end;
    else if upcase(PARAMCD) = 'DIABP' then do;
        if AVAL >= 110 or AVAL <= 50 then do;
            PCSIFL = 'Y';
            if AVAL >= 110 then PCSICAT = 'Hypertension';
            else PCSICAT = 'Hypotension';
        end;
    end;
    else if upcase(PARAMCD) = 'PULSE' then do;
        if AVAL >= 120 or AVAL <= 50 then do;
            PCSIFL = 'Y';
            if AVAL >= 120 then PCSICAT = 'Tachycardia';
            else PCSICAT = 'Bradycardia';
        end;
    end;
run;

/******************************************************************************
SECTION 3: SAFETY POPULATION DEFINITION
******************************************************************************/

/* Safety population summary */
proc freq data=work.adsl;
    tables &treatment_var * SAFFL / nocol nopercent missing;
    title1 "Safety Population Summary";
    title2 "Study: &study_id Protocol: &protocol";
    title3 "Analysis Date: &analysis_date";
run;

/* Exposure summary */
proc means data=work.adsl n mean std median q1 q3 min max;
    where SAFFL = 'Y';
    class &treatment_var;
    var EXPDUR;
    title4 "Treatment Exposure Duration (Days)";
run;

proc freq data=work.adsl;
    where SAFFL = 'Y';
    tables &treatment_var * EXPDURGR1 / nocol nopercent;
    title4 "Treatment Exposure Categories";
run;

/******************************************************************************
SECTION 4: ADVERSE EVENT ANALYSIS
******************************************************************************/

/* Treatment-emergent adverse events overview */
proc freq data=work.adae;
    where SAFFL = 'Y' and TEAEFL = 'Y';
    tables &treatment_var / nocol;
    title4 "Treatment-Emergent Adverse Events - Overview";
run;

/* AE summary by treatment */
data work.ae_summary;
    merge work.adsl(keep=USUBJID &treatment_var SAFFL
                    where=(SAFFL='Y'))
          work.adae(keep=USUBJID AESEQ TEAEFL AEDECOD AESEV AREL AESER AEACN
                    where=(TEAEFL='Y'));
    by USUBJID;
    
    /* Create flags for different AE categories */
    length ANY_AE ANY_REL_AE ANY_SAE ANY_SEV_AE DISC_AE 8;
    if not missing(AESEQ) then do;
        ANY_AE = 1;
        if upcase(AREL) in ('POSSIBLY RELATED', 'PROBABLY RELATED', 'RELATED') then ANY_REL_AE = 1;
        if upcase(AESER) = 'Y' then ANY_SAE = 1;
        if upcase(AESEV) = 'SEVERE' then ANY_SEV_AE = 1;
        if upcase(AEACN) in ('DRUG WITHDRAWN', 'DRUG INTERRUPTED') then DISC_AE = 1;
    end;
    else do;
        ANY_AE = 0;
        ANY_REL_AE = 0;
        ANY_SAE = 0;
        ANY_SEV_AE = 0;
        DISC_AE = 0;
    end;
run;

/* Subject-level AE summary */
proc sql;
    create table work.subj_ae_summary as
    select USUBJID, &treatment_var,
           max(ANY_AE) as ANY_AE,
           max(ANY_REL_AE) as ANY_REL_AE,
           max(ANY_SAE) as ANY_SAE,
           max(ANY_SEV_AE) as ANY_SEV_AE,
           max(DISC_AE) as DISC_AE
    from work.ae_summary
    group by USUBJID, &treatment_var;
quit;

/* AE incidence table */
proc freq data=work.subj_ae_summary;
    tables &treatment_var * (ANY_AE ANY_REL_AE ANY_SAE ANY_SEV_AE DISC_AE) / nocol;
    title4 "Adverse Event Incidence Summary";
run;

/* Most frequent AEs (>=5% in any treatment group) */
proc freq data=work.adae noprint;
    where SAFFL = 'Y' and TEAEFL = 'Y';
    tables AEDECOD * &treatment_var / out=work.ae_freq;
run;

proc transpose data=work.ae_freq out=work.ae_freq_t prefix=TRT;
    by AEDECOD;
    id &treatment_var;
    var COUNT;
run;

data work.ae_freq_pct;
    set work.ae_freq_t;
    
    /* Calculate percentages and identify frequent AEs */
    array trt_counts[*] TRT:;
    array trt_n[*] _temporary_;
    
    if _n_ = 1 then do;
        /* Get denominators from safety population */
        /* This would need to be calculated from ADSL */
    end;
    
    /* Flag AEs >=5% in any treatment */
    max_pct = 0;
    do i = 1 to dim(trt_counts);
        if not missing(trt_counts[i]) then do;
            /* pct = (trt_counts[i] / trt_n[i]) * 100; */
            /* max_pct = max(max_pct, pct); */
        end;
    end;
    
    if max_pct >= 5 then output;
run;

/* AEs by system organ class */
proc freq data=work.adae;
    where SAFFL = 'Y' and TEAEFL = 'Y';
    tables AESOC * &treatment_var / nocol;
    title4 "Adverse Events by System Organ Class";
run;

/******************************************************************************
SECTION 5: LABORATORY SAFETY ANALYSIS
******************************************************************************/

/* Laboratory shifts from normal at baseline */
proc freq data=work.adlb;
    where not missing(BNRIND) and not missing(ANRIND) and ANRIND ne 'NORMAL';
    tables PARAMCD * BNRANRIND / nocol list;
    title4 "Laboratory Parameter Shifts from Baseline";
run;

/* Potentially clinically significant laboratory values */
proc freq data=work.adlb;
    where PCSIFL = 'Y';
    tables PARAMCD * &treatment_var / nocol;
    title4 "Potentially Clinically Significant Laboratory Values";
run;

/* Laboratory outliers */
data work.lab_outliers;
    set work.adlb;
    
    /* Flag extreme outliers */
    length OUTLIER_FL $1;
    if not missing(AVAL) and not missing(ANRHI) then do;
        if AVAL > 3 * ANRHI then OUTLIER_FL = 'Y';
        else OUTLIER_FL = 'N';
    end;
    else if not missing(AVAL) and not missing(ANRLO) then do;
        if AVAL < 0.33 * ANRLO then OUTLIER_FL = 'Y';
        else OUTLIER_FL = 'N';
    end;
    else OUTLIER_FL = 'N';
run;

proc freq data=work.lab_outliers;
    where OUTLIER_FL = 'Y';
    tables PARAMCD * &treatment_var / nocol;
    title4 "Laboratory Extreme Outliers";
run;

/******************************************************************************
SECTION 6: VITAL SIGNS SAFETY ANALYSIS
******************************************************************************/

/* Potentially clinically significant vital signs */
proc freq data=work.advs;
    where PCSIFL = 'Y';
    tables PARAMCD * PCSICAT * &treatment_var / nocol;
    title4 "Potentially Clinically Significant Vital Signs";
run;

/* Vital signs summary statistics */
proc means data=work.advs n mean std;
    where PARAMCD in ('SYSBP', 'DIABP', 'PULSE', 'TEMP', 'RESP');
    class PARAMCD &treatment_var AVISIT;
    var AVAL CHG;
    title4 "Vital Signs Summary Statistics";
run;

/******************************************************************************
SECTION 7: DEATHS, SAEs, AND AEs LEADING TO DISCONTINUATION
******************************************************************************/

/* Deaths analysis */
data work.deaths;
    set work.adsl;
    where SAFFL = 'Y' and upcase(DTHFL) = 'Y';
    
    length DTHCAT $50;
    /* Categorize cause of death if available */
    if not missing(DTHCAT) then DTHCAT = DTHCAT;
    else DTHCAT = 'Unknown';
run;

proc freq data=work.deaths;
    tables &treatment_var * DTHCAT / fisher exact;
    title4 "Deaths by Treatment Group";
run;

/* Serious adverse events */
data work.saes;
    set work.adae;
    where SAFFL = 'Y' and TEAEFL = 'Y' and upcase(AESER) = 'Y';
    
    /* SAE categories */
    length SAECAT $100;
    if upcase(AESDTH) = 'Y' then SAECAT = 'Death';
    else if upcase(AESLIFE) = 'Y' then SAECAT = 'Life-threatening';
    else if upcase(AESHOSP) = 'Y' then SAECAT = 'Hospitalization';
    else if upcase(AESDISAB) = 'Y' then SAECAT = 'Disability/Incapacity';
    else if upcase(AESCONG) = 'Y' then SAECAT = 'Congenital Anomaly';
    else if upcase(AESMIE) = 'Y' then SAECAT = 'Important Medical Event';
    else SAECAT = 'Other Serious';
run;

proc freq data=work.saes;
    tables SAECAT * &treatment_var / nocol;
    title4 "Serious Adverse Events by Category";
run;

/* AEs leading to treatment discontinuation */
data work.disc_aes;
    set work.adae;
    where SAFFL = 'Y' and TEAEFL = 'Y' and upcase(AEACN) in ('DRUG WITHDRAWN');
run;

proc freq data=work.disc_aes;
    tables AEDECOD * &treatment_var / nocol;
    title4 "AEs Leading to Treatment Discontinuation";
run;

/******************************************************************************
SECTION 8: SAFETY TABLES GENERATION
******************************************************************************/

/* Generate standard safety tables */
ods rtf file="&output_path/Safety_Analysis_Tables.rtf";

title1 "Clinical Safety Analysis";
title2 "Study: &study_id Protocol: &protocol";
title3 "Data Cutoff: &data_cutoff Analysis Date: &analysis_date";

/* Table 1: Exposure Summary */
proc tabulate data=work.adsl;
    where SAFFL = 'Y';
    class &treatment_var;
    var EXPDUR;
    table &treatment_var, EXPDUR * (n mean std median min max) / box="Treatment Exposure (Days)";
    title4 "Table 1: Treatment Exposure Summary";
run;

/* Table 2: AE Overview */
proc tabulate data=work.subj_ae_summary;
    class &treatment_var ANY_AE ANY_REL_AE ANY_SAE ANY_SEV_AE DISC_AE;
    table (ANY_AE ANY_REL_AE ANY_SAE ANY_SEV_AE DISC_AE), &treatment_var * (n pctn) / box="Adverse Event Category";
    title4 "Table 2: Adverse Event Overview";
run;

/* Table 3: Most Frequent AEs */
proc freq data=work.adae;
    where SAFFL = 'Y' and TEAEFL = 'Y';
    tables AEDECOD * &treatment_var / nocol out=work.ae_table;
run;

proc sort data=work.ae_table;
    by descending COUNT;
run;

proc print data=work.ae_table(obs=20) label;
    title4 "Table 3: Most Frequent Adverse Events (Top 20)";
run;

/* Table 4: Laboratory Abnormalities */
proc freq data=work.adlb;
    where PCSIFL = 'Y';
    tables PARAM * &treatment_var / nocol;
    title4 "Table 4: Potentially Clinically Significant Laboratory Abnormalities";
run;

ods rtf close;

/******************************************************************************
TEMPLATE COMPLETION
******************************************************************************/

%put NOTE: Safety analysis template completed;
%put NOTE: Review all [PLACEHOLDER] values and modify as needed for your study;
%put NOTE: Key areas to customize:;
%put NOTE: - Study parameters (lines 15-19);
%put NOTE: - File paths (lines 21-25);
%put NOTE: - Treatment variable and safety cutoff (lines 27-29);
%put NOTE: - Clinically significant criteria (lines 89-124);
%put NOTE: - AE frequency threshold (line 257);

/* Log completion */
%put NOTE: Template execution completed at %sysfunc(datetime(), datetime20.);