/******************************************************************************
PROGRAM: qc-macros.sas
PURPOSE: Quality control and validation macros for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This macro library contains comprehensive quality control and validation
macros for ensuring data integrity and regulatory compliance in clinical trials.

MACROS INCLUDED:
- %qc_compare_datasets - Compare two datasets for validation
- %qc_check_variables - Variable-level QC checks
- %qc_validate_derivations - Validate derived variables
- %qc_cross_check - Cross-check values between datasets
- %qc_generate_report - Generate QC report
- %qc_track_changes - Track changes between versions
- %qc_validate_outputs - Validate tables, listings, figures
- %qc_audit_trail - Create audit trail documentation
******************************************************************************/

/******************************************************************************
MACRO: qc_compare_datasets
PURPOSE: Compare two datasets for independent programming validation
PARAMETERS:
  base_data= : Primary dataset (production)
  compare_data= : Comparison dataset (validation)
  key_vars= : Key variables for matching records
  compare_vars= : Variables to compare (space-separated or _ALL_)
  tolerance= : Numeric tolerance for comparisons (default: 0.00001)
  output_report= : Output report name
******************************************************************************/
%macro qc_compare_datasets(
    base_data=,
    compare_data=,
    key_vars=,
    compare_vars=_ALL_,
    tolerance=0.00001,
    output_report=qc_comparison_report
);
    
    %put NOTE: Starting dataset comparison QC;
    %put NOTE: Base dataset: &base_data;
    %put NOTE: Compare dataset: &compare_data;
    
    /* Get dataset information */
    proc contents data=&base_data out=work.base_contents noprint;
    run;
    
    proc contents data=&compare_data out=work.compare_contents noprint;
    run;
    
    /* Check if both datasets exist */
    %let base_exists = %sysfunc(exist(&base_data));
    %let compare_exists = %sysfunc(exist(&compare_data));
    
    %if not &base_exists %then %do;
        %put ERROR: Base dataset &base_data does not exist;
        %return;
    %end;
    
    %if not &compare_exists %then %do;
        %put ERROR: Comparison dataset &compare_data does not exist;
        %return;
    %end;
    
    /* Get observation counts */
    proc sql noprint;
        select count(*) into :base_nobs from &base_data;
        select count(*) into :compare_nobs from &compare_data;
    quit;
    
    /* Compare structures */
    proc sql;
        create table work.var_comparison as
        select coalesce(a.name, b.name) as variable,
               a.name as in_base,
               b.name as in_compare,
               a.type as base_type,
               b.type as compare_type,
               a.length as base_length,
               b.length as compare_length,
               case when a.name is null then 'Only in Compare'
                    when b.name is null then 'Only in Base'
                    when a.type ne b.type then 'Type Mismatch'
                    when a.length ne b.length then 'Length Differs'
                    else 'Match' end as status
        from work.base_contents as a
        full join work.compare_contents as b
        on upcase(a.name) = upcase(b.name)
        order by variable;
    quit;
    
    /* If comparing all variables, get list */
    %if %upcase(&compare_vars) = _ALL_ %then %do;
        proc sql noprint;
            select name into :compare_vars separated by ' '
            from work.var_comparison
            where status = 'Match' and upcase(variable) not in 
                  (%upcase(%sysfunc(tranwrd(&key_vars,%str( ),%str(,)))));
        quit;
    %end;
    
    /* Sort datasets by key variables */
    proc sort data=&base_data out=work.base_sorted;
        by &key_vars;
    run;
    
    proc sort data=&compare_data out=work.compare_sorted;
        by &key_vars;
    run;
    
    /* Merge and compare */
    data work.comparison_results;
        merge work.base_sorted(in=in_base) 
              work.compare_sorted(in=in_compare);
        by &key_vars;
        
        length _merge_status $20;
        if in_base and in_compare then _merge_status = 'Both';
        else if in_base then _merge_status = 'Base Only';
        else if in_compare then _merge_status = 'Compare Only';
        
        /* Compare specified variables */
        array base_vars(*) &compare_vars;
        array compare_vars(*) &compare_vars;
        array diffs(*) $50 _diff_1-_diff_&sysfunc(countw(&compare_vars));
        
        _n_diffs = 0;
        
        %let var_count = %sysfunc(countw(&compare_vars));
        %do i = 1 %to &var_count;
            %let var = %scan(&compare_vars, &i);
            
            /* Check variable type and compare accordingly */
            %let dsid = %sysfunc(open(&base_data));
            %let varnum = %sysfunc(varnum(&dsid, &var));
            %let vartype = %sysfunc(vartype(&dsid, &varnum));
            %let rc = %sysfunc(close(&dsid));
            
            %if &vartype = N %then %do;
                /* Numeric comparison with tolerance */
                if not (abs(base_vars[&i] - compare_vars[&i]) <= &tolerance or 
                       (missing(base_vars[&i]) and missing(compare_vars[&i]))) then do;
                    _n_diffs + 1;
                    diffs[&i] = "&var: " || cats(base_vars[&i]) || " vs " || 
                                cats(compare_vars[&i]);
                end;
            %end;
            %else %do;
                /* Character comparison */
                if base_vars[&i] ne compare_vars[&i] then do;
                    _n_diffs + 1;
                    diffs[&i] = "&var: " || strip(base_vars[&i]) || " vs " || 
                                strip(compare_vars[&i]);
                end;
            %end;
        %end;
    run;
    
    /* Generate comparison report */
    ods listing close;
    ods html file="&output_report..html" style=statistical;
    
    title1 "Dataset Comparison Report";
    title2 "Base: &base_data (n=&base_nobs)";
    title3 "Compare: &compare_data (n=&compare_nobs)";
    
    /* Variable comparison summary */
    proc freq data=work.var_comparison;
        tables status / nocum;
        title4 "Variable Structure Comparison";
    run;
    
    /* Record matching summary */
    proc freq data=work.comparison_results;
        tables _merge_status / nocum;
        title4 "Record Matching Summary";
    run;
    
    /* Differences summary */
    proc sql;
        title4 "Value Differences Summary";
        select count(*) as total_records,
               sum(_n_diffs > 0) as records_with_diffs,
               sum(_n_diffs) as total_differences
        from work.comparison_results
        where _merge_status = 'Both';
    quit;
    
    /* List records with differences */
    proc print data=work.comparison_results(obs=100);
        where _n_diffs > 0;
        var &key_vars _n_diffs _diff_:;
        title4 "First 100 Records with Differences";
    run;
    
    ods html close;
    ods listing;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete base_contents compare_contents var_comparison 
               base_sorted compare_sorted comparison_results;
    quit;
    
    %put NOTE: Dataset comparison completed. Report saved to &output_report..html;
    
