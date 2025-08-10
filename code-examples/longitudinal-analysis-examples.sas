/******************************************************************************
PROGRAM: longitudinal-analysis-examples.sas
PURPOSE: Comprehensive longitudinal data analysis examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides practical examples of longitudinal data analysis methods
commonly used in clinical trials, including mixed models for repeated measures
(MMRM), generalized estimating equations (GEE), and growth curve modeling.

SECTIONS INCLUDED:
1. Mixed Models for Repeated Measures (MMRM)
2. Generalized Estimating Equations (GEE) 
3. Growth Curve Analysis
4. Missing Data Handling in Longitudinal Studies
5. Sample Size Calculations for Longitudinal Studies
6. Visualization of Longitudinal Data
******************************************************************************/

/******************************************************************************
SECTION 1: MIXED MODELS FOR REPEATED MEASURES (MMRM)
******************************************************************************/

/******************************************************************************
MACRO: mmrm_analysis
PURPOSE: Perform MMRM analysis for longitudinal efficacy data
PARAMETERS:
  data= : Input dataset (BDS format with repeated measures)
  response_var= : Response variable (e.g., CHG, AVAL)
  treatment_var= : Treatment variable
  baseline_var= : Baseline variable (for ANCOVA-type models)
  visit_var= : Visit variable
  subject_var= : Subject ID variable
  covariates= : Additional covariates (space-separated)
  covariance_structure= : Covariance structure (UN, CS, AR1, etc.)
******************************************************************************/
%macro mmrm_analysis(
    data=,
    response_var=chg,
    treatment_var=trt01p,
    baseline_var=base,
    visit_var=avisit,
    subject_var=usubjid,
    covariates=,
    covariance_structure=UN
);
    
    %put NOTE: Performing MMRM analysis;
    
    /* Prepare data for analysis */
    data work.mmrm_data;
        set &data;
        
        /* Remove missing response values */
        where not missing(&response_var);
        
        /* Create numeric visit variable if needed */
        if upcase(&visit_var) = 'BASELINE' then visitn = 0;
        else if upcase(&visit_var) = 'WEEK 2' then visitn = 2;
        else if upcase(&visit_var) = 'WEEK 4' then visitn = 4;
        else if upcase(&visit_var) = 'WEEK 8' then visitn = 8;
        else if upcase(&visit_var) = 'WEEK 12' then visitn = 12;
        else if upcase(&visit_var) = 'WEEK 24' then visitn = 24;
        /* Add more visit mappings as needed */
        
        /* Ensure proper variable types */
        if missing(visitn) then delete;
    run;
    
    /* Sort data */
    proc sort data=work.mmrm_data;
        by &subject_var visitn;
    run;
    
    /* MMRM Analysis */
    ods output LSMeans=work.mmrm_lsmeans
               Diffs=work.mmrm_diffs
               Tests3=work.mmrm_tests
               CovParms=work.mmrm_covparms;
    
    proc mixed data=work.mmrm_data method=reml;
        class &subject_var &treatment_var &visit_var;
        model &response_var = &treatment_var &visit_var &treatment_var*&visit_var &baseline_var &covariates / ddfm=kr;
        repeated &visit_var / subject=&subject_var type=&covariance_structure r rcorr;
        lsmeans &treatment_var*&visit_var / pdiff cl;
        
        title1 "Mixed Model for Repeated Measures (MMRM)";
        title2 "Response Variable: &response_var";
        title3 "Covariance Structure: &covariance_structure";
    run;
    
    /* Display key results */
    proc print data=work.mmrm_lsmeans;
        title "Least Squares Means by Treatment and Visit";
        var &treatment_var &visit_var estimate stderr lower upper;
        format estimate stderr lower upper 8.2;
    run;
    
    proc print data=work.mmrm_diffs;
        title "Treatment Differences by Visit";
        where upcase(_&treatment_var) ne upcase(&treatment_var);
        var &visit_var _&treatment_var &treatment_var estimate stderr lower upper probt;
        format estimate stderr lower upper 8.2 probt pvalue6.4;
    run;
    
    /* Test for overall treatment effect */
    proc print data=work.mmrm_tests;
        title "Tests of Fixed Effects";
        var effect numdf dendf fvalue probf;
        format fvalue 8.2 probf pvalue6.4;
    run;
    
    /* Covariance parameter estimates */
    proc print data=work.mmrm_covparms;
        title "Covariance Parameter Estimates";
        var covparm estimate stderr;
        format estimate stderr 8.4;
    run;
    
    %put NOTE: MMRM analysis completed;
    
