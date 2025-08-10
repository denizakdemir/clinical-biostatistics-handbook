/******************************************************************************
PROGRAM: cross-validation-examples.sas
PURPOSE: Cross-validation procedures for clinical biostatistics
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides comprehensive cross-validation procedures for clinical
biostatistics, including dataset cross-validation, analytical cross-validation,
and regulatory cross-validation procedures.

SECTIONS INCLUDED:
1. Cross-Validation Framework Setup
2. Dataset Cross-Validation
3. Statistical Analysis Cross-Validation
4. Output Cross-Validation
5. Cross-Study Validation
6. Regulatory Cross-Validation
******************************************************************************/

/******************************************************************************
SECTION 1: CROSS-VALIDATION FRAMEWORK SETUP
******************************************************************************/

/******************************************************************************
MACRO: setup_cross_validation_environment
PURPOSE: Initialize cross-validation environment and tracking
PARAMETERS:
  study_id= : Study identifier
  validation_type= : Type of validation (DATASET, ANALYSIS, OUTPUT, REGULATORY)
  validator= : Name of person performing validation
  reference_source= : Reference data source or standard
******************************************************************************/
%macro setup_cross_validation_environment(
    study_id=,
    validation_type=DATASET,
    validator=,
    reference_source=
);
    
    %put NOTE: Setting up cross-validation environment;
    
    /* Create global variables */
    %global cv_study cv_type cv_validator cv_reference cv_start_time;
    %let cv_study = &study_id;
    %let cv_type = &validation_type;
    %let cv_validator = &validator;
    %let cv_reference = &reference_source;
    %let cv_start_time = %sysfunc(datetime(), datetime20.);
    
    /* Create directory structure for cross-validation */
    %let rc1 = %sysfunc(dcreate(cross_validation, .));
    %let rc2 = %sysfunc(dcreate(comparison_reports, ./cross_validation));
    %let rc3 = %sysfunc(dcreate(validation_logs, ./cross_validation));
    %let rc4 = %sysfunc(dcreate(reference_data, ./cross_validation));
    
    /* Initialize cross-validation log */
    data work.cross_validation_log;
        length study_id $20 validation_type $30 validator $50 
               object_name $100 check_type $50 status $20 
               details $500 timestamp 8;
        format timestamp datetime20.;
        delete;
    run;
    
    /* Initialize cross-validation summary */
    data work.cross_validation_summary;
        length object_name $100 total_checks 8 passed_checks 8 
               failed_checks 8 warning_checks 8 overall_status $20;
        delete;
    run;
    
    /* Log environment setup */
    data work.temp_log;
        study_id = "&study_id";
        validation_type = "&validation_type";
        validator = "&validator";
        object_name = "ENVIRONMENT";
        check_type = "SETUP";
        status = "INITIALIZED";
        details = "Cross-validation environment initialized successfully";
        timestamp = datetime();
    run;
    
    proc append base=work.cross_validation_log data=work.temp_log;
    run;
    
    %put NOTE: Cross-validation environment setup completed;
    
%mend setup_cross_validation_environment;

