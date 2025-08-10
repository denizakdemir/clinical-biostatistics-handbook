/******************************************************************************
PROGRAM: validation-framework.sas
PURPOSE: Complete validation framework for clinical biostatistics
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides a comprehensive validation framework for clinical
biostatistics, including independent programming validation, double
programming workflows, and regulatory compliance validation procedures.

SECTIONS INCLUDED:
1. Validation Environment Setup
2. Independent Programming Framework
3. Double Programming Validation
4. Output Comparison and Reconciliation
5. Validation Documentation
6. Regulatory Compliance Framework
******************************************************************************/

/******************************************************************************
SECTION 1: VALIDATION ENVIRONMENT SETUP
******************************************************************************/

/******************************************************************************
MACRO: setup_validation_environment
PURPOSE: Initialize validation environment and create audit trail
PARAMETERS:
  study_id= : Study identifier
  validation_type= : Type of validation (INDEPENDENT, DOUBLE, QC)
  programmer= : Primary programmer name
  validator= : Validator name
  validation_date= : Validation date (default: today)
******************************************************************************/
%macro setup_validation_environment(
    study_id=,
    validation_type=INDEPENDENT,
    programmer=,
    validator=,
    validation_date=
);
    
    %put NOTE: Setting up validation environment;
    %put NOTE: Study: &study_id, Type: &validation_type;
    
    /* Set default validation date */
    %if %length(&validation_date) = 0 %then %do;
        %let validation_date = %sysfunc(today(), date9.);
    %end;
    
    /* Create global validation variables */
    %global g_val_study g_val_type g_val_programmer g_val_validator g_val_date
            g_val_start_time g_val_log_path g_val_output_path;
    
    %let g_val_study = &study_id;
    %let g_val_type = &validation_type;
    %let g_val_programmer = &programmer;
    %let g_val_validator = &validator;
    %let g_val_date = &validation_date;
    %let g_val_start_time = %sysfunc(datetime(), datetime20.);
    
    /* Set up validation directories */
    %let g_val_log_path = ./validation/logs/&study_id;
    %let g_val_output_path = ./validation/output/&study_id;
    
    /* Create directories if they don't exist */
    %let rc1 = %sysfunc(dcreate(logs, ./validation));
    %let rc2 = %sysfunc(dcreate(&study_id, ./validation/logs));
    %let rc3 = %sysfunc(dcreate(output, ./validation));
    %let rc4 = %sysfunc(dcreate(&study_id, ./validation/output));
    
    /* Initialize validation log */
    data work.validation_log;
        length study_id $20 validation_type $20 action $50 
               object_name $100 status $20 details $500 
               timestamp 8 programmer $50 validator $50;
        format timestamp datetime20.;
        
        study_id = "&study_id";
        validation_type = "&validation_type";
        action = "VALIDATION_STARTED";
        object_name = "ENVIRONMENT";
        status = "INITIALIZED";
        details = "Validation environment initialized";
        timestamp = datetime();
        programmer = "&programmer";
        validator = "&validator";
        
        output;
    run;
    
    /* Save validation log */
    data validation.val_log_&study_id;
        set work.validation_log;
    run;
    
    /* Set enhanced SAS options for validation */
    options mprint mlogic symbolgen source2 notes;
    options obs=max errors=0;
    
    %put NOTE: Validation environment initialized for &study_id;
    
%mend setup_validation_environment;

/******************************************************************************
SECTION 2: INDEPENDENT PROGRAMMING FRAMEWORK
******************************************************************************/