%mend mmrm_analysis;

/******************************************************************************
SECTION 2: GENERALIZED ESTIMATING EQUATIONS (GEE)
******************************************************************************/

/******************************************************************************
MACRO: gee_analysis
PURPOSE: Perform GEE analysis for longitudinal data
PARAMETERS:
  data= : Input dataset
  response_var= : Response variable
  treatment_var= : Treatment variable
  visit_var= : Visit variable
  subject_var= : Subject ID variable
  covariates= : Additional covariates
  distribution= : Distribution (NORMAL, BINOMIAL, POISSON)
  link= : Link function (IDENTITY, LOGIT, LOG)
  corr_structure= : Working correlation (IND, EXCH, AR, UNSTR)
******************************************************************************/
%macro gee_analysis(
    data=,
    response_var=response,
    treatment_var=trt01p,
    visit_var=avisit,
    subject_var=usubjid,
    covariates=,
    distribution=NORMAL,
    link=IDENTITY,
    corr_structure=EXCH
);
    
    %put NOTE: Performing GEE analysis;
    
    /* Prepare data */
    data work.gee_data;
        set &data;
        where not missing(&response_var);
        
        /* Create numeric treatment variable if needed */
        if upcase(&treatment_var) = 'ACTIVE' then trt_num = 1;
        else if upcase(&treatment_var) = 'PLACEBO' then trt_num = 0;
    run;
    
    /* Sort data */
    proc sort data=work.gee_data;
        by &subject_var &visit_var;
    run;
    
    /* GEE Analysis */
    ods output GEEEmpPEst=work.gee_estimates
               GEERCov=work.gee_rcov;
    
    proc genmod data=work.gee_data;
        class &subject_var &treatment_var &visit_var;
        model &response_var = &treatment_var &visit_var &treatment_var*&visit_var &covariates 
              / dist=&distribution link=&link;
        repeated subject=&subject_var / within=&visit_var type=&corr_structure corrw;
        
        title1 "Generalized Estimating Equations (GEE)";
        title2 "Distribution: &distribution, Link: &link";
        title3 "Working Correlation: &corr_structure";
    run;
    
    /* Display results */
    proc print data=work.gee_estimates;
        title "GEE Parameter Estimates";
        var parm level1 level2 estimate stderr lowercl uppercl probz;
        format estimate stderr lowercl uppercl 8.4 probz pvalue6.4;
    run;
    
    /* Working correlation matrix */
    proc print data=work.gee_rcov;
        title "Working Correlation Matrix";
    run;
    
    %put NOTE: GEE analysis completed;
    
%mend gee_analysis;

/******************************************************************************
SECTION 3: GROWTH CURVE ANALYSIS
******************************************************************************/

