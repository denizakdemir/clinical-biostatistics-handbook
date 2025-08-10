# SAS Macro Library for Advanced Statistical Methods

## Survival Analysis Macros

### Comprehensive Survival Analysis Macro

```sas
/******************************************************************************
MACRO: survival_analysis
PURPOSE: Comprehensive survival analysis with diagnostics
PARAMETERS:
  data= : Input dataset
  time= : Time variable  
  censor= : Censoring variable (1=event, 0=censored)
  group= : Grouping variable for comparison
  covars= : List of covariates for Cox model
  plots= : Y/N for producing plots
  outpath= : Output path for results
******************************************************************************/

%macro survival_analysis(data=, time=, censor=, group=, covars=, plots=Y, outpath=);

    /* Step 1: Data validation */
    %if %length(&data) = 0 %then %do;
        %put ERROR: Dataset name required;
        %return;
    %end;
    
    %if not %sysfunc(exist(&data)) %then %do;
        %put ERROR: Dataset &data does not exist;
        %return;
    %end;
    
    /* Step 2: Kaplan-Meier Analysis */
    ods output ProductLimitEstimates=km_estimates
               Quartiles=km_quartiles
               HomTests=logrank_test;
               
    proc lifetest data=&data plots=%if &plots=Y %then survival(atrisk); %else none;;
        time &time*&censor(0);
        %if %length(&group) > 0 %then %do;
            strata &group / test=(logrank wilcoxon tarone);
        %end;
        title "Kaplan-Meier Survival Analysis";
    run;
    
    /* Step 3: Cox Proportional Hazards Model */
    %if %length(&group) > 0 or %length(&covars) > 0 %then %do;
        
        /* Basic Cox model */
        ods output ParameterEstimates=cox_estimates
                   HazardRatios=hazard_ratios;
                   
        proc phreg data=&data plots=%if &plots=Y %then (survival); %else none;;
            model &time*&censor(0) = &group &covars / rl ties=efron;
            
            /* Hazard ratios */
            %if %length(&group) > 0 %then %do;
                hazardratio "&group" &group / diff=ref;
            %end;
            
            title "Cox Proportional Hazards Analysis";
        run;
        
        /* Proportional hazards assumption test */
        ods output ResampPHTest=ph_test;
        
        proc phreg data=&data;
            model &time*&censor(0) = &group &covars;
            assess ph / resample seed=54321;
            title "Proportional Hazards Assumption Testing";
        run;
        
    %end;
    
    /* Step 4: Parametric survival models if requested */
    %if %length(&group) > 0 %then %do;
        
        /* Weibull AFT model */
        ods output ParameterEstimates=weibull_est
                   FitStatistics=weibull_fit;
                   
        proc lifereg data=&data;
            model &time*&censor(0) = &group &covars / distribution=weibull;
            title "Weibull Accelerated Failure Time Model";
        run;
        
        /* Log-normal AFT model */
        ods output ParameterEstimates=lognormal_est
                   FitStatistics=lognormal_fit;
                   
        proc lifereg data=&data;
            model &time*&censor(0) = &group &covars / distribution=lognormal;
            title "Log-normal Accelerated Failure Time Model";
        run;
        
    %end;
    
    /* Step 5: Create summary report */
    data survival_summary;
        length analysis $50 parameter $50 estimate 8 ci_lower 8 ci_upper 8 pvalue 8;
        
        /* Add Kaplan-Meier results */
        set km_quartiles;
        analysis = "Kaplan-Meier";
        parameter = strip(&group) || " Median Survival";
        estimate = Estimate;
        ci_lower = LowerLimit;
        ci_upper = UpperLimit;
        pvalue = .;
        output;
        
        /* Add log-rank test results */
        %if %length(&group) > 0 %then %do;
            set logrank_test;
            if Test = 'Log-Rank';
            analysis = "Log-Rank Test";
            parameter = "Overall Test";
            estimate = .;
            ci_lower = .;
            ci_upper = .;
            pvalue = ProbChiSq;
            output;
        %end;
        
        /* Add Cox model results */
        %if %length(&group) > 0 %then %do;
            set hazard_ratios;
            analysis = "Cox Model";
            parameter = strip(Description);
            estimate = HazardRatio;
            ci_lower = LowerCL;
            ci_upper = UpperCL;
            pvalue = ProbChiSq;
            output;
        %end;
    run;
    
    /* Step 6: Output results */
    %if %length(&outpath) > 0 %then %do;
        
        proc export data=survival_summary
                    outfile="&outpath/survival_analysis_summary.xlsx"
                    dbms=xlsx replace;
        run;
        
        proc export data=km_estimates  
                    outfile="&outpath/kaplan_meier_estimates.xlsx"
                    dbms=xlsx replace;
        run;
        
        %if %length(&group) > 0 %then %do;
            proc export data=cox_estimates
                        outfile="&outpath/cox_model_results.xlsx"
                        dbms=xlsx replace;
            run;
        %end;
        
    %end;
    
    /* Step 7: Print summary to log */
    proc print data=survival_summary noobs;
        title "Survival Analysis Summary";
        format estimate ci_lower ci_upper 8.3 pvalue pvalue6.4;
    run;
    
    title;

%mend survival_analysis;

/* Example usage */
%survival_analysis(
    data=sashelp.bmt,
    time=T,
    censor=Status,
    group=Group,
    covars=,
    plots=Y,
    outpath=/results/survival
);
```

