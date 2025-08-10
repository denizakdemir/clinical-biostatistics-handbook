# Quality Control Programs for CDISC Datasets

## SDTM Quality Control Programs

### Domain-Level Validation Macro

```sas
/******************************************************************************
PROGRAM: sdtm_domain_validation.sas
PURPOSE: Comprehensive SDTM domain validation
AUTHOR: [Author Name]
DATE: [Date]
******************************************************************************/

%macro validate_sdtm_domain(domain=, lib=sdtm);
    
    %let domain = %upcase(&domain);
    
    /* Initialize validation results dataset */
    data validation_results;
        length check_type $50 domain $8 variable $32 issue_desc $200 
               severity $10 record_count 8;
        stop;
    run;
    
    /* Check 1: Dataset existence */
    %if not %sysfunc(exist(&lib..&domain)) %then %do;
        data temp_results;
            check_type = "DATASET_EXISTENCE";
            domain = "&domain";
            variable = "";
            issue_desc = "Dataset &lib..&domain does not exist";
            severity = "CRITICAL";
            record_count = 0;
        run;
        
        proc append base=validation_results data=temp_results force;
        run;
        
        %goto exit;
    %end;
    
    /* Get dataset contents */
    proc contents data=&lib..&domain out=contents noprint;
    run;
    
    /* Check 2: Required variables present */
    %let req_vars = STUDYID DOMAIN USUBJID;
    
    %do i = 1 %to %sysfunc(countw(&req_vars));
        %let var = %scan(&req_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from contents
            where upcase(name) = "&var";
        quit;
        
        %if &var_exists = 0 %then %do;
            data temp_results;
                check_type = "REQUIRED_VARIABLE";
                domain = "&domain";
                variable = "&var";
                issue_desc = "Required variable &var is missing";
                severity = "CRITICAL";
                record_count = .;
            run;
            
            proc append base=validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 3: USUBJID uniqueness (Special Purpose domains) */
    %if &domain in (DM CO SE) %then %do;
        proc freq data=&lib..&domain noprint;
            tables usubjid / out=usubjid_freq;
        run;
        
        proc sql noprint;
            select count(*) into :dup_usubjid
            from usubjid_freq
            where count > 1;
        quit;
        
        %if &dup_usubjid > 0 %then %do;
            data temp_results;
                check_type = "USUBJID_UNIQUENESS";
                domain = "&domain";
                variable = "USUBJID";
                issue_desc = "&dup_usubjid subjects have duplicate USUBJID values";
                severity = "CRITICAL";
                record_count = &dup_usubjid;
            run;
            
            proc append base=validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 4: DOMAIN variable consistency */
    proc sql noprint;
        select count(*) into :wrong_domain
        from &lib..&domain
        where domain ne "&domain";
    quit;
    
    %if &wrong_domain > 0 %then %do;
        data temp_results;
            check_type = "DOMAIN_CONSISTENCY";
            domain = "&domain";
            variable = "DOMAIN";
            issue_desc = "&wrong_domain records have incorrect DOMAIN value";
            severity = "MAJOR";
            record_count = &wrong_domain;
        run;
        
        proc append base=validation_results data=temp_results force;
        run;
    %end;
    
    /* Check 5: Date format validation (ISO 8601) */
    data date_issues;
        set &lib..&domain;
        array dates _character_;
        
        do over dates;
            if index(upcase(vname(dates)), 'DTC') and not missing(dates) then do;
                /* ISO 8601 pattern: YYYY-MM-DDTHH:MM:SS or partial dates */
                if not prxmatch('/^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}(:\d{2})?)?)?)?$/', strip(dates)) then do;
                    check_type = "DATE_FORMAT";
                    domain = "&domain";
                    variable = vname(dates);
                    issue_desc = "Invalid ISO 8601 date format: " || strip(dates);
                    severity = "MAJOR";
                    record_count = 1;
                    output;
                end;
            end;
        end;
    run;
    
    proc append base=validation_results data=date_issues(keep=check_type domain variable issue_desc severity record_count) force;
    run;
    
    /* Check 6: Study day calculations (if DY variables present) */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&domain)), RFSTDTC)) > 0 %then %do;
        data dy_check;
            set &lib..&domain;
            if not missing(rfstdtc);
            
            /* Convert DTC to date */
            rfstdt = input(substr(rfstdtc,1,10), yymmdd10.);
            
            array dy_vars _numeric_;
            array dtc_vars _character_;
            
            do over dy_vars;
                if index(upcase(vname(dy_vars)), 'DY') and not missing(dy_vars) then do;
                    /* Find corresponding DTC variable */
                    dtc_var = compress(vname(dy_vars), 'Y') || 'TC';
                    
                    do over dtc_vars;
                        if upcase(vname(dtc_vars)) = upcase(dtc_var) and not missing(dtc_vars) then do;
                            event_dt = input(substr(dtc_vars,1,10), yymmdd10.);
                            if not missing(event_dt) then do;
                                calc_dy = event_dt - rfstdt + (event_dt >= rfstdt);
                                if abs(dy_vars - calc_dy) > 0 then do;
                                    check_type = "STUDY_DAY_CALC";
                                    domain = "&domain";
                                    variable = vname(dy_vars);
                                    issue_desc = "Study day calculation error: calculated=" || 
                                               put(calc_dy, best.) || " stored=" || put(dy_vars, best.);
                                    severity = "MAJOR";
                                    record_count = 1;
                                    output;
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        run;
        
        proc append base=validation_results data=dy_check(keep=check_type domain variable issue_desc severity record_count) force;
        run;
    %end;
    
    /* Check 7: Missing required values */
    data missing_check;
        set &lib..&domain;
        
        /* Check STUDYID, DOMAIN, USUBJID are not missing */
        if missing(studyid) then do;
            check_type = "MISSING_REQUIRED";
            domain = "&domain";
            variable = "STUDYID";
            issue_desc = "STUDYID is missing";
            severity = "CRITICAL";
            record_count = 1;
            output;
        end;
        
        if missing(domain) then do;
            check_type = "MISSING_REQUIRED";
            domain = "&domain";
            variable = "DOMAIN";
            issue_desc = "DOMAIN is missing";
            severity = "CRITICAL"; 
            record_count = 1;
            output;
        end;
        
        if missing(usubjid) then do;
            check_type = "MISSING_REQUIRED";
            domain = "&domain";
            variable = "USUBJID";
            issue_desc = "USUBJID is missing";
            severity = "CRITICAL";
            record_count = 1;
            output;
        end;
    run;
    
    proc append base=validation_results data=missing_check(keep=check_type domain variable issue_desc severity record_count) force;
    run;
    
    /* Summarize validation results */
    proc freq data=validation_results;
        tables check_type*severity / missing;
        title "SDTM Domain &domain Validation Summary";
    run;
    
    proc print data=validation_results;
        title "SDTM Domain &domain Validation Issues";
        var check_type variable issue_desc severity record_count;
    run;
    
    %exit:
    
%mend validate_sdtm_domain;

/* Usage examples */
%validate_sdtm_domain(domain=DM);
%validate_sdtm_domain(domain=AE);
%validate_sdtm_domain(domain=LB);
```