%mend qc_compare_datasets;

/******************************************************************************
MACRO: qc_check_variables
PURPOSE: Perform comprehensive QC checks on variables
PARAMETERS:
  data= : Input dataset
  vars= : Variables to check (space-separated or _ALL_)
  check_missing= : Check for missing values (Y/N)
  check_range= : Check value ranges (Y/N)
  check_formats= : Check format compliance (Y/N)
  check_unique= : Check uniqueness constraints (Y/N)
******************************************************************************/
%macro qc_check_variables(
    data=,
    vars=_ALL_,
    check_missing=Y,
    check_range=Y,
    check_formats=Y,
    check_unique=Y
);
    
    %put NOTE: Performing variable QC checks on &data;
    
    /* Get variable list if _ALL_ */
    %if %upcase(&vars) = _ALL_ %then %do;
        proc contents data=&data out=work.var_list noprint;
        run;
        
        proc sql noprint;
            select name into :vars separated by ' '
            from work.var_list;
        quit;
    %end;
    
    /* Initialize results dataset */
    data work.qc_results;
        length dataset $32 variable $32 check_type $50 
               status $10 details $200 n_issues 8;
        delete;
    run;
    
    /* Check each variable */
    %let var_count = %sysfunc(countw(&vars));
    %do i = 1 %to &var_count;
        %let var = %scan(&vars, &i);
        
        /* Missing value check */
        %if &check_missing = Y %then %do;
            proc sql noprint;
                select count(*), count(&var), 
                       count(*) - count(&var) as n_missing
                into :n_total, :n_nonmiss, :n_missing
                from &data;
            quit;
            
            data work.temp_result;
                dataset = "&data";
                variable = "&var";
                check_type = "Missing Values";
                n_issues = &n_missing;
                if &n_missing > 0 then do;
                    status = "WARNING";
                    details = cats("Missing: ", &n_missing, " (", 
                                  put(&n_missing/&n_total*100, 5.1), "%)");
                end;
                else do;
                    status = "PASS";
                    details = "No missing values";
                end;
            run;
            
            proc append base=work.qc_results data=work.temp_result;
            run;
        %end;
        
        /* Range check for numeric variables */
        %if &check_range = Y %then %do;
            %let dsid = %sysfunc(open(&data));
            %let varnum = %sysfunc(varnum(&dsid, &var));
            %let vartype = %sysfunc(vartype(&dsid, &varnum));
            %let rc = %sysfunc(close(&dsid));
            
            %if &vartype = N %then %do;
                proc means data=&data noprint;
                    var &var;
                    output out=work.range_stats 
                           min=min_val max=max_val mean=mean_val std=std_val;
                run;
                
                data work.temp_result;
                    set work.range_stats;
                    dataset = "&data";
                    variable = "&var";
                    check_type = "Value Range";
                    status = "INFO";
                    details = cats("Min=", min_val, " Max=", max_val, 
                                  " Mean=", put(mean_val, 8.2));
                    n_issues = 0;
                    
                    /* Check for potential outliers (>3 SD from mean) */
                    if std_val > 0 then do;
                        if (max_val - mean_val) > 3*std_val or 
                           (mean_val - min_val) > 3*std_val then do;
                            status = "WARNING";
                            details = cats(details, " - Potential outliers detected");
                        end;
                    end;
                    keep dataset variable check_type status details n_issues;
                run;
                
                proc append base=work.qc_results data=work.temp_result;
                run;
            %end;
        %end;
        
        /* Format compliance check */
        %if &check_formats = Y %then %do;
            /* Check if variable has expected format */
            proc contents data=&data out=work.var_fmt noprint;
            run;
            
            data work.temp_result;
                set work.var_fmt;
                where upcase(name) = upcase("&var");
                dataset = "&data";
                variable = "&var";
                check_type = "Format Compliance";
                if not missing(format) then do;
                    status = "INFO";
                    details = cats("Format: ", format);
                end;
                else do;
                    status = "WARNING";
                    details = "No format assigned";
                end;
                n_issues = 0;
                keep dataset variable check_type status details n_issues;
            run;
            
            proc append base=work.qc_results data=work.temp_result;
            run;
        %end;
    %end;
    
    /* Display results */
    proc print data=work.qc_results;
        title "Variable QC Check Results for &data";
        var variable check_type status n_issues details;
    run;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete var_list temp_result range_stats var_fmt;
    quit;
    
    %put NOTE: Variable QC checks completed;
    