/******************************************************************************
MACRO: growth_curve_analysis
PURPOSE: Perform growth curve analysis using random effects models
PARAMETERS:
  data= : Input dataset
  response_var= : Response variable
  time_var= : Time variable (continuous)
  treatment_var= : Treatment variable
  subject_var= : Subject ID variable
  polynomial_degree= : Degree of polynomial for time (1=linear, 2=quadratic)
******************************************************************************/
%macro growth_curve_analysis(
    data=,
    response_var=aval,
    time_var=ady,
    treatment_var=trt01p,
    subject_var=usubjid,
    polynomial_degree=2
);
    
    %put NOTE: Performing growth curve analysis;
    
    /* Prepare data */
    data work.growth_data;
        set &data;
        where not missing(&response_var) and not missing(&time_var);
        
        /* Standardize time variable */
        time_std = &time_var / 30.44; /* Convert days to months */
        
        /* Create polynomial terms */
        %if &polynomial_degree >= 2 %then %do;
            time_sq = time_std**2;
        %end;
        %if &polynomial_degree >= 3 %then %do;
            time_cu = time_std**3;
        %end;
    run;
    
    /* Growth curve model with random effects */
    ods output SolutionF=work.fixed_effects
               SolutionR=work.random_effects
               CovParms=work.variance_components;
    
    proc mixed data=work.growth_data method=reml;
        class &subject_var &treatment_var;
        model &response_var = &treatment_var time_std &treatment_var*time_std 
              %if &polynomial_degree >= 2 %then time_sq &treatment_var*time_sq;
              %if &polynomial_degree >= 3 %then time_cu &treatment_var*time_cu;
              / solution ddfm=kr;
        random intercept time_std 
               %if &polynomial_degree >= 2 %then time_sq;
               / subject=&subject_var type=un;
        
        title1 "Growth Curve Analysis";
        title2 "Polynomial Degree: &polynomial_degree";
    run;
    
    /* Display results */
    proc print data=work.fixed_effects;
        title "Fixed Effects Estimates";
        var effect &treatment_var estimate stderr df tvalue probt;
        format estimate stderr 8.3 tvalue 8.2 probt pvalue6.4;
    run;
    
    proc print data=work.variance_components;
        title "Variance Components";
        var covparm subject estimate stderr;
        format estimate stderr 8.4;
    run;
    
    /* Predicted growth curves */
    proc mixed data=work.growth_data;
        class &subject_var &treatment_var;
        model &response_var = &treatment_var time_std &treatment_var*time_std 
              %if &polynomial_degree >= 2 %then time_sq &treatment_var*time_sq;
              / outp=work.predicted_values;
        random intercept time_std / subject=&subject_var type=un;
    run;
    
    %put NOTE: Growth curve analysis completed;
    
%mend growth_curve_analysis;

/******************************************************************************
SECTION 4: MISSING DATA HANDLING
******************************************************************************/

/******************************************************************************
MACRO: missing_data_analysis
PURPOSE: Analyze missing data patterns and perform sensitivity analysis
PARAMETERS:
  data= : Input dataset
  response_var= : Response variable
  visit_var= : Visit variable
  subject_var= : Subject ID variable
  treatment_var= : Treatment variable
******************************************************************************/
%macro missing_data_analysis(
    data=,
    response_var=chg,
    visit_var=avisit,
    subject_var=usubjid,
    treatment_var=trt01p
);
    
    %put NOTE: Analyzing missing data patterns;
    
    /* Create dataset with missing data indicators */
    data work.missing_data;
        set &data;
        
        /* Missing data indicator */
        if missing(&response_var) then missing_flag = 1;
        else missing_flag = 0;
    run;
    
    /* Missing data patterns by visit */
    proc freq data=work.missing_data;
        tables &visit_var * missing_flag / missing;
        title "Missing Data Patterns by Visit";
    run;
    
    /* Missing data patterns by treatment */
    proc freq data=work.missing_data;
        tables &treatment_var * missing_flag / missing;
        title "Missing Data Patterns by Treatment";
    run;
    
    /* Dropout analysis */
    proc sort data=work.missing_data;
        by &subject_var &visit_var;
    run;
    
    data work.dropout_analysis;
        set work.missing_data;
        by &subject_var;
        
        retain last_observed_visit;
        
        if first.&subject_var then do;
            last_observed_visit = '';
            dropped_out = 0;
        end;
        
        if missing_flag = 0 then last_observed_visit = &visit_var;
        
        if last.&subject_var and not missing(last_observed_visit) then do;
            if last_observed_visit ne max_visit then dropped_out = 1;
            output;
        end;
    run;
    
    /* Multiple imputation for sensitivity analysis */
    proc mi data=work.missing_data out=work.imputed_data nimpute=5 seed=12345;
        class &subject_var &treatment_var &visit_var;
        var &response_var &treatment_var &visit_var;
        by &subject_var;
    run;
    
    /* Analyze imputed data */
    proc mixed data=work.imputed_data;
        by _imputation_;
        class &subject_var &treatment_var &visit_var;
        model &response_var = &treatment_var &visit_var &treatment_var*&visit_var / ddfm=kr;
        repeated &visit_var / subject=&subject_var type=un;
        lsmeans &treatment_var / pdiff cl;
        ods output diffs=work.mi_results;
    run;
    
    /* Combine results across imputations */
    proc mianalyze data=work.mi_results;
        modeleffects estimate;
        stderr stderr;
        title "Multiple Imputation Results";
    run;
    
    %put NOTE: Missing data analysis completed;
    
