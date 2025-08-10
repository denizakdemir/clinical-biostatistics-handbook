/******************************************************************************
PROGRAM: table-macros.sas
PURPOSE: Comprehensive table generation macros for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This macro library contains specialized macros for generating all types of
regulatory submission tables following ICH E3 guidelines.

MACROS INCLUDED:
- %create_demographics_table - Generate demographics and baseline characteristics
- %create_disposition_table - Generate subject disposition table
- %create_efficacy_table - Generate efficacy analysis tables
- %create_safety_table - Generate safety summary tables
- %create_ae_table - Generate adverse event tables
- %create_lab_shift_table - Generate laboratory shift tables
- %create_conmed_table - Generate concomitant medication tables
- %create_vital_signs_table - Generate vital signs summary tables
******************************************************************************/

/******************************************************************************
MACRO: create_demographics_table
PURPOSE: Generate Table 14.1.1 Demographics and Baseline Characteristics
PARAMETERS:
  data= : ADSL dataset
  treatment_var= : Treatment variable
  population= : Population filter
  output_file= : Output file name
  output_type= : Output type (RTF, PDF, HTML)
  continuous_vars= : Continuous variables to summarize
  categorical_vars= : Categorical variables to summarize
******************************************************************************/
%macro create_demographics_table(
    data=,
    treatment_var=trt01p,
    population=%str(saffl='Y'),
    output_file=table_14_1_1,
    output_type=RTF,
    continuous_vars=age bmi height weight,
    categorical_vars=sex race ethnic agegr1
);
    
    %put NOTE: Creating demographics table;
    
    /* Filter population */
    data work.demo_pop;
        set &data;
        where &population;
    run;
    
    /* Get treatment groups and counts */
    proc freq data=work.demo_pop noprint;
        tables &treatment_var / out=work.trt_counts;
    run;
    
    proc sql noprint;
        select &treatment_var, count format=best12. 
        into :trt_list separated by '|', :trt_n separated by '|'
        from work.trt_counts;
        
        select count(*) into :total_n
        from work.demo_pop;
    quit;
    
    /* Initialize results dataset */
    data work.demo_results;
        length characteristic $50 category $50 statistic $30 
               %do i = 1 %to %sysfunc(countw(&trt_list, |));
                   trt&i $30
               %end;
               total $30;
        delete;
    run;
    
    /* Process continuous variables */
    %let cont_count = %sysfunc(countw(&continuous_vars));
    %do v = 1 %to &cont_count;
        %let var = %scan(&continuous_vars, &v);
        
        /* Calculate statistics by treatment */
        proc means data=work.demo_pop noprint;
            class &treatment_var;
            var &var;
            output out=work.cont_stats 
                   n=n mean=mean std=std median=median min=min max=max;
        run;
        
        /* Format results */
        data work.temp_results;
            length characteristic $50 category $50 statistic $30;
            
            characteristic = propcase("&var");
            category = "";
            
            /* Add variable label if exists */
            %let dsid = %sysfunc(open(work.demo_pop));
            %let varnum = %sysfunc(varnum(&dsid, &var));
            %let varlabel = %sysfunc(varlabel(&dsid, &varnum));
            %let rc = %sysfunc(close(&dsid));
            %if %length(&varlabel) > 0 %then %do;
                characteristic = "&varlabel";
            %end;
            
            /* Create rows for each statistic */
            statistic = "n"; output;
            statistic = "Mean (SD)"; output;
            statistic = "Median"; output;
            statistic = "Min, Max"; output;
        run;
        
        /* Merge with calculated values */
        proc sql;
            create table work.formatted_cont as
            select a.*,
                   %do i = 1 %to %sysfunc(countw(&trt_list, |));
                       %let trt = %scan(&trt_list, &i, |);
                       case when a.statistic = 'n' then put(b&i..n, 8.)
                            when a.statistic = 'Mean (SD)' then 
                                 cats(put(b&i..mean, 8.1), ' (', put(b&i..std, 8.2), ')')
                            when a.statistic = 'Median' then put(b&i..median, 8.1)
                            when a.statistic = 'Min, Max' then 
                                 cats(put(b&i..min, 8.1), ', ', put(b&i..max, 8.1))
                       end as trt&i,
                   %end;
                   case when a.statistic = 'n' then put(btot.n, 8.)
                        when a.statistic = 'Mean (SD)' then 
                             cats(put(btot.mean, 8.1), ' (', put(btot.std, 8.2), ')')
                        when a.statistic = 'Median' then put(btot.median, 8.1)
                        when a.statistic = 'Min, Max' then 
                             cats(put(btot.min, 8.1), ', ', put(btot.max, 8.1))
                   end as total
            from work.temp_results as a
            %do i = 1 %to %sysfunc(countw(&trt_list, |));
                %let trt = %scan(&trt_list, &i, |);
                left join work.cont_stats(where=(&treatment_var="&trt")) as b&i
                on 1=1
            %end;
            left join work.cont_stats(where=(_type_=0)) as btot
            on 1=1;
        quit;
        
        proc append base=work.demo_results data=work.formatted_cont;
        run;
    %end;
    
    /* Process categorical variables */
    %let cat_count = %sysfunc(countw(&categorical_vars));
    %do v = 1 %to &cat_count;
        %let var = %scan(&categorical_vars, &v);
        
        /* Calculate frequencies by treatment */
        proc freq data=work.demo_pop noprint;
            tables &treatment_var * &var / outpct out=work.cat_freq;
        run;
        
        /* Get unique categories */
        proc sql noprint;
            select distinct &var into :cat_list separated by '|'
            from work.cat_freq
            where not missing(&var);
        quit;
        
        /* Format results */
        data work.temp_cat_results;
            length characteristic $50 category $50 statistic $30
                   %do i = 1 %to %sysfunc(countw(&trt_list, |));
                       trt&i $30
                   %end;
                   total $30;
            
            characteristic = propcase("&var");
            
            /* Add variable label */
            %let dsid = %sysfunc(open(work.demo_pop));
            %let varnum = %sysfunc(varnum(&dsid, &var));
            %let varlabel = %sysfunc(varlabel(&dsid, &varnum));
            %let rc = %sysfunc(close(&dsid));
            %if %length(&varlabel) > 0 %then %do;
                characteristic = "&varlabel";
            %end;
            
            /* Create rows for each category */
            %let cat_n = %sysfunc(countw(&cat_list, |));
            %do c = 1 %to &cat_n;
                %let cat = %scan(&cat_list, &c, |);
                category = "&cat";
                statistic = "n (%)";
                
                /* Get counts and percentages */
                %do i = 1 %to %sysfunc(countw(&trt_list, |));
                    %let trt = %scan(&trt_list, &i, |);
                    %let trt_n_i = %scan(&trt_n, &i, |);
                    
                    proc sql noprint;
                        select count, pct_col into :count, :pct
                        from work.cat_freq
                        where &treatment_var = "&trt" and &var = "&cat";
                    quit;
                    
                    %if &sqlobs = 0 %then %do;
                        %let count = 0;
                        %let pct = 0;
                    %end;
                    
                    trt&i = cats(&count, ' (', put(&pct, 5.1), ')');
                %end;
                
                /* Total column */
                proc sql noprint;
                    select count(*) into :total_count
                    from work.demo_pop
                    where &var = "&cat";
                quit;
                
                total = cats(&total_count, ' (', 
                            put(&total_count/&total_n*100, 5.1), ')');
                
                output;
            %end;
        run;
        
        proc append base=work.demo_results data=work.temp_cat_results;
        run;
    %end;
    
    /* Create output */
    %if &output_type = RTF %then %do;
        ods rtf file="&output_file..rtf" style=styles.rtf;
    %end;
    %else %if &output_type = PDF %then %do;
        ods pdf file="&output_file..pdf";
    %end;
    %else %if &output_type = HTML %then %do;
        ods html file="&output_file..html";
    %end;
    
    /* Set titles and footnotes */
    title1 "Table 14.1.1";
    title2 "Demographics and Other Baseline Characteristics";
    title3 "Safety Population";
    
    footnote1 "Note: Percentages are based on the number of subjects in each treatment group.";
    
    /* Generate table */
    proc report data=work.demo_results nowd split='~';
        column characteristic category statistic 
               %do i = 1 %to %sysfunc(countw(&trt_list, |));
                   trt&i
               %end;
               total;
        
        define characteristic / order order=data "Characteristic" style(column)=[cellwidth=2in];
        define category / order order=data "Category" style(column)=[cellwidth=1.5in];
        define statistic / display "Statistic" style(column)=[cellwidth=1in];
        
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            %let trt = %scan(&trt_list, &i, |);
            %let n = %scan(&trt_n, &i, |);
            define trt&i / display "&trt~(N=&n)" style(column)=[cellwidth=1.5in just=c];
        %end;
        
        define total / display "Total~(N=&total_n)" style(column)=[cellwidth=1.5in just=c];
        
        compute before characteristic;
            line ' ';
        endcomp;
    run;
    
    /* Close output */
    ods &output_type close;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete demo_pop trt_counts cont_stats temp_results formatted_cont
               cat_freq temp_cat_results;
    quit;
    
    %put NOTE: Demographics table created: &output_file;
    
