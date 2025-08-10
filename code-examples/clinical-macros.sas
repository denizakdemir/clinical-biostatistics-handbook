/******************************************************************************
PROGRAM: clinical-macros.sas
PURPOSE: Essential SAS macros for clinical trial analysis
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This macro library contains essential macros for clinical trial statistical
analysis, following industry best practices and regulatory requirements.

MACROS INCLUDED:
- %setup_clinical_environment - Environment setup
- %check_data_integrity - Data integrity checks
- %create_analysis_population - Analysis population creation
- %generate_demographics - Demographics table generation
- %perform_efficacy_analysis - Primary/secondary efficacy analysis
- %generate_safety_summary - Safety analysis and summaries
- %create_survival_analysis - Time-to-event analysis
- %validate_analysis_dataset - Dataset validation
******************************************************************************/

/******************************************************************************
MACRO: setup_clinical_environment
PURPOSE: Set up standard clinical trial analysis environment
PARAMETERS:
  study_id= : Study identifier
  protocol= : Protocol number  
  data_cutoff= : Data cutoff date (DDMMMYYYY format)
  adam_path= : Path to ADaM datasets
  sdtm_path= : Path to SDTM datasets
  output_path= : Path for output files
******************************************************************************/
%macro setup_clinical_environment(
    study_id=,
    protocol=,
    data_cutoff=,
    adam_path=,
    sdtm_path=,
    output_path=
);
    
    %put NOTE: Setting up clinical trial environment for &study_id;
    
    /* Set global macro variables */
    %global g_study_id g_protocol g_data_cutoff g_sysdate g_systime;
    %let g_study_id = &study_id;
    %let g_protocol = &protocol;
    %let g_data_cutoff = &data_cutoff;
    %let g_sysdate = %sysfunc(today(), date9.);
    %let g_systime = %sysfunc(time(), time8.);
    
    /* Set standard SAS options */
    options nodate nonumber orientation=landscape
            leftmargin=0.5in rightmargin=0.5in
            topmargin=0.75in bottommargin=0.75in
            formchar="|----|+|---+=|-/\\<>*"
            missing=' ' fmterr
            mprint mlogic symbolgen;
    
    /* Define library references */
    %if %length(&adam_path) > 0 %then %do;
        libname adam "&adam_path";
        %put NOTE: ADaM library assigned to &adam_path;
    %end;
    
    %if %length(&sdtm_path) > 0 %then %do;
        libname sdtm "&sdtm_path";
        %put NOTE: SDTM library assigned to &sdtm_path;
    %end;
    
    %if %length(&output_path) > 0 %then %do;
        libname output "&output_path";
        %put NOTE: Output library assigned to &output_path;
    %end;
    
    /* Create output directories if they don't exist */
    %if %length(&output_path) > 0 %then %do;
        %let rc = %sysfunc(dcreate(tables, &output_path));
        %let rc = %sysfunc(dcreate(listings, &output_path));
        %let rc = %sysfunc(dcreate(figures, &output_path));
        %let rc = %sysfunc(dcreate(datasets, &output_path));
    %end;
    
    %put NOTE: Clinical environment setup completed for &study_id;
    
%mend setup_clinical_environment;