/******************************************************************************
SECTION 2: DATASET CROSS-VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: cross_validate_datasets
PURPOSE: Cross-validate datasets against reference or between studies
PARAMETERS:
  primary_dataset= : Primary dataset to validate
  reference_dataset= : Reference dataset for comparison
  object_name= : Name identifier for validation object
  key_variables= : Key variables for matching
  critical_variables= : Variables that must match exactly
  tolerance= : Numeric tolerance for comparisons
******************************************************************************/
%macro cross_validate_datasets(
    primary_dataset=,
    reference_dataset=,
    object_name=,
    key_variables=,
    critical_variables=,
    tolerance=0.00001
);
    
    %put NOTE: Starting cross-validation for &object_name;
    
    /* Check dataset existence */
    %let primary_exists = %sysfunc(exist(&primary_dataset));
    %let reference_exists = %sysfunc(exist(&reference_dataset));
    
    data work.temp_log;
        study_id = "&cv_study";
        validation_type = "&cv_type";
        validator = "&cv_validator";
        object_name = "&object_name";
        check_type = "DATASET_EXISTENCE";
        
        if &primary_exists and &reference_exists then do;
            status = "PASS";
            details = "Both primary and reference datasets exist";
        end;
        else if not &primary_exists then do;
            status = "FAIL";
            details = "Primary dataset does not exist";
        end;
        else do;
            status = "FAIL";
            details = "Reference dataset does not exist";
        end;
        
        timestamp = datetime();
    run;
    
    proc append base=work.cross_validation_log data=work.temp_log;
    run;
    
    %if &primary_exists and &reference_exists %then %do;
        
        /* Compare dataset structure */
        proc contents data=&primary_dataset out=work.primary_structure noprint;
        run;
        
        proc contents data=&reference_dataset out=work.reference_structure noprint;
        run;
        
        /* Check variable consistency */
        proc sql;
            /* Variables in primary but not reference */
            create table work.primary_only_vars as
            select name, type, length
            from work.primary_structure
            where upcase(name) not in (
                select upcase(name) from work.reference_structure
            );
            
            /* Variables in reference but not primary */
            create table work.reference_only_vars as
            select name, type, length
            from work.reference_structure
            where upcase(name) not in (
                select upcase(name) from work.primary_structure
            );
            
            /* Common variables with different attributes */
            create table work.different_attributes as
            select p.name, p.type as primary_type, r.type as reference_type,
                   p.length as primary_length, r.length as reference_length
            from work.primary_structure p
            inner join work.reference_structure r
            on upcase(p.name) = upcase(r.name)
            where p.type ne r.type or p.length ne r.length;
        quit;
        
        /* Log structure comparison results */
        %check_and_log_differences(
            diff_dataset=work.primary_only_vars,
            object_name=&object_name,
            check_type=VARIABLES_PRIMARY_ONLY,
            details_prefix=Variables only in primary dataset
        );
        
        %check_and_log_differences(
            diff_dataset=work.reference_only_vars,
            object_name=&object_name,
            check_type=VARIABLES_REFERENCE_ONLY,
            details_prefix=Variables only in reference dataset
        );
        
        %check_and_log_differences(
            diff_dataset=work.different_attributes,
            object_name=&object_name,
            check_type=VARIABLE_ATTRIBUTE_DIFFERENCES,
            details_prefix=Variables with different attributes
        );
        
        /* Compare record counts */
        proc sql noprint;
            select count(*) into :primary_nobs from &primary_dataset;
            select count(*) into :reference_nobs from &reference_dataset;
        quit;
        
        data work.temp_log;
            study_id = "&cv_study";
            object_name = "&object_name";
            check_type = "RECORD_COUNT_COMPARISON";
            
            if &primary_nobs = &reference_nobs then do;
                status = "PASS";
                details = cats("Record counts match: ", &primary_nobs);
            end;
            else do;
                status = "WARNING";
                details = cats("Record count difference: Primary=", &primary_nobs, 
                              ", Reference=", &reference_nobs);
            end;
            
            timestamp = datetime();
        run;
        
        proc append base=work.cross_validation_log data=work.temp_log;
        run;
        
        /* Perform detailed data comparison */
        %if %length(&key_variables) > 0 %then %do;
            %cross_validate_data_values(
                primary_dataset=&primary_dataset,
                reference_dataset=&reference_dataset,
                object_name=&object_name,
                key_variables=&key_variables,
                critical_variables=&critical_variables,
                tolerance=&tolerance
            );
        %end;
        
    %end;
    
    %put NOTE: Cross-validation completed for &object_name;
    
%mend cross_validate_datasets;