%mend missing_data_analysis;

/******************************************************************************
SECTION 5: LONGITUDINAL SAMPLE SIZE CALCULATIONS
******************************************************************************/

/******************************************************************************
MACRO: longitudinal_sample_size
PURPOSE: Calculate sample size for longitudinal studies
PARAMETERS:
  effect_size= : Standardized effect size
  num_timepoints= : Number of time points
  correlation= : Within-subject correlation
  alpha= : Type I error rate
  power= : Desired power
  attrition_rate= : Expected attrition rate
******************************************************************************/
%macro longitudinal_sample_size(
    effect_size=0.5,
    num_timepoints=4,
    correlation=0.6,
    alpha=0.05,
    power=0.80,
    attrition_rate=0.20
);
    
    %put NOTE: Calculating sample size for longitudinal study;
    
    data work.long_sample_size;
        /* Input parameters */
        delta = &effect_size;
        k = &num_timepoints;
        rho = &correlation;
        alpha = &alpha;
        power = &power;
        attrition = &attrition_rate;
        
        /* Calculate design effect */
        design_effect = 1 + (k - 1) * rho;
        
        /* Effective sample size multiplier */
        eff_multiplier = design_effect / k;
        
        /* Z-values */
        z_alpha = probit(1 - alpha/2);
        z_beta = probit(power);
        
        /* Sample size calculation (per group) */
        n_per_group_unadj = 2 * ((z_alpha + z_beta) / delta)**2 * eff_multiplier;
        
        /* Adjust for attrition */
        n_per_group = n_per_group_unadj / (1 - attrition);
        
        /* Total sample size */
        n_total = 2 * n_per_group;
        
        /* Output results */
        format n_per_group_unadj n_per_group n_total 8.0 
               design_effect eff_multiplier 8.3;
        
        put "Longitudinal Study Sample Size Calculation:";
        put "===========================================";
        put "Effect Size (Cohen's d): " delta;
        put "Number of Time Points: " k;
        put "Within-Subject Correlation: " rho;
        put "Design Effect: " design_effect;
        put "Sample Size per Group (unadjusted): " n_per_group_unadj;
        put "Sample Size per Group (adjusted): " n_per_group;
        put "Total Sample Size: " n_total;
    run;
    
    proc print data=work.long_sample_size;
        title "Sample Size Calculation for Longitudinal Study";
        var delta k rho design_effect n_per_group_unadj n_per_group n_total;
    run;
    
    %put NOTE: Longitudinal sample size calculation completed;
    
%mend longitudinal_sample_size;

/******************************************************************************
SECTION 6: VISUALIZATION OF LONGITUDINAL DATA
******************************************************************************/