/******************************************************************************
MACRO: check_data_integrity
PURPOSE: Perform comprehensive data integrity checks
PARAMETERS:
  data= : Input dataset
  key_vars= : Key variables for uniqueness check
  required_vars= : Required variables
  date_vars= : Date variables to validate
  numeric_vars= : Numeric variables to check for outliers
******************************************************************************/
%macro check_data_integrity(
    data=,
    key_vars=,
    required_vars=,
    date_vars=,
    numeric_vars=
);
    
    %put NOTE: Performing data integrity checks on &data;
    
    /* Check if dataset exists */
    %if not %sysfunc(exist(&data)) %then %do;
        %put ERROR: Dataset &data does not exist;
        %return;
    %end;
    
    /* Get dataset information */
    proc sql noprint;
        select count(*) into :nobs
        from &data;
        
        select count(distinct cats(&key_vars)) into :unique_keys
        from &data;
    quit;
    
    %put NOTE: Dataset &data contains &nobs observations;
    
    /* Check for duplicate keys */
    %if &nobs ne &unique_keys %then %do;
        %put WARNING: Duplicate keys found in &data;
        %put WARNING: Total observations: &nobs, Unique keys: &unique_keys;
        
        /* Create duplicate report */
        proc freq data=&data;
            tables &key_vars / out=work.key_freq;
        run;
        
        data work.duplicates;
            set work.key_freq;
            where count > 1;
        run;
        
        %if %sysfunc(exist(work.duplicates)) %then %do;
            proc print data=work.duplicates;
                title "Duplicate Key Values in &data";
            run;
        %end;
    %end;
    
    /* Check required variables */
    %if %length(&required_vars) > 0 %then %do;
        %let var_count = %sysfunc(countw(&required_vars));
        %do i = 1 %to &var_count;
            %let var = %scan(&required_vars, &i);
            
            proc sql noprint;
                select count(*) into :missing_count
                from &data
                where missing(&var);
            quit;
            
            %if &missing_count > 0 %then %do;
                %put WARNING: Variable &var has &missing_count missing values;
            %end;
        %end;
    %end;
    
    /* Validate date variables */
    %if %length(&date_vars) > 0 %then %do;
        %let date_count = %sysfunc(countw(&date_vars));
        %do i = 1 %to &date_count;
            %let date_var = %scan(&date_vars, &i);
            
            proc means data=&data min max n nmiss;
                var &date_var;
                title "Date validation for &date_var in &data";
            run;
        %end;
    %end;
    
    /* Check numeric variables for outliers */
    %if %length(&numeric_vars) > 0 %then %do;
        proc means data=&data n mean std min max p1 p99;
            var &numeric_vars;
            title "Numeric variable summary for &data";
        run;
    %end;
    
    /* Clean up temporary datasets */
    proc datasets library=work nolist;
        delete key_freq duplicates;
    quit;
    
    %put NOTE: Data integrity check completed for &data;
    
%mend check_data_integrity;

/******************************************************************************
MACRO: create_analysis_population
PURPOSE: Create standardized analysis population flags
PARAMETERS:
  data= : Input dataset (usually ADSL)
  output= : Output dataset
  safety_criteria= : Criteria for safety population
  itt_criteria= : Criteria for ITT population
  pp_criteria= : Criteria for per-protocol population
******************************************************************************/
%macro create_analysis_population(
    data=,
    output=,
    safety_criteria=%str(not missing(trtsdt)),
    itt_criteria=%str(randfl='Y'),
    pp_criteria=%str(randfl='Y' and complfl='Y')
);
    
    %put NOTE: Creating analysis populations for &data;
    
    data &output;
        set &data;
        
        /* Safety population flag */
        length saffl $1;
        if (&safety_criteria) then saffl = 'Y';
        else saffl = 'N';
        
        /* Intent-to-treat population flag */
        length ittfl $1;
        if (&itt_criteria) then ittfl = 'Y';
        else ittfl = 'N';
        
        /* Per-protocol population flag */
        length pprotfl $1;
        if (&pp_criteria) then pprotfl = 'Y';
        else pprotfl = 'N';
        
        /* Efficacy population flag (usually same as ITT) */
        length efffl $1;
        efffl = ittfl;
        
        /* Labels */
        label saffl = "Safety Population Flag"
              ittfl = "Intent-To-Treat Population Flag"
              pprotfl = "Per-Protocol Population Flag"
              efffl = "Efficacy Population Flag";
    run;
    
    /* Population summary */
    proc freq data=&output;
        tables saffl ittfl pprotfl efffl / missing;
        title "Analysis Population Summary for &output";
    run;
    
    %put NOTE: Analysis populations created for &output;
    
%mend create_analysis_population;