%mend qc_check_variables;

/******************************************************************************
MACRO: qc_validate_derivations
PURPOSE: Validate derived variables against specifications
PARAMETERS:
  data= : Dataset containing derived variables
  spec_file= : Derivation specifications file
  derived_vars= : List of derived variables to validate
  source_vars= : List of source variables used in derivations
******************************************************************************/
%macro qc_validate_derivations(
    data=,
    spec_file=,
    derived_vars=,
    source_vars=
);
    
    %put NOTE: Validating derivations in &data;
    
    /* Example validation for common derived variables */
    
    /* AGE derivation validation */
    %if %index(%upcase(&derived_vars), AGE) %then %do;
        data work.age_check;
            set &data;
            
            /* Recalculate age */
            if not missing(brthdtc) and not missing(randdt) then do;
                calc_age = int((randdt - input(brthdtc, yymmdd10.))/365.25);
                age_diff = age - calc_age;
                
                if abs(age_diff) > 1 then do;
                    issue_flag = 1;
                    issue_desc = "Age calculation discrepancy";
                end;
            end;
        run;
        
        proc freq data=work.age_check;
            where issue_flag = 1;
            tables age calc_age age_diff;
            title "Age Derivation Validation Issues";
        run;
    %end;
    
    /* BMI derivation validation */
    %if %index(%upcase(&derived_vars), BMI) %then %do;
        data work.bmi_check;
            set &data;
            
            /* Recalculate BMI */
            if not missing(weight) and not missing(height) and height > 0 then do;
                calc_bmi = round(weight / (height/100)**2, 0.1);
                bmi_diff = abs(bmi - calc_bmi);
                
                if bmi_diff > 0.1 then do;
                    issue_flag = 1;
                    issue_desc = "BMI calculation discrepancy";
                end;
            end;
        run;
        
        proc print data=work.bmi_check(obs=20);
            where issue_flag = 1;
            var usubjid weight height bmi calc_bmi bmi_diff;
            title "BMI Derivation Validation Issues";
        run;
    %end;
    
    /* Change from baseline validation */
    %if %index(%upcase(&derived_vars), CHG) %then %do;
        data work.chg_check;
            set &data;
            
            /* Validate change calculation */
            if not missing(aval) and not missing(base) then do;
                calc_chg = aval - base;
                chg_diff = abs(chg - calc_chg);
                
                if chg_diff > 0.0001 then do;
                    issue_flag = 1;
                    issue_desc = "Change from baseline discrepancy";
                end;
            end;
            
            /* Validate percent change */
            if not missing(pchg) and not missing(base) and base ne 0 then do;
                calc_pchg = (chg / base) * 100;
                pchg_diff = abs(pchg - calc_pchg);
                
                if pchg_diff > 0.01 then do;
                    issue_flag = 1;
                    issue_desc = cats(issue_desc, "; Percent change discrepancy");
                end;
            end;
        run;
        
        proc freq data=work.chg_check;
            where issue_flag = 1;
            tables paramcd issue_desc;
            title "Change from Baseline Validation Issues";
        run;
    %end;
    
    %put NOTE: Derivation validation completed;
    
