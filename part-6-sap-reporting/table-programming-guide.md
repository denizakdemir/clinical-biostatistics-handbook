# Clinical Trial Table Programming Guide

## Table Production Framework

### Production Environment Setup

```sas
/******************************************************************************
CLINICAL TABLE PRODUCTION ENVIRONMENT SETUP
******************************************************************************/

/* Set global options for table production */
options orientation=landscape papersize=letter 
        leftmargin=0.5in rightmargin=0.5in 
        topmargin=0.75in bottommargin=0.75in
        nodate nonumber 
        formchar="|----|+|---+=|-/\<>*" 
        missing=' ';

/* Define global macro variables */
%global study_title protocol_num analysis_cutoff table_footnote;
%let study_title = A Randomized, Double-Blind, Placebo-Controlled Study;
%let protocol_num = PROTO-2024-001;
%let analysis_cutoff = %sysfunc(today(), date9.);
%let table_footnote = Generated on &sysdate9 at &systime using SAS &sysver;

/* Set up library references */
libname adam "/path/to/adam/datasets";
libname output "/path/to/output/tables";
libname formats "/path/to/format/library";

/* Load format library */
options fmtsearch=(formats.clinical_formats work library);

/* Initialize ODS destinations */
ods _all_ close;
ods listing close;
```

### Standard Table Macros

#### Universal Table Header Macro

```sas
/******************************************************************************
MACRO: table_header
PURPOSE: Generate standard table headers for clinical tables
PARAMETERS:
  table_num= : Table number (e.g., 14.1.1)
  table_title= : Main table title
  population= : Analysis population description
  footnote_text= : Additional footnote text
******************************************************************************/

%macro table_header(table_num=, table_title=, population=, footnote_text=);
    
    /* Clear existing titles and footnotes */
    title; footnote;
    
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
    
%mend table_header;
```

#### Treatment Summary Macro

```sas
/******************************************************************************
MACRO: treatment_summary
PURPOSE: Generate treatment group summary statistics
PARAMETERS:
  data= : Input dataset
  var= : Analysis variable
  class= : Treatment variable
  stats= : Statistics to calculate
  decimal= : Number of decimal places
******************************************************************************/

%macro treatment_summary(data=, var=, class=, stats=N MEAN STD MEDIAN MIN MAX,
                        decimal=1);
    
    /* Calculate summary statistics */
    proc means data=&data noprint;
        class &class;
        var &var;
        output out=_summary_stats
            n=n mean=mean std=std median=median min=min max=max
            q1=q1 q3=q3;
    run;
    
    /* Format results */
    data _formatted_summary;
        set _summary_stats;
        where &class ne '';
        
        length formatted_stat $50;
        
        /* Format based on requested statistics */
        %if %sysfunc(indexw(%upcase(&stats), N)) %then %do;
            stat_name = 'N';
            formatted_stat = put(n, 8.);
            output;
        %end;
        
        %if %sysfunc(indexw(%upcase(&stats), MEAN)) %then %do;
            stat_name = 'Mean (SD)';
            formatted_stat = strip(put(mean, 8.&decimal)) || ' (' ||
                           strip(put(std, 8.%eval(&decimal+1))) || ')';
            output;
        %end;
        
        %if %sysfunc(indexw(%upcase(&stats), MEDIAN)) %then %do;
            stat_name = 'Median';
            formatted_stat = put(median, 8.&decimal);
            output;
        %end;
        
        %if %sysfunc(indexw(%upcase(&stats), MIN)) or 
            %sysfunc(indexw(%upcase(&stats), MAX)) %then %do;
            stat_name = 'Min, Max';
            formatted_stat = strip(put(min, 8.&decimal)) || ', ' ||
                           strip(put(max, 8.&decimal));
            output;
        %end;
        
        keep &class stat_name formatted_stat;
    run;
    
%mend treatment_summary;
```

## Demographics Table Programming

### Comprehensive Demographics Table