### Cox Model Diagnostics Macro

```sas
/******************************************************************************
MACRO: cox_diagnostics
PURPOSE: Comprehensive Cox model diagnostic testing
******************************************************************************/

%macro cox_diagnostics(data=, time=, censor=, covars=, outpath=);

    /* Fit Cox model and output diagnostics */
    ods output ParameterEstimates=cox_params;
    
    proc phreg data=&data;
        model &time*&censor(0) = &covars / rl;
        
        /* Output residuals */
        output out=cox_residuals 
               ressch=sch_: 
               resmart=mart_resid
               resdev=dev_resid
               ressco=sco_:;
        
        /* Proportional hazards assessment */
        assess ph / resample seed=12345;
        
        /* Global model test */
        test &covars;
    run;
    
    /* Schoenfeld residual plots */
    %let nvar = %sysfunc(countw(&covars));
    %do i = 1 %to &nvar;
        %let var = %scan(&covars, &i);
        
        proc sgplot data=cox_residuals;
            scatter x=&time y=sch_&var;
            loess x=&time y=sch_&var / smooth=0.5;
            title "Schoenfeld Residuals for &var";
            xaxis label="Time";
            yaxis label="Schoenfeld Residual";
        run;
    %end;
    
    /* Martingale residual plots */
    proc sgplot data=cox_residuals;
        scatter x=mart_resid y=dev_resid;
        title "Martingale vs Deviance Residuals";
        xaxis label="Martingale Residuals";
        yaxis label="Deviance Residuals";
    run;
    
    /* Output results */
    %if %length(&outpath) > 0 %then %do;
        proc export data=cox_residuals
                    outfile="&outpath/cox_residuals.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend cox_diagnostics;
```

## Longitudinal Data Analysis Macros

### Mixed Models for Repeated Measures (MMRM) Macro

