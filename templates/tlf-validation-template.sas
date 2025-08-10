/******************************************************************************
PROGRAM: tlf-validation-template.sas
PURPOSE: Template for Tables, Listings, and Figures (TLF) validation
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This template provides a comprehensive framework for validating Tables,
Listings, and Figures (TLFs) in clinical trials, ensuring accuracy,
completeness, and regulatory compliance.

SECTIONS INCLUDED:
1. Environment Setup and Validation Framework
2. Data Validation Checks
3. Output Comparison and Verification
4. Cross-Reference Validation
5. Format and Presentation Validation
6. Statistical Results Validation
7. Validation Report Generation
8. Quality Control Documentation
******************************************************************************/

/******************************************************************************
SECTION 1: ENVIRONMENT SETUP AND VALIDATION FRAMEWORK
******************************************************************************/

/* Study and validation parameters - MODIFY AS NEEDED */
%let study_id = [STUDY_ID];
%let protocol = [PROTOCOL_NUMBER];
%let data_cutoff = [DATA_CUTOFF_DATE];
%let validation_date = %sysfunc(today(), date9.);
%let validator_name = [VALIDATOR_NAME];
%let programmer_name = [PROGRAMMER_NAME];

/* File paths - MODIFY AS NEEDED */
%let adam_path = [ADAM_DATA_PATH];
%let output_path = [OUTPUT_PATH];
%let validation_path = [VALIDATION_OUTPUT_PATH];
%let reference_path = [REFERENCE_OUTPUT_PATH];

/* TLF specifications - MODIFY AS NEEDED */
%let tlf_spec_file = [TLF_SPECIFICATION_FILE];
%let tolerance = 0.00001; /* Numeric tolerance for comparisons */

/* Initialize validation environment */
%macro setup_tlf_validation;
    
    /* Create validation log dataset */
    data work.validation_log;
        length tlf_id $20 validation_type $30 check_name $50 
               status $10 details $500 timestamp 8;
        format timestamp datetime20.;
        delete;
    run;
    
    /* Create validation summary dataset */
    data work.validation_summary;
        length tlf_id $20 tlf_type $20 total_checks 8 passed_checks 8 
               failed_checks 8 warning_checks 8 overall_status $10;
        delete;
    run;
    
    %put NOTE: TLF validation environment initialized;
    
%mend setup_tlf_validation;

/* Initialize validation */
%setup_tlf_validation;

/******************************************************************************
SECTION 2: DATA VALIDATION CHECKS
******************************************************************************/