### Cross-Domain Validation Program

```sas
/******************************************************************************
PROGRAM: sdtm_cross_domain_validation.sas  
PURPOSE: Cross-domain SDTM validation checks
******************************************************************************/

%macro cross_domain_validation(lib=sdtm);
    
    /* Initialize results */
    data cross_validation_results;
        length check_type $50 domain1 $8 domain2 $8 issue_desc $200 
               severity $10 record_count 8;
        stop;
    run;
    
    /* Check 1: USUBJID consistency across domains */
    proc sql;
        create table domain_usubjid as
        select 'DM' as domain, usubjid from &lib..dm
        union
        select 'AE' as domain, usubjid from &lib..ae (where=(usubjid is not missing))
        union  
        select 'LB' as domain, usubjid from &lib..lb (where=(usubjid is not missing))
        union
        select 'EX' as domain, usubjid from &lib..ex (where=(usubjid is not missing))
        union
        select 'CM' as domain, usubjid from &lib..cm (where=(usubjid is not missing));
    quit;
    
    /* Find subjects in other domains but not in DM */
    proc sql;
        create table missing_in_dm as
        select domain, usubjid, count(*) as record_count
        from domain_usubjid
        where domain ne 'DM' 
          and usubjid not in (select usubjid from &lib..dm)
        group by domain, usubjid;
    quit;
    
    %if %nobs(missing_in_dm) > 0 %then %do;
        data temp_results;
            set missing_in_dm;
            check_type = "USUBJID_NOT_IN_DM";
            domain1 = domain;
            domain2 = "DM";
            issue_desc = "USUBJID " || strip(usubjid) || 
                        " exists in " || strip(domain) || " but not in DM";
            severity = "CRITICAL";
        run;
        
        proc append base=cross_validation_results data=temp_results force;
        run;
    %end;
    
    /* Check 2: Treatment period consistency */
    %if %sysfunc(exist(&lib..ex)) %then %do;
        proc sql;
            create table treatment_dates as
            select a.usubjid,
                   a.rfxstdtc as dm_first_dose,
                   a.rfxendtc as dm_last_dose,
                   min(b.exstdtc) as ex_first_dose format=$19.,
                   max(case when not missing(b.exendtc) then b.exendtc else b.exstdtc end) as ex_last_dose format=$19.
            from &lib..dm a
            left join &lib..ex b on a.usubjid = b.usubjid
            where not missing(a.rfxstdtc)
            group by a.usubjid, a.rfxstdtc, a.rfxendtc;
        quit;
        
        data treatment_inconsistency;
            set treatment_dates;
            
            if not missing(dm_first_dose) and not missing(ex_first_dose) then do;
                if dm_first_dose ne ex_first_dose then do;
                    check_type = "TREATMENT_DATE_INCONSISTENCY";
                    domain1 = "DM";
                    domain2 = "EX";
                    issue_desc = "RFXSTDTC in DM (" || strip(dm_first_dose) || 
                               ") differs from first EXSTDTC (" || strip(ex_first_dose) || ")";
                    severity = "MAJOR";
                    record_count = 1;
                    output;
                end;
            end;
        run;
        
        proc append base=cross_validation_results data=treatment_inconsistency force;
        run;
    %end;
    
    /* Check 3: AE dates within study participation */
    %if %sysfunc(exist(&lib..ae)) %then %do;
        proc sql;
            create table ae_date_check as
            select a.usubjid,
                   a.rfstdtc,
                   a.rfendtc,
                   b.aeseq,
                   b.aestdtc,
                   b.aeendtc
            from &lib..dm a
            inner join &lib..ae b on a.usubjid = b.usubjid
            where not missing(b.aestdtc);
        quit;
        
        data ae_date_issues;
            set ae_date_check;
            
            /* Convert to dates for comparison */
            rfstdt = input(substr(rfstdtc,1,10), yymmdd10.);
            rfendt = input(substr(rfendtc,1,10), yymmdd10.);
            aestdt = input(substr(aestdtc,1,10), yymmdd10.);
            
            if not missing(aestdt) and not missing(rfstdt) then do;
                if aestdt < rfstdt then do;
                    check_type = "AE_BEFORE_STUDY_START";
                    domain1 = "AE";
                    domain2 = "DM";
                    issue_desc = "AE start date (" || substr(aestdtc,1,10) || 
                               ") before study start (" || substr(rfstdtc,1,10) || ")";
                    severity = "MAJOR";
                    record_count = 1;
                    output;
                end;
            end;
        run;
        
        proc append base=cross_validation_results data=ae_date_issues force;
        run;
    %end;
    
    /* Print cross-validation results */
    proc print data=cross_validation_results;
        title "SDTM Cross-Domain Validation Results";
        var check_type domain1 domain2 issue_desc severity record_count;
    run;
    
%mend cross_domain_validation;

/* Execute cross-domain validation */
%cross_domain_validation(lib=sdtm);
```