/******************************************************************************
MACRO: generate_demographics
PURPOSE: Generate standard demographics table
PARAMETERS:
  data= : Input dataset (ADSL)
  population= : Population filter (default: saffl='Y')
  treatment_var= : Treatment variable (default: trt01p)
  output_file= : Output RTF file path
  age_var= : Age variable (default: age)
  sex_var= : Sex variable (default: sex)
  race_var= : Race variable (default: race)
******************************************************************************/
%macro generate_demographics(
    data=,
    population=%str(saffl='Y'),
    treatment_var=trt01p,
    output_file=,
    age_var=age,
    sex_var=sex,
    race_var=race
);
    
    %put NOTE: Generating demographics table;
    
    /* Filter population */
    data work.demo_pop;
        set &data;
        where &population;
    run;
    
    /* Get treatment levels */
    proc freq data=work.demo_pop noprint;
        tables &treatment_var / out=work.trt_levels;
    run;
    
    /* Age statistics */
    proc means data=work.demo_pop noprint;
        class &treatment_var;
        var &age_var;
        output out=work.age_stats 
            n=n mean=mean std=std median=median min=min max=max;
    run;
    
    /* Categorical variables */
    proc freq data=work.demo_pop noprint;
        tables &treatment_var * (&sex_var &race_var) / outpct out=work.cat_stats;
    run;
    
    /* Format results for display */
    data work.demo_summary;
        length characteristic $50 statistic $30;
        
        /* Age summary */
        set work.age_stats;
        where not missing(&treatment_var);
        
        characteristic = "Age (years)";
        statistic = "n";
        value = n;
        output;
        
        statistic = "Mean (SD)";
        value_char = cats(put(mean, 8.1), " (", put(std, 8.1), ")");
        output;
        
        statistic = "Median";
        value = median;
        output;
        
        statistic = "Min, Max";
        value_char = cats(put(min, 8.0), ", ", put(max, 8.0));
        output;
    run;
    
    /* Output table */
    %if %length(&output_file) > 0 %then %do;
        ods rtf file="&output_file";
        
        title1 "Table 14.1.1";
        title2 "Summary of Demographics and Baseline Characteristics";
        title3 "Safety Population";
        title4 "Protocol: &g_protocol";
        
        proc report data=work.demo_summary nowd;
            column characteristic statistic value value_char;
            define characteristic / group "Characteristic" width=25;
            define statistic / group "Statistic" width=20;
            define value / display "Value" format=8.1;
            define value_char / display "Value";
        run;
        
        ods rtf close;
        %put NOTE: Demographics table saved to &output_file;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete demo_pop trt_levels age_stats cat_stats demo_summary;
    quit;
    
%mend generate_demographics;

/******************************************************************************
MACRO: perform_efficacy_analysis
PURPOSE: Perform primary and secondary efficacy analyses
PARAMETERS:
  data= : Input dataset (BDS format)
  parameter= : Parameter code
  visit= : Analysis visit
  population= : Population filter
  treatment_var= : Treatment variable
  analysis_var= : Analysis variable (CHG, AVAL, etc.)
  baseline_var= : Baseline variable (if ANCOVA)
  method= : Analysis method (TTEST, ANCOVA, etc.)
******************************************************************************/
%macro perform_efficacy_analysis(
    data=,
    parameter=,
    visit=,
    population=%str(ittfl='Y'),
    treatment_var=trt01p,
    analysis_var=chg,
    baseline_var=base,
    method=ANCOVA
);
    
    %put NOTE: Performing efficacy analysis for &parameter;
    
    /* Filter data */
    data work.eff_data;
        set &data;
        where &population 
            and upcase(paramcd) = upcase("&parameter")
            and upcase(visit) = upcase("&visit")
            and not missing(&analysis_var);
    run;
    
    /* Check sample sizes */
    proc freq data=work.eff_data;
        tables &treatment_var / out=work.sample_sizes;
    run;
    
    proc print data=work.sample_sizes;
        title "Sample sizes for &parameter analysis";
    run;
    
    /* Descriptive statistics */
    proc means data=work.eff_data n mean std median min max;
        class &treatment_var;
        var &analysis_var;
        title "Descriptive statistics for &parameter (&analysis_var)";
    run;
    
    /* Statistical analysis based on method */
    %if %upcase(&method) = TTEST %then %do;
        proc ttest data=work.eff_data;
            class &treatment_var;
            var &analysis_var;
            title "T-test analysis for &parameter";
        run;
    %end;
    
    %else %if %upcase(&method) = ANCOVA %then %do;
        proc glm data=work.eff_data;
            class &treatment_var;
            model &analysis_var = &treatment_var &baseline_var;
            lsmeans &treatment_var / pdiff cl;
            title "ANCOVA analysis for &parameter";
        run;
        quit;
    %end;
    
    %else %if %upcase(&method) = NONPAR %then %do;
        proc npar1way data=work.eff_data wilcoxon;
            class &treatment_var;
            var &analysis_var;
            title "Non-parametric analysis for &parameter";
        run;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete eff_data sample_sizes;
    quit;
    
    %put NOTE: Efficacy analysis completed for &parameter;
    
%mend perform_efficacy_analysis;