```sas
/******************************************************************************
MACRO: mmrm_analysis
PURPOSE: Comprehensive MMRM analysis with multiple covariance structures
******************************************************************************/

%macro mmrm_analysis(data=, response=, treatment=, visit=, baseline=, 
                     subject=, covars=, structures=UN CS AR(1) TOEP, 
                     outpath=);

    /* Validate inputs */
    %if %length(&data) = 0 or %length(&response) = 0 or %length(&treatment) = 0 %then %do;
        %put ERROR: Required parameters missing;
        %return;
    %end;
    
    /* Initialize datasets for model comparison */
    data model_comparison;
        length structure $20 negloglik 8 aic 8 bic 8 parameters 8;
        stop;
    run;
    
    /* Loop through covariance structures */
    %let nstruct = %sysfunc(countw(&structures));
    %do i = 1 %to &nstruct;
        %let struct = %scan(&structures, &i);
        %let struct_name = %sysfunc(translate(&struct, _, %str(%(%)) ));
        
        ods output FitStatistics=fit_&struct_name
                   SolutionF=solution_&struct_name
                   LSMeans=lsmeans_&struct_name
                   Diffs=diffs_&struct_name;
        
        proc mixed data=&data method=ml;
            class &subject &treatment &visit;
            model &response = &treatment &visit &treatment*&visit 
                  %if %length(&baseline) > 0 %then &baseline;
                  %if %length(&covars) > 0 %then &covars;
                  / ddfm=kr solution;
            repeated &visit / subject=&subject type=&struct;
            lsmeans &treatment*&visit / pdiff slice=&visit;
            
            title "MMRM Analysis - &struct Covariance Structure";
        run;
        
        /* Extract fit statistics */
        data temp_fit;
            set fit_&struct_name;
            structure = "&struct";
            if Descr = '-2 Log Likelihood' then negloglik = Value;
            else if Descr = 'AIC (smaller is better)' then aic = Value;
            else if Descr = 'BIC (smaller is better)' then bic = Value;
            else if Descr = 'Number of Estimated Parameters' then parameters = Value;
            keep structure negloglik aic bic parameters;
        run;
        
        proc sql noprint;
            insert into model_comparison
            select structure, negloglik, aic, bic, parameters
            from temp_fit
            where not missing(aic);
        quit;
        
    %end;
    
    /* Select best model based on AIC */
    proc sort data=model_comparison;
        by aic;
    run;
    
    data _null_;
        set model_comparison(obs=1);
        call symputx('best_structure', structure);
        put "Best covariance structure by AIC: " structure;
    run;
    
    /* Refit best model with REML */
    %let best_struct = %sysfunc(translate(&best_structure, _, %str(%(%)) ));
    
    ods output SolutionF=final_solution
               LSMeans=final_lsmeans  
               Diffs=final_diffs
               CovParms=final_covparms;
    
    proc mixed data=&data method=reml plots=(residualpanel);
        class &subject &treatment &visit;
        model &response = &treatment &visit &treatment*&visit
              %if %length(&baseline) > 0 %then &baseline;
              %if %length(&covars) > 0 %then &covars;
              / ddfm=kr solution residual outpred=mmrm_predicted;
        repeated &visit / subject=&subject type=&best_structure rcorr;
        lsmeans &treatment*&visit / pdiff slice=&visit cl;
        estimate 'Treatment at Final Visit' &treatment 1 -1 &treatment*&visit 0 0 1 0 0 -1;
        
        title "Final MMRM Analysis - &best_structure Covariance";
    run;
    
    /* Model diagnostics */
    proc sgplot data=mmrm_predicted;
        scatter x=pred y=resid;
        loess x=pred y=resid;
        title "Residuals vs Predicted Values";
        xaxis label="Predicted Values";
        yaxis label="Residuals";
    run;
    
    proc univariate data=mmrm_predicted normal;
        var resid;
        histogram resid / normal;
        qqplot resid / normal(mu=0 sigma=est);
        title "Residual Distribution Assessment";
    run;
    
    /* Output results */
    %if %length(&outpath) > 0 %then %do;
        
        proc export data=model_comparison
                    outfile="&outpath/mmrm_model_comparison.xlsx"
                    dbms=xlsx replace;
        run;
        
        proc export data=final_lsmeans
                    outfile="&outpath/mmrm_lsmeans.xlsx" 
                    dbms=xlsx replace;
        run;
        
        proc export data=final_diffs
                    outfile="&outpath/mmrm_treatment_differences.xlsx"
                    dbms=xlsx replace;
        run;
        
    %end;
    
    /* Summary report */
    proc print data=model_comparison noobs;
        title "Covariance Structure Comparison";
        format aic bic negloglik 8.1;
    run;
    
    proc print data=final_diffs noobs;
        where &visit = %scan(&structures, -1); /* Last visit */
        title "Treatment Differences at Final Visit";
        var estimate stderr tvalue probt lower upper;
        format estimate stderr lower upper 8.3 probt pvalue6.4;
    run;

%mend mmrm_analysis;
```

### GEE Analysis Macro

