/******************************************************************************
PROGRAM: survival-analysis-examples.sas
PURPOSE: Comprehensive survival analysis examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides practical examples of survival analysis methods
commonly used in clinical trials, including Kaplan-Meier analysis,
Cox proportional hazards regression, and competing risks analysis.

SECTIONS INCLUDED:
1. Kaplan-Meier Survival Analysis
2. Log-rank Test for Treatment Comparison  
3. Cox Proportional Hazards Regression
4. Competing Risks Analysis
5. Parametric Survival Models
6. Sample Size Calculations for Survival Studies
******************************************************************************/

/******************************************************************************
SECTION 1: KAPLAN-MEIER SURVIVAL ANALYSIS
******************************************************************************/

/******************************************************************************
MACRO: km_analysis
PURPOSE: Perform Kaplan-Meier survival analysis with plots and statistics
PARAMETERS:
  data= : Input dataset (ADTTE format)
  time_var= : Time to event variable (AVAL)
  event_var= : Event indicator (CNSR: 0=event, 1=censored)
  group_var= : Grouping variable (treatment)
  output_path= : Path for output files
  title_text= : Title for analysis
******************************************************************************/
%macro km_analysis(
    data=,
    time_var=aval,
    event_var=cnsr,
    group_var=trt01p,
    output_path=,
    title_text=Kaplan-Meier Analysis
);
    
    %put NOTE: Performing Kaplan-Meier analysis;
    
    /* Create event indicator (1=event, 0=censored for PROC LIFETEST) */
    data work.km_data;
        set &data;
        
        /* Convert CDISC CNSR to SAS event indicator */
        if &event_var = 0 then event = 1; /* Event occurred */
        else if &event_var = 1 then event = 0; /* Censored */
        
        /* Remove missing values */
        if not missing(&time_var) and not missing(event);
    run;
    
    /* Kaplan-Meier analysis with log-rank test */
    ods output SurvivalPlot=work.km_plot 
               Quartiles=work.km_quartiles
               HomTests=work.logrank_test;
    
    proc lifetest data=work.km_data plots=survival(cl atrisk=0 to 24 by 6);
        time &time_var*event(0);
        strata &group_var;
        title1 "&title_text";
        title2 "Kaplan-Meier Survival Curves by Treatment Group";
    run;
    
    /* Create custom survival plot */
    %if %length(&output_path) > 0 %then %do;
        ods graphics / reset imagename="km_survival_plot" imagefmt=png;
        ods listing gpath="&output_path";
        
        proc sgplot data=work.km_plot;
            step x=time y=survival / group=stratum lineattrs=(thickness=2);
            step x=time y=lowerci / group=stratum linattrs=(pattern=2);
            step x=time y=upperci / group=stratum linattrs=(pattern=2);
            
            xaxis label="Time to Event (Months)" grid;
            yaxis label="Survival Probability" grid values=(0 to 1 by 0.2);
            
            title1 "&title_text";
            title2 "Kaplan-Meier Survival Curves with 95% Confidence Intervals";
        run;
    %end;
    
    /* Summary statistics */
    proc print data=work.km_quartiles;
        title "Survival Time Quartiles by Treatment Group";
        var stratum quartile estimate lowercl uppercl;
        format estimate lowercl uppercl 8.2;
    run;
    
    proc print data=work.logrank_test;
        title "Log-rank Test for Treatment Comparison";
        var test chisq df probchisq;
    run;
    
    /* At-risk table */
    proc lifetest data=work.km_data atrisk;
        time &time_var*event(0);
        strata &group_var;
        title "Number of Subjects at Risk";
    run;
    
    %put NOTE: Kaplan-Meier analysis completed;
    
%mend km_analysis;

/******************************************************************************
SECTION 2: COX PROPORTIONAL HAZARDS REGRESSION
******************************************************************************/