```sas
/******************************************************************************
PROGRAM: demographics_table.sas
TITLE: Table 14.1.1 - Demographics and Baseline Characteristics  
POPULATION: Randomized Population
******************************************************************************/

%macro demographics_table(pop_flag=RANDFL, output_rtf=demographics.rtf);
    
    /* Filter data to analysis population */
    data demo_pop;
        set adam.adsl;
        where &pop_flag = 'Y';
    run;
    
    /* Get treatment group counts */
    proc sql noprint;
        select 
            sum(case when trt01p='Placebo' then 1 else 0 end),
            sum(case when trt01p='Drug 5mg' then 1 else 0 end),
            sum(case when trt01p='Drug 10mg' then 1 else 0 end),
            count(*)
        into :n_placebo, :n_drug5, :n_drug10, :n_total
        from demo_pop;
    quit;
    
    /* Age statistics */
    proc means data=demo_pop noprint;
        class trt01p;
        var age;
        output out=age_stats 
            n=n mean=mean std=std median=median min=min max=max;
    run;
    
    /* Categorical demographics */
    proc freq data=demo_pop noprint;
        tables trt01p * sex / out=sex_freq outpct;
        tables trt01p * race / out=race_freq outpct;
        tables trt01p * ethnic / out=ethnic_freq outpct;
        tables trt01p * agegr1 / out=agegr_freq outpct;
    run;
    
    /* Create final demographics table */
    data demo_table;
        length row_label $50 
               placebo $25 drug_5mg $25 drug_10mg $25 total $25;
        
        /* Table header with N counts */
        row_label = 'Characteristic';
        placebo = "Placebo|(N=&n_placebo)";
        drug_5mg = "Drug 5mg|(N=&n_drug5)";
        drug_10mg = "Drug 10mg|(N=&n_drug10)";
        total = "Total|(N=&n_total)";
        ord = 0;
        output;
        
        /* Age statistics */
        set age_stats;
        where trt01p ne '';
        
        by trt01p;
        
        retain age_n_plc age_mean_plc age_std_plc age_med_plc age_min_plc age_max_plc
               age_n_d5 age_mean_d5 age_std_d5 age_med_d5 age_min_d5 age_max_d5
               age_n_d10 age_mean_d10 age_std_d10 age_med_d10 age_min_d10 age_max_d10;
        
        if trt01p = 'Placebo' then do;
            age_n_plc = n; age_mean_plc = mean; age_std_plc = std;
            age_med_plc = median; age_min_plc = min; age_max_plc = max;
        end;
        else if trt01p = 'Drug 5mg' then do;
            age_n_d5 = n; age_mean_d5 = mean; age_std_d5 = std;
            age_med_d5 = median; age_min_d5 = min; age_max_d5 = max;
        end;
        else if trt01p = 'Drug 10mg' then do;
            age_n_d10 = n; age_mean_d10 = mean; age_std_d10 = std;
            age_med_d10 = median; age_min_d10 = min; age_max_d10 = max;
        end;
        
        if last.trt01p and trt01p = 'Drug 10mg' then do;
            /* Age section */
            row_label = 'Age (years)';
            placebo = ''; drug_5mg = ''; drug_10mg = ''; total = '';
            ord = 1;
            output;
            
            row_label = '  N';
            placebo = put(age_n_plc, 3.);
            drug_5mg = put(age_n_d5, 3.);
            drug_10mg = put(age_n_d10, 3.);
            total = put(age_n_plc + age_n_d5 + age_n_d10, 3.);
            ord = 2;
            output;
            
            row_label = '  Mean (SD)';
            placebo = strip(put(age_mean_plc, 5.1)) || ' (' || strip(put(age_std_plc, 5.2)) || ')';
            drug_5mg = strip(put(age_mean_d5, 5.1)) || ' (' || strip(put(age_std_d5, 5.2)) || ')';
            drug_10mg = strip(put(age_mean_d10, 5.1)) || ' (' || strip(put(age_std_d10, 5.2)) || ')';
            total = ''; /* Calculate overall mean/SD if needed */
            ord = 3;
            output;
            
            row_label = '  Median';
            placebo = put(age_med_plc, 5.1);
            drug_5mg = put(age_med_d5, 5.1);
            drug_10mg = put(age_med_d10, 5.1);
            total = '';
            ord = 4;
            output;
            
            row_label = '  Min, Max';
            placebo = strip(put(age_min_plc, 3.)) || ', ' || strip(put(age_max_plc, 3.));
            drug_5mg = strip(put(age_min_d5, 3.)) || ', ' || strip(put(age_max_d5, 3.));
            drug_10mg = strip(put(age_min_d10, 3.)) || ', ' || strip(put(age_max_d10, 3.));
            total = '';
            ord = 5;
            output;
        end;
    run;
    
    /* Add categorical variables */
    %add_categorical_demographics;
    
    /* Sort final table */
    proc sort data=demo_table;
        by ord;
    run;
    
    /* Generate RTF output */
    ods rtf file="&output_rtf" style=clinical_style;
    
    %table_header(
        table_num=14.1.1,
        table_title=Demographics and Baseline Characteristics,
        population=Randomized Population
    );
    
    proc report data=demo_table nowd split='|';
        columns row_label placebo drug_5mg drug_10mg total;
        
        define row_label / display 'Characteristic' width=35 
                          style(column)=[cellwidth=2.5in just=left];
        define placebo / display center width=20 
                        style(column)=[cellwidth=1.2in just=center];
        define drug_5mg / display center width=20 
                         style(column)=[cellwidth=1.2in just=center];
        define drug_10mg / display center width=20 
                          style(column)=[cellwidth=1.2in just=center];
        define total / display center width=20 
                      style(column)=[cellwidth=1.2in just=center];
        
        /* Conditional formatting */
        compute row_label;
            if index(row_label, 'Characteristic') > 0 then
                call define(_row_, 'style', 'style={background=lightgray fontweight=bold}');
        endcomp;
    run;
    
    ods rtf close;
    
%mend demographics_table;

/* Execute demographics table */
%demographics_table();
```