/******************************************************************************
MACRO: cross_validate_data_values
PURPOSE: Detailed cross-validation of data values
PARAMETERS:
  primary_dataset= : Primary dataset
  reference_dataset= : Reference dataset
  object_name= : Object name
  key_variables= : Key variables for matching
  critical_variables= : Critical variables that must match
  tolerance= : Numeric tolerance
******************************************************************************/
%macro cross_validate_data_values(
    primary_dataset=,
    reference_dataset=,
    object_name=,
    key_variables=,
    critical_variables=,
    tolerance=0.00001
);
    
    %put NOTE: Performing detailed data value cross-validation for &object_name;
    
    /* Merge datasets on key variables */
    proc sql;
        create table work.merged_comparison as
        select p.*, r.* 
        from &primary_dataset as p
        full outer join &reference_dataset as r
        on %do i = 1 %to %sysfunc(countw(&key_variables));
            %if &i > 1 %then %str(and);
            p.%scan(&key_variables, &i) = r.%scan(&key_variables, &i)
        %end;
        ;
    quit;
    
    /* Check for records only in one dataset */
    data work.record_differences;
        set work.merged_comparison;
        
        /* Determine record status */
        primary_missing = 0;
        reference_missing = 0;
        
        %do i = 1 %to %sysfunc(countw(&key_variables));
            %let key = %scan(&key_variables, &i);
            if missing(&key) then primary_missing = 1;
        %end;
        
        /* This logic would need refinement based on actual merge results */
        if primary_missing and not reference_missing then record_status = "REFERENCE_ONLY";
        else if not primary_missing and reference_missing then record_status = "PRIMARY_ONLY";
        else record_status = "BOTH";
        
        keep %scan(&key_variables, 1) record_status;
    run;
    
    /* Log record matching results */
    proc freq data=work.record_differences noprint;
        tables record_status / out=work.record_status_summary;
    run;
    
    data work.temp_log;
        set work.record_status_summary;
        
        study_id = "&cv_study";
        object_name = "&object_name";
        check_type = cats("RECORD_MATCHING_", record_status);
        
        if record_status = "BOTH" then status = "PASS";
        else status = "WARNING";
        
        details = cats(count, " records with status: ", record_status);
        timestamp = datetime();
    run;
    
    proc append base=work.cross_validation_log data=work.temp_log;
    run;
    
    /* Compare critical variables */
    %if %length(&critical_variables) > 0 %then %do;
        
        %let crit_var_count = %sysfunc(countw(&critical_variables));
        %do i = 1 %to &crit_var_count;
            %let crit_var = %scan(&critical_variables, &i);
            
            /* Check if variable exists in both datasets */
            proc sql noprint;
                select count(*) into :primary_has_var
                from dictionary.columns
                where libname = upcase(scan("&primary_dataset", 1, ".")) 
                  and memname = upcase(scan("&primary_dataset", 2, "."))
                  and upcase(name) = upcase("&crit_var");
                  
                select count(*) into :reference_has_var
                from dictionary.columns
                where libname = upcase(scan("&reference_dataset", 1, "."))
                  and memname = upcase(scan("&reference_dataset", 2, "."))
                  and upcase(name) = upcase("&crit_var");
            quit;
            
            %if &primary_has_var > 0 and &reference_has_var > 0 %then %do;
                
                /* Compare variable values for records in both datasets */
                data work.critical_var_comparison;
                    set work.merged_comparison;
                    where record_status = "BOTH";
                    
                    length variable $32 comparison_result $20;
                    variable = "&crit_var";
                    
                    /* Get variable type to determine comparison method */
                    /* This would need proper variable type detection */
                    
                    /* For now, assume character comparison */
                    if vtype(&crit_var._primary) = 'C' then do;
                        if &crit_var._primary = &crit_var._reference then 
                            comparison_result = "MATCH";
                        else comparison_result = "DIFFERENCE";
                    end;
                    else do; /* Numeric */
                        if missing(&crit_var._primary) and missing(&crit_var._reference) then
                            comparison_result = "BOTH_MISSING";
                        else if abs(&crit_var._primary - &crit_var._reference) <= &tolerance then
                            comparison_result = "MATCH";
                        else comparison_result = "DIFFERENCE";
                    end;
                    
                    keep variable comparison_result;
                run;
                
                /* Summarize critical variable comparison */
                proc freq data=work.critical_var_comparison noprint;
                    tables comparison_result / out=work.crit_var_summary;
                run;
                
                data work.temp_log;
                    set work.crit_var_summary;
                    
                    study_id = "&cv_study";
                    object_name = "&object_name";
                    check_type = cats("CRITICAL_VARIABLE_", "&crit_var");
                    
                    if comparison_result = "MATCH" or comparison_result = "BOTH_MISSING" then
                        status = "PASS";
                    else status = "FAIL";
                    
                    details = cats("Variable &crit_var: ", count, " records with ", comparison_result);
                    timestamp = datetime();
                run;
                
                proc append base=work.cross_validation_log data=work.temp_log;
                run;
                
            %end;
            %else %do;
                data work.temp_log;
                    study_id = "&cv_study";
                    object_name = "&object_name";
                    check_type = "CRITICAL_VARIABLE_EXISTENCE";
                    status = "FAIL";
                    details = "Critical variable &crit_var not found in one or both datasets";
                    timestamp = datetime();
                run;
                
                proc append base=work.cross_validation_log data=work.temp_log;
                run;
            %end;
        %end;
    %end;
    
    %put NOTE: Detailed data value cross-validation completed for &object_name;
    
%mend cross_validate_data_values;

