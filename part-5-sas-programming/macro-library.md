# Clinical SAS Macro Library

## Essential Data Management Macros

### Data Validation Macro

```sas
/******************************************************************************
MACRO: check_data
PURPOSE: Comprehensive data validation for clinical datasets
PARAMETERS:
  data= : Input dataset to validate
  vars= : Variables to check (default: all)
  missing_threshold= : % missing threshold for warning (default: 10)
  outlier_method= : Method for outlier detection (IQR/SD)
  report= : Generate validation report (Y/N)
******************************************************************************/

%macro check_data(data=, vars=_ALL_, missing_threshold=10, 
                  outlier_method=IQR, report=Y);
    
    %local dsid nvars i varname vartype;
    
    /* Open dataset and get variable information */
    %let dsid = %sysfunc(open(&data));
    %if &dsid = 0 %then %do;
        %put ERROR: Dataset &data could not be opened;
        %return;
    %end;
    
    %let nvars = %sysfunc(attrn(&dsid, nvars));
    
    /* Create validation results dataset */
    data validation_results;
        length variable $32 issue $100 severity $10 count 8;
        delete;
    run;
    
    /* Check each variable */
    %do i = 1 %to &nvars;
        %let varname = %sysfunc(varname(&dsid, &i));
        %let vartype = %sysfunc(vartype(&dsid, &i));
        
        /* Skip if not in requested variable list */
        %if %upcase(&vars) ^= _ALL_ %then %do;
            %if %sysfunc(indexw(%upcase(&vars), %upcase(&varname))) = 0 %then
                %goto next_var;
        %end;
        
        /* Missing value analysis */
        proc sql noprint;
            select count(*) into :total_obs
            from &data;
            
            select count(*) into :missing_count
            from &data
            where &varname is missing;
            
            select calculated(&missing_count * 100 / &total_obs) into :missing_pct
            from (select 1);
        quit;
        
        /* Flag high missing percentages */
        %if &missing_pct > &missing_threshold %then %do;
            data _temp_validation;
                variable = "&varname";
                issue = "High missing percentage: &missing_pct%";
                severity = "WARNING";
                count = &missing_count;
                output;
            run;
            
            proc append base=validation_results data=_temp_validation;
            run;
        %end;
        
        /* Numeric variable specific checks */
        %if &vartype = N %then %do;
            
            /* Outlier detection */
            proc means data=&data noprint;
                var &varname;
                output out=_temp_stats
                    mean=mean std=std q1=q1 q3=q3 n=n;
            run;
            
            data _null_;
                set _temp_stats;
                call symputx('var_mean', mean);
                call symputx('var_std', std);
                call symputx('var_q1', q1);
                call symputx('var_q3', q3);
                call symputx('var_n', n);
            run;
            
            %if &outlier_method = IQR %then %do;
                %let iqr = %sysevalf(&var_q3 - &var_q1);
                %let lower_bound = %sysevalf(&var_q1 - 1.5 * &iqr);
                %let upper_bound = %sysevalf(&var_q3 + 1.5 * &iqr);
            %end;
            %else %do;
                %let lower_bound = %sysevalf(&var_mean - 3 * &var_std);
                %let upper_bound = %sysevalf(&var_mean + 3 * &var_std);
            %end;
            
            proc sql noprint;
                select count(*) into :outlier_count
                from &data
                where &varname < &lower_bound or &varname > &upper_bound;
            quit;
            
            %if &outlier_count > 0 %then %do;
                data _temp_validation;
                    variable = "&varname";
                    issue = "Potential outliers detected";
                    severity = "INFO";
                    count = &outlier_count;
                    output;
                run;
                
                proc append base=validation_results data=_temp_validation;
                run;
            %end;
        %end;
        
        /* Character variable specific checks */
        %else %do;
            /* Check for leading/trailing spaces */
            proc sql noprint;
                select count(*) into :space_count
                from &data
                where &varname ^= strip(&varname) and &varname is not missing;
            quit;
            
            %if &space_count > 0 %then %do;
                data _temp_validation;
                    variable = "&varname";
                    issue = "Leading/trailing spaces detected";
                    severity = "WARNING";
                    count = &space_count;
                    output;
                run;
                
                proc append base=validation_results data=_temp_validation;
                run;
            %end;
        %end;
        
        %next_var:
    %end;
    
    %let dsid = %sysfunc(close(&dsid));
    
    /* Generate report if requested */
    %if %upcase(&report) = Y %then %do;
        title "Data Validation Report for &data";
        proc print data=validation_results noobs;
            var variable issue severity count;
        run;
        title;
    %end;
    
    /* Clean up temporary datasets */
    proc datasets library=work nolist;
        delete _temp_validation _temp_stats;
    quit;
    
%mend check_data;
```