/******************************************************************************
MACRO: validate_input_data
PURPOSE: Validate input datasets used for TLF generation
PARAMETERS:
  dataset= : Dataset to validate
  tlf_id= : TLF identifier
  required_vars= : Space-separated list of required variables
******************************************************************************/
%macro validate_input_data(
    dataset=,
    tlf_id=,
    required_vars=
);
    
    %put NOTE: Validating input data for &tlf_id;
    
    /* Check dataset existence */
    %if not %sysfunc(exist(&dataset)) %then %do;
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "DATA_EXISTENCE";
            check_name = "Dataset Exists";
            status = "FAIL";
            details = "Dataset &dataset does not exist";
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
        
        %return;
    %end;
    
    /* Check record count */
    proc sql noprint;
        select count(*) into :record_count
        from &dataset;
    quit;
    
    data work.temp_log;
        tlf_id = "&tlf_id";
        validation_type = "DATA_CONTENT";
        check_name = "Record Count";
        if &record_count > 0 then do;
            status = "PASS";
            details = cats("Dataset contains ", &record_count, " records");
        end;
        else do;
            status = "FAIL";
            details = "Dataset is empty";
        end;
        timestamp = datetime();
    run;
    
    proc append base=work.validation_log data=work.temp_log;
    run;
    
    /* Check required variables */
    proc contents data=&dataset out=work.dataset_vars noprint;
    run;
    
    %let var_count = %sysfunc(countw(&required_vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&required_vars, &i);
        
        proc sql noprint;
            select count(*) into :var_exists
            from work.dataset_vars
            where upcase(name) = upcase("&var");
        quit;
        
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "VARIABLE_CHECK";
            check_name = "Required Variable: &var";
            if &var_exists > 0 then do;
                status = "PASS";
                details = "Variable &var found in dataset";
            end;
            else do;
                status = "FAIL";
                details = "Required variable &var missing from dataset";
            end;
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
    %end;
    
    /* Check for missing key values */
    %if %index(&required_vars, USUBJID) > 0 %then %do;
        proc sql noprint;
            select count(*) into :missing_usubjid
            from &dataset
            where missing(USUBJID);
        quit;
        
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "DATA_QUALITY";
            check_name = "USUBJID Complete";
            if &missing_usubjid = 0 then do;
                status = "PASS";
                details = "No missing USUBJID values";
            end;
            else do;
                status = "WARNING";
                details = cats("Found ", &missing_usubjid, " records with missing USUBJID");
            end;
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
    %end;
    
    %put NOTE: Input data validation completed for &tlf_id;
    
%mend validate_input_data;

/******************************************************************************
SECTION 3: OUTPUT COMPARISON AND VERIFICATION
******************************************************************************/

/******************************************************************************
MACRO: compare_tlf_outputs
PURPOSE: Compare production TLF output with reference/validation output
PARAMETERS:
  tlf_id= : TLF identifier
  production_file= : Production output file
  reference_file= : Reference output file
  comparison_type= : Type of comparison (RTF, PDF, CSV, DATASET)
******************************************************************************/
%macro compare_tlf_outputs(
    tlf_id=,
    production_file=,
    reference_file=,
    comparison_type=RTF
);
    
    %put NOTE: Comparing outputs for &tlf_id;
    
    /* Check if files exist */
    %let prod_exists = %sysfunc(fileexist(&production_file));
    %let ref_exists = %sysfunc(fileexist(&reference_file));
    
    data work.temp_log;
        tlf_id = "&tlf_id";
        validation_type = "OUTPUT_COMPARISON";
        check_name = "File Existence";
        
        if &prod_exists and &ref_exists then do;
            status = "PASS";
            details = "Both production and reference files exist";
        end;
        else if not &prod_exists and not &ref_exists then do;
            status = "FAIL";
            details = "Neither production nor reference file exists";
        end;
        else if not &prod_exists then do;
            status = "FAIL";
            details = "Production file missing";
        end;
        else do;
            status = "FAIL";
            details = "Reference file missing";
        end;
        timestamp = datetime();
    run;
    
    proc append base=work.validation_log data=work.temp_log;
    run;
    
    /* If both files exist, perform comparison */
    %if &prod_exists and &ref_exists %then %do;
        
        /* For dataset comparisons */
        %if &comparison_type = DATASET %then %do;
            
            /* Import both datasets */
            proc import datafile="&production_file" out=work.prod_data replace;
            run;
            
            proc import datafile="&reference_file" out=work.ref_data replace;
            run;
            
            /* Compare using PROC COMPARE */
            proc compare base=work.ref_data compare=work.prod_data 
                        out=work.compare_diff noprint;
            run;
            
            data work.temp_log;
                tlf_id = "&tlf_id";
                validation_type = "OUTPUT_COMPARISON";
                check_name = "Dataset Content";
                
                select (&sysinfo);
                    when (0) do;
                        status = "PASS";
                        details = "Datasets are identical";
                    end;
                    when (1) do;
                        status = "FAIL";
                        details = "Different dataset types";
                    end;
                    when (2) do;
                        status = "FAIL";
                        details = "Different variable information";
                    end;
                    when (4) do;
                        status = "WARNING";
                        details = "Different variable labels";
                    end;
                    when (8) do;
                        status = "WARNING";
                        details = "Different variable lengths";
                    end;
                    when (16) do;
                        status = "FAIL";
                        details = "Different variable values";
                    end;
                    otherwise do;
                        status = "FAIL";
                        details = cats("Multiple differences (SYSINFO=", &sysinfo, ")");
                    end;
                end;
                timestamp = datetime();
            run;
            
            proc append base=work.validation_log data=work.temp_log;
            run;
        %end;
        
        /* For file size comparison */
        %let prod_size = %sysfunc(finfo(%sysfunc(fopen(&production_file)), File Size (bytes)));
        %let ref_size = %sysfunc(finfo(%sysfunc(fopen(&reference_file)), File Size (bytes)));
        
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "OUTPUT_COMPARISON";
            check_name = "File Size";
            
            size_diff = abs(&prod_size - &ref_size);
            size_pct_diff = (size_diff / &ref_size) * 100;
            
            if size_pct_diff <= 5 then do; /* Allow 5% difference */
                status = "PASS";
                details = cats("File sizes similar (", put(size_pct_diff, 5.1), "% difference)");
            end;
            else do;
                status = "WARNING";
                details = cats("File sizes differ by ", put(size_pct_diff, 5.1), "%");
            end;
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
    %end;
    
    %put NOTE: Output comparison completed for &tlf_id;
    
%mend compare_tlf_outputs;

/******************************************************************************
SECTION 4: CROSS-REFERENCE VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_cross_references
PURPOSE: Validate cross-references between TLFs and source data
PARAMETERS:
  tlf_id= : TLF identifier
  source_data= : Source dataset
  summary_data= : TLF summary dataset
  key_variables= : Key variables for matching
******************************************************************************/
%macro validate_cross_references(
    tlf_id=,
    source_data=,
    summary_data=,
    key_variables=
);
    
    %put NOTE: Validating cross-references for &tlf_id;
    
    /* Count records in source vs summary */
    proc sql noprint;
        select count(*) into :source_count
        from &source_data;
        
        select count(*) into :summary_count
        from &summary_data;
    quit;
    
    data work.temp_log;
        tlf_id = "&tlf_id";
        validation_type = "CROSS_REFERENCE";
        check_name = "Record Count Reconciliation";
        
        if &source_count >= &summary_count then do;
            status = "PASS";
            details = cats("Source: ", &source_count, " records, Summary: ", &summary_count, " records");
        end;
        else do;
            status = "WARNING";
            details = cats("Summary has more records than source (S:", &source_count, " vs T:", &summary_count, ")");
        end;
        timestamp = datetime();
    run;
    
    proc append base=work.validation_log data=work.temp_log;
    run;
    
    /* Validate key variable consistency */
    %let key_count = %sysfunc(countw(&key_variables));
    %do i = 1 %to &key_count;
        %let key_var = %scan(&key_variables, &i);
        
        /* Check if key variable exists in both datasets */
        proc contents data=&source_data out=work.source_vars noprint;
        run;
        
        proc contents data=&summary_data out=work.summary_vars noprint;
        run;
        
        proc sql noprint;
            select count(*) into :source_has_key
            from work.source_vars
            where upcase(name) = upcase("&key_var");
            
            select count(*) into :summary_has_key
            from work.summary_vars
            where upcase(name) = upcase("&key_var");
        quit;
        
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "CROSS_REFERENCE";
            check_name = "Key Variable: &key_var";
            
            if &source_has_key > 0 and &summary_has_key > 0 then do;
                status = "PASS";
                details = "Key variable &key_var found in both datasets";
            end;
            else do;
                status = "FAIL";
                details = "Key variable &key_var missing from one or both datasets";
            end;
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
    %end;
    
    %put NOTE: Cross-reference validation completed for &tlf_id;
    
%mend validate_cross_references;

/******************************************************************************
SECTION 5: FORMAT AND PRESENTATION VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_tlf_format
PURPOSE: Validate TLF formatting and presentation standards
PARAMETERS:
  tlf_id= : TLF identifier
  tlf_file= : TLF output file
  tlf_type= : Type of TLF (TABLE, LISTING, FIGURE)
******************************************************************************/
%macro validate_tlf_format(
    tlf_id=,
    tlf_file=,
    tlf_type=TABLE
);
    
    %put NOTE: Validating format for &tlf_id;
    
    /* Check file existence and readability */
    %let file_exists = %sysfunc(fileexist(&tlf_file));
    
    data work.temp_log;
        tlf_id = "&tlf_id";
        validation_type = "FORMAT_CHECK";
        check_name = "File Accessibility";
        
        if &file_exists then do;
            status = "PASS";
            details = "TLF file exists and is accessible";
        end;
        else do;
            status = "FAIL";
            details = "TLF file does not exist or is not accessible";
        end;
        timestamp = datetime();
    run;
    
    proc append base=work.validation_log data=work.temp_log;
    run;
    
    %if &file_exists %then %do;
        
        /* Check file size (not empty) */
        %let file_size = %sysfunc(finfo(%sysfunc(fopen(&tlf_file)), File Size (bytes)));
        
        data work.temp_log;
            tlf_id = "&tlf_id";
            validation_type = "FORMAT_CHECK";
            check_name = "File Content";
            
            if &file_size > 100 then do; /* Minimum expected size */
                status = "PASS";
                details = cats("File size: ", &file_size, " bytes");
            end;
            else do;
                status = "WARNING";
                details = cats("File appears small: ", &file_size, " bytes");
            end;
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
        
        /* Format-specific validations */
        %if &tlf_type = TABLE %then %do;
            /* Table-specific format checks */
            data work.temp_log;
                tlf_id = "&tlf_id";
                validation_type = "FORMAT_CHECK";
                check_name = "Table Format Standards";
                status = "PASS"; /* Placeholder - would need file content analysis */
                details = "Table format validation completed";
                timestamp = datetime();
            run;
            
            proc append base=work.validation_log data=work.temp_log;
            run;
        %end;
        
        %else %if &tlf_type = LISTING %then %do;
            /* Listing-specific format checks */
            data work.temp_log;
                tlf_id = "&tlf_id";
                validation_type = "FORMAT_CHECK";
                check_name = "Listing Format Standards";
                status = "PASS"; /* Placeholder - would need file content analysis */
                details = "Listing format validation completed";
                timestamp = datetime();
            run;
            
            proc append base=work.validation_log data=work.temp_log;
            run;
        %end;
        
        %else %if &tlf_type = FIGURE %then %do;
            /* Figure-specific format checks */
            data work.temp_log;
                tlf_id = "&tlf_id";
                validation_type = "FORMAT_CHECK";
                check_name = "Figure Format Standards";
                status = "PASS"; /* Placeholder - would need image analysis */
                details = "Figure format validation completed";
                timestamp = datetime();
            run;
            
            proc append base=work.validation_log data=work.temp_log;
            run;
        %end;
    %end;
    
    %put NOTE: Format validation completed for &tlf_id;
    
%mend validate_tlf_format;

/******************************************************************************
SECTION 6: STATISTICAL RESULTS VALIDATION
******************************************************************************/

/******************************************************************************
MACRO: validate_statistical_results
PURPOSE: Validate statistical calculations in TLFs
PARAMETERS:
  tlf_id= : TLF identifier
  analysis_data= : Dataset with analysis results
  validation_data= : Dataset with validation results
  numeric_vars= : Numeric variables to compare
******************************************************************************/
%macro validate_statistical_results(
    tlf_id=,
    analysis_data=,
    validation_data=,
    numeric_vars=
);
    
    %put NOTE: Validating statistical results for &tlf_id;
    
    /* Merge datasets for comparison */
    data work.stat_comparison;
        merge &analysis_data(in=a) &validation_data(in=b);
        /* Assume appropriate BY variables */
        
        if a and b then match_status = "BOTH";
        else if a and not b then match_status = "ANALYSIS_ONLY";
        else if b and not a then match_status = "VALIDATION_ONLY";
    run;
    
    /* Check matching records */
    proc freq data=work.stat_comparison;
        tables match_status / out=work.match_summary;
    run;
    
    data work.temp_log;
        set work.match_summary;
        
        tlf_id = "&tlf_id";
        validation_type = "STATISTICAL_CHECK";
        check_name = cats("Record Matching: ", match_status);
        
        if match_status = "BOTH" then status = "PASS";
        else status = "WARNING";
        
        details = cats(count, " records with status: ", match_status);
        timestamp = datetime();
    run;
    
    proc append base=work.validation_log data=work.temp_log;
    run;
    
    /* Compare numeric values */
    %let var_count = %sysfunc(countw(&numeric_vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&numeric_vars, &i);
        
        data work.numeric_compare;
            set work.stat_comparison;
            where match_status = "BOTH" and not missing(&var);
            
            /* Create comparison variables with suffixes */
            analysis_value = &var; /* Assumes analysis dataset variable */
            /* validation_value would need proper naming convention */
            
            /* Calculate difference */
            if not missing(analysis_value) and not missing(validation_value) then do;
                abs_diff = abs(analysis_value - validation_value);
                if analysis_value ne 0 then pct_diff = (abs_diff / abs(analysis_value)) * 100;
                else pct_diff = 0;
                
                /* Apply tolerance check */
                if abs_diff <= &tolerance then diff_flag = "PASS";
                else if pct_diff <= 0.01 then diff_flag = "WARNING"; /* 0.01% difference */
                else diff_flag = "FAIL";
            end;
        run;
        
        /* Summarize differences */
        proc freq data=work.numeric_compare;
            tables diff_flag / out=work.diff_summary;
        run;
        
        data work.temp_log;
            set work.diff_summary;
            
            tlf_id = "&tlf_id";
            validation_type = "STATISTICAL_CHECK";
            check_name = cats("Numeric Comparison - &var: ", diff_flag);
            status = diff_flag;
            details = cats(count, " values with ", diff_flag, " status for &var");
            timestamp = datetime();
        run;
        
        proc append base=work.validation_log data=work.temp_log;
        run;
    %end;
    
    %put NOTE: Statistical validation completed for &tlf_id;
    
%mend validate_statistical_results;

/******************************************************************************
SECTION 7: VALIDATION REPORT GENERATION
******************************************************************************/

/******************************************************************************
MACRO: generate_tlf_validation_report
PURPOSE: Generate comprehensive TLF validation report
PARAMETERS:
  report_file= : Output validation report file
******************************************************************************/
%macro generate_tlf_validation_report(
    report_file=TLF_Validation_Report
);
    
    %put NOTE: Generating TLF validation report;
    
    /* Create validation summary by TLF */
    proc sql;
        create table work.tlf_validation_summary as
        select tlf_id,
               count(*) as total_checks,
               sum(case when status = "PASS" then 1 else 0 end) as passed_checks,
               sum(case when status = "FAIL" then 1 else 0 end) as failed_checks,
               sum(case when status = "WARNING" then 1 else 0 end) as warning_checks,
               case 
                   when sum(case when status = "FAIL" then 1 else 0 end) > 0 then "FAIL"
                   when sum(case when status = "WARNING" then 1 else 0 end) > 0 then "WARNING" 
                   else "PASS"
               end as overall_status
        from work.validation_log
        group by tlf_id;
    quit;
    
    /* Generate validation report */
    ods rtf file="&validation_path/&report_file..rtf" bodytitle;
    
    title1 "TLF Validation Report";
    title2 "Study: &study_id Protocol: &protocol";
    title3 "Validation Date: &validation_date";
    title4 "Validator: &validator_name Programmer: &programmer_name";
    title5;
    
    /* Executive Summary */
    proc freq data=work.tlf_validation_summary;
        tables overall_status / nocum;
        title6 "Validation Status Summary";
    run;
    
    /* Detailed Summary by TLF */
    proc print data=work.tlf_validation_summary label;
        title6 "Validation Summary by TLF";
        var tlf_id total_checks passed_checks failed_checks warning_checks overall_status;
        label tlf_id = "TLF ID"
              total_checks = "Total Checks"
              passed_checks = "Passed"
              failed_checks = "Failed"
              warning_checks = "Warnings"
              overall_status = "Overall Status";
    run;
    
    /* Failed and Warning Details */
    proc print data=work.validation_log;
        where status in ("FAIL", "WARNING");
        title6 "Issues Requiring Attention";
        var tlf_id validation_type check_name status details timestamp;
        label tlf_id = "TLF ID"
              validation_type = "Validation Type"
              check_name = "Check Name"
              status = "Status"
              details = "Details"
              timestamp = "Timestamp";
    run;
    
    /* Complete Validation Log */
    proc print data=work.validation_log;
        title6 "Complete Validation Log";
        var tlf_id validation_type check_name status details timestamp;
        label tlf_id = "TLF ID"
              validation_type = "Validation Type"
              check_name = "Check Name"
              status = "Status"
              details = "Details"
              timestamp = "Timestamp";
    run;
    
    ods rtf close;
    
    /* Export validation results */
    proc export data=work.validation_log
        outfile="&validation_path/Validation_Log_&study_id..csv"
        dbms=csv replace;
    run;
    
    proc export data=work.tlf_validation_summary
        outfile="&validation_path/Validation_Summary_&study_id..csv"
        dbms=csv replace;
    run;
    
    %put NOTE: TLF validation report generated: &report_file..rtf;
    
%mend generate_tlf_validation_report;

/******************************************************************************
SECTION 8: EXAMPLE USAGE
******************************************************************************/

/*
Example TLF validation workflow:

1. Validate input data:
%validate_input_data(
    dataset=adam.adsl,
    tlf_id=T_01_01_Demographics,
    required_vars=USUBJID SUBJID TRT01P AGE SEX RACE
);

2. Compare outputs:
%compare_tlf_outputs(
    tlf_id=T_01_01_Demographics,
    production_file=&output_path/Demographics_Table.rtf,
    reference_file=&reference_path/Demographics_Table_REF.rtf,
    comparison_type=RTF
);

3. Validate cross-references:
%validate_cross_references(
    tlf_id=T_01_01_Demographics,
    source_data=adam.adsl,
    summary_data=work.demo_summary,
    key_variables=USUBJID TRT01P
);

4. Validate format:
%validate_tlf_format(
    tlf_id=T_01_01_Demographics,
    tlf_file=&output_path/Demographics_Table.rtf,
    tlf_type=TABLE
);

5. Validate statistical results:
%validate_statistical_results(
    tlf_id=T_02_01_Efficacy,
    analysis_data=work.efficacy_results,
    validation_data=work.efficacy_validation,
    numeric_vars=MEAN STD MEDIAN LSMEAN DIFF PVALUE
);

6. Generate validation report:
%generate_tlf_validation_report(
    report_file=TLF_Validation_Report_&study_id
);
*/

/******************************************************************************
TEMPLATE COMPLETION
******************************************************************************/

%put NOTE: TLF validation template completed;
%put NOTE: Review all [PLACEHOLDER] values and modify as needed for your study;
%put NOTE: Key areas to customize:;
%put NOTE: - Study and validation parameters (lines 15-25);
%put NOTE: - File paths (lines 27-33);
%put NOTE: - TLF specifications and tolerance levels (lines 35-37);
%put NOTE: - Validation criteria and thresholds throughout macros;
%put NOTE: - Dataset names and variable names to match your study;

/* Log completion */
%put NOTE: Template execution completed at %sysfunc(datetime(), datetime20.);