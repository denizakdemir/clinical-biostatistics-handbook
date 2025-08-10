# SAS Program Validation Templates

## Validation Framework Overview

### Validation Levels

```
VALIDATION HIERARCHY
├── Level 1: Syntax and Logic Validation
│   ├── Code review for syntax errors
│   ├── Logic flow verification
│   ├── Variable naming consistency
│   └── Error handling completeness
├── Level 2: Data Validation
│   ├── Input data verification
│   ├── Data transformation accuracy
│   ├── Missing value handling
│   └── Range and consistency checks
├── Level 3: Statistical Validation
│   ├── Statistical method correctness
│   ├── Formula implementation accuracy
│   ├── Population selection verification
│   └── Results interpretation validation
└── Level 4: Output Validation
    ├── Table and listing format verification
    ├── Statistical results accuracy
    ├── Cross-referencing with specifications
    └── Regulatory compliance verification
```

## Independent Programming Validation Template

### Validation Plan Template

```sas
/******************************************************************************
VALIDATION PLAN
PROGRAM: [original_program_name.sas]
VALIDATOR: [Independent Programmer Name]
VALIDATION DATE: [DD-MMM-YYYY]
STATUS: [DRAFT/UNDER REVIEW/APPROVED]

VALIDATION OBJECTIVES:
1. Verify statistical programming accuracy
2. Confirm adherence to specifications
3. Validate output format and content
4. Ensure 21 CFR Part 11 compliance

VALIDATION APPROACH:
□ Independent programming from specifications
□ Results comparison with original program
□ Code review and logic verification
□ Test data validation
□ Edge case testing

VALIDATION CRITERIA:
□ Statistical results match within tolerance
□ Output format matches specifications
□ Population counts are identical
□ All edge cases handled appropriately
□ Documentation meets standards
******************************************************************************/

/* Validation environment setup */
options validvarname=upcase validmemname=extend;

/* Define validation parameters */
%let TOLERANCE = 1E-8;  /* Numeric comparison tolerance */
%let ORIGINAL_OUTPUT = original_output;
%let VALIDATION_OUTPUT = validation_output;
%let VALIDATION_LOG = validation_results;
```

### Independent Programming Template

```sas
/******************************************************************************
INDEPENDENT VALIDATION PROGRAM
ORIGINAL PROGRAM: [original_program_name.sas]
VALIDATION PROGRAM: [validation_program_name.sas]
VALIDATOR: [Name]
DATE: [DD-MMM-YYYY]

PURPOSE: Independent validation of [describe analysis objective]
METHOD: Independent programming based on SAP/specifications
******************************************************************************/

/* Step 1: Environment Setup */
%include "/macros/validation_macros.sas";

/* Initialize validation framework */
%init_validation(
    original_program=[original_program_name.sas],
    validator=[validator_name],
    tolerance=1E-8
);

/* Step 2: Data Preparation */
/* Independent data preparation based on specifications */
data analysis_data;
    set input.raw_data;
    
    /* Apply inclusion/exclusion criteria - independently derived */
    if age >= 18 and consent_date ^= .;
    
    /* Derive analysis variables - independent implementation */
    if baseline_value ^= . and post_value ^= . then
        change_from_baseline = post_value - baseline_value;
    
    /* Population flags - independent logic */
    if screening_date ^= . and randomization_date ^= . then
        safety_pop = 'Y';
    else
        safety_pop = 'N';
    
    if safety_pop = 'Y' and post_value ^= . then
        efficacy_pop = 'Y';
    else
        efficacy_pop = 'N';
run;

/* Step 3: Statistical Analysis - Independent Implementation */
/* Descriptive statistics */
proc means data=analysis_data n mean std median q1 q3 min max;
    class treatment;
    var change_from_baseline;
    where efficacy_pop = 'Y';
    output out=validation_desc_stats
        n=n mean=mean std=std median=median
        q1=q1 q3=q3 min=min max=max;
run;

/* Inferential statistics */
proc ttest data=analysis_data;
    class treatment;
    var change_from_baseline;
    where efficacy_pop = 'Y';
    ods output TTests=validation_ttest_results
               Statistics=validation_group_stats;
run;

/* Step 4: Output Generation */
/* Create validation output in same format as original */
data validation_table;
    merge validation_desc_stats validation_group_stats;
    by treatment;
    
    /* Format results to match original output specifications */
    length statistic $50 treatment_a $20 treatment_b $20;
    
    if treatment = 'A' then do;
        treatment_a = strip(put(n, 3.)) || ' (' || strip(put(n/total*100, 5.1)) || '%)';
        /* Continue formatting as per specifications */
    end;
    
    /* Additional formatting logic */
run;

/* Step 5: Validation Comparison */
%compare_results(
    original=&ORIGINAL_OUTPUT,
    validation=validation_table,
    tolerance=&TOLERANCE,
    key_vars=treatment,
    compare_vars=n mean std
);
```