### Dataset Comparison Macro

```sas
/******************************************************************************
MACRO: compare_datasets
PURPOSE: Compare two datasets for differences
PARAMETERS:
  base= : Base dataset for comparison
  compare= : Dataset to compare against base
  id= : ID variable(s) for matching records
  vars= : Variables to compare (default: all common variables)
  tolerance= : Numeric tolerance for differences (default: 1E-8)
******************************************************************************/

%macro compare_datasets(base=, compare=, id=, vars=, tolerance=1E-8);
    
    /* Get common variables if not specified */
    %if %length(&vars) = 0 %then %do;
        proc contents data=&base out=_base_vars(keep=name) noprint;
        run;
        
        proc contents data=&compare out=_comp_vars(keep=name) noprint;
        run;
        
        proc sql noprint;
            select name into :vars separated by ' '
            from _base_vars
            where upcase(name) in (select upcase(name) from _comp_vars)
            and upcase(name) not in (%sysfunc(tranwrd(%upcase(&id), %str( ), %str(' '))));
        quit;
    %end;
    
    /* Perform comparison */
    proc compare base=&base compare=&compare
                 criterion=&tolerance
                 out=comparison_results
                 outbase outcompare outdiff noprint;
        id &id;
        var &vars;
    run;
    
    /* Analyze results */
    data comparison_summary;
        set comparison_results;
        by &id;
        
        length difference_type $20 variable $32 issue $100;
        
        if _type_ = 'DIF' then do;
            difference_type = 'Value Difference';
            %do i = 1 %to %sysfunc(countw(&vars));
                %let var = %scan(&vars, &i);
                if &var ^= . then do;
                    variable = "&var";
                    issue = strip(put(&var, best12.));
                    output;
                end;
            %end;
        end;
        else if _type_ = 'BASE' then do;
            difference_type = 'In Base Only';
            variable = 'Record';
            issue = 'Record exists in base dataset only';
            output;
        end;
        else if _type_ = 'COMPARE' then do;
            difference_type = 'In Compare Only';
            variable = 'Record';
            issue = 'Record exists in compare dataset only';
            output;
        end;
    run;
    
    /* Report summary */
    title "Dataset Comparison Summary";
    title2 "Base: &base vs Compare: &compare";
    
    proc freq data=comparison_summary;
        tables difference_type / nocum nopercent;
    run;
    
    proc print data=comparison_summary;
        by difference_type;
        var &id variable issue;
    run;
    
    title;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete _base_vars _comp_vars;
    quit;
    
%mend compare_datasets;
```

## Statistical Analysis Macros

### Descriptive Statistics Macro

```sas
/******************************************************************************
MACRO: desc_stats
PURPOSE: Generate comprehensive descriptive statistics
PARAMETERS:
  data= : Input dataset
  var= : Analysis variable
  by= : Grouping variable(s)
  class= : Classification variables
  stats= : Statistics to calculate
  format= : Output format (TABLE/LISTING)
******************************************************************************/

%macro desc_stats(data=, var=, by=, class=, 
                  stats=N MEAN STD MIN Q1 MEDIAN Q3 MAX,
                  format=TABLE);
    
    /* Calculate descriptive statistics */
    proc means data=&data noprint;
        %if %length(&class) > 0 %then class &class;;
        %if %length(&by) > 0 %then by &by;;
        var &var;
        output out=_desc_stats
            n=n mean=mean std=std min=min
            q1=q1 median=median q3=q3 max=max;
    run;
    
    %if %upcase(&format) = TABLE %then %do;
        /* Create publication-ready table */
        data _formatted_stats;
            set _desc_stats;
            
            length statistic $50;
            
            %if %sysfunc(indexw(%upcase(&stats), N)) %then %do;
                statistic = 'N';
                value = put(n, 8.);
                output;
            %end;
            
            %if %sysfunc(indexw(%upcase(&stats), MEAN)) %then %do;
                statistic = 'Mean (SD)';
                value = strip(put(mean, 8.1)) || ' (' || strip(put(std, 8.2)) || ')';
                output;
            %end;
            
            %if %sysfunc(indexw(%upcase(&stats), MEDIAN)) %then %do;
                statistic = 'Median (Q1, Q3)';
                value = strip(put(median, 8.1)) || ' (' || 
                       strip(put(q1, 8.1)) || ', ' || strip(put(q3, 8.1)) || ')';
                output;
            %end;
            
            %if %sysfunc(indexw(%upcase(&stats), MIN)) %then %do;
                statistic = 'Min, Max';
                value = strip(put(min, 8.1)) || ', ' || strip(put(max, 8.1));
                output;
            %end;
            
            keep &class &by statistic value;
        run;
        
        proc print data=_formatted_stats noobs;
            %if %length(&class) > 0 %then by &class;;
            var statistic value;
        run;
    %end;
    %else %do;
        /* Standard listing format */
        proc print data=_desc_stats noobs;
            %if %length(&class) > 0 %then by &class;;
            var &by n mean std min q1 median q3 max;
            format mean std min q1 median q3 max 8.2;
        run;
    %end;
    
    proc datasets library=work nolist;
        delete _desc_stats _formatted_stats;
    quit;
    
%mend desc_stats;
```