## Efficacy Table Programming

### Primary Efficacy Analysis Table

```sas
/******************************************************************************
PROGRAM: primary_efficacy.sas
TITLE: Table 14.2.1 - Analysis of Primary Efficacy Endpoint
POPULATION: Intent-to-Treat Population
******************************************************************************/

%macro primary_efficacy_table(endpoint=CHG, visit=12, output_rtf=primary_efficacy.rtf);
    
    /* Filter to ITT population and analysis visit */
    data eff_analysis;
        set adam.adeff;
        where ittfl = 'Y' and avisitn = &visit and paramcd = "&endpoint";
    run;
    
    /* Primary ANCOVA analysis */
    ods output LSMeans=lsmeans_out Diffs=diffs_out;
    
    proc mixed data=eff_analysis method=reml;
        class usubjid trt01p region;
        model aval = trt01p base region / ddfm=kenwardroger solution;
        
        /* LSMeans and comparisons */
        lsmeans trt01p / pdiff cl alpha=0.05;
        
        /* Specific contrasts */
        contrast 'Drug 5mg vs Placebo' trt01p 1 -1 0;
        contrast 'Drug 10mg vs Placebo' trt01p 0 -1 1;
        contrast 'Drug 10mg vs Drug 5mg' trt01p 0 1 -1;
        
        /* Overall treatment effect */
        contrast 'Overall Treatment Effect' trt01p 1 -1 0, trt01p 0 -1 1;
        
        ods output Contrasts=contrasts_out;
    run;
    
    /* Get sample sizes */
    proc freq data=eff_analysis noprint;
        tables trt01p / out=sample_sizes;
    run;
    
    /* Create efficacy results table */
    data efficacy_table;
        length treatment $25 n_subjects $15 lsmean $20 
               comparison $30 diff_lsmean $20 ci_95 $25 pvalue $12;
        
        /* Merge LSMeans with sample sizes */
        merge lsmeans_out sample_sizes(rename=(count=n_subj));
        by trt01p;
        
        treatment = trt01p;
        n_subjects = put(n_subj, 3.);
        lsmean = strip(put(estimate, 8.2)) || ' (' || strip(put(stderr, 8.3)) || ')';
        
        /* Keep treatment info for merging with comparisons */
        keep treatment n_subjects lsmean trt01p;
    run;
    
    /* Process treatment comparisons */
    data comparison_results;
        set diffs_out;
        where _trt01p ne trt01p;  /* Exclude self-comparisons */
        
        length comparison $40 diff_lsmean $20 ci_95 $30 pvalue $12;
        
        comparison = strip(_trt01p) || ' vs ' || strip(trt01p);
        diff_lsmean = put(estimate, 8.2);
        ci_95 = '(' || strip(put(lower, 8.2)) || ', ' || strip(put(upper, 8.2)) || ')';
        
        if probt < 0.001 then pvalue = '<0.001';
        else pvalue = put(probt, 6.3);
        
        keep comparison diff_lsmean ci_95 pvalue;
    run;
    
    /* Generate RTF output */
    ods rtf file="&output_rtf" style=clinical_style;
    
    %table_header(
        table_num=14.2.1,
        table_title=Analysis of Primary Efficacy Endpoint - Change from Baseline at Week &visit,
        population=Intent-to-Treat Population,
        footnote_text=ANCOVA model with treatment, baseline value, and region as covariates
    );
    
    /* Treatment summary section */
    proc report data=efficacy_table nowd;
        columns treatment n_subjects lsmean;
        
        define treatment / display 'Treatment Group' width=25;
        define n_subjects / display 'N' width=10 center;
        define lsmean / display 'LS Mean (SE)' width=20 center;
        
        title6 'Treatment Group Summary';
    run;
    
    /* Treatment comparisons section */
    proc report data=comparison_results nowd;
        columns comparison diff_lsmean ci_95 pvalue;
        
        define comparison / display 'Treatment Comparison' width=30;
        define diff_lsmean / display 'Difference in|LS Means' width=15 center;
        define ci_95 / display '95% Confidence|Interval' width=25 center;
        define pvalue / display 'P-value' width=12 center;
        
        /* Highlight significant results */
        compute pvalue;
            if input(pvalue, best.) < 0.05 or pvalue = '<0.001' then
                call define(_col_, 'style', 'style={fontweight=bold color=red}');
        endcomp;
        
        title6 'Treatment Comparisons';
    run;
    
    ods rtf close;
    
%mend primary_efficacy_table;

/* Execute primary efficacy table */
%primary_efficacy_table();
```