/******************************************************************************
MACRO: cox_regression
PURPOSE: Perform Cox proportional hazards regression analysis
PARAMETERS:
  data= : Input dataset
  time_var= : Time to event variable
  event_var= : Event indicator (CNSR format)
  treatment_var= : Main treatment variable
  covariates= : List of covariates (space-separated)
  output_path= : Output path for results
******************************************************************************/
%macro cox_regression(
    data=,
    time_var=aval,
    event_var=cnsr,
    treatment_var=trt01pn,
    covariates=age sex,
    output_path=
);
    
    %put NOTE: Performing Cox proportional hazards regression;
    
    /* Prepare data */
    data work.cox_data;
        set &data;
        
        /* Convert CNSR to event indicator */
        if &event_var = 0 then event = 1;
        else if &event_var = 1 then event = 0;
        
        /* Remove missing values */
        if not missing(&time_var) and not missing(event);
    run;
    
    /* Cox regression analysis */
    ods output ParameterEstimates=work.cox_estimates
               HazardRatios=work.hazard_ratios
               ModelInfo=work.model_info
               GlobalTests=work.global_tests;
    
    proc phreg data=work.cox_data;
        model &time_var*event(0) = &treatment_var &covariates;
        hazardratio &treatment_var;
        title1 "Cox Proportional Hazards Regression";
        title2 "Treatment Effect Adjusted for Covariates";
    run;
    
    /* Display key results */
    proc print data=work.hazard_ratios;
        title "Hazard Ratios with 95% Confidence Intervals";
        var description hazardratio lowercl uppercl probchisq;
        format hazardratio lowercl uppercl 8.3 probchisq pvalue6.4;
    run;
    
    proc print data=work.cox_estimates;
        title "Parameter Estimates";
        var parameter estimate stderr chisq probchisq;
        format estimate stderr 8.4 chisq 8.2 probchisq pvalue6.4;
    run;
    
    /* Test proportional hazards assumption */
    proc phreg data=work.cox_data;
        model &time_var*event(0) = &treatment_var &covariates;
        assess ph / resample;
        title "Proportional Hazards Assumption Testing";
    run;
    
    /* Adjusted survival curves */
    proc phreg data=work.cox_data;
        model &time_var*event(0) = &treatment_var &covariates;
        baseline covariates=work.reference_covariates survival=work.adjusted_surv / method=pl;
        title "Adjusted Survival Curves";
    run;
    
    %put NOTE: Cox regression analysis completed;
    
%mend cox_regression;

/******************************************************************************
SECTION 3: COMPETING RISKS ANALYSIS
******************************************************************************/

/******************************************************************************
MACRO: competing_risks_analysis
PURPOSE: Analyze competing risks using cumulative incidence functions
PARAMETERS:
  data= : Input dataset
  time_var= : Time to event variable
  event_var= : Event type variable (0=censored, 1=event of interest, 2=competing event)
  group_var= : Grouping variable
******************************************************************************/
%macro competing_risks_analysis(
    data=,
    time_var=aval,
    event_var=evnttype,
    group_var=trt01p
);
    
    %put NOTE: Performing competing risks analysis;
    
    /* Prepare data */
    data work.competing_data;
        set &data;
        
        /* Ensure event variable is properly coded */
        if missing(&event_var) then &event_var = 0;
        
        /* Create event labels */
        length event_label $50;
        select (&event_var);
            when (0) event_label = "Censored";
            when (1) event_label = "Primary Event";
            when (2) event_label = "Competing Event";
            otherwise event_label = "Other";
        end;
    run;
    
    /* Cumulative incidence analysis */
    proc lifetest data=work.competing_data method=cif;
        time &time_var*&event_var(0) / eventcode=1;
        strata &group_var;
        title1 "Competing Risks Analysis";
        title2 "Cumulative Incidence Functions";
    run;
    
    /* Gray's test for comparing cumulative incidence */
    proc lifetest data=work.competing_data method=cif;
        time &time_var*&event_var(0) / eventcode=1;
        strata &group_var / test=gray;
        title "Gray's Test for Comparing Cumulative Incidence";
    run;
    
    /* Fine-Gray subdistribution hazards model */
    proc phreg data=work.competing_data;
        model &time_var*&event_var(0) = &group_var / eventcode=1;
        title "Fine-Gray Subdistribution Hazards Model";
    run;
    
    %put NOTE: Competing risks analysis completed;
    