/******************************************************************************
MACRO: independent_program_validation
PURPOSE: Execute independent programming validation
PARAMETERS:
  primary_program= : Path to primary program
  validation_program= : Path to validation program
  comparison_datasets= : Space-separated list of datasets to compare
  tolerance= : Numeric tolerance for comparisons
  output_report= : Validation report name
******************************************************************************/
%macro independent_program_validation(
    primary_program=,
    validation_program=,
    comparison_datasets=,
    tolerance=0.00001,
    output_report=
);
    
    %put NOTE: Starting independent programming validation;
    
    /* Log validation start */
    %log_validation_action(
        action=INDEPENDENT_VALIDATION_STARTED,
        object_name=&primary_program,
        details=Independent programming validation initiated
    );
    
    /* Execute primary program */
    %put NOTE: Executing primary program: &primary_program;
    %include "&primary_program";
    
    /* Rename primary outputs */
    %let dataset_count = %sysfunc(countw(&comparison_datasets));
    %do i = 1 %to &dataset_count;
        %let dataset = %scan(&comparison_datasets, &i);
        
        proc datasets library=work nolist;
            change &dataset = &dataset._primary;
        quit;
    %end;
    
    /* Execute validation program */
    %put NOTE: Executing validation program: &validation_program;
    %include "&validation_program";
    
    /* Rename validation outputs */
    %do i = 1 %to &dataset_count;
        %let dataset = %scan(&comparison_datasets, &i);
        
        proc datasets library=work nolist;
            change &dataset = &dataset._validation;
        quit;
    %end;
    
    /* Compare datasets */
    data work.comparison_summary;
        length dataset $32 comparison_type $50 status $20 
               differences 8 details $500;
        delete;
    run;
    
    %do i = 1 %to &dataset_count;
        %let dataset = %scan(&comparison_datasets, &i);
        
        %put NOTE: Comparing dataset: &dataset;
        
        /* Check if both datasets exist */
        %let primary_exists = %sysfunc(exist(work.&dataset._primary));
        %let validation_exists = %sysfunc(exist(work.&dataset._validation));
        
        %if &primary_exists and &validation_exists %then %do;
            
            /* Compare structure */
            proc compare base=work.&dataset._primary 
                        compare=work.&dataset._validation
                        out=work.diff_&dataset noprint;
            run;
            
            /* Capture comparison results */
            data work.temp_comparison;
                length dataset $32 comparison_type $50 status $20 
                       differences 8 details $500;
                
                dataset = "&dataset";
                comparison_type = "STRUCTURE_AND_DATA";
                
                /* Check SYSINFO for comparison results */
                select (&sysinfo);
                    when (0) do;
                        status = "IDENTICAL";
                        differences = 0;
                        details = "Datasets are identical";
                    end;
                    when (1) do;
                        status = "DIFFERENT_DATASETS";
                        differences = 1;
                        details = "Different dataset types";
                    end;
                    when (2) do;
                        status = "DIFFERENT_VARIABLES";
                        differences = 1;
                        details = "Different variable information";
                    end;
                    when (4) do;
                        status = "DIFFERENT_LABELS";
                        differences = 1;
                        details = "Different variable labels";
                    end;
                    when (8) do;
                        status = "DIFFERENT_LENGTH";
                        differences = 1;
                        details = "Different variable lengths";
                    end;
                    when (16) do;
                        status = "DIFFERENT_VALUES";
                        differences = 1;
                        details = "Different variable values";
                    end;
                    otherwise do;
                        status = "MULTIPLE_DIFFERENCES";
                        differences = 1;
                        details = cats("Multiple differences detected (SYSINFO=", &sysinfo, ")");
                    end;
                end;
            run;
            
            proc append base=work.comparison_summary data=work.temp_comparison;
            run;
            
            /* Detailed value comparison if needed */
            %if &sysinfo > 0 %then %do;
                %detailed_dataset_comparison(
                    dataset1=work.&dataset._primary,
                    dataset2=work.&dataset._validation,
                    tolerance=&tolerance,
                    output=work.detailed_diff_&dataset
                );
            %end;
            
        %end;
        %else %do;
            data work.temp_comparison;
                dataset = "&dataset";
                comparison_type = "EXISTENCE_CHECK";
                status = "MISSING_DATASET";
                differences = 1;
                
                if not &primary_exists and not &validation_exists then
                    details = "Both datasets missing";
                else if not &primary_exists then
                    details = "Primary dataset missing";
                else
                    details = "Validation dataset missing";
            run;
            
            proc append base=work.comparison_summary data=work.temp_comparison;
            run;
        %end;
    %end;
    
    /* Generate validation report */
    ods html file="&g_val_output_path/&output_report..html";
    
    title1 "Independent Programming Validation Report";
    title2 "Study: &g_val_study";
    title3 "Primary Program: &primary_program";
    title4 "Validation Program: &validation_program";
    title5 "Validation Date: &g_val_date";
    
    /* Summary */
    proc freq data=work.comparison_summary;
        tables status / nocum;
        title6 "Validation Status Summary";
    run;
    
    /* Detailed results */
    proc print data=work.comparison_summary;
        title6 "Detailed Comparison Results";
        var dataset comparison_type status differences details;
    run;
    
    /* Show detailed differences if any */
    %do i = 1 %to &dataset_count;
        %let dataset = %scan(&comparison_datasets, &i);
        
        %if %sysfunc(exist(work.detailed_diff_&dataset)) %then %do;
            proc print data=work.detailed_diff_&dataset(obs=20);
                title6 "Detailed Differences: &dataset (First 20)";
            run;
        %end;
    %end;
    
    ods html close;
    
    /* Log validation completion */
    proc sql noprint;
        select sum(case when status in ('IDENTICAL') then 0 else 1 end) into :total_issues
        from work.comparison_summary;
    quit;
    
    %if &total_issues = 0 %then %do;
        %log_validation_action(
            action=INDEPENDENT_VALIDATION_PASSED,
            object_name=&primary_program,
            details=All datasets identical between primary and validation programs
        );
    %end;
    %else %do;
        %log_validation_action(
            action=INDEPENDENT_VALIDATION_FAILED,
            object_name=&primary_program,
            details=%str(&total_issues differences found between primary and validation programs)
        );
    %end;
    
    %put NOTE: Independent programming validation completed;
    