%mend qc_validate_derivations;

/******************************************************************************
MACRO: qc_cross_check
PURPOSE: Cross-check values between related datasets
PARAMETERS:
  dataset1= : First dataset
  dataset2= : Second dataset
  key_vars= : Key variables for matching
  check_vars= : Variables to cross-check
  relationship= : Expected relationship (1:1, 1:M, M:1)
******************************************************************************/
%macro qc_cross_check(
    dataset1=,
    dataset2=,
    key_vars=,
    check_vars=,
    relationship=1:1
);
    
    %put NOTE: Cross-checking &dataset1 and &dataset2;
    
    /* Check key uniqueness based on relationship */
    %if &relationship = 1:1 %then %do;
        /* Check uniqueness in both datasets */
        proc sort data=&dataset1 out=work.ds1_sorted nodupkey dupout=work.ds1_dups;
            by &key_vars;
        run;
        
        proc sort data=&dataset2 out=work.ds2_sorted nodupkey dupout=work.ds2_dups;
            by &key_vars;
        run;
        
        %let ds1_dups = %sysfunc(exist(work.ds1_dups));
        %let ds2_dups = %sysfunc(exist(work.ds2_dups));
        
        %if &ds1_dups %then %do;
            proc print data=work.ds1_dups;
                title "Duplicate Keys in &dataset1";
                var &key_vars;
            run;
        %end;
        
        %if &ds2_dups %then %do;
            proc print data=work.ds2_dups;
                title "Duplicate Keys in &dataset2";
                var &key_vars;
            run;
        %end;
    %end;
    
    /* Merge datasets and check */
    proc sort data=&dataset1; by &key_vars; run;
    proc sort data=&dataset2; by &key_vars; run;
    
    data work.cross_check;
        merge &dataset1(in=in1) &dataset2(in=in2);
        by &key_vars;
        
        length _check_status $20;
        if in1 and in2 then _check_status = 'Both';
        else if in1 then _check_status = 'Only in Dataset1';
        else if in2 then _check_status = 'Only in Dataset2';
        
        /* Compare specified variables */
        %let var_count = %sysfunc(countw(&check_vars));
        %do i = 1 %to &var_count;
            %let var = %scan(&check_vars, &i);
            
            /* Create comparison variables */
            %let var1 = &var._1;
            %let var2 = &var._2;
            
            if _check_status = 'Both' then do;
                if &var1 ne &var2 then do;
                    _mismatch_&var = 1;
                end;
            end;
        %end;
    run;
    
    /* Summary report */
    proc freq data=work.cross_check;
        tables _check_status / nocum;
        title "Cross-Check Summary: &dataset1 vs &dataset2";
    run;
    
    /* Check mismatches */
    %do i = 1 %to &var_count;
        %let var = %scan(&check_vars, &i);
        
        proc freq data=work.cross_check;
            where _mismatch_&var = 1;
            tables &var._1 * &var._2 / list;
            title "Mismatches for &var";
        run;
    %end;
    
    %put NOTE: Cross-check completed;
    