### Survival Analysis Macro

```sas
/******************************************************************************
MACRO: survival_analysis
PURPOSE: Comprehensive survival analysis with KM and Cox models
PARAMETERS:
  data= : Input dataset
  time= : Time-to-event variable
  censor= : Censoring indicator (1=event, 0=censored)
  strata= : Stratification variable
  covars= : Covariates for Cox model
  alpha= : Significance level (default: 0.05)
******************************************************************************/

%macro survival_analysis(data=, time=, censor=, strata=, covars=, alpha=0.05);
    
    /* Kaplan-Meier Analysis */
    ods output ProductLimitEstimates=_km_est
               Quartiles=_km_quartiles
               HomTests=_logrank_test;
    
    proc lifetest data=&data plots=survival(atrisk);
        time &time*&censor(0);
        %if %length(&strata) > 0 %then %do;
            strata &strata / test=logrank;
        %end;
        title "Kaplan-Meier Survival Analysis";
    run;
    
    /* Cox Proportional Hazards Model */
    %if %length(&strata) > 0 or %length(&covars) > 0 %then %do;
        
        ods output ParameterEstimates=_cox_parms
                   HazardRatios=_hazard_ratios;
        
        proc phreg data=&data;
            model &time*&censor(0) = &strata &covars / rl;
            
            %if %length(&strata) > 0 %then %do;
                hazardratio "&strata Effect" &strata;
            %end;
            
            title "Cox Proportional Hazards Analysis";
        run;
        
        /* Test proportional hazards assumption */
        ods output ResampPHTest=_ph_test;
        
        proc phreg data=&data;
            model &time*&censor(0) = &strata &covars;
            assess ph / resample;
            title "Proportional Hazards Assumption Test";
        run;
    %end;
    
    /* Create summary report */
    data survival_summary;
        length analysis $50 result $100;
        
        /* Sample size */
        analysis = 'Total Sample Size';
        set &data end=last;
        if last then do;
            result = put(_n_, 8.);
            output;
        end;
        
        /* Event rate */
        retain events 0;
        if &censor = 1 then events + 1;
        if last then do;
            analysis = 'Total Events';
            result = put(events, 8.) || ' (' || 
                    put(events/_n_*100, 5.1) || '%)';
            output;
        end;
    run;
    
    /* Add median survival times */
    %if %sysfunc(exist(_km_quartiles)) %then %do;
        data _median_survival;
            set _km_quartiles;
            where percent = 50;
            
            length analysis $50 result $100;
            analysis = 'Median Survival';
            if estimate ^= . then
                result = put(estimate, 8.1) || ' (' ||
                        put(lowerCL, 8.1) || ', ' ||
                        put(upperCL, 8.1) || ')';
            else
                result = 'Not Reached';
        run;
        
        proc append base=survival_summary data=_median_survival;
        run;
    %end;
    
    title "Survival Analysis Summary";
    proc print data=survival_summary noobs;
        var analysis result;
    run;
    title;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete _km_est _km_quartiles _logrank_test
               _cox_parms _hazard_ratios _ph_test
               _median_survival;
    quit;
    
%mend survival_analysis;
```

## Utility Macros

### Variable Existence Check

```sas
%macro varexist(data, var);
    %local dsid rc result;
    %let dsid = %sysfunc(open(&data));
    %if &dsid %then %do;
        %let result = %sysfunc(varnum(&dsid, &var));
        %let rc = %sysfunc(close(&dsid));
        %if &result %then 1;
        %else 0;
    %end;
    %else 0;
%mend varexist;
```

### Dataset Existence Check

```sas
%macro dataexist(data);
    %if %sysfunc(exist(&data)) %then 1;
    %else 0;
%mend dataexist;
```

### Create Formatted Date

```sas
%macro today(format=DATE9.);
    %sysfunc(today(), &format)
%mend today;
```

### Log Message with Timestamp

```sas
%macro log_msg(msg, type=INFO);
    %put %sysfunc(datetime(), datetime19.) [&type] &msg;
%mend log_msg;
```

### Get Dataset Observations Count

```sas
%macro nobs(data);
    %local dsid nobs rc;
    %let dsid = %sysfunc(open(&data));
    %if &dsid %then %do;
        %let nobs = %sysfunc(attrn(&dsid, nobs));
        %let rc = %sysfunc(close(&dsid));
        &nobs
    %end;
    %else 0;
%mend nobs;
```