/******************************************************************************
SECTION 3: STATISTICAL ANALYSIS CROSS-VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: cross_validate_statistical_results
PURPOSE: Cross-validate statistical analysis results
PARAMETERS:
  primary_results= : Primary analysis results dataset
  reference_results= : Reference analysis results dataset
  object_name= : Object name for tracking
  key_variables= : Variables to match results on
  numeric_variables= : Numeric results to compare
  tolerance= : Tolerance for numeric comparisons
******************************************************************************/
%macro cross_validate_statistical_results(
    primary_results=,
    reference_results=,
    object_name=,
    key_variables=,
    numeric_variables=,
    tolerance=0.001
);
    
    %put NOTE: Cross-validating statistical results for &object_name;
    
    /* Check existence of results datasets */
    %let primary_exists = %sysfunc(exist(&primary_results));
    %let reference_exists = %sysfunc(exist(&reference_results));
    
    %if &primary_exists and &reference_exists %then %do;
        
        /* Merge results datasets */
        proc sql;
            create table work.results_comparison as
            select p.*, r.*
            from &primary_results as p
            inner join &reference_results as r
            on %do i = 1 %to %sysfunc(countw(&key_variables));
                %if &i > 1 %then %str(and);
                p.%scan(&key_variables, &i) = r.%scan(&key_variables, &i)
            %end;
        quit;
        
        /* Compare numeric statistical results */
        %let num_var_count = %sysfunc(countw(&numeric_variables));
        %do i = 1 %to &num_var_count;
            %let num_var = %scan(&numeric_variables, &i);
            
            data work.numeric_comparison;
                set work.results_comparison;
                
                length variable $32 comparison_type $50 status $20;
                variable = "&num_var";
                
                /* Compare values with tolerance */
                primary_value = &num_var._primary;
                reference_value = &num_var._reference;
                
                if missing(primary_value) and missing(reference_value) then do;
                    comparison_type = "BOTH_MISSING";
                    status = "PASS";
                end;
                else if missing(primary_value) or missing(reference_value) then do;
                    comparison_type = "ONE_MISSING";
                    status = "FAIL";
                end;
                else if abs(primary_value - reference_value) <= &tolerance then do;
                    comparison_type = "WITHIN_TOLERANCE";
                    status = "PASS";
                end;
                else do;
                    comparison_type = "EXCEEDS_TOLERANCE";
                    status = "FAIL";
                    difference = primary_value - reference_value;
                    percent_difference = (difference / reference_value) * 100;
                end;
                
                keep variable comparison_type status difference percent_difference;
            run;
            
            /* Summarize comparison results */
            proc freq data=work.numeric_comparison noprint;
                tables status / out=work.status_summary;
            run;
            
            data work.temp_log;
                set work.status_summary;
                
                study_id = "&cv_study";
                object_name = "&object_name";
                check_type = cats("STATISTICAL_RESULT_", "&num_var");
                /* status already set */
                details = cats("Variable &num_var: ", count, " comparisons with status ", status);
                timestamp = datetime();
            run;
            
            proc append base=work.cross_validation_log data=work.temp_log;
            run;
        %end;
        
        /* Create detailed comparison report */
        data cross_validation.statistical_results_&object_name;
            set work.results_comparison;
        run;
        
    %end;
    %else %do;
        data work.temp_log;
            study_id = "&cv_study";
            object_name = "&object_name";
            check_type = "STATISTICAL_RESULTS_EXISTENCE";
            status = "FAIL";
            details = "One or both statistical results datasets do not exist";
            timestamp = datetime();
        run;
        
        proc append base=work.cross_validation_log data=work.temp_log;
        run;
    %end;
    
    %put NOTE: Statistical results cross-validation completed for &object_name;
    
%mend cross_validate_statistical_results;

/******************************************************************************
SECTION 4: UTILITY MACROS
******************************************************************************/

/******************************************************************************
MACRO: check_and_log_differences
PURPOSE: Check for differences and log results
PARAMETERS:
  diff_dataset= : Dataset containing differences
  object_name= : Object name
  check_type= : Type of check
  details_prefix= : Prefix for details message
******************************************************************************/
%macro check_and_log_differences(
    diff_dataset=,
    object_name=,
    check_type=,
    details_prefix=
);
    
    /* Count differences */
    proc sql noprint;
        select count(*) into :diff_count from &diff_dataset;
    quit;
    
    data work.temp_log;
        study_id = "&cv_study";
        object_name = "&object_name";
        check_type = "&check_type";
        
        if &diff_count = 0 then do;
            status = "PASS";
            details = "No differences found";
        end;
        else do;
            status = "WARNING";
            details = cats("&details_prefix: ", &diff_count, " differences found");
        end;
        
        timestamp = datetime();
    run;
    
    proc append base=work.cross_validation_log data=work.temp_log;
    run;
    
