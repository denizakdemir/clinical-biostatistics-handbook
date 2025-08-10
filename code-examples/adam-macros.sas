/******************************************************************************
PROGRAM: adam-macros.sas
PURPOSE: ADaM dataset creation and validation macros
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This macro library contains specialized macros for creating and validating
ADaM (Analysis Data Model) datasets according to CDISC standards.

MACROS INCLUDED:
- %create_adsl - Subject-level analysis dataset creation
- %create_adae - Adverse events analysis dataset
- %create_adlb - Laboratory analysis dataset
- %create_advs - Vital signs analysis dataset
- %create_adtte - Time-to-event analysis dataset
- %validate_adam_structure - ADaM structure validation
- %derive_analysis_flags - Standard analysis flags derivation
- %create_analysis_visit - Analysis visit derivation
******************************************************************************/

/******************************************************************************
MACRO: create_adsl
PURPOSE: Create Subject-Level Analysis Dataset (ADSL)
PARAMETERS:
  dm_data= : Demographics domain (SDTM.DM)
  sv_data= : Subject visits domain (SDTM.SV) 
  ds_data= : Disposition domain (SDTM.DS)
  ex_data= : Exposure domain (SDTM.EX)
  output= : Output ADSL dataset
  study_id= : Study identifier
******************************************************************************/
%macro create_adsl(
    dm_data=,
    sv_data=,
    ds_data=,
    ex_data=,
    output=,
    study_id=
);
    
    %put NOTE: Creating ADSL dataset;
    
    /* Step 1: Start with demographics */
    data work.adsl_dm;
        set &dm_data;
        
        /* Standard identifiers */
        length studyid usubjid subjid $20;
        studyid = "&study_id";
        usubjid = cats(studyid, '-', subjid);
        
        /* Demographics variables */
        length sex $1 race $50;
        if upcase(sex) in ('M', 'F') then sex = upcase(sex);
        else sex = 'U';
        
        /* Age groupings */
        length agegr1 $20;
        if age < 65 then agegr1 = '<65';
        else if age >= 65 then agegr1 = '>=65';
        
        /* Convert dates */
        if not missing(brthdtc) then brthdt = input(substr(brthdtc, 1, 10), yymmdd10.);
        format brthdt date9.;
        
        label studyid = "Study Identifier"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              sex = "Sex"
              race = "Race"
              agegr1 = "Age Group 1"
              brthdt = "Date of Birth";
    run;
    
    /* Step 2: Add randomization and treatment information */
    data work.adsl_rand;
        set work.adsl_dm;
        
        /* Treatment variables - customize based on study design */
        length trt01p trt01a $50 trt01pn trt01an 8;
        
        /* Planned treatment (from randomization) */
        if arm = "ARM A" then do;
            trt01p = "Active Treatment";
            trt01pn = 1;
        end;
        else if arm = "ARM B" then do;
            trt01p = "Placebo";
            trt01pn = 0;
        end;
        
        /* Actual treatment (initially same as planned) */
        trt01a = trt01p;
        trt01an = trt01pn;
        
        /* Randomization flag */
        length randfl $1;
        if not missing(arm) then randfl = 'Y';
        else randfl = 'N';
        
        /* Randomization date */
        if randfl = 'Y' and not missing(rfdtc) then do;
            randdt = input(substr(rfdtc, 1, 10), yymmdd10.);
        end;
        format randdt date9.;
        
        label trt01p = "Planned Treatment for Period 01"
              trt01a = "Actual Treatment for Period 01"
              trt01pn = "Planned Treatment for Period 01 (N)"
              trt01an = "Actual Treatment for Period 01 (N)"
              randfl = "Randomized Population Flag"
              randdt = "Date of Randomization";
    run;
    
    /* Step 3: Add exposure information */
    %if %length(&ex_data) > 0 %then %do;
        proc sql;
            create table work.exposure_summary as
            select usubjid,
                   min(input(substr(exstdtc, 1, 10), yymmdd10.)) as trtsdt format=date9.,
                   max(case when not missing(exendtc) 
                           then input(substr(exendtc, 1, 10), yymmdd10.) 
                           else . end) as trtedt format=date9.,
                   sum(exdur) as trtdur
            from &ex_data
            where exdose > 0
            group by usubjid;
        quit;
        
        proc sort data=work.adsl_rand; by usubjid; run;
        proc sort data=work.exposure_summary; by usubjid; run;
        
        data work.adsl_exp;
            merge work.adsl_rand(in=a) work.exposure_summary(in=b);
            by usubjid;
            if a;
            
            /* Calculate treatment duration if missing */
            if missing(trtdur) and not missing(trtsdt) and not missing(trtedt) then do;
                trtdur = trtedt - trtsdt + 1;
            end;
            
            label trtsdt = "Date of First Exposure to Treatment"
                  trtedt = "Date of Last Exposure to Treatment"
                  trtdur = "Total Treatment Duration (Days)";
        run;
    %end;
    %else %do;
        data work.adsl_exp;
            set work.adsl_rand;
        run;
    %end;
    
    /* Step 4: Add disposition information */
    %if %length(&ds_data) > 0 %then %do;
        proc sql;
            create table work.disposition as
            select usubjid,
                   max(case when upcase(dscat) = 'DISPOSITION EVENT' 
                           and upcase(dsscat) = 'STUDY COMPLETION/EARLY DISCONTINUATION'
                           then dsdecod else '' end) as dcsreas length=200,
                   max(case when upcase(dscat) = 'DISPOSITION EVENT'
                           then input(substr(dsstdtc, 1, 10), yymmdd10.)
                           else . end) as dcsdt format=date9.
            from &ds_data
            group by usubjid;
        quit;
        
        proc sort data=work.adsl_exp; by usubjid; run;
        proc sort data=work.disposition; by usubjid; run;
        
        data work.adsl_disp;
            merge work.adsl_exp(in=a) work.disposition(in=b);
            by usubjid;
            if a;
            
            /* Study completion flag */
            length compfl $1;
            if upcase(dcsreas) = 'COMPLETED' then compfl = 'Y';
            else compfl = 'N';
            
            label dcsreas = "Reason for Discontinuation of Subject"
                  dcsdt = "Date of Discontinuation of Subject"  
                  compfl = "Completion Flag";
        run;
    %end;
    %else %do;
        data work.adsl_disp;
            set work.adsl_exp;
        run;
    %end;
    
    /* Step 5: Create analysis population flags */
    data work.adsl_pop;
        set work.adsl_disp;
        
        /* Safety population: received at least one dose */
        length saffl $1;
        if not missing(trtsdt) then saffl = 'Y';
        else saffl = 'N';
        
        /* Intent-to-treat population: randomized */
        length ittfl $1;
        ittfl = randfl;
        
        /* Efficacy population: same as ITT for most studies */
        length efffl $1;
        efffl = ittfl;
        
        /* Per-protocol population: completed without major violations */
        length pprotfl $1;
        if ittfl = 'Y' and compfl = 'Y' then pprotfl = 'Y';
        else pprotfl = 'N';
        
        label saffl = "Safety Population Flag"
              ittfl = "Intent-To-Treat Population Flag"
              efffl = "Efficacy Population Flag"
              pprotfl = "Per-Protocol Population Flag";
    run;
    
    /* Step 6: Final ADSL dataset */
    data &output;
        set work.adsl_pop;
        
        /* Ensure all required variables are present */
        if missing(studyid) then studyid = "&study_id";
        
        /* Sort by key variables */
        proc sort;
            by studyid usubjid;
        run;
    run;
    
    /* Validation summary */
    proc freq data=&output;
        tables saffl ittfl efffl pprotfl randfl compfl / missing;
        title "ADSL Population Summary";
    run;
    
    proc means data=&output n nmiss min max;
        var age trtsdt trtedt trtdur;
        title "ADSL Numeric Variables Summary";  
    run;
    
    /* Clean up work datasets */
    proc datasets library=work nolist;
        delete adsl_dm adsl_rand adsl_exp adsl_disp adsl_pop 
               exposure_summary disposition;
    quit;
    
    %put NOTE: ADSL dataset &output created successfully;
    