```sas
/******************************************************************************
MACRO: gee_analysis  
PURPOSE: Generalized Estimating Equations analysis
******************************************************************************/

%macro gee_analysis(data=, response=, treatment=, visit=, subject=, 
                    dist=normal, link=identity, corr=unstr, outpath=);

    /* Fit GEE model */
    ods output GEEEmpPEst=gee_estimates
               GEEWCorr=working_corr;
    
    proc genmod data=&data;
        class &subject &treatment &visit;
        model &response = &treatment &visit &treatment*&visit / 
              dist=&dist link=&link type3;
        repeated subject=&subject / withinsubject=&visit type=&corr 
                 corrw modelse;
        
        /* Contrasts for treatment effects */
        %if &dist = binomial %then %do;
            estimate 'Treatment OR at Final Visit' &treatment 1 
                     &treatment*&visit 0 0 1 / exp;
        %end;
        %else %do;
            estimate 'Treatment Difference at Final Visit' &treatment 1 
                     &treatment*&visit 0 0 1;
        %end;
        
        title "GEE Analysis - &dist distribution, &corr correlation";
    run;
    
    /* Assess correlation structure */
    proc print data=working_corr noobs;
        title "Working Correlation Matrix";
    run;
    
    /* Output results */  
    %if %length(&outpath) > 0 %then %do;
        proc export data=gee_estimates
                    outfile="&outpath/gee_parameter_estimates.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend gee_analysis;
```

## Adaptive Design Macros

### Group Sequential Design Macro

```sas
/******************************************************************************
MACRO: group_sequential_design
PURPOSE: Design and monitor group sequential trials
******************************************************************************/

%macro group_sequential_design(design_phase=DESIGN, 
                               nstages=3, method=errfuncobf, 
                               alpha=0.025, beta=0.10, altref=,
                               test_stats=, info_times=, 
                               outpath=);

    %if &design_phase = DESIGN %then %do;
        
        /* Design phase - create boundaries */
        ods output Boundary=gs_boundary
                   SampleSizes=gs_samplesize;
        
        proc seqdesign altref=&altref pss plots=boundary;
            GroupSequential: design nstages=&nstages
                            method=&method  
                            alpha=&alpha beta=&beta;
            samplesize model=twosamplemean(stddev=1);
        run;
        
        /* Output design */
        %if %length(&outpath) > 0 %then %do;
            proc export data=gs_boundary
                        outfile="&outpath/group_sequential_boundaries.xlsx"
                        dbms=xlsx replace;
            run;
        %end;
        
    %end;
    
    %else %if &design_phase = MONITOR %then %do;
        
        /* Monitoring phase - test boundaries */
        %if %length(&test_stats) = 0 or %length(&info_times) = 0 %then %do;
            %put ERROR: Test statistics and information times required for monitoring;
            %return;
        %end;
        
        ods output Test=gs_test_results
                   ConditionalPower=conditional_power;
        
        proc seqtest boundary=gs_boundary plots=test;
            TwoSampleMean: test statistic=(&test_stats)
                          info=(&info_times)
                          boundaryscale=stdz
                          ;
        run;
        
        /* Output monitoring results */
        proc print data=gs_test_results noobs;
            title "Group Sequential Test Results";
        run;
        
        proc print data=conditional_power noobs;
            title "Conditional Power Assessment";
        run;
        
        %if %length(&outpath) > 0 %then %do;
            proc export data=gs_test_results
                        outfile="&outpath/gs_test_results.xlsx"
                        dbms=xlsx replace;
            run;
        %end;
        
    %end;

%mend group_sequential_design;
```

### Sample Size Re-estimation Macro