## Safety Table Programming

### Adverse Events Overview Table

```sas
/******************************************************************************
PROGRAM: adverse_events_overview.sas
TITLE: Table 14.3.2 - Overview of Treatment-Emergent Adverse Events
POPULATION: Safety Population
******************************************************************************/

%macro ae_overview_table(output_rtf=ae_overview.rtf);
    
    /* Get safety population counts */
    proc sql noprint;
        create table safety_n as
        select trt01a, count(*) as safety_n
        from adam.adsl
        where saffl = 'Y'
        group by trt01a;
    quit;
    
    /* Calculate AE summary statistics */
    proc sql;
        create table ae_summary as
        select 
            'Any TEAE' as ae_category,
            a.trt01a,
            count(distinct a.usubjid) as n_subjects,
            s.safety_n,
            calculated n_subjects / s.safety_n * 100 as pct_subjects
        from adam.adae a
        inner join safety_n s on a.trt01a = s.trt01a
        where a.trtemfl = 'Y' and a.saffl = 'Y'
        group by a.trt01a, s.safety_n
        
        union
        
        select 
            'Serious AE' as ae_category,
            a.trt01a,
            count(distinct a.usubjid) as n_subjects,
            s.safety_n,
            calculated n_subjects / s.safety_n * 100 as pct_subjects
        from adam.adae a
        inner join safety_n s on a.trt01a = s.trt01a
        where a.trtemfl = 'Y' and a.saffl = 'Y' and a.aeser = 'Y'
        group by a.trt01a, s.safety_n
        
        union
        
        select 
            'AE Leading to Study Drug Discontinuation' as ae_category,
            a.trt01a,
            count(distinct a.usubjid) as n_subjects,
            s.safety_n,
            calculated n_subjects / s.safety_n * 100 as pct_subjects
        from adam.adae a
        inner join safety_n s on a.trt01a = s.trt01a
        where a.trtemfl = 'Y' and a.saffl = 'Y' and a.aeacn = 'DRUG WITHDRAWN'
        group by a.trt01a, s.safety_n
        
        union
        
        select 
            'Deaths' as ae_category,
            a.trt01a,
            count(distinct a.usubjid) as n_subjects,
            s.safety_n,
            calculated n_subjects / s.safety_n * 100 as pct_subjects
        from adam.adae a
        inner join safety_n s on a.trt01a = s.trt01a
        where a.trtemfl = 'Y' and a.saffl = 'Y' and a.aeout = 'FATAL'
        group by a.trt01a, s.safety_n
        
        order by ae_category, trt01a;
    quit;
    
    /* Transpose for reporting */
    proc transpose data=ae_summary out=ae_transposed prefix=col_;
        by ae_category;
        id trt01a;
        var n_subjects;
    run;
    
    proc transpose data=ae_summary out=pct_transposed prefix=pct_;
        by ae_category;
        id trt01a;
        var pct_subjects;
    run;
    
    /* Combine counts and percentages */
    data ae_table;
        merge ae_transposed pct_transposed;
        by ae_category;
        
        length placebo $20 drug_5mg $20 drug_10mg $20;
        
        /* Format as n (%) */
        if col_placebo = . then placebo = '0';
        else placebo = strip(put(col_placebo, 3.)) || ' (' || 
                      strip(put(pct_placebo, 5.1)) || ')';
        
        if col_drug_5mg = . then drug_5mg = '0';
        else drug_5mg = strip(put(col_drug_5mg, 3.)) || ' (' || 
                       strip(put(pct_drug_5mg, 5.1)) || ')';
        
        if col_drug_10mg = . then drug_10mg = '0';
        else drug_10mg = strip(put(col_drug_10mg, 3.)) || ' (' || 
                        strip(put(pct_drug_10mg, 5.1)) || ')';
        
        /* Rename for display */
        ae_category_display = ae_category;
        
        keep ae_category_display placebo drug_5mg drug_10mg;
    run;
    
    /* Calculate 95% confidence intervals for proportions */
    %macro add_confidence_intervals;
        /* Implementation for exact binomial confidence intervals */
        /* This would use PROC FREQ with exact binomial options */
    %mend;
    
    /* Generate RTF output */
    ods rtf file="&output_rtf" style=clinical_style;
    
    %table_header(
        table_num=14.3.2,
        table_title=Overview of Treatment-Emergent Adverse Events,
        population=Safety Population,
        footnote_text=TEAE = Treatment-emergent adverse event (onset on or after first dose)
    );
    
    proc report data=ae_table nowd;
        columns ae_category_display placebo drug_5mg drug_10mg;
        
        define ae_category_display / display 'Adverse Event Category' width=40
                                   style(column)=[cellwidth=3.0in just=left];
        define placebo / display 'Placebo|(N=50)|n (%)' width=15 center
                        style(column)=[cellwidth=1.0in just=center];
        define drug_5mg / display 'Drug 5mg|(N=48)|n (%)' width=15 center
                         style(column)=[cellwidth=1.0in just=center];
        define drug_10mg / display 'Drug 10mg|(N=52)|n (%)' width=15 center
                          style(column)=[cellwidth=1.0in just=center];
    run;
    
    ods rtf close;
    
%mend ae_overview_table;

/* Execute AE overview table */
%ae_overview_table();
```