/******************************************************************************
MACRO: longitudinal_plots
PURPOSE: Create standard plots for longitudinal data
PARAMETERS:
  data= : Input dataset
  response_var= : Response variable
  visit_var= : Visit variable
  treatment_var= : Treatment variable
  subject_var= : Subject ID variable
  output_path= : Output path for plots
******************************************************************************/
%macro longitudinal_plots(
    data=,
    response_var=chg,
    visit_var=avisit,
    treatment_var=trt01p,
    subject_var=usubjid,
    output_path=
);
    
    %put NOTE: Creating longitudinal data visualizations;
    
    /* Mean profiles over time */
    proc means data=&data noprint;
        class &treatment_var &visit_var;
        var &response_var;
        output out=work.mean_profiles mean=mean_response stderr=se_response;
    run;
    
    data work.mean_profiles;
        set work.mean_profiles;
        where not missing(&treatment_var) and not missing(&visit_var);
        
        /* Create confidence intervals */
        lower_ci = mean_response - 1.96 * se_response;
        upper_ci = mean_response + 1.96 * se_response;
    run;
    
    /* Mean profile plot */
    %if %length(&output_path) > 0 %then %do;
        ods graphics / imagename="longitudinal_mean_profile" imagefmt=png;
        ods listing gpath="&output_path";
    %end;
    
    proc sgplot data=work.mean_profiles;
        series x=&visit_var y=mean_response / group=&treatment_var markers
               lineattrs=(thickness=2);
        highlow x=&visit_var low=lower_ci high=upper_ci / group=&treatment_var
                transparency=0.3;
        
        xaxis label="Visit" grid;
        yaxis label="Mean Change from Baseline" grid;
        title1 "Mean Response Profiles Over Time";
        title2 "with 95% Confidence Intervals";
    run;
    
    /* Individual subject profiles */
    %if %length(&output_path) > 0 %then %do;
        ods graphics / imagename="longitudinal_individual_profiles" imagefmt=png;
    %end;
    
    proc sgpanel data=&data;
        panelby &treatment_var;
        series x=&visit_var y=&response_var / group=&subject_var
               transparency=0.7 lineattrs=(thickness=1);
        loess x=&visit_var y=&response_var / nomarkers
              lineattrs=(color=red thickness=3);
        
        colaxis label="Visit" grid;
        rowaxis label="&response_var" grid;
        title "Individual Subject Profiles by Treatment";
    run;
    
    /* Box plots by visit */
    %if %length(&output_path) > 0 %then %do;
        ods graphics / imagename="longitudinal_boxplots" imagefmt=png;
    %end;
    
    proc sgpanel data=&data;
        panelby &visit_var / columns=4;
        vbox &response_var / category=&treatment_var;
        
        colaxis label="Treatment";
        rowaxis label="&response_var" grid;
        title "Distribution of Response by Visit and Treatment";
    run;
    
    %put NOTE: Longitudinal visualization completed;
    
%mend longitudinal_plots;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: MMRM Analysis
%mmrm_analysis(
    data=adam.adlb,
    response_var=chg,
    treatment_var=trt01p,
    baseline_var=base,
    visit_var=avisit,
    subject_var=usubjid,
    covariates=age sex,
    covariance_structure=UN
);

Example 2: GEE Analysis  
%gee_analysis(
    data=adam.adlb,
    response_var=chg,
    treatment_var=trt01p,
    visit_var=avisit,
    subject_var=usubjid,
    covariates=age sex base,
    distribution=NORMAL,
    link=IDENTITY,
    corr_structure=EXCH
);

Example 3: Growth Curve Analysis
%growth_curve_analysis(
    data=adam.adlb,
    response_var=aval,
    time_var=ady,
    treatment_var=trt01p,
    subject_var=usubjid,
    polynomial_degree=2
);

Example 4: Missing Data Analysis
%missing_data_analysis(
    data=adam.adlb,
    response_var=chg,
    visit_var=avisit,
    subject_var=usubjid,
    treatment_var=trt01p
);

Example 5: Sample Size Calculation
%longitudinal_sample_size(
    effect_size=0.6,
    num_timepoints=5,
    correlation=0.7,
    alpha=0.05,
    power=0.85,
    attrition_rate=0.25
);

Example 6: Longitudinal Plots
%longitudinal_plots(
    data=adam.adlb,
    response_var=chg,
    visit_var=avisit,
    treatment_var=trt01p,
    subject_var=usubjid,
    output_path=/outputs/figures/
);
*/

%put NOTE: Longitudinal analysis examples loaded successfully;
%put NOTE: Available macros: mmrm_analysis, gee_analysis, growth_curve_analysis,;
%put NOTE:                  missing_data_analysis, longitudinal_sample_size, longitudinal_plots;