## Advanced Macros

### Dynamic Macro Variable Creation

```sas
/******************************************************************************
MACRO: create_macro_vars
PURPOSE: Create macro variables from dataset values
PARAMETERS:
  data= : Input dataset
  var= : Variable containing values
  prefix= : Prefix for macro variable names
  suffix= : Suffix for macro variable names
******************************************************************************/

%macro create_macro_vars(data=, var=, prefix=, suffix=);
    
    proc sql noprint;
        select count(*) into :num_vars
        from &data;
        
        select &var into :&prefix.1-:&prefix.&num_vars
        from &data;
    quit;
    
    %global &prefix.count;
    %let &prefix.count = &num_vars;
    
    %put INFO: Created &num_vars macro variables with prefix &prefix;
    
%mend create_macro_vars;
```

### Conditional Processing Macro

```sas
/******************************************************************************
MACRO: conditional_proc
PURPOSE: Execute procedure only if condition is met
PARAMETERS:
  condition= : Condition to evaluate
  proc_code= : SAS procedure code to execute
******************************************************************************/

%macro conditional_proc(condition=, proc_code=);
    
    %if &condition %then %do;
        %log_msg(Executing conditional procedure);
        &proc_code;
    %end;
    %else %do;
        %log_msg(Condition not met - skipping procedure, type=WARNING);
    %end;
    
%mend conditional_proc;
```

### Batch Processing Macro

```sas
/******************************************************************************
MACRO: batch_process
PURPOSE: Process multiple datasets with same operations
PARAMETERS:
  datasets= : Space-separated list of datasets
  operations= : Macro to apply to each dataset
******************************************************************************/

%macro batch_process(datasets=, operations=);
    
    %local i dataset;
    %let i = 1;
    %let dataset = %scan(&datasets, &i);
    
    %do %while(&dataset ne );
        %log_msg(Processing dataset: &dataset);
        
        %&operations(data=&dataset);
        
        %let i = %eval(&i + 1);
        %let dataset = %scan(&datasets, &i);
    %end;
    
    %log_msg(Batch processing completed);
    
%mend batch_process;
```

## Macro Library Management

### Auto-loading Macro Setup

```sas
/******************************************************************************
Setup for automatic macro loading
Place this code at the beginning of your main program
******************************************************************************/

/* Define macro library location */
%let MACRO_LIB = /path/to/your/macro/library;

/* Create filename for macro library */
filename macros "&MACRO_LIB";

/* Auto-compile all macros in library */
%macro load_macro_library(path=&MACRO_LIB);
    
    %local filrf rc did memname i;
    
    /* Assign fileref to directory */
    %let filrf = maclib;
    %let rc = %sysfunc(filename(filrf, &path));
    
    /* Open directory */
    %let did = %sysfunc(dopen(&filrf));
    
    /* Process each .sas file */
    %if &did ne 0 %then %do;
        %do i = 1 %to %sysfunc(dnum(&did));
            %let memname = %sysfunc(dread(&did, &i));
            
            /* Only process .sas files */
            %if %scan(&memname, -1, .) = sas %then %do;
                %log_msg(Loading macro from: &memname);
                %include "&path/&memname";
            %end;
        %end;
    %end;
    %else %do;
        %log_msg(Could not open macro library directory: &path, type=ERROR);
    %end;
    
    /* Clean up */
    %let rc = %sysfunc(dclose(&did));
    %let rc = %sysfunc(filename(filrf));
    
%mend load_macro_library;

/* Load all macros */
%load_macro_library();
```

### Macro Documentation Template

```sas
/******************************************************************************
MACRO: [macro_name]
PURPOSE: [Brief description of what the macro does]
CREATED: [Date] by [Author]
MODIFIED: [Date] by [Author] - [Description of changes]

PARAMETERS:
  Required:
    param1= : [Description of required parameter]
    param2= : [Description of required parameter]
  
  Optional:
    param3= : [Description with default value]
    param4= : [Description with default value]

USAGE:
  %[macro_name](param1=value1, param2=value2);

EXAMPLE:
  %[macro_name](data=test, var=age, by=treatment);

NOTES:
  - [Any special considerations or limitations]
  - [Dependencies on other macros or datasets]
  - [Known issues or workarounds]

OUTPUT:
  - [Description of datasets created]
  - [Description of reports generated]
******************************************************************************/

%macro [macro_name](/* parameter definitions */);
    
    /* Macro code here */
    
%mend [macro_name];
```

---

*This macro library provides a foundation for clinical programming efficiency and consistency. Regular updates and customization based on specific organizational needs are recommended.*