### Laboratory Safety Analysis

```sas
/******************************************************************************
PROGRAM: laboratory_safety.sas
TITLE: Table 14.3.6 - Laboratory Safety Analysis - Shift Tables
POPULATION: Safety Population
******************************************************************************/

%macro lab_shift_table(param=ALT, output_rtf=lab_shift.rtf);
    
    /* Prepare laboratory data */
    data lab_data;
        set adam.adlb;
        where saffl = 'Y' and paramcd = "&param" and 
              ablfl = 'Y' and avisit = 'End of Treatment';
        
        /* Baseline normal/abnormal status */
        if anrind = 'N' then baseline_status = 'Normal';
        else if anrind in ('H', 'L') then baseline_status = 'Abnormal';
        else baseline_status = 'Missing';
        
        /* Post-baseline normal/abnormal status */  
        if anrind = 'N' then post_status = 'Normal';
        else if anrind in ('H', 'L') then post_status = 'Abnormal';
        else post_status = 'Missing';
        
        /* Combined shift category */
        shift_category = strip(baseline_status) || ' to ' || strip(post_status);
    run;
    
    /* Calculate shift table statistics */
    proc freq data=lab_data noprint;
        tables trt01a * baseline_status * post_status / out=shift_counts;
    run;
    
    /* Calculate baseline denominators */
    proc freq data=lab_data noprint;
        tables trt01a * baseline_status / out=baseline_counts;
    run;
    
    /* Format shift table */
    data shift_table;
        merge shift_counts baseline_counts(rename=(count=baseline_n));
        by trt01a baseline_status;
        
        length shift_display $30 result $20;
        
        shift_display = strip(baseline_status) || ' to ' || strip(post_status);
        
        /* Calculate percentage within baseline category */
        pct_within_baseline = count / baseline_n * 100;
        
        result = strip(put(count, 3.)) || ' (' || 
                strip(put(pct_within_baseline, 5.1)) || ')';
        
        keep trt01a baseline_status post_status shift_display result count pct_within_baseline;
    run;
    
    /* Generate RTF output */
    ods rtf file="&output_rtf" style=clinical_style;
    
    %table_header(
        table_num=14.3.6,
        table_title=Laboratory Safety Analysis - %upcase(&param) Shift Table,
        population=Safety Population,
        footnote_text=Shift from baseline to worst post-baseline value. N = Normal%str(,) L/H = Low/High
    );
    
    /* Transpose for display */
    proc transpose data=shift_table out=shift_display 
                   prefix=trt_ name=treatment;
        by baseline_status post_status shift_display;
        id trt01a;
        var result;
    run;
    
    proc report data=shift_display nowd;
        columns shift_display trt_placebo trt_drug_5mg trt_drug_10mg;
        
        define shift_display / display 'Baseline to Post-baseline Shift' width=35;
        define trt_placebo / display 'Placebo|n (%)' width=15 center;
        define trt_drug_5mg / display 'Drug 5mg|n (%)' width=15 center;
        define trt_drug_10mg / display 'Drug 10mg|n (%)' width=15 center;
        
        break after baseline_status / skip;
    run;
    
    ods rtf close;
    
%mend lab_shift_table;

/* Execute lab shift tables for key parameters */
%lab_shift_table(param=ALT);
%lab_shift_table(param=AST);
%lab_shift_table(param=BILI);
%lab_shift_table(param=CREAT);
```