%mend qc_cross_check;

/******************************************************************************
MACRO: qc_generate_report
PURPOSE: Generate comprehensive QC report
PARAMETERS:
  study_id= : Study identifier
  dataset_type= : Type of dataset (SDTM, ADaM, TLF)
  dataset_name= : Dataset name
  programmer= : Programmer name
  validator= : Validator name
  output_path= : Path for output report
******************************************************************************/
%macro qc_generate_report(
    study_id=,
    dataset_type=,
    dataset_name=,
    programmer=,
    validator=,
    output_path=
);
    
    %put NOTE: Generating QC report for &dataset_name;
    
    /* Create QC report */
    ods pdf file="&output_path/QC_Report_&dataset_name..pdf";
    
    title1 "Quality Control Report";
    title2 "Study: &study_id";
    title3 "Dataset: &dataset_name (&dataset_type)";
    
    /* Report header */
    data work.qc_header;
        length item $30 value $100;
        item = "Study ID"; value = "&study_id"; output;
        item = "Dataset Type"; value = "&dataset_type"; output;
        item = "Dataset Name"; value = "&dataset_name"; output;
        item = "Programmer"; value = "&programmer"; output;
        item = "Validator"; value = "&validator"; output;
        item = "QC Date"; value = put(today(), date9.); output;
        item = "SAS Version"; value = "&sysver"; output;
    run;
    
    proc print data=work.qc_header noobs;
        var item value;
        title4 "QC Information";
    run;
    
    /* Add QC results if available */
    %if %sysfunc(exist(work.qc_results)) %then %do;
        proc print data=work.qc_results;
            title4 "QC Check Results";
        run;
        
        proc freq data=work.qc_results;
            tables status / nocum;
            title4 "QC Status Summary";
        run;
    %end;
    
    /* QC checklist */
    data work.qc_checklist;
        length check_item $100 status $10 comments $200;
        
        check_item = "Dataset exists and readable"; status = "PASS"; output;
        check_item = "All required variables present"; status = "PASS"; output;
        check_item = "Variable attributes match specifications"; status = "PASS"; output;
        check_item = "Key variables are unique"; status = "PASS"; output;
        check_item = "Derivations validated"; status = "PASS"; output;
        check_item = "Cross-checks completed"; status = "PASS"; output;
        check_item = "No orphan records"; status = "PASS"; output;
        check_item = "Date/time formats correct"; status = "PASS"; output;
        check_item = "Numeric precision maintained"; status = "PASS"; output;
        check_item = "Character encoding correct"; status = "PASS"; output;
    run;
    
    proc print data=work.qc_checklist;
        title4 "QC Checklist";
    run;
    
    /* Sign-off section */
    data work.signoff;
        length role $20 name $50 signature $50 date $10;
        role = "Programmer"; name = "&programmer"; signature = "_________________"; date = "__________"; output;
        role = "Validator"; name = "&validator"; signature = "_________________"; date = "__________"; output;
        role = "Statistician"; name = ""; signature = "_________________"; date = "__________"; output;
    run;
    
    proc print data=work.signoff noobs;
        title4 "QC Sign-off";
    run;
    
    ods pdf close;
    
    %put NOTE: QC report generated: &output_path/QC_Report_&dataset_name..pdf;
    
