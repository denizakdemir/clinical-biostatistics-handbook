/******************************************************************************
PROGRAM: double-programming-examples.sas
PURPOSE: Examples and framework for double programming validation
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides comprehensive examples and macros for implementing
double programming validation in clinical trials, ensuring independent
verification of statistical analyses and outputs.

SECTIONS INCLUDED:
1. Double Programming Setup and Standards
2. Independent Programming Validation
3. Output Comparison and Reconciliation
4. Discrepancy Resolution Framework
5. Documentation and Reporting
6. Quality Control Examples
******************************************************************************/

/******************************************************************************
SECTION 1: DOUBLE PROGRAMMING SETUP AND STANDARDS
******************************************************************************/

/******************************************************************************
MACRO: setup_double_programming_environment
PURPOSE: Initialize environment for double programming validation
PARAMETERS:
  study_id= : Study identifier
  lead_programmer= : Lead programmer name
  validation_programmer= : Validation programmer name
  validation_type= : Type of validation (FULL, SELECTIVE, OUTPUT_ONLY)
******************************************************************************/
%macro setup_double_programming_environment(
    study_id=,
    lead_programmer=,
    validation_programmer=,
    validation_type=FULL
);
    
    %put NOTE: Setting up double programming environment for &study_id;
    
    /* Create global variables for double programming */
    %global dp_study dp_lead dp_validator dp_type dp_start_time dp_log_file;
    
    %let dp_study = &study_id;
    %let dp_lead = &lead_programmer;
    %let dp_validator = &validation_programmer;
    %let dp_type = &validation_type;
    %let dp_start_time = %sysfunc(datetime(), datetime20.);
    %let dp_log_file = ./validation/double_programming_log_&study_id..txt;
    
    /* Create directory structure */
    %let rc1 = %sysfunc(dcreate(validation, .));
    %let rc2 = %sysfunc(dcreate(lead_programmer, ./validation));
    %let rc3 = %sysfunc(dcreate(validation_programmer, ./validation));
    %let rc4 = %sysfunc(dcreate(comparison_results, ./validation));
    %let rc5 = %sysfunc(dcreate(final_outputs, ./validation));
    
    /* Initialize validation log */
    data work.double_prog_log;
        length study_id $20 lead_programmer $50 validation_programmer $50
               object_name $100 validation_type $20 action $50
               status $20 details $500 timestamp 8;
        format timestamp datetime20.;
        
        study_id = "&study_id";
        lead_programmer = "&lead_programmer";
        validation_programmer = "&validation_programmer";
        object_name = "ENVIRONMENT";
        validation_type = "&validation_type";
        action = "SETUP_INITIATED";
        status = "STARTED";
        details = "Double programming environment initialized";
        timestamp = datetime();
        
        output;
    run;
    
    /* Create validation tracking dataset */
    data work.validation_tracker;
        length object_name $100 object_type $50 lead_status $20 
               validation_status $20 comparison_status $20 final_status $20
               lead_completion_date 8 validation_completion_date 8
               comparison_completion_date 8;
        format lead_completion_date validation_completion_date 
               comparison_completion_date date9.;
        delete;
    run;
    
    %put NOTE: Double programming environment setup completed;
    
%mend setup_double_programming_environment;