```sas
/******************************************************************************
MACRO: sample_size_reestimation
PURPOSE: Blinded sample size re-estimation
******************************************************************************/

%macro sample_size_reestimation(data=, response=, treatment=, 
                                original_n=, target_power=0.80, 
                                alpha=0.025, target_effect=,
                                max_inflation=2.0, outpath=);

    /* Estimate pooled variance (blinded) */
    proc mixed data=&data method=ml;
        model &response = / solution;
        ods output CovParms=variance_est;
    run;
    
    data _null_;
        set variance_est;
        if CovParm = 'Residual';
        
        /* Calculate inflation factor */
        observed_var = Estimate;
        
        /* Assumed variance (set based on original assumptions) */
        assumed_var = 1.0; /* Update based on original sample size calculation */
        
        inflation_factor = observed_var / assumed_var;
        new_n_per_arm = ceil(&original_n * inflation_factor);
        
        /* Cap inflation */
        if inflation_factor > &max_inflation then do;
            inflation_factor = &max_inflation;
            new_n_per_arm = ceil(&original_n * &max_inflation);
        end;
        
        call symputx('inflation_factor', put(inflation_factor, 8.3));
        call symputx('new_n_per_arm', put(new_n_per_arm, 8.));
        call symputx('observed_sd', put(sqrt(observed_var), 8.3));
        
        put "Original sample size per arm: &original_n";
        put "Observed standard deviation: " observed_sd;
        put "Inflation factor: " inflation_factor;
        put "Recommended sample size per arm: " new_n_per_arm;
    run;
    
    /* Calculate power with new sample size */
    proc power;
        twosamplemean test=diff
                     meandiff=&target_effect
                     stddev=&observed_sd
                     ntotal=%eval(2*&new_n_per_arm)
                     alpha=&alpha
                     power=.;
        ods output Output=power_calculation;
    run;
    
    /* Create summary report */
    data ssr_summary;
        length parameter $50 value $20;
        
        parameter = 'Original Sample Size per Arm'; value = "&original_n"; output;
        parameter = 'Observed Standard Deviation'; value = "&observed_sd"; output;  
        parameter = 'Variance Inflation Factor'; value = "&inflation_factor"; output;
        parameter = 'New Sample Size per Arm'; value = "&new_n_per_arm"; output;
    run;
    
    /* Merge with power calculation */
    data final_ssr_summary;
        set ssr_summary;
        set power_calculation(keep=Power rename=(Power=calculated_power));
        if _n_ = 4 then do;
            parameter = 'Achieved Power'; 
            value = put(calculated_power, percent8.1); 
            output;
        end;
        drop calculated_power;
    run;
    
    proc print data=final_ssr_summary noobs;
        title "Sample Size Re-estimation Summary";
    run;
    
    /* Output results */
    %if %length(&outpath) > 0 %then %do;
        proc export data=final_ssr_summary
                    outfile="&outpath/sample_size_reestimation.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend sample_size_reestimation;
```

## Bayesian Analysis Macros

### Bayesian Two-Sample Comparison

```sas
/******************************************************************************
MACRO: bayesian_two_sample  
PURPOSE: Bayesian analysis for two-sample comparison
******************************************************************************/

%macro bayesian_two_sample(data=, response=, group=, 
                          prior_mean=0, prior_var=100, 
                          nbi=2000, nmc=10000, seed=54321,
                          decision_threshold=0, prob_threshold=0.975,
                          outpath=);

    /* Bayesian analysis using PROC MCMC */
    ods output PostSummaries=posterior_summaries
               PostIntervals=posterior_intervals;
    
    proc mcmc data=&data nbi=&nbi nmc=&nmc seed=&seed 
              plots=(trace autocorr density);
        
        /* Parameters */
        parms mu_1 0 mu_2 0 sigma2 1;
        
        /* Priors */
        prior mu_1 ~ normal(&prior_mean, var=&prior_var);
        prior mu_2 ~ normal(&prior_mean, var=&prior_var);  
        prior sigma2 ~ igamma(0.01, s=0.01);
        
        /* Likelihood */
        if &group = 1 then
            model &response ~ normal(mu_1, var=sigma2);
        else if &group = 2 then
            model &response ~ normal(mu_2, var=sigma2);
            
        /* Derived quantities */
        diff = mu_1 - mu_2;
        
        title "Bayesian Two-Sample Analysis";
    run;
    
    /* Calculate probabilities of interest */
    data posterior_probs;
        set posterior_summaries;
        
        if Parameter = 'diff' then do;
            /* Probability of positive difference */
            prob_positive = 1 - probnorm(&decision_threshold, Mean, StdDev);
            
            /* Probability of clinically meaningful difference */
            prob_meaningful = 1 - probnorm(1.0, Mean, StdDev);
            
            /* Probability of harm */
            prob_harm = probnorm(-0.5, Mean, StdDev);
            
            /* Decision based on probability threshold */
            if prob_positive > &prob_threshold then 
                decision = 'Conclude Benefit';
            else if prob_harm > (1-&prob_threshold) then
                decision = 'Conclude Harm';  
            else
                decision = 'Inconclusive';
                
            output;
        end;
        
        keep Parameter Mean StdDev prob_positive prob_meaningful prob_harm decision;
    run;
    
    proc print data=posterior_probs noobs;
        title "Bayesian Decision Analysis";
        format prob_positive prob_meaningful prob_harm percent8.1;
    run;
    
    /* Output results */
    %if %length(&outpath) > 0 %then %do;
        proc export data=posterior_summaries
                    outfile="&outpath/bayesian_posterior_summaries.xlsx"
                    dbms=xlsx replace;
        run;
        
        proc export data=posterior_probs
                    outfile="&outpath/bayesian_decisions.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend bayesian_two_sample;
```