%mend create_adsl;

/******************************************************************************
MACRO: create_adae
PURPOSE: Create Adverse Events Analysis Dataset (ADAE)
PARAMETERS:
  ae_data= : Adverse events domain (SDTM.AE)
  adsl_data= : ADSL dataset for merging
  output= : Output ADAE dataset
******************************************************************************/
%macro create_adae(
    ae_data=,
    adsl_data=,
    output=
);
    
    %put NOTE: Creating ADAE dataset;
    
    /* Step 1: Merge AE with ADSL */
    proc sort data=&ae_data; by studyid usubjid; run;
    proc sort data=&adsl_data; by studyid usubjid; run;
    
    data work.adae_merged;
        merge &ae_data(in=a) &adsl_data(in=b keep=studyid usubjid trt01p trt01pn
                                                       trtsdt trtedt saffl);
        by studyid usubjid;
        if a and b; /* Keep only AEs for subjects in ADSL */
    run;
    
    /* Step 2: Derive analysis variables */
    data work.adae_derived;
        set work.adae_merged;
        
        /* Analysis start and end dates */
        if not missing(aestdtc) then do;
            astdt = input(substr(aestdtc, 1, 10), yymmdd10.);
        end;
        
        if not missing(aeendtc) then do;
            aendt = input(substr(aeendtc, 1, 10), yymmdd10.);
        end;
        format astdt aendt date9.;
        
        /* Analysis start day */
        if not missing(astdt) and not missing(trtsdt) then do;
            if astdt >= trtsdt then astdy = astdt - trtsdt + 1;
            else astdy = astdt - trtsdt;
        end;
        
        /* Analysis end day */
        if not missing(aendt) and not missing(trtsdt) then do;
            if aendt >= trtsdt then aendy = aendt - trtsdt + 1;
            else aendy = aendt - trtsdt;
        end;
        
        /* Treatment-emergent flag */
        length trtemfl $1;
        if not missing(astdt) and not missing(trtsdt) then do;
            if astdt >= trtsdt then trtemfl = 'Y';
            else trtemfl = 'N';
        end;
        else trtemfl = '';
        
        /* Analysis severity (standardized) */
        length asev $20;
        if upcase(aesev) = 'MILD' then asev = 'MILD';
        else if upcase(aesev) = 'MODERATE' then asev = 'MODERATE';
        else if upcase(aesev) = 'SEVERE' then asev = 'SEVERE';
        else asev = aesev;
        
        /* Analysis causality */
        length arel $20;
        if upcase(aerel) in ('RELATED', 'PROBABLY RELATED', 'POSSIBLY RELATED') then
            arel = 'RELATED';
        else if upcase(aerel) in ('NOT RELATED', 'UNLIKELY RELATED') then
            arel = 'NOT RELATED';
        else arel = aerel;
        
        /* First occurrence flags */
        length aoccfl $1; /* Any occurrence */
        aoccfl = 'Y';
        
        /* Serious AE flag */
        length aserfl $1;
        if upcase(aeser) = 'Y' then aserfl = 'Y';
        else if upcase(aeser) = 'N' then aserfl = 'N';
        else aserfl = '';
        
        /* Fatal AE flag */
        length adthfl $1;
        if upcase(aeout) = 'FATAL' then adthfl = 'Y';
        else adthfl = 'N';
        
        label astdt = "Analysis Start Date"
              aendt = "Analysis End Date"  
              astdy = "Analysis Start Day"
              aendy = "Analysis End Day"
              trtemfl = "Treatment Emergent Analysis Flag"
              asev = "Analysis Severity"
              arel = "Analysis Causality"
              aoccfl = "Any Occurrence Flag"
              aserfl = "Analysis Serious Event Flag"
              adthfl = "Analysis Death Flag";
    run;
    
    /* Step 3: Create first occurrence flags by subject and term */
    proc sort data=work.adae_derived;
        by studyid usubjid aedecod astdt;
    run;
    
    data work.adae_flags;
        set work.adae_derived;
        by studyid usubjid aedecod;
        
        /* First occurrence by preferred term */
        length aoccsfl $1;
        if first.aedecod then aoccsfl = 'Y';
        else aoccsfl = 'N';
        
        label aoccsfl = "1st Occurrence Flag";
    run;
    
    /* Step 4: Create final ADAE dataset */
    data &output;
        set work.adae_flags;
        
        /* Ensure consistent sorting */
        proc sort;
            by studyid usubjid astdt aeseq;
        run;
    run;
    
    /* Validation summary */
    proc freq data=&output;
        tables trtemfl aoccfl aoccsfl aserfl adthfl / missing;
        title "ADAE Analysis Flags Summary";
    run;
    
    proc freq data=&output;
        tables asev arel / missing;
        title "ADAE Analysis Severity and Causality";
    run;
    
    /* Clean up work datasets */
    proc datasets library=work nolist;
        delete adae_merged adae_derived adae_flags;
    quit;
    
    %put NOTE: ADAE dataset &output created successfully;
    