## ADaM Quality Control Programs

### ADSL Validation Program

```sas
/******************************************************************************
PROGRAM: adsl_validation.sas
PURPOSE: Comprehensive ADSL validation
******************************************************************************/

%macro validate_adsl(lib=adam);
    
    data adsl_validation_results;
        length check_type $50 variable $32 issue_desc $200 
               severity $10 record_count 8;
        stop;
    run;
    
    /* Check 1: One record per subject */
    proc freq data=&lib..adsl noprint;
        tables usubjid / out=usubjid_count;
    run;
    
    proc sql noprint;
        select count(*) into :dup_subjects
        from usubjid_count
        where count > 1;
    quit;
    
    %if &dup_subjects > 0 %then %do;
        data temp_results;
            check_type = "SUBJECT_UNIQUENESS";
            variable = "USUBJID";
            issue_desc = "&dup_subjects subjects have multiple records";
            severity = "CRITICAL";
            record_count = &dup_subjects;
        run;
        
        proc append base=adsl_validation_results data=temp_results force;
        run;
    %end;
    
    /* Check 2: Population flag consistency */
    data flag_check;
        set &lib..adsl;
        
        /* ITTFL should be subset of SAFFL typically */
        if ittfl = 'Y' and saffl ne 'Y' then do;
            check_type = "POPULATION_FLAG_INCONSISTENCY";
            variable = "ITTFL/SAFFL";
            issue_desc = "Subject has ITTFL='Y' but SAFFL ne 'Y'";
            severity = "MAJOR";
            record_count = 1;
            output;
        end;
        
        /* Treatment dates should exist for treated subjects */
        if saffl = 'Y' and (missing(trtsdt) or missing(trtedt)) then do;
            check_type = "MISSING_TREATMENT_DATES";
            variable = "TRTSDT/TRTEDT";
            issue_desc = "Safety population subject missing treatment dates";
            severity = "MAJOR";
            record_count = 1;
            output;
        end;
        
        /* Treatment start should be <= end */
        if not missing(trtsdt) and not missing(trtedt) and trtsdt > trtedt then do;
            check_type = "TREATMENT_DATE_ORDER";
            variable = "TRTSDT/TRTEDT";
            issue_desc = "Treatment start date after end date";
            severity = "MAJOR";
            record_count = 1;
            output;
        end;
    run;
    
    proc append base=adsl_validation_results data=flag_check force;
    run;
    
    /* Check 3: Treatment variable consistency */
    data treatment_check;
        set &lib..adsl;
        
        /* Planned vs actual treatment consistency checks */
        if not missing(trt01p) and missing(trt01pn) then do;
            check_type = "MISSING_NUMERIC_TREATMENT";
            variable = "TRT01PN";
            issue_desc = "TRT01P populated but TRT01PN missing";
            severity = "MINOR";
            record_count = 1;
            output;
        end;
        
        if not missing(trt01a) and missing(trt01an) then do;
            check_type = "MISSING_NUMERIC_TREATMENT";
            variable = "TRT01AN";
            issue_desc = "TRT01A populated but TRT01AN missing";
            severity = "MINOR";
            record_count = 1;
            output;
        end;
    run;
    
    proc append base=adsl_validation_results data=treatment_check force;
    run;
    
    /* Check 4: Age group consistency */
    data age_check;
        set &lib..adsl;
        
        if not missing(age) and not missing(agegr1) then do;
            /* Example age group logic - customize as needed */
            if age < 65 and agegr1 ne '<65' then do;
                check_type = "AGE_GROUP_INCONSISTENCY";
                variable = "AGEGR1";
                issue_desc = "AGE=" || put(age, best.) || " but AGEGR1=" || strip(agegr1);
                severity = "MAJOR";
                record_count = 1;
                output;
            end;
            else if age >= 65 and agegr1 ne '>=65' then do;
                check_type = "AGE_GROUP_INCONSISTENCY";
                variable = "AGEGR1";
                issue_desc = "AGE=" || put(age, best.) || " but AGEGR1=" || strip(agegr1);
                severity = "MAJOR";
                record_count = 1;
                output;
            end;
        end;
    run;
    
    proc append base=adsl_validation_results data=age_check force;
    run;
    
    /* Print validation summary */
    proc freq data=adsl_validation_results;
        tables check_type*severity / missing;
        title "ADSL Validation Summary";
    run;
    
    proc print data=adsl_validation_results;
        title "ADSL Validation Issues";
        var check_type variable issue_desc severity record_count;
    run;
    
%mend validate_adsl;

/* Execute ADSL validation */
%validate_adsl(lib=adam);
```