/******************************************************************************
MACRO: generate_safety_summary
PURPOSE: Generate comprehensive safety summary tables
PARAMETERS:
  ae_data= : Adverse events dataset
  population= : Population filter
  treatment_var= : Treatment variable
  output_path= : Path for output files
******************************************************************************/
%macro generate_safety_summary(
    ae_data=,
    population=%str(saffl='Y'),
    treatment_var=trt01p,
    output_path=
);
    
    %put NOTE: Generating safety summary tables;
    
    /* Filter population */
    data work.safety_pop;
        set &ae_data;
        where &population;
    run;
    
    /* Overall AE summary */
    proc freq data=work.safety_pop;
        tables &treatment_var * (aoccfl aeser aesdth) / out=work.ae_overall outpct;
        title "Overall Adverse Event Summary";
    run;
    
    /* AE by System Organ Class */
    proc freq data=work.safety_pop;
        tables &treatment_var * aesoc / out=work.ae_soc outpct;
        title "Adverse Events by System Organ Class";
    run;
    
    /* AE by Preferred Term (most frequent) */
    proc freq data=work.safety_pop;
        tables aedecod / out=work.ae_freq;
    run;
    
    proc sort data=work.ae_freq;
        by descending count;
    run;
    
    data work.ae_freq_top;
        set work.ae_freq(obs=20);
    run;
    
    proc freq data=work.safety_pop;
        tables &treatment_var * aedecod / out=work.ae_pt outpct;
        where aedecod in (select aedecod from work.ae_freq_top);
        title "Most Frequent Adverse Events by Preferred Term";
    run;
    
    /* AE by severity */
    proc freq data=work.safety_pop;
        tables &treatment_var * aesev / out=work.ae_severity outpct;
        title "Adverse Events by Severity";
    run;
    
    /* Export tables if output path specified */
    %if %length(&output_path) > 0 %then %do;
        ods rtf file="&output_path/safety_summary.rtf";
        
        title1 "Safety Summary Tables";
        title2 "Protocol: &g_protocol";
        
        proc print data=work.ae_overall;
            title3 "Overall AE Summary";
        run;
        
        proc print data=work.ae_soc;
            title3 "AE by System Organ Class";
        run;
        
        ods rtf close;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete safety_pop ae_overall ae_soc ae_freq ae_freq_top ae_pt ae_severity;
    quit;
    
    %put NOTE: Safety summary generation completed;
    
%mend generate_safety_summary;

/******************************************************************************
MACRO: validate_analysis_dataset  
PURPOSE: Comprehensive validation of analysis datasets
PARAMETERS:
  data= : Dataset to validate
  type= : Dataset type (ADSL, ADAE, ADLB, etc.)
  key_vars= : Key variables for the dataset
******************************************************************************/
%macro validate_analysis_dataset(
    data=,
    type=,
    key_vars=usubjid
);
    
    %put NOTE: Validating analysis dataset &data (&type);
    
    /* Basic dataset checks */
    %check_data_integrity(
        data=&data,
        key_vars=&key_vars,
        required_vars=studyid usubjid
    );
    
    /* Type-specific validations */
    %if %upcase(&type) = ADSL %then %do;
        %put NOTE: Performing ADSL-specific validations;
        
        proc freq data=&data;
            tables saffl ittfl pprotfl / missing;
            title "Population Flags Validation - &data";
        run;
        
        proc means data=&data n nmiss min max;
            var randdt trtsdt trtedt;
            title "Key Dates Validation - &data";
        run;
    %end;
    
    %else %if %upcase(&type) = ADAE %then %do;
        %put NOTE: Performing ADAE-specific validations;
        
        proc freq data=&data;
            tables aeser aesev aerel / missing;
            title "AE Characteristics Validation - &data";
        run;
    %end;
    
    %else %if %upcase(&type) = ADLB %then %do;
        %put NOTE: Performing ADLB-specific validations;
        
        proc freq data=&data;
            tables paramcd / missing;
            title "Parameter Distribution - &data";
        run;
        
        proc means data=&data n nmiss;
            var aval base chg;
            title "Analysis Values Validation - &data";
        run;
    %end;
    
    %put NOTE: Dataset validation completed for &data;
    
%mend validate_analysis_dataset;

%put NOTE: Clinical macros library loaded successfully;
%put NOTE: Available macros: setup_clinical_environment, check_data_integrity, create_analysis_population,;
%put NOTE:                  generate_demographics, perform_efficacy_analysis, generate_safety_summary,;
%put NOTE:                  validate_analysis_dataset;