/******************************************************************************
PROGRAM: table-macro-template.sas
PURPOSE: Template for creating regulatory submission tables
AUTHOR: [Your Name]
DATE: [Creation Date]
VERSION: 1.0

STUDY: [Study ID]
PROTOCOL: [Protocol Number]

MODIFICATIONS:
Date        Author      Description
----------  ----------  --------------------------------------------------
[Date]      [Author]    Initial template creation

NOTES:
- This template follows ICH E3 table standards
- Customize table specifications for your study requirements
- Include appropriate statistical tests and formatting
- Ensure regulatory compliance for submission tables
******************************************************************************/

/* Set up environment */
options orientation=landscape papersize=letter 
        leftmargin=0.5in rightmargin=0.5in 
        topmargin=0.75in bottommargin=0.75in
        nodate nonumber 
        formchar="|----|+|---+=|-/\\<>*" 
        missing=' ';

/* Define global macro variables - CUSTOMIZE FOR YOUR STUDY */
%global study_title protocol_num analysis_cutoff table_footnote;
%let study_title = [STUDY TITLE];
%let protocol_num = [PROTOCOL NUMBER];
%let analysis_cutoff = [ANALYSIS CUTOFF DATE];
%let table_footnote = Generated on &sysdate9 at &systime using SAS &sysver;

/* Set up library references - CUSTOMIZE PATHS */
libname adam "[ADAM LIBRARY PATH]";
libname output "[OUTPUT PATH]";
libname formats "[FORMAT LIBRARY PATH]";

/* Load format library */
options fmtsearch=(formats.clinical_formats work library);

/******************************************************************************
UNIVERSAL TABLE HEADER MACRO
******************************************************************************/
%macro table_header(
    table_num=,         /* Table number (e.g., 14.1.1) */
    table_title=,       /* Main table title */
    population=,        /* Analysis population description */
    footnote_text=,     /* Additional footnote text */
    footnote2_text=,    /* Second footnote if needed */
    page_orientation=LANDSCAPE  /* PORTRAIT or LANDSCAPE */
);
    
    /* Clear existing titles and footnotes */
    title; footnote;
    
    /* Set page orientation */
    %if &page_orientation = PORTRAIT %then %do;
        options orientation=portrait;
    %end;
    %else %do;
        options orientation=landscape;
    %end;
    
    /* Set table titles */
    title1 justify=left "Table &table_num";
    title2 justify=left "&table_title";
    
    %if %length(&population) > 0 %then %do;
        title3 justify=left "&population";
    %end;
    
    title4 justify=left "Protocol: &protocol_num";
    title5 justify=left "Analysis Cutoff: &analysis_cutoff";
    
    /* Set standard footnotes */
    footnote1 justify=left "&table_footnote";
    
    %if %length(&footnote_text) > 0 %then %do;
        footnote2 justify=left "&footnote_text";
    %end;
    
    %if %length(&footnote2_text) > 0 %then %do;
        footnote3 justify=left "&footnote2_text";
    %end;
    
%mend table_header;

