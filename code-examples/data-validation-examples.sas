/******************************************************************************
PROGRAM: data-validation-examples.sas
PURPOSE: Comprehensive data validation examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook  
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides comprehensive data validation checks for clinical trial
datasets, covering SDTM and ADaM standards, data integrity, and regulatory
compliance requirements.

SECTIONS INCLUDED:
1. SDTM Domain Validation
2. ADaM Dataset Validation  
3. Cross-Domain Validation
4. Data Integrity Checks
5. Regulatory Compliance Validation
6. Custom Validation Rules
******************************************************************************/

/******************************************************************************
SECTION 1: SDTM DOMAIN VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_sdtm_domain
PURPOSE: Comprehensive SDTM domain validation
PARAMETERS:
  data= : SDTM dataset to validate
  domain= : Domain code (DM, AE, LB, etc.)
  output_report= : Output validation report
******************************************************************************/
%macro validate_sdtm_domain(
    data=,
    domain=,
    output_report=sdtm_validation_report
);
    
    %put NOTE: Validating SDTM domain &domain;
    
    /* Initialize validation results */
    data work.validation_results;
        length domain $2 check_type $50 check_name $100 
               status $10 n_issues 8 details $500;
        delete;
    run;
    
    /* Check 1: Required variables present */
    %let required_vars = STUDYID DOMAIN USUBJID SUBJID;
    
    proc contents data=&data out=work.contents noprint;
    run;
    
    %let var_count = %sysfunc(countw(&required_vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&required_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from work.contents
            where upcase(name) = "&var";
        quit;
        
        data work.temp_result;
            domain = "&domain";
            check_type = "Required Variables";
            check_name = "Variable &var Present";
            if &var_exists > 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "Variable &var found";
            end;
            else do;
                status = "FAIL";
                n_issues = 1;
                details = "Required variable &var missing";
            end;
        run;
        
        proc append base=work.validation_results data=work.temp_result;
        run;
    %end;
    
    /* Check 2: Key variable uniqueness */
    %if &domain = DM %then %do;
        proc sql noprint;
            select count(*) as total,
                   count(distinct usubjid) as unique_usubjid
            into :total_records, :unique_usubjid
            from &data;
        quit;
        
        data work.temp_result;
            domain = "&domain";
            check_type = "Data Integrity";
            check_name = "USUBJID Uniqueness";
            if &total_records = &unique_usubjid then do;
                status = "PASS";
                n_issues = 0;
                details = "All USUBJID values are unique";
            end;
            else do;
                status = "FAIL"; 
                n_issues = &total_records - &unique_usubjid;
                details = cats("Found ", n_issues, " duplicate USUBJID values");
            end;
        run;
        
        proc append base=work.validation_results data=work.temp_result;
        run;
    %end;
    
    /* Check 3: Domain consistency */
    proc sql noprint;
        select count(distinct domain) into :domain_count
        from &data
        where not missing(domain);
        
        select domain into :domain_value
        from &data
        where not missing(domain);
    quit;
    
    data work.temp_result;
        domain = "&domain";
        check_type = "Domain Standards";
        check_name = "Domain Value Consistency";
        if &domain_count = 1 and "&domain_value" = "&domain" then do;
            status = "PASS";
            n_issues = 0;
            details = "Domain variable consistent with expected value &domain";
        end;
        else do;
            status = "FAIL";
            n_issues = 1;
            details = "Domain variable inconsistent or missing";
        end;
    run;
    
    proc append base=work.validation_results data=work.temp_result;
    run;
    
    /* Check 4: Date format validation */
    %if &domain in (AE LB VS EX) %then %do;
        %let date_vars = ;
        %if &domain = AE %then %let date_vars = AESTDTC AEENDTC;
        %else %if &domain = LB %then %let date_vars = LBDTC;
        %else %if &domain = VS %then %let date_vars = VSDTC;
        %else %if &domain = EX %then %let date_vars = EXSTDTC EXENDTC;
        
        %let date_count = %sysfunc(countw(&date_vars));
        %do i = 1 %to &date_count;
            %let date_var = %scan(&date_vars, &i);
            
            /* Check if variable exists first */
            proc sql noprint;
                select count(*) into :var_exists
                from work.contents
                where upcase(name) = "&date_var";
            quit;
            
            %if &var_exists > 0 %then %do;
                data work.date_check;
                    set &data;
                    where not missing(&date_var);
                    
                    /* Check ISO 8601 format */
                    length date_format_ok 8;
                    if prxmatch('/^\d{4}-\d{2}-\d{2}/', &date_var) then
                        date_format_ok = 1;
                    else date_format_ok = 0;
                run;
                
                proc sql noprint;
                    select count(*) as total,
                           sum(date_format_ok) as valid_format
                    into :total_dates, :valid_dates
                    from work.date_check;
                quit;
                
                data work.temp_result;
                    domain = "&domain";
                    check_type = "Date Format";
                    check_name = "&date_var ISO 8601 Format";
                    if &valid_dates = &total_dates then do;
                        status = "PASS";
                        n_issues = 0;
                        details = "All &date_var values in valid ISO 8601 format";
                    end;
                    else do;
                        status = "FAIL";
                        n_issues = &total_dates - &valid_dates;
                        details = cats("Found ", n_issues, " invalid date formats in &date_var");
                    end;
                run;
                
                proc append base=work.validation_results data=work.temp_result;
                run;
            %end;
        %end;
    %end;
    
    /* Check 5: Controlled terminology */
    %if &domain = DM %then %do;
        /* SEX validation */
        proc sql noprint;
            select count(*) as total,
                   sum(case when upcase(sex) in ('M', 'F', 'U') then 1 else 0 end) as valid_sex
            into :total_sex, :valid_sex  
            from &data
            where not missing(sex);
        quit;
        
        data work.temp_result;
            domain = "&domain";
            check_type = "Controlled Terminology";
            check_name = "SEX Valid Values";
            if &valid_sex = &total_sex then do;
                status = "PASS";
                n_issues = 0;
                details = "All SEX values are valid (M, F, U)";
            end;
            else do;
                status = "FAIL";
                n_issues = &total_sex - &valid_sex;
                details = cats("Found ", n_issues, " invalid SEX values");
            end;
        run;
        
        proc append base=work.validation_results data=work.temp_result;
        run;
    %end;
    
    /* Generate validation report */
    ods html file="&output_report..html";
    
    title1 "SDTM Domain Validation Report";
    title2 "Domain: &domain";
    title3 "Dataset: &data";
    
    proc print data=work.validation_results;
        var check_type check_name status n_issues details;
    run;
    
    proc freq data=work.validation_results;
        tables status / nocum;
        title4 "Validation Status Summary";
    run;
    
    ods html close;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete validation_results temp_result contents date_check;
    quit;
    
    %put NOTE: SDTM validation completed for domain &domain;
    
%mend validate_sdtm_domain;

/******************************************************************************
SECTION 2: ADAM DATASET VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_adam_dataset
PURPOSE: Comprehensive ADaM dataset validation
PARAMETERS:
  data= : ADaM dataset to validate
  dataset_type= : Dataset type (ADSL, ADAE, ADLB, etc.)
  output_report= : Output validation report
******************************************************************************/
%macro validate_adam_dataset(
    data=,
    dataset_type=,
    output_report=adam_validation_report
);
    
    %put NOTE: Validating ADaM dataset &dataset_type;
    
    /* Initialize validation results */
    data work.adam_validation;
        length dataset_type $10 check_type $50 check_name $100 
               status $10 n_issues 8 details $500;
        delete;
    run;
    
    /* Define required variables by dataset type */
    %let required_vars = ;
    %if &dataset_type = ADSL %then %let required_vars = STUDYID USUBJID SUBJID TRT01P SAFFL ITTFL;
    %else %if &dataset_type = ADAE %then %let required_vars = STUDYID USUBJID AESEQ AEDECOD TRTEMFL;
    %else %if &dataset_type = ADLB %then %let required_vars = STUDYID USUBJID PARAMCD AVAL ADT ABLFL;
    %else %let required_vars = STUDYID USUBJID;
    
    /* Check required variables */
    proc contents data=&data out=work.adam_contents noprint;
    run;
    
    %let var_count = %sysfunc(countw(&required_vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&required_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from work.adam_contents
            where upcase(name) = "&var";
        quit;
        
        data work.temp_result;
            dataset_type = "&dataset_type";
            check_type = "Required Variables";
            check_name = "Variable &var Present";
            if &var_exists > 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "Required variable &var found";
            end;
            else do;
                status = "FAIL";
                n_issues = 1;
                details = "Required variable &var missing";
            end;
        run;
        
        proc append base=work.adam_validation data=work.temp_result;
        run;
    %end;
    
    /* Dataset-specific validations */
    %if &dataset_type = ADSL %then %do;
        /* Population flag consistency */
        proc sql noprint;
            select sum(case when saffl = 'Y' and ittfl = 'N' then 1 else 0 end) as safety_not_itt
            into :safety_not_itt
            from &data;
        quit;
        
        data work.temp_result;
            dataset_type = "&dataset_type";
            check_type = "Business Logic";
            check_name = "Population Flag Consistency";
            if &safety_not_itt = 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "No subjects in safety but not in ITT";
            end;
            else do;
                status = "WARNING";
                n_issues = &safety_not_itt;
                details = cats("Found ", n_issues, " subjects in safety but not ITT population");
            end;
        run;
        
        proc append base=work.adam_validation data=work.temp_result;
        run;
        
        /* Treatment assignment consistency */
        proc sql noprint;
            select count(*) as total,
                   sum(case when missing(trt01p) then 1 else 0 end) as missing_trt
            into :total_subj, :missing_trt
            from &data
            where ittfl = 'Y';
        quit;
        
        data work.temp_result;
            dataset_type = "&dataset_type";
            check_type = "Treatment Assignment";
            check_name = "Planned Treatment Complete";
            if &missing_trt = 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "All ITT subjects have planned treatment assigned";
            end;
            else do;
                status = "FAIL";
                n_issues = &missing_trt;
                details = cats("Found ", n_issues, " ITT subjects missing planned treatment");
            end;
        run;
        
        proc append base=work.adam_validation data=work.temp_result;
        run;
    %end;
    
    %else %if &dataset_type = ADLB %then %do;
        /* BDS structure validation */
        proc sql noprint;
            select count(*) as total,
                   sum(case when missing(paramcd) then 1 else 0 end) as missing_paramcd,
                   sum(case when missing(aval) and missing(avalc) then 1 else 0 end) as missing_aval
            into :total_obs, :missing_paramcd, :missing_aval
            from &data;
        quit;
        
        data work.temp_result;
            dataset_type = "&dataset_type";
            check_type = "BDS Structure";
            check_name = "PARAMCD Complete";
            if &missing_paramcd = 0 then do;
                status = "PASS"; 
                n_issues = 0;
                details = "All records have PARAMCD";
            end;
            else do;
                status = "FAIL";
                n_issues = &missing_paramcd;
                details = cats("Found ", n_issues, " records missing PARAMCD");
            end;
        run;
        
        proc append base=work.adam_validation data=work.temp_result;
        run;
        
        /* Baseline flag validation */
        proc sql noprint;
            select count(distinct usubjid || paramcd) as param_subj,
                   count(distinct case when ablfl = 'Y' then usubjid || paramcd end) as baseline_records
            into :param_subj, :baseline_records
            from &data;
        quit;
        
        data work.temp_result;
            dataset_type = "&dataset_type";
            check_type = "Baseline Logic";
            check_name = "Baseline Records Present";
            baseline_pct = (&baseline_records / &param_subj) * 100;
            if baseline_pct >= 80 then do;
                status = "PASS";
                n_issues = 0;
                details = cats("Baseline records present for ", put(baseline_pct, 5.1), "% of parameter-subjects");
            end;
            else do;
                status = "WARNING";
                n_issues = &param_subj - &baseline_records;
                details = cats("Only ", put(baseline_pct, 5.1), "% of parameter-subjects have baseline");
            end;
        run;
        
        proc append base=work.adam_validation data=work.temp_result;
        run;
    %end;
    
    /* Generate validation report */
    ods html file="&output_report..html";
    
    title1 "ADaM Dataset Validation Report";
    title2 "Dataset Type: &dataset_type";
    title3 "Dataset: &data";
    
    proc print data=work.adam_validation;
        var check_type check_name status n_issues details;
    run;
    
    proc freq data=work.adam_validation;
        tables status / nocum;
        title4 "Validation Status Summary";
    run;
    
    ods html close;
    
    %put NOTE: ADaM validation completed for &dataset_type;
    
%mend validate_adam_dataset;

/******************************************************************************
SECTION 3: CROSS-DOMAIN VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_cross_domain
PURPOSE: Validate consistency across SDTM domains
PARAMETERS:
  dm_data= : Demographics domain
  ae_data= : Adverse events domain (optional)
  lb_data= : Laboratory domain (optional)
  output_report= : Output report
******************************************************************************/
%macro validate_cross_domain(
    dm_data=,
    ae_data=,
    lb_data=,
    output_report=cross_domain_validation
);
    
    %put NOTE: Performing cross-domain validation;
    
    data work.cross_validation;
        length check_type $50 check_name $100 status $10 n_issues 8 details $500;
        delete;
    run;
    
    /* Get subject list from DM */
    proc sql;
        create table work.dm_subjects as
        select distinct usubjid from &dm_data;
    quit;
    
    /* Check AE subjects exist in DM */
    %if %length(&ae_data) > 0 %then %do;
        proc sql;
            create table work.ae_orphans as
            select distinct a.usubjid
            from &ae_data as a
            left join work.dm_subjects as b
            on a.usubjid = b.usubjid
            where b.usubjid is null;
        quit;
        
        proc sql noprint;
            select count(*) into :ae_orphans
            from work.ae_orphans;
        quit;
        
        data work.temp_result;
            check_type = "Cross-Domain";
            check_name = "AE Subjects in DM";
            if &ae_orphans = 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "All AE subjects exist in DM domain";
            end;
            else do;
                status = "FAIL";
                n_issues = &ae_orphans;
                details = cats("Found ", n_issues, " AE subjects not in DM domain");
            end;
        run;
        
        proc append base=work.cross_validation data=work.temp_result;
        run;
    %end;
    
    /* Check LB subjects exist in DM */
    %if %length(&lb_data) > 0 %then %do;
        proc sql;
            create table work.lb_orphans as
            select distinct a.usubjid
            from &lb_data as a
            left join work.dm_subjects as b
            on a.usubjid = b.usubjid
            where b.usubjid is null;
        quit;
        
        proc sql noprint;
            select count(*) into :lb_orphans
            from work.lb_orphans;
        quit;
        
        data work.temp_result;
            check_type = "Cross-Domain";
            check_name = "LB Subjects in DM";
            if &lb_orphans = 0 then do;
                status = "PASS";
                n_issues = 0;
                details = "All LB subjects exist in DM domain";
            end;
            else do;
                status = "FAIL";
                n_issues = &lb_orphans;
                details = cats("Found ", n_issues, " LB subjects not in DM domain");
            end;
        run;
        
        proc append base=work.cross_validation data=work.temp_result;
        run;
    %end;
    
    /* Generate report */
    ods html file="&output_report..html";
    
    title1 "Cross-Domain Validation Report";
    
    proc print data=work.cross_validation;
        var check_type check_name status n_issues details;
    run;
    
    ods html close;
    
%mend validate_cross_domain;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Validate SDTM domain
%validate_sdtm_domain(
    data=sdtm.dm,
    domain=DM,
    output_report=dm_validation
);

Example 2: Validate ADaM dataset
%validate_adam_dataset(
    data=adam.adsl,
    dataset_type=ADSL,
    output_report=adsl_validation
);

Example 3: Cross-domain validation
%validate_cross_domain(
    dm_data=sdtm.dm,
    ae_data=sdtm.ae,
    lb_data=sdtm.lb,
    output_report=cross_domain_validation
);
*/

%put NOTE: Data validation examples loaded successfully;
%put NOTE: Available macros: validate_sdtm_domain, validate_adam_dataset, validate_cross_domain;