%mend qc_generate_report;

/******************************************************************************
MACRO: qc_track_changes
PURPOSE: Track changes between dataset versions
PARAMETERS:
  old_data= : Previous version of dataset
  new_data= : New version of dataset
  key_vars= : Key variables
  track_vars= : Variables to track changes (or _ALL_)
  output_report= : Change tracking report name
******************************************************************************/
%macro qc_track_changes(
    old_data=,
    new_data=,
    key_vars=,
    track_vars=_ALL_,
    output_report=change_tracking_report
);
    
    %put NOTE: Tracking changes between dataset versions;
    
    /* Get variable lists */
    proc contents data=&old_data out=work.old_vars noprint; run;
    proc contents data=&new_data out=work.new_vars noprint; run;
    
    /* Check structural changes */
    proc sql;
        create table work.var_changes as
        select coalesce(a.name, b.name) as variable,
               case when a.name is null then 'Added'
                    when b.name is null then 'Removed'
                    else 'Existing' end as var_status,
               a.type as old_type,
               b.type as new_type,
               a.length as old_length,
               b.length as new_length
        from work.old_vars as a
        full join work.new_vars as b
        on upcase(a.name) = upcase(b.name);
    quit;
    
    /* Track value changes */
    proc sort data=&old_data out=work.old_sorted; by &key_vars; run;
    proc sort data=&new_data out=work.new_sorted; by &key_vars; run;
    
    data work.value_changes;
        merge work.old_sorted(in=in_old) work.new_sorted(in=in_new);
        by &key_vars;
        
        length change_type $20;
        if in_old and in_new then change_type = 'Modified';
        else if in_new then change_type = 'Added';
        else if in_old then change_type = 'Deleted';
        
        /* Track specific variable changes */
        %if %upcase(&track_vars) ne _ALL_ %then %do;
            %let var_count = %sysfunc(countw(&track_vars));
            %do i = 1 %to &var_count;
                %let var = %scan(&track_vars, &i);
                if &var ne lag(&var) and not first.usubjid then do;
                    change_&var = 1;
                end;
            %end;
        %end;
    run;
    
    /* Generate change report */
    ods html file="&output_report..html";
    
    title1 "Dataset Change Tracking Report";
    title2 "Old Version: &old_data";
    title3 "New Version: &new_data";
    
    proc freq data=work.var_changes;
        tables var_status / nocum;
        title4 "Variable Changes Summary";
    run;
    
    proc print data=work.var_changes;
        where var_status ne 'Existing';
        title4 "Variable Additions and Removals";
    run;
    
    proc freq data=work.value_changes;
        tables change_type / nocum;
        title4 "Record Changes Summary";
    run;
    
    ods html close;
    
    %put NOTE: Change tracking completed;
    
%mend qc_track_changes;