### BDS Dataset Validation Program

```sas
/******************************************************************************
PROGRAM: bds_validation.sas
PURPOSE: BDS (Basic Data Structure) validation for ADaM datasets
******************************************************************************/

%macro validate_bds(dataset=, lib=adam);
    
    %let dataset = %upcase(&dataset);
    
    data bds_validation_results;
        length check_type $50 variable $32 issue_desc $200 
               severity $10 record_count 8;
        stop;
    run;
    
    /* Check 1: Required BDS variables */
    %let req_vars = STUDYID USUBJID PARAM PARAMCD;
    
    proc contents data=&lib..&dataset out=contents noprint;
    run;
    
    %do i = 1 %to %sysfunc(countw(&req_vars));
        %let var = %scan(&req_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from contents
            where upcase(name) = "&var";
        quit;
        
        %if &var_exists = 0 %then %do;
            data temp_results;
                check_type = "MISSING_BDS_VARIABLE";
                variable = "&var";
                issue_desc = "Required BDS variable &var is missing";
                severity = "CRITICAL";
                record_count = .;
            run;
            
            proc append base=bds_validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 2: AVAL/AVALC mutual exclusivity */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), AVAL)) > 0 and 
        %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), AVALC)) > 0 %then %do;
        
        proc sql noprint;
            select count(*) into :both_populated
            from &lib..&dataset
            where not missing(aval) and not missing(avalc);
        quit;
        
        %if &both_populated > 0 %then %do;
            data temp_results;
                check_type = "AVAL_AVALC_BOTH_POPULATED";
                variable = "AVAL/AVALC";
                issue_desc = "&both_populated records have both AVAL and AVALC populated";
                severity = "MAJOR";
                record_count = &both_populated;
            run;
            
            proc append base=bds_validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 3: Baseline flag validation */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), ABLFL)) > 0 %then %do;
        
        /* Check for multiple baseline records per parameter */
        proc freq data=&lib..&dataset noprint;
            tables usubjid*paramcd*ablfl / out=baseline_count;
            where ablfl = 'Y';
        run;
        
        proc sql noprint;
            select count(*) into :mult_baselines
            from baseline_count
            where count > 1;
        quit;
        
        %if &mult_baselines > 0 %then %do;
            data temp_results;
                check_type = "MULTIPLE_BASELINES";
                variable = "ABLFL";
                issue_desc = "&mult_baselines subject-parameter combinations have multiple baseline records";
                severity = "MAJOR";
                record_count = &mult_baselines;
            run;
            
            proc append base=bds_validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 4: Change from baseline calculations */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), CHG)) > 0 and
        %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), BASE)) > 0 and
        %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), AVAL)) > 0 %then %do;
        
        data chg_validation;
            set &lib..&dataset;
            where not missing(aval) and not missing(base) and not missing(chg);
            
            calc_chg = aval - base;
            
            if abs(chg - calc_chg) > 1e-10 then do;
                check_type = "CHG_CALCULATION_ERROR";
                variable = "CHG";
                issue_desc = "CHG calculation error: USUBJID=" || strip(usubjid) || 
                           " PARAMCD=" || strip(paramcd) || 
                           " calculated=" || put(calc_chg, best.) || 
                           " stored=" || put(chg, best.);
                severity = "MAJOR";
                record_count = 1;
                output;
            end;
            
            keep check_type variable issue_desc severity record_count;
        run;
        
        proc append base=bds_validation_results data=chg_validation force;
        run;
    %end;
    
    /* Check 5: Visit structure consistency */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), AVISIT)) > 0 and
        %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), AVISITN)) > 0 %then %do;
        
        proc freq data=&lib..&dataset noprint;
            tables avisit*avisitn / out=visit_consistency;
        run;
        
        proc sql;
            create table visit_issues as
            select avisit, count(distinct avisitn) as distinct_visitn
            from visit_consistency
            group by avisit
            having count(distinct avisitn) > 1;
        quit;
        
        %if %nobs(visit_issues) > 0 %then %do;
            data temp_results;
                set visit_issues;
                check_type = "VISIT_INCONSISTENCY";
                variable = "AVISIT/AVISITN";
                issue_desc = "AVISIT '" || strip(avisit) || 
                           "' maps to multiple AVISITN values";
                severity = "MAJOR";
                record_count = distinct_visitn;
            run;
            
            proc append base=bds_validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Check 6: Analysis flags */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), ANL01FL)) > 0 %then %do;
        
        proc sql noprint;
            select count(*) into :invalid_anl01fl
            from &lib..&dataset
            where anl01fl not in ('Y', '');
        quit;
        
        %if &invalid_anl01fl > 0 %then %do;
            data temp_results;
                check_type = "INVALID_ANALYSIS_FLAG";
                variable = "ANL01FL";
                issue_desc = "&invalid_anl01fl records have invalid ANL01FL values";
                severity = "MAJOR";
                record_count = &invalid_anl01fl;
            run;
            
            proc append base=bds_validation_results data=temp_results force;
            run;
        %end;
    %end;
    
    /* Print validation results */
    proc freq data=bds_validation_results;
        tables check_type*severity / missing;
        title "&dataset BDS Validation Summary";
    run;
    
    proc print data=bds_validation_results;
        title "&dataset BDS Validation Issues";
        var check_type variable issue_desc severity record_count;
    run;
    
%mend validate_bds;

/* Execute BDS validation */
%validate_bds(dataset=ADLB);
%validate_bds(dataset=ADVS);
%validate_bds(dataset=ADAE);
```