/******************************************************************************
SECTION 2: INDEPENDENT PROGRAMMING VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: register_validation_object
PURPOSE: Register an object for double programming validation
PARAMETERS:
  object_name= : Name of object to validate
  object_type= : Type (DATASET, TABLE, LISTING, FIGURE, MACRO)
  priority= : Priority level (HIGH, MEDIUM, LOW)
  lead_program= : Lead programmer's program path
  validation_program= : Validation programmer's program path
******************************************************************************/
%macro register_validation_object(
    object_name=,
    object_type=DATASET,
    priority=MEDIUM,
    lead_program=,
    validation_program=
);
    
    %put NOTE: Registering &object_name for double programming validation;
    
    data work.temp_tracker;
        length object_name $100 object_type $50 priority $10
               lead_program $200 validation_program $200
               lead_status $20 validation_status $20 comparison_status $20 final_status $20;
        
        object_name = "&object_name";
        object_type = "&object_type";
        priority = "&priority";
        lead_program = "&lead_program";
        validation_program = "&validation_program";
        lead_status = "REGISTERED";
        validation_status = "REGISTERED";
        comparison_status = "PENDING";
        final_status = "PENDING";
        registration_date = today();
        
        output;
    run;
    
    proc append base=work.validation_tracker data=work.temp_tracker;
    run;
    
    /* Log registration */
    data work.temp_log;
        study_id = "&dp_study";
        lead_programmer = "&dp_lead";
        validation_programmer = "&dp_validator";
        object_name = "&object_name";
        validation_type = "&dp_type";
        action = "OBJECT_REGISTERED";
        status = "REGISTERED";
        details = cats("Object registered for ", "&priority", " priority validation");
        timestamp = datetime();
    run;
    
    proc append base=work.double_prog_log data=work.temp_log;
    run;
    
%mend register_validation_object;

/******************************************************************************
MACRO: execute_lead_programming
PURPOSE: Execute lead programmer's code and capture results
PARAMETERS:
  object_name= : Object name being programmed
  program_path= : Path to lead programmer's code
  output_location= : Where to save lead outputs
******************************************************************************/
%macro execute_lead_programming(
    object_name=,
    program_path=,
    output_location=./validation/lead_programmer
);
    
    %put NOTE: Executing lead programming for &object_name;
    
    /* Set up lead programmer environment */
    libname leadout "&output_location";
    
    /* Capture log information */
    %let log_file = &output_location/&object_name._lead.log;
    proc printto log="&log_file" new;
    run;
    
    /* Execute lead programmer's code */
    %include "&program_path";
    
    /* Reset log */
    proc printto;
    run;
    
    /* Update tracking dataset */
    data work.validation_tracker;
        set work.validation_tracker;
        if object_name = "&object_name" then do;
            lead_status = "COMPLETED";
            lead_completion_date = today();
            lead_completion_time = datetime();
        end;
    run;
    
    /* Log completion */
    data work.temp_log;
        study_id = "&dp_study";
        object_name = "&object_name";
        action = "LEAD_PROGRAMMING_COMPLETED";
        status = "COMPLETED";
        details = "Lead programming execution completed successfully";
        timestamp = datetime();
    run;
    
    proc append base=work.double_prog_log data=work.temp_log;
    run;
    
    %put NOTE: Lead programming completed for &object_name;
    
%mend execute_lead_programming;

/******************************************************************************
MACRO: execute_validation_programming
PURPOSE: Execute validation programmer's code independently
PARAMETERS:
  object_name= : Object name being validated
  program_path= : Path to validation programmer's code
  output_location= : Where to save validation outputs
******************************************************************************/
%macro execute_validation_programming(
    object_name=,
    program_path=,
    output_location=./validation/validation_programmer
);
    
    %put NOTE: Executing validation programming for &object_name;
    
    /* Set up validation programmer environment */
    libname validout "&output_location";
    
    /* Clear any existing work datasets to ensure independence */
    proc datasets library=work kill;
    quit;
    
    /* Capture log information */
    %let log_file = &output_location/&object_name._validation.log;
    proc printto log="&log_file" new;
    run;
    
    /* Execute validation programmer's code */
    %include "&program_path";
    
    /* Reset log */
    proc printto;
    run;
    
    /* Update tracking dataset */
    data work.validation_tracker;
        set work.validation_tracker;
        if object_name = "&object_name" then do;
            validation_status = "COMPLETED";
            validation_completion_date = today();
            validation_completion_time = datetime();
        end;
    run;
    
    /* Log completion */
    data work.temp_log;
        study_id = "&dp_study";
        object_name = "&object_name";
        action = "VALIDATION_PROGRAMMING_COMPLETED";
        status = "COMPLETED";
        details = "Validation programming execution completed successfully";
        timestamp = datetime();
    run;
    
    proc append base=work.double_prog_log data=work.temp_log;
    run;
    
    %put NOTE: Validation programming completed for &object_name;
    
%mend execute_validation_programming;

/******************************************************************************
SECTION 3: OUTPUT COMPARISON AND RECONCILIATION
******************************************************************************/