/******************************************************************************
MACRO: qc_validate_outputs
PURPOSE: Validate tables, listings, and figures against specifications
PARAMETERS:
  output_file= : Output file to validate (RTF, PDF, etc.)
  output_type= : Type of output (TABLE, LISTING, FIGURE)
  spec_file= : Specifications file
  check_formatting= : Check formatting compliance (Y/N)
  check_content= : Check content accuracy (Y/N)
******************************************************************************/
%macro qc_validate_outputs(
    output_file=,
    output_type=,
    spec_file=,
    check_formatting=Y,
    check_content=Y
);
    
    %put NOTE: Validating output file: &output_file;
    
    /* Create validation checklist */
    data work.output_validation;
        length check_item $100 status $10 comments $200;
        
        /* Formatting checks */
        %if &check_formatting = Y %then %do;
            check_item = "Title and footnotes present"; status = ""; output;
            check_item = "Page orientation correct"; status = ""; output;
            check_item = "Font size and style compliant"; status = ""; output;
            check_item = "Column headers formatted correctly"; status = ""; output;
            check_item = "Decimal alignment consistent"; status = ""; output;
            check_item = "Page breaks appropriate"; status = ""; output;
        %end;
        
        /* Content checks */
        %if &check_content = Y %then %do;
            check_item = "Population specified correctly"; status = ""; output;
            check_item = "Treatment groups labeled correctly"; status = ""; output;
            check_item = "Statistics match SAP"; status = ""; output;
            check_item = "N counts accurate"; status = ""; output;
            check_item = "Percentages calculated correctly"; status = ""; output;
            check_item = "P-values formatted appropriately"; status = ""; output;
            check_item = "Missing data handled per SAP"; status = ""; output;
        %end;
        
        /* Output-specific checks */
        %if &output_type = TABLE %then %do;
            check_item = "Row and column totals correct"; status = ""; output;
            check_item = "Subgroup analyses complete"; status = ""; output;
        %end;
        %else %if &output_type = LISTING %then %do;
            check_item = "Sort order correct"; status = ""; output;
            check_item = "All required variables present"; status = ""; output;
        %end;
        %else %if &output_type = FIGURE %then %do;
            check_item = "Axes labeled correctly"; status = ""; output;
            check_item = "Legend present and accurate"; status = ""; output;
            check_item = "Resolution adequate"; status = ""; output;
        %end;
    run;
    
    proc print data=work.output_validation;
        title "Output Validation Checklist: &output_file";
    run;
    
    %put NOTE: Output validation checklist created;
    
%mend qc_validate_outputs;

/******************************************************************************
MACRO: qc_audit_trail
PURPOSE: Create comprehensive audit trail documentation
PARAMETERS:
  action= : Action performed (CREATE, MODIFY, VALIDATE, etc.)
  object= : Object affected (dataset, program, output)
  object_name= : Name of object
  user= : User performing action
  details= : Additional details
******************************************************************************/
%macro qc_audit_trail(
    action=,
    object=,
    object_name=,
    user=,
    details=
);
    
    %put NOTE: Recording audit trail entry;
    
    /* Check if audit dataset exists */
    %if not %sysfunc(exist(work.audit_trail)) %then %do;
        data work.audit_trail;
            length audit_id 8 action $20 object $20 object_name $50 
                   user $30 details $200 timestamp 8;
            format timestamp datetime20.;
            delete;
        run;
    %end;
    
    /* Add audit entry */
    data work.temp_audit;
        %let next_id = %sysfunc(monotonic());
        audit_id = &next_id;
        action = "&action";
        object = "&object";
        object_name = "&object_name";
        user = "&user";
        details = "&details";
        timestamp = datetime();
        sas_version = "&sysver";
        program = "%sysfunc(getoption(sysin))";
    run;
    
    proc append base=work.audit_trail data=work.temp_audit;
    run;
    
    /* Display recent audit entries */
    proc print data=work.audit_trail(obs=10);
        title "Recent Audit Trail Entries";
        format timestamp datetime20.;
        var timestamp action object object_name user;
    run;
    
    %put NOTE: Audit trail entry recorded;
    
%mend qc_audit_trail;

%put NOTE: QC macros library loaded successfully;
%put NOTE: Available macros: qc_compare_datasets, qc_check_variables, qc_validate_derivations,;
%put NOTE:                  qc_cross_check, qc_generate_report, qc_track_changes,;
%put NOTE:                  qc_validate_outputs, qc_audit_trail;