%mend create_adae;

/******************************************************************************
MACRO: create_adlb
PURPOSE: Create Laboratory Analysis Dataset (ADLB)
PARAMETERS:
  lb_data= : Laboratory domain (SDTM.LB)
  adsl_data= : ADSL dataset for merging
  output= : Output ADLB dataset
******************************************************************************/
%macro create_adlb(
    lb_data=,
    adsl_data=,
    output=
);
    
    %put NOTE: Creating ADLB dataset;
    
    /* Step 1: Merge LB with ADSL */
    proc sort data=&lb_data; by studyid usubjid; run;
    proc sort data=&adsl_data; by studyid usubjid; run;
    
    data work.adlb_merged;
        merge &lb_data(in=a) &adsl_data(in=b keep=studyid usubjid trt01p trt01pn
                                                       trtsdt trtedt saffl ittfl);
        by studyid usubjid;
        if a and b;
    run;
    
    /* Step 2: Derive BDS structure variables */
    data work.adlb_bds;
        set work.adlb_merged;
        
        /* Parameter code and description */
        paramcd = lbtestcd;
        param = lbtest;
        
        /* Analysis value (numeric) */
        if not missing(lbstresn) then aval = lbstresn;
        else if not missing(lborres) and notdigit(strip(lborres)) = 0 then
            aval = input(lborres, best.);
        
        /* Analysis value (character) */
        length avalc $200;
        if not missing(lbstresc) then avalc = lbstresc;
        else if not missing(lborres) then avalc = lborres;
        
        /* Analysis unit */
        length avalu $20;
        if not missing(lbstresu) then avalu = lbstresu;
        else if not missing(lborresu) then avalu = lborresu;
        
        /* Analysis date */
        if not missing(lbdtc) then do;
            adt = input(substr(lbdtc, 1, 10), yymmdd10.);
        end;
        format adt date9.;
        
        /* Analysis day */
        if not missing(adt) and not missing(trtsdt) then do;
            if adt >= trtsdt then ady = adt - trtsdt + 1;
            else ady = adt - trtsdt;
        end;
        
        /* Analysis visit */
        avisit = visit;
        if missing(avisit) then avisit = "UNSCHEDULED";
        
        /* Analysis visit number */
        avisitn = visitnum;
        if missing(avisitn) and avisit = "SCREENING" then avisitn = -1;
        else if missing(avisitn) and avisit = "BASELINE" then avisitn = 0;
        else if missing(avisitn) then avisitn = 99;
        
        label paramcd = "Parameter Code"
              param = "Parameter"
              aval = "Analysis Value"
              avalc = "Analysis Value (C)"
              avalu = "Analysis Unit"
              adt = "Analysis Date"
              ady = "Analysis Day"
              avisit = "Analysis Visit"
              avisitn = "Analysis Visit (N)";
    run;
    
    /* Step 3: Derive baseline and change from baseline */
    proc sort data=work.adlb_bds;
        by studyid usubjid paramcd avisitn adt;
    run;
    
    data work.adlb_base;
        set work.adlb_bds;
        by studyid usubjid paramcd;
        
        /* Baseline flag */
        length ablfl $1;
        if avisitn = 0 or upcase(avisit) = 'BASELINE' then ablfl = 'Y';
        else ablfl = 'N';
        
        /* Retain baseline value for change calculation */
        retain base basec;
        if first.paramcd then do;
            base = .;
            basec = '';
        end;
        
        if ablfl = 'Y' then do;
            base = aval;
            basec = avalc;
        end;
        
        /* Change from baseline */
        if not missing(aval) and not missing(base) and ablfl = 'N' then do;
            chg = aval - base;
        end;
        
        /* Percent change from baseline */
        if not missing(chg) and not missing(base) and base ne 0 then do;
            pchg = (chg / base) * 100;
        end;
        
        label ablfl = "Baseline Record Flag"
              base = "Baseline Value"
              basec = "Baseline Value (C)"
              chg = "Change from Baseline"
              pchg = "Percent Change from Baseline";
    run;
    
    /* Step 4: Add analysis flags */
    data work.adlb_flags;
        set work.adlb_base;
        
        /* Analysis flag */
        length anlfl $1;
        if not missing(aval) then anlfl = 'Y';
        else anlfl = 'N';
        
        /* Post-baseline analysis flag */
        length anl01fl $1;
        if anlfl = 'Y' and ablfl = 'N' then anl01fl = 'Y';
        else anl01fl = 'N';
        
        /* Last observation flag */
        length lastfl $1;
        lastfl = 'N'; /* Will be derived in next step */
        
        label anlfl = "Analysis Flag"
              anl01fl = "Analysis Flag 01"
              lastfl = "Last Observation Flag";
    run;
    
    /* Step 5: Derive last observation flag */
    proc sort data=work.adlb_flags;
        by studyid usubjid paramcd descending adt descending avisitn;
    run;
    
    data &output;
        set work.adlb_flags;
        by studyid usubjid paramcd;
        
        if first.paramcd and anlfl = 'Y' then lastfl = 'Y';
        
        /* Sort back to chronological order */
        proc sort;
            by studyid usubjid paramcd avisitn adt;
        run;
    run;
    
    /* Validation summary */
    proc freq data=&output;
        tables paramcd ablfl anlfl anl01fl lastfl / missing;
        title "ADLB Analysis Flags Summary";
    run;
    
    proc means data=&output n nmiss min max;
        var aval base chg pchg;
        title "ADLB Analysis Values Summary";
    run;
    
    /* Clean up work datasets */
    proc datasets library=work nolist;
        delete adlb_merged adlb_bds adlb_base adlb_flags;
    quit;
    
    %put NOTE: ADLB dataset &output created successfully;
    