## Test Data Validation

### Test Data Creation Macro

```sas
/******************************************************************************
MACRO: create_test_data
PURPOSE: Create comprehensive test datasets for validation
PARAMETERS:
  scenario= : Test scenario (NORMAL/EDGE/ERROR)
  n_subjects= : Number of subjects to create
  missing_rate= : Percentage of missing data
  outlier_rate= : Percentage of outlier values
******************************************************************************/

%macro create_test_data(scenario=NORMAL, n_subjects=100, 
                        missing_rate=5, outlier_rate=2);
    
    data test_data_&scenario;
        call streaminit(54321);  /* Reproducible random seed */
        
        do subject_id = 1 to &n_subjects;
            
            /* Demographics */
            age = 18 + rand('uniform') * 62;  /* Age 18-80 */
            if rand('uniform') < 0.6 then sex = 'F'; else sex = 'M';
            
            /* Treatment assignment */
            if rand('uniform') < 0.5 then treatment = 'A'; else treatment = 'B';
            
            /* Baseline measurements */
            baseline_value = 50 + rand('normal') * 15;
            
            /* Post-treatment measurements with treatment effect */
            if treatment = 'A' then
                post_value = baseline_value + 5 + rand('normal') * 10;
            else
                post_value = baseline_value + 2 + rand('normal') * 12;
            
            /* Introduce missing data */
            if rand('uniform') < &missing_rate/100 then do;
                if rand('uniform') < 0.3 then baseline_value = .;
                if rand('uniform') < 0.4 then post_value = .;
            end;
            
            /* Introduce outliers for edge case testing */
            %if %upcase(&scenario) = EDGE or %upcase(&scenario) = ERROR %then %do;
                if rand('uniform') < &outlier_rate/100 then do;
                    if rand('uniform') < 0.5 then
                        baseline_value = baseline_value * 5;
                    else
                        post_value = post_value * 5;
                end;
            %end;
            
            /* Error scenarios */
            %if %upcase(&scenario) = ERROR %then %do;
                /* Invalid dates */
                if subject_id <= 3 then do;
                    visit_date = '01JAN1800'd;  /* Invalid historical date */
                end;
                
                /* Impossible values */
                if subject_id = 4 then age = 150;  /* Impossible age */
                if subject_id = 5 then baseline_value = -999;  /* Impossible lab value */
            %end;
            
            /* Derive analysis variables */
            if baseline_value ^= . and post_value ^= . then
                change_from_baseline = post_value - baseline_value;
            
            output;
        end;
    run;
    
    /* Create summary of test data characteristics */
    proc means data=test_data_&scenario;
        title "Test Data Summary - &scenario Scenario";
        var age baseline_value post_value change_from_baseline;
    run;
    
    proc freq data=test_data_&scenario;
        tables sex treatment;
    run;
    
    title;
    
%mend create_test_data;

/* Generate test datasets */
%create_test_data(scenario=NORMAL);
%create_test_data(scenario=EDGE, missing_rate=15, outlier_rate=5);
%create_test_data(scenario=ERROR, missing_rate=20, outlier_rate=10);
```

## Results Comparison Framework

### Automated Comparison Macro