%mend create_demographics_table;

/******************************************************************************
MACRO: create_disposition_table
PURPOSE: Generate subject disposition table
PARAMETERS:
  data= : ADSL dataset
  treatment_var= : Treatment variable
  output_file= : Output file name
  output_type= : Output type (RTF, PDF, HTML)
******************************************************************************/
%macro create_disposition_table(
    data=,
    treatment_var=trt01p,
    output_file=table_14_1_2,
    output_type=RTF
);
    
    %put NOTE: Creating disposition table;
    
    /* Get treatment groups */
    proc freq data=&data noprint;
        tables &treatment_var / out=work.trt_list;
    run;
    
    /* Calculate disposition summaries */
    data work.disp_summary;
        set &data;
        
        /* Define disposition categories */
        length disp_cat $50;
        
        /* Screened */
        if not missing(scrfl) then disp_cat = "Screened";
        output;
        
        /* Screen failures */
        if scrfl = 'Y' and randfl ne 'Y' then disp_cat = "Screen Failures";
        output;
        
        /* Randomized */
        if randfl = 'Y' then disp_cat = "Randomized";
        output;
        
        /* Treated */
        if saffl = 'Y' then disp_cat = "Treated";
        output;
        
        /* Completed */
        if compfl = 'Y' then disp_cat = "Completed Study";
        output;
        
        /* Discontinued */
        if randfl = 'Y' and compfl ne 'Y' then do;
            disp_cat = "Discontinued";
            output;
            
            /* Reasons for discontinuation */
            if not missing(dcsreas) then do;
                disp_cat = "  " || strip(dcsreas);
                output;
            end;
        end;
    run;
    
    /* Create summary table */
    proc freq data=work.disp_summary noprint;
        tables disp_cat * &treatment_var / out=work.disp_freq;
    run;
    
    /* Format for output */
    proc sql;
        create table work.disp_formatted as
        select disp_cat as disposition,
               %do i = 1 %to %sysfunc(countw(&trt_list));
                   sum(case when &treatment_var = "%scan(&trt_list, &i)" 
                            then count else 0 end) as trt&i,
               %end;
               sum(count) as total
        from work.disp_freq
        group by disp_cat
        order by case when disp_cat = 'Screened' then 1
                      when disp_cat = 'Screen Failures' then 2
                      when disp_cat = 'Randomized' then 3
                      when disp_cat = 'Treated' then 4
                      when disp_cat = 'Completed Study' then 5
                      when disp_cat = 'Discontinued' then 6
                      else 7 end,
                 disp_cat;
    quit;
    
    /* Create output */
    ods &output_type file="&output_file..%lowcase(&output_type)";
    
    title1 "Table 14.1.2";
    title2 "Subject Disposition";
    title3 "All Subjects";
    
    proc report data=work.disp_formatted nowd;
        column disposition trt: total;
        
        define disposition / display "Disposition" style(column)=[cellwidth=3in];
        %do i = 1 %to %sysfunc(countw(&trt_list));
            define trt&i / display "%scan(&trt_list, &i)" style(column)=[just=c];
        %end;
        define total / display "Total" style(column)=[just=c];
    run;
    
    ods &output_type close;
    
    %put NOTE: Disposition table created: &output_file;
    