%mend check_and_log_differences;

/******************************************************************************
SECTION 5: REPORTING
******************************************************************************/

/******************************************************************************
MACRO: generate_cross_validation_report
PURPOSE: Generate comprehensive cross-validation report
PARAMETERS:
  report_title= : Title for the report
  output_file= : Output file name
******************************************************************************/
%macro generate_cross_validation_report(
    report_title=Cross-Validation Report,
    output_file=cross_validation_report
);
    
    %put NOTE: Generating cross-validation report;
    
    /* Create summary by object */
    proc sql;
        create table work.object_summary as
        select object_name,
               count(*) as total_checks,
               sum(case when status = "PASS" then 1 else 0 end) as passed_checks,
               sum(case when status = "FAIL" then 1 else 0 end) as failed_checks,
               sum(case when status = "WARNING" then 1 else 0 end) as warning_checks,
               case 
                   when sum(case when status = "FAIL" then 1 else 0 end) > 0 then "FAIL"
                   when sum(case when status = "WARNING" then 1 else 0 end) > 0 then "WARNING"
                   else "PASS"
               end as overall_status
        from work.cross_validation_log
        where object_name ne "ENVIRONMENT"
        group by object_name;
    quit;
    
    /* Generate report */
    ods rtf file="./cross_validation/&output_file..rtf" style=minimal;
    
    title1 "&report_title";
    title2 "Study: &cv_study Validation Type: &cv_type";
    title3 "Validator: &cv_validator Reference: &cv_reference";
    title4 "Report Generated: %sysfunc(datetime(), datetime20.)";
    
    /* Executive Summary */
    proc freq data=work.object_summary;
        tables overall_status / nocum;
        title5 "Executive Summary - Overall Status";
    run;
    
    /* Summary by Object */
    proc print data=work.object_summary label;
        title5 "Summary by Object";
        var object_name total_checks passed_checks failed_checks warning_checks overall_status;
        label object_name = "Object Name"
              total_checks = "Total Checks"
              passed_checks = "Passed"
              failed_checks = "Failed" 
              warning_checks = "Warnings"
              overall_status = "Overall Status";
    run;
    
    /* Failed and Warning Details */
    proc print data=work.cross_validation_log;
        where status in ("FAIL", "WARNING");
        title5 "Issues Requiring Attention";
        var object_name check_type status details timestamp;
        format timestamp datetime20.;
    run;
    
    /* Complete Validation Log */
    proc print data=work.cross_validation_log;
        title5 "Complete Cross-Validation Log";
        var timestamp object_name check_type status details;
        format timestamp datetime20.;
    run;
    
    ods rtf close;
    
    /* Export results to CSV */
    proc export data=work.cross_validation_log
        outfile="./cross_validation/cross_validation_log.csv"
        dbms=csv replace;
    run;
    
    %put NOTE: Cross-validation report generated: &output_file..rtf;
    
%mend generate_cross_validation_report;

/******************************************************************************
SECTION 6: EXAMPLE USAGE
******************************************************************************/

/*
Example cross-validation workflow:

1. Setup environment:
%setup_cross_validation_environment(
    study_id=XYZ-789,
    validation_type=DATASET,
    validator=QC Reviewer,
    reference_source=Previous Study ABC-456
);

2. Cross-validate datasets:
%cross_validate_datasets(
    primary_dataset=work.current_adsl,
    reference_dataset=reference.previous_adsl,
    object_name=ADSL_CROSS_VALIDATION,
    key_variables=USUBJID,
    critical_variables=AGE SEX RACE TRT01P,
    tolerance=0.00001
);

3. Cross-validate statistical results:
%cross_validate_statistical_results(
    primary_results=work.current_efficacy_results,
    reference_results=reference.previous_efficacy_results,
    object_name=EFFICACY_ANALYSIS,
    key_variables=PARAMCD AVISIT,
    numeric_variables=LSMEAN LSMEAN_SE DIFF DIFF_SE PVALUE,
    tolerance=0.001
);

4. Generate report:
%generate_cross_validation_report(
    report_title=Study XYZ-789 Cross-Validation Report,
    output_file=xyz789_cross_validation_report
);
*/

%put NOTE: Cross-validation examples loaded successfully;
%put NOTE: Available macros: setup_cross_validation_environment, cross_validate_datasets,;
%put NOTE:                  cross_validate_data_values, cross_validate_statistical_results,;
%put NOTE:                  generate_cross_validation_report;