/******************************************************************************
MACRO: compare_datasets
PURPOSE: Compare datasets produced by lead and validation programmers
PARAMETERS:
  object_name= : Name of object being compared
  lead_dataset= : Lead programmer's dataset
  validation_dataset= : Validation programmer's dataset
  key_vars= : Key variables for comparison
  tolerance= : Numeric tolerance for comparisons
******************************************************************************/
%macro compare_datasets(
    object_name=,
    lead_dataset=,
    validation_dataset=,
    key_vars=,
    tolerance=0.00001
);
    
    %put NOTE: Comparing datasets for &object_name;
    
    /* Check if both datasets exist */
    %let lead_exists = %sysfunc(exist(&lead_dataset));
    %let val_exists = %sysfunc(exist(&validation_dataset));
    
    data work.comparison_results;
        length object_name $100 comparison_type $50 status $20 
               details $500 differences_count 8;
        
        object_name = "&object_name";
        comparison_type = "DATASET_EXISTENCE";
        
        if &lead_exists and &val_exists then do;
            status = "PASS";
            details = "Both datasets exist";
            differences_count = 0;
        end;
        else if not &lead_exists and not &val_exists then do;
            status = "FAIL";
            details = "Neither dataset exists";
            differences_count = 1;
        end;
        else if not &lead_exists then do;
            status = "FAIL";
            details = "Lead dataset missing";
            differences_count = 1;
        end;
        else do;
            status = "FAIL";
            details = "Validation dataset missing";
            differences_count = 1;
        end;
    run;
    
    %if &lead_exists and &val_exists %then %do;
        
        /* Perform detailed comparison using PROC COMPARE */
        proc compare base=&lead_dataset compare=&validation_dataset 
                    out=work.detailed_differences noprint;
        run;
        
        /* Analyze comparison results */
        data work.temp_comparison;
            length object_name $100 comparison_type $50 status $20 details $500;
            
            object_name = "&object_name";
            comparison_type = "DATASET_CONTENT";
            
            /* Check SYSINFO for comparison results */
            select (&sysinfo);
                when (0) do;
                    status = "PASS";
                    details = "Datasets are identical";
                    differences_count = 0;
                end;
                when (1) do;
                    status = "FAIL";
                    details = "Different dataset types";
                    differences_count = 1;
                end;
                when (2) do;
                    status = "WARNING";
                    details = "Different variable information (names, types, lengths)";
                    differences_count = 1;
                end;
                when (4) do;
                    status = "WARNING";
                    details = "Different variable labels";
                    differences_count = 1;
                end;
                when (8) do;
                    status = "WARNING";
                    details = "Different variable lengths";
                    differences_count = 1;
                end;
                when (16) do;
                    status = "FAIL";
                    details = "Different data values";
                    differences_count = 1;
                end;
                otherwise do;
                    status = "FAIL";
                    details = cats("Multiple differences detected (SYSINFO=", &sysinfo, ")");
                    differences_count = 1;
                end;
            end;
        run;
        
        proc append base=work.comparison_results data=work.temp_comparison;
        run;
        
        /* If there are data differences, perform detailed analysis */
        %if &sysinfo > 0 %then %do;
            %detailed_difference_analysis(
                object_name=&object_name,
                lead_dataset=&lead_dataset,
                validation_dataset=&validation_dataset,
                key_vars=&key_vars,
                tolerance=&tolerance
            );
        %end;
    %end;
    
    /* Update tracking dataset */
    data work.validation_tracker;
        set work.validation_tracker;
        if object_name = "&object_name" then do;
            comparison_status = "COMPLETED";
            comparison_completion_date = today();
        end;
    run;
    
    /* Log comparison results */
    proc sql noprint;
        select max(case when status = "FAIL" then 1 else 0 end) into :has_failures
        from work.comparison_results
        where object_name = "&object_name";
    quit;
    
    data work.temp_log;
        study_id = "&dp_study";
        object_name = "&object_name";
        action = "DATASET_COMPARISON_COMPLETED";
        if &has_failures then do;
            status = "DIFFERENCES_FOUND";
            details = "Dataset comparison completed with differences requiring review";
        end;
        else do;
            status = "IDENTICAL";
            details = "Dataset comparison completed - datasets are identical";
        end;
        timestamp = datetime();
    run;
    
    proc append base=work.double_prog_log data=work.temp_log;
    run;
    
    %put NOTE: Dataset comparison completed for &object_name;
    