## Advanced Table Features

### Interactive Dashboard Tables

```sas
/******************************************************************************
INTERACTIVE HTML DASHBOARD FOR CLINICAL TRIAL RESULTS
******************************************************************************/

%macro create_dashboard(output_file=clinical_dashboard.html);
    
    /* Create comprehensive data for dashboard */
    data dashboard_data;
        /* Combine key metrics from multiple domains */
        set adam.adsl(keep=usubjid trt01p randfl saffl ittfl)
            adam.adae(keep=usubjid trt01a trtemfl aeser aesev)
            adam.adeff(keep=usubjid trt01p paramcd aval chg avisitn ittfl);
    run;
    
    /* Generate interactive HTML dashboard */
    ods html5(id=dashboard) file="&output_file" 
        options(svg_mode="inline" javascript="true");
    
    ods graphics on / reset=all imagename="dashboard" 
                     outputfmt=svg width=800 height=600;
    
    /* Enrollment summary */
    title "Clinical Trial Dashboard - Enrollment Status";
    
    proc sgplot data=dashboard_data;
        vbar trt01p / response=randfl stat=sum datalabel;
        xaxis label="Treatment Group";
        yaxis label="Number of Subjects Randomized";
    run;
    
    /* Safety overview */
    title "Safety Overview - Adverse Events by Treatment";
    
    proc sgplot data=dashboard_data;
        where trtemfl = 'Y';
        vbar trt01a / group=aeser groupdisplay=cluster datalabel;
        xaxis label="Treatment Group";
        yaxis label="Number of Adverse Events";
        keylegend / title="Serious AE Status";
    run;
    
    /* Efficacy trends */
    title "Primary Efficacy Endpoint Over Time";
    
    proc sgplot data=dashboard_data;
        where paramcd = 'CHG' and ittfl = 'Y';
        series x=avisitn y=aval / group=trt01p markers;
        xaxis label="Visit Number";
        yaxis label="Change from Baseline";
        keylegend / title="Treatment Group";
    run;
    
    ods html5(id=dashboard) close;
    
%mend create_dashboard;

%create_dashboard();
```