## Traceability Validation Programs

### SDTM to ADaM Traceability Check

```sas
/******************************************************************************
PROGRAM: traceability_validation.sas
PURPOSE: Validate traceability from SDTM to ADaM datasets
******************************************************************************/

%macro validate_traceability(adam_dataset=, sdtm_lib=sdtm, adam_lib=adam);
    
    %let adam_dataset = %upcase(&adam_dataset);
    
    /* ADSL traceability to DM */
    %if &adam_dataset = ADSL %then %do;
        
        proc sql;
            create table dm_adsl_compare as
            select a.usubjid,
                   a.studyid as dm_studyid,
                   b.studyid as adsl_studyid,
                   a.age as dm_age,
                   b.age as adsl_age,
                   a.sex as dm_sex,
                   b.sex as adsl_sex,
                   a.race as dm_race,
                   b.race as adsl_race
            from &sdtm_lib..dm a
            full join &adam_lib..adsl b on a.usubjid = b.usubjid;
        quit;
        
        data traceability_issues;
            set dm_adsl_compare;
            
            if missing(dm_studyid) then do;
                issue = "USUBJID " || strip(usubjid) || " in ADSL but not in DM";
                output;
            end;
            else if missing(adsl_studyid) then do;
                issue = "USUBJID " || strip(usubjid) || " in DM but not in ADSL";
                output;
            end;
            else do;
                if dm_studyid ne adsl_studyid then do;
                    issue = "STUDYID mismatch for " || strip(usubjid);
                    output;
                end;
                
                if dm_age ne adsl_age then do;
                    issue = "AGE mismatch for " || strip(usubjid) || 
                           " (DM=" || put(dm_age, best.) || 
                           " ADSL=" || put(adsl_age, best.) || ")";
                    output;
                end;
                
                if dm_sex ne adsl_sex then do;
                    issue = "SEX mismatch for " || strip(usubjid);
                    output;
                end;
            end;
            
            keep usubjid issue;
        run;
        
        proc print data=traceability_issues;
            title "ADSL to DM Traceability Issues";
        run;
    %end;
    
    /* ADLB traceability to LB */
    %if &adam_dataset = ADLB %then %do;
        
        /* Check parameter consistency */
        proc sql;
            create table param_compare as
            select a.lbtestcd as sdtm_testcd,
                   a.lbtest as sdtm_test,
                   b.paramcd as adam_paramcd,
                   b.param as adam_param,
                   count(*) as record_count
            from &sdtm_lib..lb a
            left join &adam_lib..adlb b on a.usubjid = b.usubjid 
                                      and a.lbtestcd = b.paramcd
                                      and a.lbdtc = put(b.adt, is8601da.)
            group by a.lbtestcd, a.lbtest, b.paramcd, b.param;
        quit;
        
        data param_issues;
            set param_compare;
            if missing(adam_paramcd) then do;
                issue = "SDTM parameter " || strip(sdtm_testcd) || 
                       " not found in ADLB";
                output;
            end;
        run;
        
        proc print data=param_issues;
            title "ADLB Parameter Traceability Issues";
        run;
        
        /* Check value consistency */
        proc sql;
            create table value_compare as
            select a.usubjid,
                   a.lbtestcd,
                   a.lbdtc,
                   a.lbstresn as sdtm_value,
                   b.aval as adam_value
            from &sdtm_lib..lb a
            inner join &adam_lib..adlb b on a.usubjid = b.usubjid
                                      and a.lbtestcd = b.paramcd
                                      and a.lbdtc = put(b.adt, is8601da.)
            where not missing(a.lbstresn) and not missing(b.aval);
        quit;
        
        data value_issues;
            set value_compare;
            if abs(sdtm_value - adam_value) > 1e-10 then do;
                issue = "Value mismatch for " || strip(usubjid) || 
                       " " || strip(lbtestcd) || " " || strip(lbdtc) ||
                       " (SDTM=" || put(sdtm_value, best.) ||
                       " ADaM=" || put(adam_value, best.) || ")";
                output;
            end;
        run;
        
        proc print data=value_issues;
            title "ADLB Value Traceability Issues";
        run;
    %end;
    
%mend validate_traceability;

/* Execute traceability validation */
%validate_traceability(adam_dataset=ADSL);
%validate_traceability(adam_dataset=ADLB);
```