%mend competing_risks_analysis;

/******************************************************************************
SECTION 4: PARAMETRIC SURVIVAL MODELS
******************************************************************************/

/******************************************************************************
MACRO: parametric_survival
PURPOSE: Fit parametric survival models (Weibull, Exponential, etc.)
PARAMETERS:
  data= : Input dataset
  time_var= : Time to event variable
  event_var= : Event indicator (CNSR format)
  treatment_var= : Treatment variable
  distribution= : Distribution (WEIBULL, EXPONENTIAL, LOGNORMAL, GAMMA)
******************************************************************************/
%macro parametric_survival(
    data=,
    time_var=aval,
    event_var=cnsr,
    treatment_var=trt01pn,
    distribution=WEIBULL
);
    
    %put NOTE: Fitting parametric survival model (&distribution);
    
    /* Prepare data */
    data work.param_data;
        set &data;
        
        /* Convert CNSR to event indicator */
        if &event_var = 0 then event = 1;
        else if &event_var = 1 then event = 0;
    run;
    
    /* Fit parametric model */
    ods output ParameterEstimates=work.param_estimates
               GoodnessOfFit=work.gof;
    
    proc lifereg data=work.param_data;
        model &time_var*event(0) = &treatment_var / distribution=&distribution;
        title1 "Parametric Survival Analysis";
        title2 "Distribution: &distribution";
    run;
    
    /* Model comparison using AIC/BIC */
    %let distributions = WEIBULL EXPONENTIAL LOGNORMAL GAMMA;
    %let dist_count = %sysfunc(countw(&distributions));
    
    data work.model_comparison;
        length distribution $20;
        format aic bic 10.2;
        
        %do i = 1 %to &dist_count;
            %let dist = %scan(&distributions, &i);
            
            /* Fit model and capture fit statistics */
            proc lifereg data=work.param_data outest=work.temp_est noprint;
                model &time_var*event(0) = &treatment_var / distribution=&dist;
                ods output FitStatistics=work.temp_fit;
            run;
            
            /* Extract AIC and BIC */
            data work.temp_comparison;
                set work.temp_fit;
                where criterion in ('AIC', 'SBC');
                distribution = "&dist";
                if criterion = 'AIC' then aic = value;
                if criterion = 'SBC' then bic = value;
            run;
            
            proc transpose data=work.temp_comparison out=work.temp_trans;
                by distribution;
                id criterion;
                var value;
            run;
            
            %if &i = 1 %then %do;
                data work.model_comparison;
                    set work.temp_trans;
                    rename AIC=aic SBC=bic;
                run;
            %end;
            %else %do;
                data work.model_comparison;
                    set work.model_comparison work.temp_trans(rename=(AIC=aic SBC=bic));
                run;
            %end;
        %end;
    run;
    
    proc print data=work.model_comparison;
        title "Model Comparison Using Information Criteria";
        var distribution aic bic;
    run;
    
    %put NOTE: Parametric survival analysis completed;
    
%mend parametric_survival;

/******************************************************************************
SECTION 5: SAMPLE SIZE CALCULATIONS
******************************************************************************/