%mend independent_program_validation;

/******************************************************************************
SECTION 3: DETAILED DATASET COMPARISON
******************************************************************************/

/******************************************************************************
MACRO: detailed_dataset_comparison
PURPOSE: Perform detailed comparison of two datasets
PARAMETERS:
  dataset1= : First dataset (primary)
  dataset2= : Second dataset (validation)
  tolerance= : Numeric tolerance
  output= : Output dataset with differences
******************************************************************************/
%macro detailed_dataset_comparison(
    dataset1=,
    dataset2=,
    tolerance=0.00001,
    output=
);
    
    /* Get variable information from both datasets */
    proc contents data=&dataset1 out=work.vars1 noprint;
    run;
    
    proc contents data=&dataset2 out=work.vars2 noprint;
    run;
    
    /* Find common variables */
    proc sql;
        create table work.common_vars as
        select a.name, a.type, a.length as length1, b.length as length2
        from work.vars1 as a
        inner join work.vars2 as b
        on upcase(a.name) = upcase(b.name)
        order by a.varnum;
    quit;
    
    /* Create comparison dataset */
    data &output;
        length variable $32 record_id $100 difference_type $50 
               primary_value $200 validation_value $200 numeric_diff 8;
        delete;
    run;
    
    /* Get record counts */
    proc sql noprint;
        select count(*) into :nobs1 from &dataset1;
        select count(*) into :nobs2 from &dataset2;
    quit;
    
    /* Record count comparison */
    %if &nobs1 ne &nobs2 %then %do;
        data work.temp_diff;
            variable = "_NOBS_";
            record_id = "OVERALL";
            difference_type = "RECORD_COUNT";
            primary_value = "&nobs1";
            validation_value = "&nobs2";
            numeric_diff = &nobs1 - &nobs2;
        run;
        
        proc append base=&output data=work.temp_diff;
        run;
    %end;
    
    /* Variable-by-variable comparison for first 100 records */
    %let max_compare = %sysfunc(min(&nobs1, &nobs2, 100));
    
    data work.comparison_data;
        merge &dataset1(obs=&max_compare in=in1) 
              &dataset2(obs=&max_compare in=in2);
        
        record_num = _n_;
        
        /* Create record identifier */
        length record_id $100;
        record_id = cats("Record_", record_num);
        
        if in1 and not in2 then do;
            variable = "_MERGE_";
            difference_type = "MISSING_IN_VALIDATION";
            call symputx('merge_issues', 1);
        end;
        else if in2 and not in1 then do;
            variable = "_MERGE_";
            difference_type = "MISSING_IN_PRIMARY";
            call symputx('merge_issues', 1);
        end;
    run;
    
    /* Compare each common variable */
    proc sql noprint;
        select name into :var_list separated by ' '
        from work.common_vars;
        
        select count(*) into :num_vars
        from work.common_vars;
    quit;
    
    %do v = 1 %to &num_vars;
        %let var = %scan(&var_list, &v);
        
        /* Get variable type */
        proc sql noprint;
            select type into :var_type
            from work.common_vars
            where name = "&var";
        quit;
        
        data work.var_diff_&v;
            set work.comparison_data;
            
            length variable $32 difference_type $50 
                   primary_value $200 validation_value $200 numeric_diff 8;
            
            variable = "&var";
            
            %if &var_type = 1 %then %do; /* Numeric variable */
                array primary_arr[1] &var;
                array validation_arr[1] &var;
                
                /* Compare with tolerance */
                if not missing(primary_arr[1]) and not missing(validation_arr[1]) then do;
                    if abs(primary_arr[1] - validation_arr[1]) > &tolerance then do;
                        difference_type = "NUMERIC_DIFFERENCE";
                        primary_value = put(primary_arr[1], best.);
                        validation_value = put(validation_arr[1], best.);
                        numeric_diff = primary_arr[1] - validation_arr[1];
                        output;
                    end;
                end;
                else if missing(primary_arr[1]) and not missing(validation_arr[1]) then do;
                    difference_type = "MISSING_IN_PRIMARY";
                    primary_value = ".";
                    validation_value = put(validation_arr[1], best.);
                    output;
                end;
                else if not missing(primary_arr[1]) and missing(validation_arr[1]) then do;
                    difference_type = "MISSING_IN_VALIDATION";
                    primary_value = put(primary_arr[1], best.);
                    validation_value = ".";
                    output;
                end;
            %end;
            %else %do; /* Character variable */
                array primary_arr[1] $ &var;
                array validation_arr[1] $ &var;
                
                if primary_arr[1] ne validation_arr[1] then do;
                    difference_type = "CHARACTER_DIFFERENCE";
                    primary_value = primary_arr[1];
                    validation_value = validation_arr[1];
                    output;
                end;
            %end;
            
            keep record_id variable difference_type primary_value validation_value numeric_diff;
        run;
        
        proc append base=&output data=work.var_diff_&v;
        run;
    %end;
    
    /* Clean up temporary datasets */
    proc datasets library=work nolist;
        delete vars1 vars2 common_vars temp_diff comparison_data var_diff_:;
    quit;
    