## Utility Macros for Quality Control

### Dataset Comparison Macro

```sas
/******************************************************************************
PROGRAM: dataset_compare.sas
PURPOSE: Compare two datasets for differences (useful for independent QC)
******************************************************************************/

%macro compare_datasets(base=, compare=, out=comparison_results);
    
    proc compare base=&base compare=&compare out=&out noprint;
    run;
    
    /* Summarize comparison results */
    data comparison_summary;
        set &out;
        
        /* Categorize differences */
        if _type_ = 'DIF' then difference_type = 'Value Difference';
        else if _type_ = 'BASE' then difference_type = 'Only in Base';
        else if _type_ = 'COMP' then difference_type = 'Only in Compare';
        else difference_type = 'Other';
    run;
    
    proc freq data=comparison_summary;
        tables difference_type / missing;
        title "Dataset Comparison Summary: &base vs &compare";
    run;
    
    proc print data=comparison_summary(obs=100);
        title "First 100 Differences: &base vs &compare";
    run;
    
%mend compare_datasets;
```

### Data Quality Report Macro

```sas
/******************************************************************************
PROGRAM: data_quality_report.sas
PURPOSE: Generate comprehensive data quality report
******************************************************************************/

%macro data_quality_report(dataset=, lib=, out_path=);
    
    ods pdf file="&out_path/&dataset._data_quality_report.pdf";
    
    /* Dataset overview */
    proc contents data=&lib..&dataset;
        title "Dataset Contents: &dataset";
    run;
    
    /* Record counts */
    proc sql;
        select count(*) as total_records,
               count(distinct usubjid) as unique_subjects
        from &lib..&dataset;
        title "Record Count Summary: &dataset";
    quit;
    
    /* Missing data analysis */
    proc format;
        value $missing
            ' ' = 'Missing'
            other = 'Non-Missing';
    run;
    
    proc freq data=&lib..&dataset;
        tables _all_ / missing;
        format _character_ $missing.;
        title "Missing Data Analysis: &dataset";
    run;
    
    /* Duplicate analysis (if USUBJID exists) */
    %if %sysfunc(varnum(%sysfunc(open(&lib..&dataset)), USUBJID)) > 0 %then %do;
        proc freq data=&lib..&dataset;
            tables usubjid / noprint out=dup_check;
        run;
        
        proc print data=dup_check(where=(count > 1));
            title "Duplicate USUBJID Analysis: &dataset";
        run;
    %end;
    
    /* Numeric variable distributions */
    proc means data=&lib..&dataset n nmiss min max mean std;
        title "Numeric Variable Distributions: &dataset";
    run;
    
    ods pdf close;
    
%mend data_quality_report;
```

## Implementation Guidelines

### QC Program Usage
1. **Development Phase**: Run validation programs during dataset creation
2. **Review Phase**: Use for independent programming QC
3. **Submission Phase**: Final validation before regulatory submission
4. **Maintenance**: Regular validation for dataset updates

### Customization Notes
- Adapt validation rules to study-specific requirements
- Add therapeutic area-specific checks as needed
- Modify severity levels based on organizational standards
- Integrate with automated QC systems where possible

### Best Practices
- Document all validation rules and rationale
- Maintain version control for QC programs
- Regular review and update of validation criteria
- Integration with dataset development workflow

---

*These QC programs should be customized based on specific study requirements, therapeutic areas, and organizational validation standards. Regular updates are recommended to maintain effectiveness.*