### Bayesian Historical Data Borrowing

```sas
/******************************************************************************
MACRO: bayesian_borrowing
PURPOSE: Borrow strength from historical control data
******************************************************************************/

%macro bayesian_borrowing(current_data=, historical_mean=, historical_n=, 
                         historical_var=, power_prior_weight=0.5,
                         response=, treatment=, nbi=2000, nmc=10000,
                         outpath=);

    /* Power prior analysis */
    ods output PostSummaries=borrowing_results;
    
    proc mcmc data=&current_data nbi=&nbi nmc=&nmc seed=12345;
        
        /* Current study parameters */
        parms mu_trt 0 mu_ctrl 0 sigma2 1;
        
        /* Power prior for control group */
        /* Effective sample size = power_prior_weight * historical_n */
        historical_precision = &power_prior_weight * &historical_n / &historical_var;
        
        prior mu_ctrl ~ normal(&historical_mean, var=1/historical_precision);
        prior mu_trt ~ normal(0, var=100);  /* Non-informative for treatment */
        prior sigma2 ~ igamma(0.01, s=0.01);
        
        /* Likelihood for current data */
        if &treatment = 'Control' then
            model &response ~ normal(mu_ctrl, var=sigma2);
        else if &treatment = 'Treatment' then  
            model &response ~ normal(mu_trt, var=sigma2);
            
        /* Treatment effect */
        treatment_effect = mu_trt - mu_ctrl;
        
        title "Bayesian Analysis with Historical Borrowing";
    run;
    
    /* Compare with non-borrowing analysis */
    ods output PostSummaries=no_borrowing_results;
    
    proc mcmc data=&current_data nbi=&nbi nmc=&nmc seed=12345;
        
        parms mu_trt 0 mu_ctrl 0 sigma2 1;
        
        /* Non-informative priors */
        prior mu_ctrl ~ normal(0, var=100);
        prior mu_trt ~ normal(0, var=100);
        prior sigma2 ~ igamma(0.01, s=0.01);
        
        if &treatment = 'Control' then
            model &response ~ normal(mu_ctrl, var=sigma2);
        else if &treatment = 'Treatment' then
            model &response ~ normal(mu_trt, var=sigma2);
            
        treatment_effect = mu_trt - mu_ctrl;
        
        title "Bayesian Analysis without Historical Borrowing";
    run;
    
    /* Compare results */
    data comparison;
        length analysis $30 parameter $20;
        
        set borrowing_results(in=a) no_borrowing_results(in=b);
        
        if a then analysis = 'With Historical Borrowing';
        if b then analysis = 'Without Historical Borrowing';
        
        if Parameter = 'treatment_effect';
        
        keep analysis Mean StdDev HPDLower HPDUpper;
    run;
    
    proc print data=comparison noobs;
        title "Comparison of Borrowing vs Non-Borrowing";
        format Mean StdDev HPDLower HPDUpper 8.3;
    run;
    
    %if %length(&outpath) > 0 %then %do;
        proc export data=comparison
                    outfile="&outpath/borrowing_comparison.xlsx" 
                    dbms=xlsx replace;
        run;
    %end;

%mend bayesian_borrowing;
```

## Utility Macros

### Model Comparison and Selection