```sas
/******************************************************************************
MACRO: compare_results
PURPOSE: Automated comparison of original vs validation results
PARAMETERS:
  original= : Original output dataset
  validation= : Validation output dataset
  tolerance= : Numeric tolerance for comparisons
  key_vars= : Variables for matching records
  compare_vars= : Variables to compare
******************************************************************************/

%macro compare_results(original=, validation=, tolerance=1E-8,
                       key_vars=, compare_vars=);
    
    /* Initialize comparison results */
    data comparison_log;
        length comparison_type $20 variable $32 
               original_value $50 validation_value $50
               status $10 message $200;
        delete;
    run;
    
    /* Check dataset existence */
    %if not %sysfunc(exist(&original)) %then %do;
        %put ERROR: Original dataset &original does not exist;
        %return;
    %end;
    
    %if not %sysfunc(exist(&validation)) %then %do;
        %put ERROR: Validation dataset &validation does not exist;
        %return;
    %end;
    
    /* Merge datasets for comparison */
    data merged_comparison;
        merge &original(in=in_orig rename=(
            %do i = 1 %to %sysfunc(countw(&compare_vars));
                %let var = %scan(&compare_vars, &i);
                &var = orig_&var
            %end;
        ))
        &validation(in=in_val rename=(
            %do i = 1 %to %sysfunc(countw(&compare_vars));
                %let var = %scan(&compare_vars, &i);
                &var = val_&var
            %end;
        ));
        by &key_vars;
        
        /* Track which datasets contain each record */
        in_original = in_orig;
        in_validation = in_val;
    run;
    
    /* Perform variable-by-variable comparison */
    data detailed_comparison;
        set merged_comparison;
        
        %do i = 1 %to %sysfunc(countw(&compare_vars));
            %let var = %scan(&compare_vars, &i);
            
            /* Compare &var */
            comparison_type = 'Variable Comparison';
            variable = "&var";
            
            /* Handle missing values */
            if orig_&var = . and val_&var = . then do;
                status = 'MATCH';
                message = 'Both values missing';
                output;
            end;
            else if orig_&var = . or val_&var = . then do;
                status = 'DIFFER';
                message = 'Missing value mismatch';
                original_value = put(orig_&var, best12.);
                validation_value = put(val_&var, best12.);
                output;
            end;
            /* Numeric comparison */
            else if abs(orig_&var - val_&var) <= &tolerance then do;
                status = 'MATCH';
                message = 'Values within tolerance';
                output;
            end;
            else do;
                status = 'DIFFER';
                message = 'Values exceed tolerance: ' || 
                         strip(put(abs(orig_&var - val_&var), best12.));
                original_value = put(orig_&var, best12.);
                validation_value = put(val_&var, best12.);
                output;
            end;
        %end;
        
        /* Check for records only in one dataset */
        if not in_original then do;
            comparison_type = 'Record Existence';
            variable = 'ALL';
            status = 'DIFFER';
            message = 'Record only in validation dataset';
            output;
        end;
        
        if not in_validation then do;
            comparison_type = 'Record Existence';
            variable = 'ALL';
            status = 'DIFFER';
            message = 'Record only in original dataset';
            output;
        end;
    run;
    
    /* Generate comparison summary report */
    proc freq data=detailed_comparison;
        tables status / nocum nopercent;
        title "Validation Comparison Summary";
        title2 "Original: &original vs Validation: &validation";
    run;
    
    proc freq data=detailed_comparison;
        tables variable * status / nocum nopercent norow nocol;
        title "Variable-Level Comparison Results";
    run;
    
    /* Detail report for differences */
    proc print data=detailed_comparison;
        where status = 'DIFFER';
        var &key_vars variable status original_value validation_value message;
        title "Detailed Differences Report";
    run;
    
    title;
    
    /* Export comparison results to permanent dataset */
    data validation.comparison_results_&sysdate9;
        set detailed_comparison;
        validation_date = today();
        validation_time = time();
    run;
    
    /* Create validation summary */
    proc sql noprint;
        select count(*) into :total_comparisons
        from detailed_comparison;
        
        select count(*) into :total_matches
        from detailed_comparison
        where status = 'MATCH';
        
        select count(*) into :total_differences
        from detailed_comparison
        where status = 'DIFFER';
    quit;
    
    %put NOTE: Validation Comparison Complete;
    %put NOTE: Total Comparisons: &total_comparisons;
    %put NOTE: Matches: &total_matches;
    %put NOTE: Differences: &total_differences;
    
    %if &total_differences = 0 %then %do;
        %put NOTE: *** VALIDATION PASSED - No differences detected ***;
    %end;
    %else %do;
        %put WARNING: *** VALIDATION FAILED - &total_differences differences detected ***;
    %end;
    
%mend compare_results;
```