/******************************************************************************
DEMOGRAPHICS TABLE MACRO
******************************************************************************/
%macro demo_table(
    data=adam.adsl,         /* Input dataset */
    output_file=,           /* Output file name */
    population=SAFFL='Y',   /* Population filter */
    treatment_var=TRT01P,   /* Treatment variable */
    output_type=RTF,        /* RTF, PDF, or EXCEL */
    debug=N                 /* Debug mode */
);
    
    %put NOTE: Creating demographics table;
    %put NOTE: Input data: &data;
    %put NOTE: Population: &population;
    
    /* Filter population */
    data work.demo_pop;
        set &data;
        where &population;
    run;
    
    /* Calculate treatment group counts */
    proc freq data=work.demo_pop noprint;
        tables &treatment_var / out=work.trt_counts;
    run;
    
    /* Age statistics */
    proc means data=work.demo_pop noprint;
        class &treatment_var;
        var age;
        output out=work.age_stats 
            n=age_n mean=age_mean std=age_std 
            median=age_median min=age_min max=age_max;
    run;
    
    /* Categorical demographics */
    proc freq data=work.demo_pop noprint;
        tables &treatment_var * (sex race ethnic agegr1) / outpct out=work.demo_freq;
    run;
    
    /* Format results for table output */
    data work.demo_summary;
        length characteristic $50 
               col1 $25 col2 $25 col3 $25 total_col $25;
        
        /* Age summary statistics */
        set work.age_stats;
        where not missing(&treatment_var);
        
        characteristic = "Age (years)";
        
        if &treatment_var = "Placebo" then do;
            col1 = cats("n=", age_n);
            col1 = cats(col1, ", Mean=", put(age_mean, 5.1));
            col1 = cats(col1, ", SD=", put(age_std, 5.1));
        end;
        
        /* Add more treatment groups as needed */
        
        output;
        
        /* Age categories */
        /* Add age group summaries from demo_freq */
        
    run;
    
    /* Set up ODS output */
    %if &output_type = RTF %then %do;
        ods rtf file="&output_file..rtf" style=styles.rtf;
    %end;
    %else %if &output_type = PDF %then %do;
        ods pdf file="&output_file..pdf";
    %end;
    %else %if &output_type = EXCEL %then %do;
        ods excel file="&output_file..xlsx";
    %end;
    
    /* Generate table header */
    %table_header(
        table_num=14.1.1,
        table_title=Demographic and Baseline Characteristics,
        population=Safety Population,
        footnote_text=Age presented as mean (SD) unless otherwise specified
    );
    
    /* Output formatted table */
    proc report data=work.demo_summary nowd headline;
        column characteristic col1 col2 col3 total_col;
        
        define characteristic / display "Characteristic" width=30 
                                style(column)=[just=left];
        define col1 / display "Placebo~(N=XXX)" width=15 
                     style(column)=[just=center];
        define col2 / display "Treatment 1~(N=XXX)" width=15 
                     style(column)=[just=center];
        define col3 / display "Treatment 2~(N=XXX)" width=15 
                     style(column)=[just=center];
        define total_col / display "Total~(N=XXX)" width=15 
                          style(column)=[just=center];
    run;
    
    /* Close ODS */
    %if &output_type = RTF %then %do;
        ods rtf close;
    %end;
    %else %if &output_type = PDF %then %do;
        ods pdf close;
    %end;
    %else %if &output_type = EXCEL %then %do;
        ods excel close;
    %end;
    
    /* Debug output */
    %if &debug = Y %then %do;
        proc print data=work.demo_summary;
            title "Debug: Demographics Summary Data";
        run;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete demo_pop trt_counts age_stats demo_freq demo_summary;
    quit;
    
    %put NOTE: Demographics table completed: &output_file;
    
%mend demo_table;