```sas
/******************************************************************************
MACRO: model_comparison
PURPOSE: Compare multiple statistical models using information criteria
******************************************************************************/

%macro model_comparison(models=, criteria=AIC BIC, outpath=);

    /* Initialize comparison dataset */
    data model_comp;
        length model_name $50;
        %do i = 1 %to %sysfunc(countw(&criteria));
            %let crit = %scan(&criteria, &i);
            &crit = .;
        %end;
        stop;
    run;
    
    /* Extract fit statistics from each model */
    %let nmodels = %sysfunc(countw(&models));
    %do i = 1 %to &nmodels;
        %let model = %scan(&models, &i);
        
        /* Assume fit statistics are stored in datasets named fit_&model */
        %if %sysfunc(exist(fit_&model)) %then %do;
            data temp_&model;
                set fit_&model;
                model_name = "&model";
                
                /* Extract relevant criteria */
                %do j = 1 %to %sysfunc(countw(&criteria));
                    %let crit = %scan(&criteria, &j);
                    if index(upcase(Descr), upcase("&crit")) then &crit = Value;
                %end;
                
                keep model_name %do k = 1 %to %sysfunc(countw(&criteria)); 
                                    %scan(&criteria, &k) 
                                %end;;
            run;
            
            proc sql;
                insert into model_comp
                select model_name, %do l = 1 %to %sysfunc(countw(&criteria));
                                       %if &l > 1 %then ,;
                                       max(%scan(&criteria, &l))
                                   %end;
                from temp_&model
                group by model_name;
            quit;
        %end;
    %end;
    
    /* Rank models by each criterion */
    %do m = 1 %to %sysfunc(countw(&criteria));
        %let crit = %scan(&criteria, &m);
        
        proc rank data=model_comp out=temp_rank;
            var &crit;
            ranks &crit._rank;
        run;
        
        data model_comp;
            merge model_comp temp_rank;
            by model_name;
        run;
    %end;
    
    /* Print comparison */
    proc print data=model_comp noobs;
        title "Model Comparison";
        format %do n = 1 %to %sysfunc(countw(&criteria));
                   %scan(&criteria, &n) 8.1
               %end;;
    run;
    
    %if %length(&outpath) > 0 %then %do;
        proc export data=model_comp
                    outfile="&outpath/model_comparison.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend model_comparison;
```

### Effect Size Calculation Macro

```sas
/******************************************************************************
MACRO: effect_sizes
PURPOSE: Calculate various effect size measures
******************************************************************************/

%macro effect_sizes(data=, response=, group=, type=continuous, outpath=);

    %if &type = continuous %then %do;
        
        /* Two-sample t-test with effect sizes */
        proc ttest data=&data cochran ci=equal umpu;
            class &group;
            var &response;
            ods output TTests=ttest_results
                       Statistics=desc_stats;
        run;
        
        /* Calculate effect sizes */
        data effect_sizes;
            merge ttest_results desc_stats;
            
            /* Cohen's d */
            cohens_d = Estimate / sqrt(((N1-1)*Std1**2 + (N2-1)*Std2**2)/(N1+N2-2));
            
            /* Glass's delta */
            glass_delta = Estimate / Std2; /* Using control group SD */
            
            /* Hedges' g */
            pooled_sd = sqrt(((N1-1)*Std1**2 + (N2-1)*Std2**2)/(N1+N2-2));
            correction = 1 - (3/(4*(N1+N2-2)-1));
            hedges_g = cohens_d * correction;
            
            /* Effect size interpretation */
            if abs(cohens_d) < 0.2 then effect_magnitude = 'Negligible';
            else if abs(cohens_d) < 0.5 then effect_magnitude = 'Small';
            else if abs(cohens_d) < 0.8 then effect_magnitude = 'Medium';
            else effect_magnitude = 'Large';
            
            keep cohens_d glass_delta hedges_g effect_magnitude;
        run;
        
    %end;
    
    %else %if &type = binary %then %do;
        
        /* Binary outcome effect sizes */
        proc freq data=&data;
            tables &group*&response / relrisk;
            ods output RelativeRisks=rr_results
                       CrossTabFreqs=freq_results;
        run;
        
        data binary_effects;
            set rr_results;
            
            /* Add odds ratio calculation */
            /* This would be extracted from PROC FREQ output */
            
            /* Risk difference */
            /* This would be calculated from frequency table */
            
            /* Number needed to treat */
            if RiskDifference ne 0 then NNT = 1 / abs(RiskDifference);
            
        run;
        
    %end;
    
    /* Output results */
    proc print data=effect_sizes noobs;
        title "Effect Size Measures";
        %if &type = continuous %then %do;
            format cohens_d glass_delta hedges_g 8.3;
        %end;
    run;
    
    %if %length(&outpath) > 0 %then %do;
        proc export data=effect_sizes
                    outfile="&outpath/effect_sizes.xlsx"
                    dbms=xlsx replace;
        run;
    %end;

%mend effect_sizes;
```