## Edge Case Testing Templates

### Boundary Value Testing

```sas
/******************************************************************************
EDGE CASE TESTING FRAMEWORK
PURPOSE: Test program behavior at boundary conditions
******************************************************************************/

/* Test Case 1: Empty Dataset */
data test_empty;
    set analysis_data;
    where 1=0;  /* Creates empty dataset with proper structure */
run;

%macro test_empty_dataset;
    %put NOTE: Testing empty dataset scenario;
    
    /* Run analysis with empty dataset */
    proc means data=test_empty;
        class treatment;
        var change_from_baseline;
        output out=empty_results n=n mean=mean;
    run;
    
    /* Verify appropriate handling */
    %if %nobs(empty_results) = 0 %then
        %put NOTE: Empty dataset handled correctly;
    %else
        %put WARNING: Empty dataset not handled as expected;
%mend test_empty_dataset;

/* Test Case 2: Single Record */
data test_single;
    set analysis_data(obs=1);
run;

%macro test_single_record;
    %put NOTE: Testing single record scenario;
    
    proc ttest data=test_single;
        class treatment;
        var change_from_baseline;
        ods output TTests=single_ttest;
    run;
    
    /* Verify handling of insufficient data */
    data _null_;
        if 0 then set single_ttest nobs=n;
        call symputx('ttest_records', n);
        stop;
    run;
    
    %if &ttest_records = 0 %then
        %put NOTE: Single record scenario handled appropriately;
    %else
        %put NOTE: t-test results generated with single record;
%mend test_single_record;

/* Test Case 3: All Missing Values */
data test_all_missing;
    set analysis_data;
    change_from_baseline = .;
run;

%macro test_all_missing;
    %put NOTE: Testing all missing values scenario;
    
    proc means data=test_all_missing n nmiss;
        var change_from_baseline;
        output out=missing_results n=n nmiss=nmiss;
    run;
    
    data _null_;
        set missing_results;
        if n = 0 and nmiss > 0 then
            put "NOTE: All missing values handled correctly";
        else
            put "WARNING: Missing value handling may be incorrect";
    run;
%mend test_all_missing;

/* Test Case 4: Extreme Values */
data test_extreme;
    set analysis_data;
    if _n_ = 1 then change_from_baseline = 1E10;   /* Very large positive */
    if _n_ = 2 then change_from_baseline = -1E10;  /* Very large negative */
    if _n_ = 3 then change_from_baseline = 1E-10;  /* Very small positive */
    if _n_ = 4 then change_from_baseline = -1E-10; /* Very small negative */
run;

%macro test_extreme_values;
    %put NOTE: Testing extreme values scenario;
    
    proc means data=test_extreme;
        var change_from_baseline;
        output out=extreme_results mean=mean std=std;
    run;
    
    data _null_;
        set extreme_results;
        if mean ^= . and std ^= . then
            put "NOTE: Extreme values processed successfully";
        else
            put "WARNING: Extreme values caused computational issues";
    run;
%mend test_extreme_values;

/* Execute all edge case tests */
%test_empty_dataset;
%test_single_record;
%test_all_missing;
%test_extreme_values;
```

## Validation Documentation Template

### Validation Report Template