%mend compare_datasets;

/******************************************************************************
MACRO: detailed_difference_analysis
PURPOSE: Perform detailed analysis of differences between datasets
PARAMETERS:
  object_name= : Name of object
  lead_dataset= : Lead dataset
  validation_dataset= : Validation dataset  
  key_vars= : Key variables
  tolerance= : Numeric tolerance
******************************************************************************/
%macro detailed_difference_analysis(
    object_name=,
    lead_dataset=,
    validation_dataset=,
    key_vars=,
    tolerance=0.00001
);
    
    %put NOTE: Performing detailed difference analysis for &object_name;
    
    /* Get variable information */
    proc contents data=&lead_dataset out=work.lead_vars noprint;
    run;
    
    proc contents data=&validation_dataset out=work.val_vars noprint;
    run;
    
    /* Find common numeric and character variables */
    proc sql;
        create table work.common_vars as
        select a.name, a.type, a.length as lead_length, b.length as val_length
        from work.lead_vars as a
        inner join work.val_vars as b
        on upcase(a.name) = upcase(b.name)
        order by a.varnum;
    quit;
    
    /* Create detailed comparison report */
    data work.detailed_differences;
        length object_name $100 variable $32 difference_type $50
               record_identifier $200 lead_value $200 validation_value $200
               numeric_difference 8;
        delete;
    run;
    
    /* Merge datasets and compare values */
    data work.merged_comparison;
        merge &lead_dataset(in=lead) &validation_dataset(in=val);
        %if %length(&key_vars) > 0 %then %do;
            by &key_vars;
        %end;
        
        /* Create record identifier */
        length record_id $200;
        %if %length(&key_vars) > 0 %then %do;
            record_id = cats(%do i = 1 %to %sysfunc(countw(&key_vars));
                %let key = %scan(&key_vars, &i);
                %if &i > 1 %then %do; "|", %end;
                &key
            %end;);
        %end;
        %else %do;
            record_id = cats("Record_", _n_);
        %end;
        
        /* Flag records present in only one dataset */
        if lead and not val then record_status = "LEAD_ONLY";
        else if val and not lead then record_status = "VALIDATION_ONLY";
        else record_status = "BOTH";
    run;
    
    /* Analyze record-level differences */
    proc freq data=work.merged_comparison;
        tables record_status / out=work.record_status_summary;
    run;
    
    /* Create summary of record differences */
    data work.temp_differences;
        set work.record_status_summary;
        
        object_name = "&object_name";
        variable = "_RECORDS_";
        difference_type = cats("RECORD_", record_status);
        record_identifier = "OVERALL";
        lead_value = "";
        validation_value = "";
        numeric_difference = count;
        
        keep object_name variable difference_type record_identifier 
             lead_value validation_value numeric_difference;
    run;
    
    proc append base=work.detailed_differences data=work.temp_differences;
    run;
    
    /* Variable-by-variable comparison for matching records */
    %let var_count = 0;
    proc sql noprint;
        select count(*) into :var_count
        from work.common_vars;
    quit;
    
    %if &var_count > 0 %then %do;
        proc sql noprint;
            select name into :var_list separated by " "
            from work.common_vars;
        quit;
        
        /* Compare each variable */
        %do v = 1 %to &var_count;
            %let var = %scan(&var_list, &v);
            
            /* Get variable type */
            proc sql noprint;
                select type into :var_type
                from work.common_vars
                where name = "&var";
            quit;
            
            data work.var_differences;
                set work.merged_comparison;
                where record_status = "BOTH";
                
                length variable $32 difference_type $50 lead_value $200 validation_value $200;
                variable = "&var";
                
                %if &var_type = 1 %then %do; /* Numeric */
                    if not missing(&var._lead) and not missing(&var._val) then do;
                        if abs(&var._lead - &var._val) > &tolerance then do;
                            difference_type = "NUMERIC_VALUE_DIFFERENCE";
                            lead_value = put(&var._lead, best32.);
                            validation_value = put(&var._val, best32.);
                            numeric_difference = &var._lead - &var._val;
                            output;
                        end;
                    end;
                    else if missing(&var._lead) ne missing(&var._val) then do;
                        difference_type = "MISSING_VALUE_PATTERN";
                        if missing(&var._lead) then lead_value = "MISSING";
                        else lead_value = put(&var._lead, best32.);
                        if missing(&var._val) then validation_value = "MISSING";
                        else validation_value = put(&var._val, best32.);
                        output;
                    end;
                %end;
                %else %do; /* Character */
                    if &var._lead ne &var._val then do;
                        difference_type = "CHARACTER_VALUE_DIFFERENCE";
                        lead_value = &var._lead;
                        validation_value = &var._val;
                        output;
                    end;
                %end;
                
                object_name = "&object_name";
                record_identifier = record_id;
                
                keep object_name variable difference_type record_identifier 
                     lead_value validation_value numeric_difference;
            run;
            
            proc append base=work.detailed_differences data=work.var_differences;
            run;
        %end;
    %end;
    
    /* Save detailed differences for review */
    data validation.detailed_differences_&object_name;
        set work.detailed_differences;
    run;
    
    %put NOTE: Detailed difference analysis completed for &object_name;
    