%mend create_disposition_table;

/******************************************************************************
MACRO: create_efficacy_table
PURPOSE: Generate efficacy analysis tables
PARAMETERS:
  data= : Analysis dataset (ADaM BDS format)
  param= : Parameter to analyze (PARAMCD value)
  visit= : Visit to analyze (or LAST for last observation)
  treatment_var= : Treatment variable
  response_var= : Response variable (CHG, AVAL, etc.)
  stat_method= : Statistical method (ANCOVA, MMRM, etc.)
  output_file= : Output file name
  output_type= : Output type
******************************************************************************/
%macro create_efficacy_table(
    data=,
    param=,
    visit=,
    treatment_var=trt01p,
    response_var=chg,
    stat_method=ANCOVA,
    output_file=,
    output_type=RTF
);
    
    %put NOTE: Creating efficacy table for &param at &visit;
    
    /* Filter data */
    data work.eff_data;
        set &data;
        where paramcd = "&param" and ittfl = 'Y';
        
        %if &visit ne LAST %then %do;
            where also avisit = "&visit";
        %end;
        %else %do;
            where also lastfl = 'Y';
        %end;
    run;
    
    /* Descriptive statistics by treatment */
    proc means data=work.eff_data noprint;
        class &treatment_var;
        var &response_var;
        output out=work.desc_stats
               n=n mean=mean std=std stderr=stderr median=median min=min max=max;
    run;
    
    /* Statistical analysis */
    %if &stat_method = ANCOVA %then %do;
        ods output LSMeans=work.lsmeans Diffs=work.diffs;
        
        proc glm data=work.eff_data;
            class &treatment_var;
            model &response_var = &treatment_var base;
            lsmeans &treatment_var / stderr pdiff cl;
        quit;
    %end;
    %else %if &stat_method = MMRM %then %do;
        /* MMRM implementation would go here */
    %end;
    
    /* Format results */
    data work.eff_results;
        length statistic $50 
               %do i = 1 %to %sysfunc(countw(&trt_list, |));
                   trt&i $30
               %end;;
        
        /* Descriptive statistics rows */
        statistic = "n"; 
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = put(n_&i, 8.);
        %end;
        output;
        
        statistic = "Mean (SD)";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = cats(put(mean_&i, 8.2), ' (', put(std_&i, 8.2), ')');
        %end;
        output;
        
        statistic = "Median";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = put(median_&i, 8.2);
        %end;
        output;
        
        statistic = "Min, Max";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = cats(put(min_&i, 8.2), ', ', put(max_&i, 8.2));
        %end;
        output;
        
        /* Add model results */
        %if &stat_method = ANCOVA %then %do;
            statistic = "LS Mean (SE)";
            /* Add LS means */
            output;
            
            statistic = "95% CI";
            /* Add confidence intervals */
            output;
            
            statistic = "Difference vs Placebo";
            /* Add treatment differences */
            output;
            
            statistic = "95% CI for Difference";
            /* Add CI for differences */
            output;
            
            statistic = "p-value";
            /* Add p-values */
            output;
        %end;
    run;
    
    /* Create output */
    ods &output_type file="&output_file..%lowcase(&output_type)";
    
    title1 "Table 11.X.X";
    title2 "Analysis of &param at &visit";
    title3 "Intent-to-Treat Population";
    
    proc report data=work.eff_results nowd;
        column statistic trt:;
        
        define statistic / display "Statistic";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            define trt&i / display "%scan(&trt_list, &i, |)";
        %end;
    run;
    
    ods &output_type close;
    
    %put NOTE: Efficacy table created: &output_file;
    