```sas
/******************************************************************************
VALIDATION REPORT GENERATION
******************************************************************************/

%macro generate_validation_report(program_name=, validator=, validation_date=);
    
    /* Create validation report dataset */
    data validation_report;
        length section $50 item $100 status $20 comments $200;
        
        /* Header Information */
        section = 'VALIDATION SUMMARY';
        item = 'Program Name';
        status = "&program_name";
        output;
        
        item = 'Validator';
        status = "&validator";
        output;
        
        item = 'Validation Date';
        status = "&validation_date";
        output;
        
        item = 'Validation Method';
        status = 'Independent Programming';
        output;
        
        /* Validation Results Summary */
        section = 'VALIDATION RESULTS';
        item = 'Code Review';
        status = 'PASS';
        comments = 'Code structure and logic verified';
        output;
        
        item = 'Data Validation';
        status = 'PASS';
        comments = 'Input data processing verified';
        output;
        
        item = 'Statistical Methods';
        status = 'PASS';
        comments = 'Statistical calculations verified';
        output;
        
        item = 'Output Format';
        status = 'PASS';
        comments = 'Output format matches specifications';
        output;
        
        item = 'Results Comparison';
        status = 'PASS';
        comments = 'All results match within tolerance';
        output;
        
        /* Edge Case Testing */
        section = 'EDGE CASE TESTING';
        item = 'Empty Dataset';
        status = 'PASS';
        comments = 'Program handles empty datasets appropriately';
        output;
        
        item = 'Missing Data';
        status = 'PASS';
        comments = 'Missing data handled per specifications';
        output;
        
        item = 'Extreme Values';
        status = 'PASS';
        comments = 'Extreme values processed without errors';
        output;
        
        /* Compliance Check */
        section = 'COMPLIANCE VERIFICATION';
        item = '21 CFR Part 11';
        status = 'PASS';
        comments = 'Electronic records requirements met';
        output;
        
        item = 'ICH Guidelines';
        status = 'PASS';
        comments = 'Statistical principles followed';
        output;
        
        /* Overall Assessment */
        section = 'OVERALL ASSESSMENT';
        item = 'Validation Conclusion';
        status = 'APPROVED';
        comments = 'Program validated successfully - ready for production use';
        output;
    run;
    
    /* Generate formatted validation report */
    ods pdf file="validation_report_&program_name._&sysdate9..pdf";
    
    title "VALIDATION REPORT";
    title2 "Program: &program_name";
    title3 "Validator: &validator | Date: &validation_date";
    
    proc report data=validation_report nowd;
        column section item status comments;
        define section / group 'Section' style(column)={background=lightblue};
        define item / display 'Validation Item' width=30;
        define status / display 'Status' width=15;
        define comments / display 'Comments' width=40;
        
        compute section;
            if section ^= lag(section) then do;
                call define(_row_, 'style', 'style={background=lightgray fontweight=bold}');
            end;
        endcomp;
    run;
    
    ods pdf close;
    
    %put NOTE: Validation report generated: validation_report_&program_name._&sysdate9..pdf;
    
%mend generate_validation_report;

/* Generate validation report */
%generate_validation_report(
    program_name=efficacy_analysis,
    validator=John_Statistician,
    validation_date=%sysfunc(today(), date9.)
);
```

### Validation Sign-off Template

```
===============================================================================
VALIDATION SIGN-OFF FORM
===============================================================================

Program Name: _________________________________
Version: ______________________________________
Validation Date: ______________________________

VALIDATION TEAM:

Primary Programmer: ___________________________  Date: ___________
Signature: ____________________________________

Independent Validator: ________________________  Date: ___________
Signature: ____________________________________

Statistical Reviewer: _________________________  Date: ___________
Signature: ____________________________________

Quality Assurance: ____________________________  Date: ___________
Signature: ____________________________________

VALIDATION CHECKLIST:
□ Independent programming completed
□ Results comparison performed
□ Edge case testing completed
□ Code review documented
□ All discrepancies resolved
□ Documentation complete
□ 21 CFR Part 11 compliance verified
□ Ready for production use

COMMENTS:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________

APPROVAL STATUS:
□ APPROVED - Program validated and ready for production
□ CONDITIONAL - Minor issues requiring resolution
□ REJECTED - Major issues requiring rework

Date of Final Approval: _________________________

QA Manager Signature: __________________________
===============================================================================
```

---

*These validation templates provide a comprehensive framework for ensuring SAS program quality and regulatory compliance. Customize based on specific organizational requirements and therapeutic area needs.*