## Usage Examples and Best Practices

### Example Analysis Workflow

```sas
/* Set up libraries and options */
libname study '/studies/abc001/data';
libname results '/studies/abc001/results';

options mprint mlogic symbolgen;

/* Include macro library */
%include '/macros/survival_analysis.sas';
%include '/macros/mmrm_analysis.sas';
%include '/macros/group_sequential_design.sas';

/* Example 1: Comprehensive survival analysis */
%survival_analysis(
    data=study.survival_data,
    time=os_time,
    censor=os_event,
    group=treatment,
    covars=age sex stage,
    plots=Y,
    outpath=/studies/abc001/results/survival
);

/* Example 2: Longitudinal analysis */
%mmrm_analysis(
    data=study.longitudinal_data,
    response=change_from_baseline,
    treatment=treatment_group,
    visit=analysis_visit,
    baseline=baseline_value,
    subject=usubjid,
    covars=age_group sex,
    outpath=/studies/abc001/results/mmrm
);

/* Example 3: Adaptive design monitoring */
%group_sequential_design(
    design_phase=MONITOR,
    test_stats=2.1 1.8,
    info_times=0.5 0.75,
    outpath=/studies/abc001/results/adaptive
);
```

### Macro Documentation Standards

```sas
/******************************************************************************
MACRO NAME: [macro_name]
PURPOSE: [Brief description of macro functionality]

PARAMETERS:
  REQUIRED:
    data=        Dataset name
    response=    Response variable name
    
  OPTIONAL:  
    outpath=     Output path for results (default: none)
    plots=       Generate plots Y/N (default: Y)
    
OUTPUTS:
  - [List of output datasets created]
  - [List of files exported if outpath specified]
  - [Printed results to log/output window]
  
DEPENDENCIES:
  - SAS/STAT procedures required
  - Other macros called
  
EXAMPLES:
  %macro_name(data=test, response=outcome);
  
NOTES:
  - [Special considerations]
  - [Limitations or assumptions]
  
AUTHOR: [Name]
DATE: [Creation date]
MODIFIED: [Modification history]
******************************************************************************/
```

### Error Handling Best Practices

```sas
/* Standard error checking template */
%macro error_check_template(data=, required_vars=);

    /* Check if dataset exists */
    %if %length(&data) = 0 %then %do;
        %put ERROR: Dataset parameter required;
        %goto exit;
    %end;
    
    %if not %sysfunc(exist(&data)) %then %do;
        %put ERROR: Dataset &data does not exist;
        %goto exit;
    %end;
    
    /* Check for required variables */
    %let nvars = %sysfunc(countw(&required_vars));
    %do i = 1 %to &nvars;
        %let var = %scan(&required_vars, &i);
        
        %if %sysfunc(varnum(%sysfunc(open(&data)), &var)) = 0 %then %do;
            %put ERROR: Variable &var not found in dataset &data;
            %goto exit;
        %end;
    %end;
    
    /* Check for observations */
    %let dsid = %sysfunc(open(&data));
    %let nobs = %sysfunc(attrn(&dsid, nobs));
    %let rc = %sysfunc(close(&dsid));
    
    %if &nobs = 0 %then %do;
        %put WARNING: Dataset &data has no observations;
    %end;
    
    %exit:

%mend error_check_template;
```

---

*These SAS macros provide a comprehensive library for advanced statistical methods in clinical trials. Customize based on specific study requirements and organizational standards. Regular testing and validation of macros is recommended before production use.*