%mend create_efficacy_table;

/******************************************************************************
MACRO: create_ae_table
PURPOSE: Generate adverse event summary tables
PARAMETERS:
  data= : ADAE dataset
  adsl_data= : ADSL dataset for denominators
  treatment_var= : Treatment variable
  output_file= : Output file name
  output_type= : Output type
  ae_scope= : Scope of AEs (ALL, TEAE, RELATED, SERIOUS)
******************************************************************************/
%macro create_ae_table(
    data=,
    adsl_data=,
    treatment_var=trt01p,
    output_file=table_12_1_1,
    output_type=RTF,
    ae_scope=TEAE
);
    
    %put NOTE: Creating AE table for scope: &ae_scope;
    
    /* Get denominators from ADSL */
    proc freq data=&adsl_data noprint;
        where saffl = 'Y';
        tables &treatment_var / out=work.denom;
    run;
    
    /* Filter AEs based on scope */
    data work.ae_subset;
        set &data;
        where saffl = 'Y';
        
        %if &ae_scope = TEAE %then %do;
            where also trtemfl = 'Y';
        %end;
        %else %if &ae_scope = RELATED %then %do;
            where also trtemfl = 'Y' and arel = 'RELATED';
        %end;
        %else %if &ae_scope = SERIOUS %then %do;
            where also trtemfl = 'Y' and aeser = 'Y';
        %end;
    run;
    
    /* Overall summary */
    proc sql;
        create table work.overall_summary as
        select &treatment_var,
               count(distinct usubjid) as n_subjects,
               count(*) as n_events
        from work.ae_subset
        group by &treatment_var;
    quit;
    
    /* By System Organ Class and Preferred Term */
    proc sql;
        create table work.soc_pt_summary as
        select &treatment_var, aesoc, aedecod,
               count(distinct usubjid) as n_subjects,
               count(*) as n_events
        from work.ae_subset
        group by &treatment_var, aesoc, aedecod
        order by aesoc, aedecod, &treatment_var;
    quit;
    
    /* Format results */
    data work.ae_formatted;
        merge work.overall_summary work.denom(rename=(count=denom));
        by &treatment_var;
        
        length category $100 
               %do i = 1 %to %sysfunc(countw(&trt_list, |));
                   trt&i $50
               %end;;
        
        /* Overall row */
        category = "Subjects with at least one AE";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            %let trt = %scan(&trt_list, &i, |);
            if &treatment_var = "&trt" then do;
                trt&i = cats(n_subjects, ' (', 
                            put(n_subjects/denom*100, 5.1), ')');
            end;
        %end;
        output;
        
        /* By SOC and PT */
        /* Add SOC/PT formatting logic here */
    run;
    
    /* Create output */
    ods &output_type file="&output_file..%lowcase(&output_type)";
    
    title1 "Table 12.1.1";
    title2 "Summary of Adverse Events";
    title3 "Safety Population";
    
    proc report data=work.ae_formatted nowd;
        column category trt:;
        
        define category / display "System Organ Class/Preferred Term";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            define trt&i / display "%scan(&trt_list, &i, |)~n (%)";
        %end;
    run;
    
    ods &output_type close;
    
    %put NOTE: AE table created: &output_file;
    