/******************************************************************************
EFFICACY SUMMARY TABLE MACRO
******************************************************************************/
%macro efficacy_table(
    data=,                  /* Input dataset (ADaM BDS format) */
    output_file=,          /* Output file name */
    parameter=,            /* Parameter code (PARAMCD) */
    visit=,                /* Analysis visit */
    population=ITTFL='Y',  /* Population filter */
    treatment_var=TRT01P,  /* Treatment variable */
    analysis_var=CHG,      /* Analysis variable (CHG, AVAL, etc.) */
    output_type=RTF,       /* Output type */
    include_pvalue=Y,      /* Include p-value */
    debug=N
);
    
    %put NOTE: Creating efficacy table for parameter &parameter;
    
    /* Filter data */
    data work.efficacy_pop;
        set &data;
        where &population and upcase(paramcd) = upcase("&parameter");
        %if %length(&visit) > 0 %then %do;
            where also upcase(visit) = upcase("&visit");
        %end;
    run;
    
    /* Calculate descriptive statistics by treatment */
    proc means data=work.efficacy_pop noprint;
        class &treatment_var;
        var &analysis_var;
        output out=work.efficacy_stats 
            n=n mean=mean std=std median=median min=min max=max;
    run;
    
    /* Perform statistical test if requested */
    %if &include_pvalue = Y %then %do;
        proc ttest data=work.efficacy_pop;
            class &treatment_var;
            var &analysis_var;
            ods output TTests=work.ttest_results;
        run;
    %end;
    
    /* Format results */
    data work.efficacy_summary;
        set work.efficacy_stats;
        where not missing(&treatment_var);
        
        length statistic $30 value_formatted $20;
        
        statistic = "n";
        value_formatted = put(n, best8.);
        output;
        
        statistic = "Mean (SD)";
        value_formatted = cats(put(mean, 8.2), " (", put(std, 8.2), ")");
        output;
        
        statistic = "Median";
        value_formatted = put(median, 8.2);
        output;
        
        statistic = "Min, Max";
        value_formatted = cats(put(min, 8.2), ", ", put(max, 8.2));
        output;
    run;
    
    /* Set up output and generate table */
    %if &output_type = RTF %then %do;
        ods rtf file="&output_file..rtf";
    %end;
    
    %table_header(
        table_num=11.X.X,
        table_title=Summary of &parameter by Treatment Group,
        population=Intent-to-Treat Population,
        footnote_text=Statistical test: t-test (if applicable)
    );
    
    /* Create the report */
    proc report data=work.efficacy_summary nowd;
        column statistic (&treatment_var, value_formatted);
        define statistic / group "Statistic" width=20;
        define value_formatted / display "Value" width=15;
        
        /* Add treatment group columns dynamically */
    run;
    
    %if &output_type = RTF %then %do;
        ods rtf close;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete efficacy_pop efficacy_stats efficacy_summary;
        %if &include_pvalue = Y %then %do;
            delete ttest_results;
        %end;
    quit;
    
%mend efficacy_table;

/******************************************************************************
SAFETY SUMMARY TABLE MACRO
******************************************************************************/
%macro safety_table(
    data=adam.adae,         /* Input dataset */
    output_file=,          /* Output file name */
    population=SAFFL='Y',  /* Population filter */
    treatment_var=TRT01P,  /* Treatment variable */
    severity_var=AESEV,    /* Severity variable */
    output_type=RTF,
    debug=N
);
    
    %put NOTE: Creating safety summary table;
    
    /* Filter population */
    data work.safety_pop;
        set &data;
        where &population;
    run;
    
    /* Overall AE summary */
    proc freq data=work.safety_pop noprint;
        tables &treatment_var * (aoccfl aoccsfl aeser aesdth) / out=work.ae_summary outpct;
    run;
    
    /* AE by severity */
    proc freq data=work.safety_pop noprint;
        tables &treatment_var * &severity_var / out=work.ae_severity outpct;
    run;
    
    /* Format for output */
    /* Add formatting logic here */
    
    /* Generate table */
    %if &output_type = RTF %then %do;
        ods rtf file="&output_file..rtf";
    %end;
    
    %table_header(
        table_num=12.X.X,
        table_title=Summary of Adverse Events,
        population=Safety Population
    );
    
    /* Add report generation code */
    
    %if &output_type = RTF %then %do;
        ods rtf close;
    %end;
    
%mend safety_table;

/******************************************************************************
EXAMPLE USAGE - CUSTOMIZE FOR YOUR STUDY
******************************************************************************/

/*
%demo_table(
    data=adam.adsl,
    output_file=output/table_14_1_1_demographics,
    population=SAFFL='Y',
    treatment_var=TRT01P,
    output_type=RTF,
    debug=Y
);

%efficacy_table(
    data=adam.adlb,
    output_file=output/table_11_1_1_efficacy,
    parameter=CHOL,
    visit=WEEK 12,
    population=ITTFL='Y',
    treatment_var=TRT01P,
    analysis_var=CHG,
    output_type=RTF,
    include_pvalue=Y
);
*/

/******************************************************************************
QUALITY CONTROL CHECKLIST:

□ All macro parameters customized for study
□ Population filters verified against SAP
□ Treatment variables and labels confirmed
□ Statistical methods match SAP requirements
□ Output formatting meets submission standards
□ Table headers and footnotes complete
□ Debug mode tested with sample data
□ Independent review completed
□ Output files generated successfully
□ File naming convention followed
******************************************************************************/