%mend detailed_dataset_comparison;

/******************************************************************************
SECTION 4: VALIDATION DOCUMENTATION
******************************************************************************/

/******************************************************************************
MACRO: log_validation_action
PURPOSE: Log validation actions for audit trail
PARAMETERS:
  action= : Action performed
  object_name= : Object affected
  status= : Status (optional)
  details= : Additional details
******************************************************************************/
%macro log_validation_action(
    action=,
    object_name=,
    status=,
    details=
);
    
    /* Create log entry */
    data work.temp_log;
        length study_id $20 validation_type $20 action $50 
               object_name $100 status $20 details $500 
               timestamp 8 programmer $50 validator $50;
        format timestamp datetime20.;
        
        study_id = "&g_val_study";
        validation_type = "&g_val_type";
        action = "&action";
        object_name = "&object_name";
        status = "&status";
        details = "&details";
        timestamp = datetime();
        programmer = "&g_val_programmer";
        validator = "&g_val_validator";
    run;
    
    /* Append to validation log */
    proc append base=validation.val_log_&g_val_study data=work.temp_log;
    run;
    
    %put NOTE: Logged validation action: &action for &object_name;
    
%mend log_validation_action;

/******************************************************************************
MACRO: generate_validation_summary
PURPOSE: Generate comprehensive validation summary report
PARAMETERS:
  study_id= : Study identifier
  output_path= : Output path for report
******************************************************************************/
%macro generate_validation_summary(
    study_id=,
    output_path=
);
    
    %put NOTE: Generating validation summary for &study_id;
    
    /* Read validation log */
    data work.val_log;
        set validation.val_log_&study_id;
    run;
    
    /* Create validation summary report */
    ods pdf file="&output_path/Validation_Summary_&study_id..pdf";
    
    title1 "Validation Summary Report";
    title2 "Study: &study_id";
    title3 "Generated: %sysfunc(datetime(), datetime20.)";
    
    /* Validation overview */
    proc freq data=work.val_log;
        tables action / nocum;
        title4 "Validation Activities Summary";
    run;
    
    proc freq data=work.val_log;
        tables status / nocum;
        title4 "Validation Status Summary";
    run;
    
    /* Timeline of activities */
    proc print data=work.val_log;
        format timestamp datetime20.;
        title4 "Validation Activity Timeline";
        var timestamp action object_name status programmer validator;
    run;
    
    /* Issues summary */
    proc print data=work.val_log;
        where status in ('FAILED', 'ERROR', 'WARNING');
        title4 "Issues Requiring Attention";
        var timestamp action object_name details;
    run;
    
    ods pdf close;
    
    %put NOTE: Validation summary report generated;
    