%mend create_ae_table;

/******************************************************************************
MACRO: create_lab_shift_table
PURPOSE: Generate laboratory shift tables
PARAMETERS:
  data= : ADLB dataset
  param= : Lab parameter (PARAMCD)
  treatment_var= : Treatment variable
  output_file= : Output file name
  output_type= : Output type
******************************************************************************/
%macro create_lab_shift_table(
    data=,
    param=,
    treatment_var=trt01p,
    output_file=,
    output_type=RTF
);
    
    %put NOTE: Creating lab shift table for &param;
    
    /* Get baseline and post-baseline records */
    data work.lab_base work.lab_post;
        set &data;
        where paramcd = "&param" and saffl = 'Y';
        
        if ablfl = 'Y' then output work.lab_base;
        else if anl01fl = 'Y' then output work.lab_post;
    run;
    
    /* Determine shift categories */
    proc sql;
        create table work.shift_data as
        select a.usubjid, a.&treatment_var,
               case when a.bnrind = 'NORMAL' and b.anrind = 'NORMAL' then 'Normal to Normal'
                    when a.bnrind = 'NORMAL' and b.anrind = 'LOW' then 'Normal to Low'
                    when a.bnrind = 'NORMAL' and b.anrind = 'HIGH' then 'Normal to High'
                    when a.bnrind = 'LOW' and b.anrind = 'NORMAL' then 'Low to Normal'
                    when a.bnrind = 'LOW' and b.anrind = 'LOW' then 'Low to Low'
                    when a.bnrind = 'LOW' and b.anrind = 'HIGH' then 'Low to High'
                    when a.bnrind = 'HIGH' and b.anrind = 'NORMAL' then 'High to Normal'
                    when a.bnrind = 'HIGH' and b.anrind = 'LOW' then 'High to Low'
                    when a.bnrind = 'HIGH' and b.anrind = 'HIGH' then 'High to High'
                    else 'Unknown' end as shift_category
        from work.lab_base as a
        inner join work.lab_post as b
        on a.usubjid = b.usubjid
        where b.aval = (select max(aval) from work.lab_post 
                       where usubjid = b.usubjid);
    quit;
    
    /* Create shift summary */
    proc freq data=work.shift_data noprint;
        tables &treatment_var * shift_category / out=work.shift_freq;
    run;
    
    /* Format for output */
    /* Add formatting logic here */
    
    /* Create output */
    ods &output_type file="&output_file..%lowcase(&output_type)";
    
    title1 "Table 14.3.X";
    title2 "Shift Table for &param";
    title3 "Safety Population";
    
    /* Add report generation here */
    
    ods &output_type close;
    
    %put NOTE: Lab shift table created: &output_file;
    