%mend detailed_difference_analysis;

/******************************************************************************
SECTION 4: DISCREPANCY RESOLUTION FRAMEWORK
******************************************************************************/

/******************************************************************************
MACRO: initiate_discrepancy_resolution
PURPOSE: Start the discrepancy resolution process
PARAMETERS:
  object_name= : Name of object with discrepancies
  resolution_priority= : Priority (HIGH, MEDIUM, LOW)
  assigned_to= : Person assigned to resolve
******************************************************************************/
%macro initiate_discrepancy_resolution(
    object_name=,
    resolution_priority=HIGH,
    assigned_to=
);
    
    %put NOTE: Initiating discrepancy resolution for &object_name;
    
    /* Create discrepancy resolution tracking */
    data work.discrepancy_resolution;
        length object_name $100 resolution_priority $10 assigned_to $50
               resolution_status $20 resolution_details $500
               initiation_date 8 target_resolution_date 8 actual_resolution_date 8;
        format initiation_date target_resolution_date actual_resolution_date date9.;
        
        object_name = "&object_name";
        resolution_priority = "&resolution_priority";
        assigned_to = "&assigned_to";
        resolution_status = "OPEN";
        resolution_details = "Discrepancy resolution process initiated";
        initiation_date = today();
        
        /* Set target resolution date based on priority */
        select (resolution_priority);
            when ("HIGH") target_resolution_date = today() + 1;
            when ("MEDIUM") target_resolution_date = today() + 3;
            when ("LOW") target_resolution_date = today() + 7;
            otherwise target_resolution_date = today() + 3;
        end;
    run;
    
    /* Update validation tracker */
    data work.validation_tracker;
        set work.validation_tracker;
        if object_name = "&object_name" then do;
            final_status = "DISCREPANCY_RESOLUTION";
        end;
    run;
    
    /* Log discrepancy initiation */
    data work.temp_log;
        study_id = "&dp_study";
        object_name = "&object_name";
        action = "DISCREPANCY_RESOLUTION_INITIATED";
        status = "OPEN";
        details = cats("Assigned to ", "&assigned_to", " with ", "&resolution_priority", " priority");
        timestamp = datetime();
    run;
    
    proc append base=work.double_prog_log data=work.temp_log;
    run;
    
    %put NOTE: Discrepancy resolution initiated for &object_name;
    
%mend initiate_discrepancy_resolution;

/******************************************************************************
SECTION 5: DOCUMENTATION AND REPORTING
******************************************************************************/