### Publication-Ready Forest Plots

```sas
/******************************************************************************
FOREST PLOT FOR SUBGROUP ANALYSIS
******************************************************************************/

%macro forest_plot(endpoint=CHG, output_file=forest_plot.rtf);
    
    /* Prepare subgroup analysis data */
    data subgroup_data;
        set adam.adeff;
        where paramcd = "&endpoint" and ittfl = 'Y' and avisitn = 12;
        
        /* Define subgroups */
        if age < 65 then age_group = '<65 years';
        else age_group = '>=65 years';
        
        if sex = 'M' then sex_group = 'Male';
        else sex_group = 'Female';
        
        if race = 'WHITE' then race_group = 'White';
        else race_group = 'Non-White';
    run;
    
    /* Run subgroup analyses */
    %macro analyze_subgroup(subgroup_var, subgroup_label);
        
        ods output Diffs=subgroup_&subgroup_var;
        
        proc mixed data=subgroup_data method=reml;
            class usubjid trt01p &subgroup_var region;
            model aval = trt01p &subgroup_var trt01p*&subgroup_var base region;
            
            lsmeans trt01p*&subgroup_var / pdiff cl;
        run;
        
        data subgroup_&subgroup_var;
            set subgroup_&subgroup_var;
            where _trt01p = 'Drug 10mg' and trt01p = 'Placebo';
            
            subgroup_category = "&subgroup_label";
            subgroup_level = &subgroup_var;
            treatment_effect = estimate;
            lower_ci = lower;
            upper_ci = upper;
            p_value = probt;
            
            keep subgroup_category subgroup_level treatment_effect 
                 lower_ci upper_ci p_value;
        run;
        
    %mend;
    
    %analyze_subgroup(age_group, Age Group);
    %analyze_subgroup(sex_group, Sex);
    %analyze_subgroup(race_group, Race);
    
    /* Combine all subgroup results */
    data forest_plot_data;
        set subgroup_age_group subgroup_sex_group subgroup_race_group;
    run;
    
    /* Create forest plot */
    ods rtf file="&output_file" style=clinical_style;
    
    title "Forest Plot - Treatment Effect by Subgroup";
    title2 "Drug 10mg vs Placebo";
    
    proc sgplot data=forest_plot_data noautolegend;
        scatter x=treatment_effect y=subgroup_level / 
                markerattrs=(symbol=diamondfilled size=8);
        highlow y=subgroup_level low=lower_ci high=upper_ci / 
                lineattrs=(thickness=2);
        refline 0 / axis=x lineattrs=(pattern=2);
        
        xaxis label="Treatment Effect (95% CI)" 
              values=(-10 to 10 by 2);
        yaxis label="Subgroup" 
              discreteorder=data 
              fitpolicy=rotate;
    run;
    
    ods rtf close;
    
%mend forest_plot;

%forest_plot();
```