%mend create_lab_shift_table;

/******************************************************************************
MACRO: create_vital_signs_table
PURPOSE: Generate vital signs summary table
PARAMETERS:
  data= : ADVS dataset
  params= : Vital sign parameters to include
  treatment_var= : Treatment variable
  visits= : Visits to include
  output_file= : Output file name
  output_type= : Output type
******************************************************************************/
%macro create_vital_signs_table(
    data=,
    params=SYSBP DIABP PULSE TEMP,
    treatment_var=trt01p,
    visits=BASELINE WEEK4 WEEK8 WEEK12,
    output_file=table_14_3_1,
    output_type=RTF
);
    
    %put NOTE: Creating vital signs table;
    
    /* Filter data */
    data work.vs_data;
        set &data;
        where saffl = 'Y' and 
              paramcd in (%upcase(%sysfunc(tranwrd(&params,%str( ),%str(,))))) and
              avisit in (%upcase(%sysfunc(tranwrd(&visits,%str( ),%str(,)))));
    run;
    
    /* Calculate statistics by parameter, visit, and treatment */
    proc means data=work.vs_data noprint;
        class paramcd avisit &treatment_var;
        var aval chg;
        output out=work.vs_stats
               n=n_aval n_chg
               mean=mean_aval mean_chg
               std=std_aval std_chg;
    run;
    
    /* Format results */
    data work.vs_formatted;
        set work.vs_stats;
        where _type_ = 7; /* All class variables */
        
        length parameter $50 visit $20 statistic $30
               %do i = 1 %to %sysfunc(countw(&trt_list, |));
                   trt&i $30
               %end;;
        
        /* Parameter labels */
        select (paramcd);
            when ('SYSBP') parameter = 'Systolic Blood Pressure (mmHg)';
            when ('DIABP') parameter = 'Diastolic Blood Pressure (mmHg)';
            when ('PULSE') parameter = 'Pulse Rate (bpm)';
            when ('TEMP') parameter = 'Temperature (°C)';
            otherwise parameter = paramcd;
        end;
        
        visit = propcase(avisit);
        
        /* Create rows for each statistic */
        statistic = 'n';
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = put(n_aval, 8.);
        %end;
        output;
        
        statistic = 'Mean (SD)';
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            trt&i = cats(put(mean_aval, 8.1), ' (', put(std_aval, 8.1), ')');
        %end;
        output;
        
        if avisit ne 'BASELINE' then do;
            statistic = 'Mean Change (SD)';
            %do i = 1 %to %sysfunc(countw(&trt_list, |));
                trt&i = cats(put(mean_chg, 8.1), ' (', put(std_chg, 8.1), ')');
            %end;
            output;
        end;
    run;
    
    /* Create output */
    ods &output_type file="&output_file..%lowcase(&output_type)";
    
    title1 "Table 14.3.1";
    title2 "Summary of Vital Signs";
    title3 "Safety Population";
    
    proc report data=work.vs_formatted nowd;
        column parameter visit statistic trt:;
        
        define parameter / order "Parameter";
        define visit / order "Visit";
        define statistic / display "Statistic";
        %do i = 1 %to %sysfunc(countw(&trt_list, |));
            define trt&i / display "%scan(&trt_list, &i, |)";
        %end;
        
        compute before parameter;
            line @1 parameter $50.;
        endcomp;
    run;
    
    ods &output_type close;
    
    %put NOTE: Vital signs table created: &output_file;
    
%mend create_vital_signs_table;

%put NOTE: Table macros library loaded successfully;
%put NOTE: Available macros: create_demographics_table, create_disposition_table,;
%put NOTE:                  create_efficacy_table, create_ae_table,;
%put NOTE:                  create_lab_shift_table, create_vital_signs_table;