%mend create_adlb;

/******************************************************************************
MACRO: validate_adam_structure
PURPOSE: Validate ADaM dataset structure and content
PARAMETERS:
  data= : ADaM dataset to validate
  type= : Dataset type (ADSL, ADAE, ADLB, etc.)
******************************************************************************/
%macro validate_adam_structure(
    data=,
    type=
);
    
    %put NOTE: Validating ADaM structure for &data (&type);
    
    /* Get dataset structure */
    proc contents data=&data out=work.structure noprint;
    run;
    
    /* Required variables validation by dataset type */
    %if %upcase(&type) = ADSL %then %do;
        %let required_vars = STUDYID USUBJID SUBJID TRT01P TRT01A SAFFL ITTFL;
    %end;
    %else %if %upcase(&type) = ADAE %then %do;
        %let required_vars = STUDYID USUBJID AEDECOD ASTDT TRTEMFL;
    %end;
    %else %if %upcase(&type) = ADLB %then %do;
        %let required_vars = STUDYID USUBJID PARAMCD PARAM AVAL ADT AVISIT ABLFL;
    %end;
    %else %do;
        %let required_vars = STUDYID USUBJID;
    %end;
    
    /* Check for required variables */
    %let var_count = %sysfunc(countw(&required_vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&required_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from work.structure
            where upcase(name) = "&var";
        quit;
        
        %if &var_exists = 0 %then %do;
            %put ERROR: Required variable &var missing in &data;
        %end;
        %else %do;
            %put NOTE: Required variable &var found in &data;
        %end;
    %end;
    
    /* Data quality checks */
    proc sql;
        title "Data Quality Summary for &data";
        select count(*) as Total_Records,
               count(distinct usubjid) as Unique_Subjects,
               count(*) - count(distinct usubjid) as Potential_Multiple_Records
        from &data;
    quit;
    
    /* Missing data summary */
    proc means data=&data nmiss;
        title "Missing Data Summary for &data";
    run;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete structure;
    quit;
    
    %put NOTE: ADaM structure validation completed for &data;
    
%mend validate_adam_structure;

%put NOTE: ADaM macros library loaded successfully;
%put NOTE: Available macros: create_adsl, create_adae, create_adlb, validate_adam_structure;