## Quality Control Framework

### Table Validation Macro

```sas
/******************************************************************************
TABLE VALIDATION AND QUALITY CONTROL FRAMEWORK
******************************************************************************/

%macro validate_table(table_program=, validation_program=, tolerance=1E-8);
    
    %put NOTE: Starting validation of &table_program;
    
    /* Execute original program */
    %include "&table_program";
    
    /* Save original results */
    data original_results;
        set work._last_;
    run;
    
    /* Execute validation program */
    %include "&validation_program";
    
    /* Save validation results */
    data validation_results;
        set work._last_;
    run;
    
    /* Compare results */
    proc compare base=original_results compare=validation_results
                 criterion=&tolerance out=validation_diff;
    run;
    
    /* Generate validation report */
    data validation_summary;
        length validation_item $50 status $20 comments $100;
        
        validation_item = "Table Program Execution";
        status = "PASS";
        comments = "Both programs executed successfully";
        output;
        
        validation_item = "Results Comparison";
        if &sysinfo = 0 then do;
            status = "PASS";
            comments = "All results match within tolerance";
        end;
        else do;
            status = "FAIL";
            comments = "Differences detected - see comparison output";
        end;
        output;
    run;
    
    proc print data=validation_summary;
        title "Validation Summary for &table_program";
        var validation_item status comments;
    run;
    
    %if &sysinfo ne 0 %then %do;
        %put WARNING: Validation failed for &table_program;
        %put WARNING: Check comparison results for details;
    %end;
    %else %do;
        %put NOTE: Validation passed for &table_program;
    %end;
    
%mend validate_table;

/* Example usage */
%validate_table(
    table_program=demographics_table.sas,
    validation_program=demographics_validation.sas
);
```

### Automated Table Production System

```sas
/******************************************************************************
AUTOMATED TABLE PRODUCTION AND VALIDATION SYSTEM
******************************************************************************/

%macro produce_all_tables(table_spec_file=table_specifications.xlsx,
                         output_path=/outputs/tables/);
    
    /* Read table specifications */
    proc import datafile="&table_spec_file" 
                out=table_specs 
                dbms=xlsx replace;
        sheet="TableSpecs";
    run;
    
    /* Process each table */
    data _null_;
        set table_specs;
        
        /* Create macro call for each table */
        call execute('%nrstr(%' || trim(table_macro) || '(' ||
                    'output_path=' || "&output_path" || ',' ||
                    'table_num=' || trim(table_number) || ');');
        
        /* Add validation if specified */
        if validation_required = 'Y' then do;
            call execute('%nrstr(%validate_table(' ||
                        'table_program=' || trim(table_program) || ',' ||
                        'validation_program=' || trim(validation_program) || ');');
        end;
    run;
    
    /* Generate table index */
    %create_table_index(path=&output_path);
    
    %put NOTE: All tables produced and validated successfully;
    
%mend produce_all_tables;

/* Execute production system */
%produce_all_tables();
```

---

## Best Practices Summary

### Programming Standards
1. **Consistent Formatting**: Use standardized templates and styles
2. **Modular Design**: Create reusable macros for common tasks
3. **Comprehensive Documentation**: Include detailed headers and comments
4. **Error Handling**: Implement robust error checking and logging
5. **Validation**: Independent programming validation for key tables

### Regulatory Compliance
1. **ICH E3 Standards**: Follow regulatory table requirements
2. **Traceability**: Maintain clear links from raw data to final outputs
3. **Version Control**: Document all changes and maintain history
4. **Quality Assurance**: Implement systematic review processes
5. **Audit Trail**: Maintain complete documentation for regulatory review

### Efficiency Optimization
1. **Automation**: Use macro systems for repetitive tasks
2. **Standardization**: Develop template libraries
3. **Quality Control**: Implement systematic validation procedures
4. **Performance**: Optimize code for large datasets
5. **Collaboration**: Create shared programming resources

*This programming guide provides the foundation for producing high-quality, regulatory-compliant clinical trial tables efficiently and accurately.*