/******************************************************************************
MACRO: generate_double_programming_report
PURPOSE: Generate comprehensive double programming validation report
PARAMETERS:
  report_title= : Title for the report
  output_file= : Output file name
******************************************************************************/
%macro generate_double_programming_report(
    report_title=Double Programming Validation Report,
    output_file=double_programming_report
);
    
    %put NOTE: Generating double programming validation report;
    
    /* Create summary statistics */
    proc sql;
        create table work.summary_stats as
        select count(*) as total_objects,
               sum(case when final_status = "COMPLETED" then 1 else 0 end) as completed_objects,
               sum(case when final_status = "DISCREPANCY_RESOLUTION" then 1 else 0 end) as objects_with_discrepancies,
               sum(case when final_status = "PENDING" then 1 else 0 end) as pending_objects
        from work.validation_tracker;
    quit;
    
    /* Generate report */
    ods rtf file="./validation/&output_file..rtf" style=minimal;
    
    title1 "&report_title";
    title2 "Study: &dp_study";
    title3 "Lead Programmer: &dp_lead, Validation Programmer: &dp_validator";
    title4 "Report Generated: %sysfunc(datetime(), datetime20.)";
    
    /* Executive Summary */
    proc print data=work.summary_stats noobs label;
        title5 "Executive Summary";
        label total_objects = "Total Objects"
              completed_objects = "Completed"
              objects_with_discrepancies = "With Discrepancies"
              pending_objects = "Pending";
    run;
    
    /* Detailed Object Status */
    proc print data=work.validation_tracker label;
        title5 "Detailed Object Status";
        var object_name object_type priority final_status 
            lead_completion_date validation_completion_date comparison_completion_date;
        label object_name = "Object Name"
              object_type = "Type"
              priority = "Priority"
              final_status = "Final Status"
              lead_completion_date = "Lead Completed"
              validation_completion_date = "Validation Completed"
              comparison_completion_date = "Comparison Completed";
    run;
    
    /* Comparison Results Summary */
    proc freq data=work.comparison_results;
        tables status / nocum;
        title5 "Comparison Results Summary";
    run;
    
    /* Objects Requiring Attention */
    proc print data=work.validation_tracker;
        where final_status in ("DISCREPANCY_RESOLUTION", "PENDING");
        title5 "Objects Requiring Attention";
        var object_name object_type priority final_status;
    run;
    
    /* Detailed Activity Log */
    proc print data=work.double_prog_log;
        title5 "Detailed Activity Log";
        var timestamp object_name action status details;
        format timestamp datetime20.;
    run;
    
    ods rtf close;
    
    %put NOTE: Double programming validation report generated: &output_file..rtf;
    
%mend generate_double_programming_report;

/******************************************************************************
SECTION 6: EXAMPLE USAGE
******************************************************************************/

/*
Example double programming validation workflow:

1. Setup environment:
%setup_double_programming_environment(
    study_id=ABC-123,
    lead_programmer=John Smith,
    validation_programmer=Jane Doe,
    validation_type=FULL
);

2. Register objects for validation:
%register_validation_object(
    object_name=ADSL,
    object_type=DATASET,
    priority=HIGH,
    lead_program=programs/create_adsl_lead.sas,
    validation_program=validation/create_adsl_validation.sas
);

3. Execute lead programming:
%execute_lead_programming(
    object_name=ADSL,
    program_path=programs/create_adsl_lead.sas,
    output_location=./validation/lead_programmer
);

4. Execute validation programming:
%execute_validation_programming(
    object_name=ADSL,
    program_path=validation/create_adsl_validation.sas,
    output_location=./validation/validation_programmer
);

5. Compare outputs:
%compare_datasets(
    object_name=ADSL,
    lead_dataset=leadout.adsl,
    validation_dataset=validout.adsl,
    key_vars=USUBJID,
    tolerance=0.00001
);

6. Generate report:
%generate_double_programming_report(
    report_title=ADSL Double Programming Validation Report,
    output_file=adsl_double_programming_report
);
*/

%put NOTE: Double programming examples loaded successfully;
%put NOTE: Available macros: setup_double_programming_environment, register_validation_object,;
%put NOTE:                  execute_lead_programming, execute_validation_programming,;
%put NOTE:                  compare_datasets, initiate_discrepancy_resolution,;
%put NOTE:                  generate_double_programming_report;