%mend generate_validation_summary;

/******************************************************************************
SECTION 5: REGULATORY COMPLIANCE VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: regulatory_compliance_check
PURPOSE: Perform regulatory compliance validation
PARAMETERS:
  study_id= : Study identifier
  datasets= : Space-separated list of datasets to validate
  compliance_standard= : Standard to validate against (FDA, ICH, CDISC)
******************************************************************************/
%macro regulatory_compliance_check(
    study_id=,
    datasets=,
    compliance_standard=CDISC
);
    
    %put NOTE: Performing regulatory compliance check;
    %put NOTE: Standard: &compliance_standard;
    
    data work.compliance_results;
        length dataset $32 compliance_area $50 requirement $200 
               status $20 details $500;
        delete;
    run;
    
    %let dataset_count = %sysfunc(countw(&datasets));
    %do i = 1 %to &dataset_count;
        %let dataset = %scan(&datasets, &i);
        
        %put NOTE: Checking compliance for &dataset;
        
        /* CDISC compliance checks */
        %if &compliance_standard = CDISC %then %do;
            
            /* Check for required CDISC variables */
            %if %sysfunc(find(&dataset, SDTM, i)) %then %do;
                /* SDTM compliance */
                %check_sdtm_compliance(
                    dataset=&dataset,
                    output=work.sdtm_compliance
                );
                
                proc append base=work.compliance_results data=work.sdtm_compliance;
                run;
            %end;
            %else %if %sysfunc(find(&dataset, ADAM, i)) %then %do;
                /* ADaM compliance */
                %check_adam_compliance(
                    dataset=&dataset,
                    output=work.adam_compliance
                );
                
                proc append base=work.compliance_results data=work.adam_compliance;
                run;
            %end;
        %end;
        
        /* FDA 21 CFR Part 11 compliance */
        %check_cfr_compliance(
            dataset=&dataset,
            output=work.cfr_compliance
        );
        
        proc append base=work.compliance_results data=work.cfr_compliance;
        run;
    %end;
    
    /* Generate compliance report */
    ods html file="&g_val_output_path/Regulatory_Compliance_&study_id..html";
    
    title1 "Regulatory Compliance Validation Report";
    title2 "Study: &study_id";
    title3 "Standard: &compliance_standard";
    
    proc freq data=work.compliance_results;
        tables status / nocum;
        title4 "Compliance Status Summary";
    run;
    
    proc print data=work.compliance_results;
        title4 "Detailed Compliance Results";
    run;
    
    ods html close;
    
    %log_validation_action(
        action=REGULATORY_COMPLIANCE_CHECK,
        object_name=&datasets,
        status=COMPLETED,
        details=Regulatory compliance check completed for &compliance_standard
    );
    
%mend regulatory_compliance_check;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Setup validation environment
%setup_validation_environment(
    study_id=ABC-001,
    validation_type=INDEPENDENT,
    programmer=John Doe,
    validator=Jane Smith
);

Example 2: Independent programming validation
%independent_program_validation(
    primary_program=programs/create_adsl.sas,
    validation_program=validation/validate_adsl.sas,
    comparison_datasets=adsl adae adlb,
    tolerance=0.00001,
    output_report=adsl_validation
);

Example 3: Generate validation summary
%generate_validation_summary(
    study_id=ABC-001,
    output_path=./validation/reports
);
*/

%put NOTE: Validation framework loaded successfully;
%put NOTE: Available macros: setup_validation_environment, independent_program_validation,;
%put NOTE:                  detailed_dataset_comparison, log_validation_action,;
%put NOTE:                  generate_validation_summary, regulatory_compliance_check;