/******************************************************************************
MACRO: survival_sample_size
PURPOSE: Calculate sample size for survival studies
PARAMETERS:
  hazard_ratio= : Expected hazard ratio
  control_median= : Median survival in control group (months)
  alpha= : Type I error rate (default 0.05)
  power= : Desired power (default 0.80)
  accrual_time= : Accrual period (months)
  followup_time= : Additional follow-up after accrual (months)
******************************************************************************/
%macro survival_sample_size(
    hazard_ratio=0.7,
    control_median=24,
    alpha=0.05,
    power=0.80,
    accrual_time=18,
    followup_time=12
);
    
    %put NOTE: Calculating sample size for survival study;
    
    data work.sample_size_calc;
        /* Input parameters */
        hr = &hazard_ratio;
        med_control = &control_median;
        alpha = &alpha;
        power = &power;
        accrual = &accrual_time;
        followup = &followup_time;
        
        /* Calculate control group hazard rate */
        lambda_control = log(2) / med_control;
        
        /* Calculate treatment group hazard rate */
        lambda_treatment = hr * lambda_control;
        
        /* Treatment group median */
        med_treatment = log(2) / lambda_treatment;
        
        /* Total study time */
        total_time = accrual + followup;
        
        /* Probability of event in control group */
        /* Assuming uniform accrual */
        p_event_control = 1 - (1/accrual) * (1 - exp(-lambda_control * followup)) / lambda_control +
                         (1/accrual) * (1 - exp(-lambda_control * total_time)) / lambda_control;
        
        /* Probability of event in treatment group */
        p_event_treatment = 1 - (1/accrual) * (1 - exp(-lambda_treatment * followup)) / lambda_treatment +
                           (1/accrual) * (1 - exp(-lambda_treatment * total_time)) / lambda_treatment;
        
        /* Average probability of event */
        p_event_avg = (p_event_control + p_event_treatment) / 2;
        
        /* Calculate required number of events */
        z_alpha = probit(1 - alpha/2);
        z_beta = probit(power);
        
        num_events = ((z_alpha + z_beta) / log(hr))**2;
        
        /* Calculate total sample size */
        n_total = num_events / p_event_avg;
        n_per_group = n_total / 2;
        
        /* Output results */
        format hr 8.2 med_control med_treatment 8.1 
               p_event_control p_event_treatment p_event_avg 8.3
               num_events n_total n_per_group 8.0;
        
        put "Sample Size Calculation Results:";
        put "=================================";
        put "Hazard Ratio: " hr;
        put "Control Median Survival: " med_control " months";
        put "Treatment Median Survival: " med_treatment " months";
        put "Required Events: " num_events;
        put "Total Sample Size: " n_total;
        put "Sample Size per Group: " n_per_group;
        put "Probability of Event (Control): " p_event_control;
        put "Probability of Event (Treatment): " p_event_treatment;
    run;
    
    proc print data=work.sample_size_calc;
        title "Sample Size Calculation for Survival Study";
        var hr med_control med_treatment num_events n_total n_per_group 
            p_event_control p_event_treatment;
    run;
    
    %put NOTE: Sample size calculation completed;
    
%mend survival_sample_size;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Basic Kaplan-Meier Analysis
%km_analysis(
    data=adam.adtte,
    time_var=aval,
    event_var=cnsr,
    group_var=trt01p,
    output_path=/outputs/figures/,
    title_text=Overall Survival Analysis
);

Example 2: Cox Regression
%cox_regression(
    data=adam.adtte,
    time_var=aval,
    event_var=cnsr,
    treatment_var=trt01pn,
    covariates=age sex race,
    output_path=/outputs/
);

Example 3: Competing Risks
%competing_risks_analysis(
    data=adam.adtte,
    time_var=aval,
    event_var=evnttype,
    group_var=trt01p
);

Example 4: Parametric Models
%parametric_survival(
    data=adam.adtte,
    time_var=aval,
    event_var=cnsr,
    treatment_var=trt01pn,
    distribution=WEIBULL
);

Example 5: Sample Size Calculation
%survival_sample_size(
    hazard_ratio=0.75,
    control_median=12,
    alpha=0.05,
    power=0.90,
    accrual_time=24,
    followup_time=12
);
*/

%put NOTE: Survival analysis examples loaded successfully;
%put NOTE: Available macros: km_analysis, cox_regression, competing_risks_analysis,;
%put NOTE:                  parametric_survival, survival_sample_size;