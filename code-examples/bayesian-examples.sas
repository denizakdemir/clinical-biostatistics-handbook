/******************************************************************************
PROGRAM: bayesian-examples.sas
PURPOSE: Bayesian analysis examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides practical examples of Bayesian methods in clinical trials,
including Bayesian adaptive designs, posterior probability calculations,
credible intervals, and predictive probability assessments.

SECTIONS INCLUDED:
1. Bayesian Basics and Prior Specification
2. Bayesian Analysis for Binary Endpoints
3. Bayesian Analysis for Continuous Endpoints
4. Bayesian Adaptive Designs
5. Bayesian Sample Size Determination
6. Bayesian Hierarchical Models
******************************************************************************/

/******************************************************************************
SECTION 1: BAYESIAN BASICS AND PRIOR SPECIFICATION
******************************************************************************/

/******************************************************************************
MACRO: bayesian_binary_single_arm
PURPOSE: Bayesian analysis for single-arm trial with binary endpoint
PARAMETERS:
  n_success= : Number of successes
  n_total= : Total sample size
  prior_alpha= : Beta prior alpha parameter (default=1 for uniform)
  prior_beta= : Beta prior beta parameter (default=1 for uniform)
  target_rate= : Target response rate for comparison
  credible_level= : Credible interval level (default=0.95)
******************************************************************************/
%macro bayesian_binary_single_arm(
    n_success=,
    n_total=,
    prior_alpha=1,
    prior_beta=1,
    target_rate=0.3,
    credible_level=0.95
);
    
    %put NOTE: Performing Bayesian analysis for binary endpoint;
    %put NOTE: Prior: Beta(&prior_alpha, &prior_beta);
    %put NOTE: Data: &n_success successes out of &n_total;
    
    /* Calculate posterior parameters */
    %let post_alpha = %sysevalf(&prior_alpha + &n_success);
    %let post_beta = %sysevalf(&prior_beta + &n_total - &n_success);
    
    %put NOTE: Posterior: Beta(&post_alpha, &post_beta);
    
    /* Create dataset with posterior distribution */
    data work.posterior_dist;
        /* Posterior parameters */
        post_alpha = &post_alpha;
        post_beta = &post_beta;
        
        /* Point estimates */
        posterior_mean = post_alpha / (post_alpha + post_beta);
        posterior_mode = (post_alpha - 1) / (post_alpha + post_beta - 2);
        
        /* Credible interval */
        lower_ci = quantile('beta', (1-&credible_level)/2, post_alpha, post_beta);
        upper_ci = quantile('beta', 1-(1-&credible_level)/2, post_alpha, post_beta);
        
        /* Probability of exceeding target */
        prob_exceed_target = 1 - cdf('beta', &target_rate, post_alpha, post_beta);
        
        /* Format output */
        format posterior_mean posterior_mode lower_ci upper_ci 
               prob_exceed_target percent10.2;
    run;
    
    /* Display results */
    proc print data=work.posterior_dist noobs;
        title1 "Bayesian Analysis Results - Binary Endpoint";
        title2 "Prior: Beta(&prior_alpha, &prior_beta)";
        title3 "Data: &n_success/&n_total";
        var posterior_mean posterior_mode lower_ci upper_ci prob_exceed_target;
    run;
    
    /* Plot posterior distribution */
    data work.posterior_plot;
        do p = 0 to 1 by 0.001;
            density = pdf('beta', p, &post_alpha, &post_beta);
            output;
        end;
    run;
    
    proc sgplot data=work.posterior_plot;
        series x=p y=density / lineattrs=(thickness=2);
        refline &target_rate / axis=x label="Target Rate" 
                              lineattrs=(pattern=dash);
        refline &posterior_mean / axis=x label="Posterior Mean" 
                                lineattrs=(color=red);
        xaxis label="Response Rate" values=(0 to 1 by 0.1);
        yaxis label="Posterior Density";
        title "Posterior Distribution of Response Rate";
    run;
    
%mend bayesian_binary_single_arm;

/******************************************************************************
MACRO: bayesian_binary_two_arm
PURPOSE: Bayesian comparison of two arms with binary endpoints
PARAMETERS:
  n1_success= : Number of successes in arm 1
  n1_total= : Total sample size in arm 1
  n2_success= : Number of successes in arm 2  
  n2_total= : Total sample size in arm 2
  prior_alpha= : Common prior alpha (default=1)
  prior_beta= : Common prior beta (default=1)
  n_simulations= : Number of posterior samples (default=10000)
******************************************************************************/
%macro bayesian_binary_two_arm(
    n1_success=,
    n1_total=,
    n2_success=,
    n2_total=,
    prior_alpha=1,
    prior_beta=1,
    n_simulations=10000
);
    
    %put NOTE: Bayesian comparison of two arms;
    
    /* Calculate posterior parameters */
    %let post1_alpha = %sysevalf(&prior_alpha + &n1_success);
    %let post1_beta = %sysevalf(&prior_beta + &n1_total - &n1_success);
    %let post2_alpha = %sysevalf(&prior_alpha + &n2_success);
    %let post2_beta = %sysevalf(&prior_beta + &n2_total - &n2_success);
    
    /* Generate posterior samples */
    data work.posterior_samples;
        do i = 1 to &n_simulations;
            /* Sample from posterior distributions */
            p1 = rand('beta', &post1_alpha, &post1_beta);
            p2 = rand('beta', &post2_alpha, &post2_beta);
            
            /* Calculate differences and ratios */
            diff = p1 - p2;
            ratio = p1 / p2;
            odds_ratio = (p1/(1-p1)) / (p2/(1-p2));
            
            /* Indicators */
            p1_greater = (p1 > p2);
            
            output;
        end;
    run;
    
    /* Summarize results */
    proc means data=work.posterior_samples noprint;
        var p1 p2 diff ratio odds_ratio p1_greater;
        output out=work.summary
               mean=mean_p1 mean_p2 mean_diff mean_ratio mean_or prob_p1_greater
               p2.5=p2_5_p1 p2_5_p2 p2_5_diff p2_5_ratio p2_5_or .
               p97.5=p97_5_p1 p97_5_p2 p97_5_diff p97_5_ratio p97_5_or .;
    run;
    
    /* Format and display results */
    data work.results;
        set work.summary;
        
        length measure $30 estimate $20 ci_95 $30 probability $20;
        
        measure = "Response Rate Arm 1"; 
        estimate = put(mean_p1, percent10.2);
        ci_95 = cats(put(p2_5_p1, percent10.2), ' to ', 
                    put(p97_5_p1, percent10.2));
        probability = '';
        output;
        
        measure = "Response Rate Arm 2";
        estimate = put(mean_p2, percent10.2);
        ci_95 = cats(put(p2_5_p2, percent10.2), ' to ', 
                    put(p97_5_p2, percent10.2));
        probability = '';
        output;
        
        measure = "Difference (Arm1 - Arm2)";
        estimate = put(mean_diff, percent10.2);
        ci_95 = cats(put(p2_5_diff, percent10.2), ' to ', 
                    put(p97_5_diff, percent10.2));
        probability = cats('P(Arm1 > Arm2) = ', put(prob_p1_greater, percent10.2));
        output;
        
        measure = "Odds Ratio";
        estimate = put(mean_or, 8.2);
        ci_95 = cats(put(p2_5_or, 8.2), ' to ', put(p97_5_or, 8.2));
        probability = '';
        output;
        
        keep measure estimate ci_95 probability;
    run;
    
    proc print data=work.results noobs;
        title1 "Bayesian Two-Arm Comparison Results";
        title2 "Arm 1: &n1_success/&n1_total, Arm 2: &n2_success/&n2_total";
    run;
    
    /* Plot posterior distributions */
    proc sgplot data=work.posterior_samples;
        histogram diff / binwidth=0.01;
        density diff / type=kernel;
        refline 0 / axis=x lineattrs=(pattern=dash);
        xaxis label="Difference in Response Rates (Arm1 - Arm2)";
        yaxis label="Density";
        title "Posterior Distribution of Treatment Difference";
    run;
    
%mend bayesian_binary_two_arm;

/******************************************************************************
SECTION 2: BAYESIAN ANALYSIS FOR CONTINUOUS ENDPOINTS
******************************************************************************/

/******************************************************************************
MACRO: bayesian_continuous_mcmc
PURPOSE: Bayesian analysis for continuous endpoint using PROC MCMC
PARAMETERS:
  data= : Input dataset
  response_var= : Response variable
  treatment_var= : Treatment variable
  covariates= : Covariates (optional)
  n_burnin= : Burn-in iterations (default=5000)
  n_mc= : MCMC iterations (default=20000)
******************************************************************************/
%macro bayesian_continuous_mcmc(
    data=,
    response_var=,
    treatment_var=,
    covariates=,
    n_burnin=5000,
    n_mc=20000
);
    
    %put NOTE: Performing Bayesian MCMC analysis for continuous endpoint;
    
    /* Run MCMC analysis */
    ods output PostSummaries=work.post_summaries PostIntervals=work.post_intervals;
    
    proc mcmc data=&data nbi=&n_burnin nmc=&n_mc plots=all;
        parms beta0 0 beta_trt 0 sigma2 1;
        
        /* Prior distributions */
        prior beta0 ~ normal(0, var=1000);
        prior beta_trt ~ normal(0, var=1000);
        prior sigma2 ~ igamma(0.001, scale=0.001);
        
        /* Likelihood */
        mu = beta0 + beta_trt*&treatment_var
             %if %length(&covariates) > 0 %then + &covariates;
             ;
        model &response_var ~ normal(mu, var=sigma2);
        
        title1 "Bayesian Analysis Using MCMC";
        title2 "Response: &response_var";
    run;
    
    /* Display results */
    proc print data=work.post_summaries;
        title3 "Posterior Summaries";
    run;
    
    proc print data=work.post_intervals;
        title3 "95% Credible Intervals";
    run;
    
%mend bayesian_continuous_mcmc;

/******************************************************************************
SECTION 3: BAYESIAN ADAPTIVE DESIGNS
******************************************************************************/

/******************************************************************************
MACRO: bayesian_adaptive_randomization
PURPOSE: Calculate adaptive randomization probabilities based on posterior
PARAMETERS:
  n_arms= : Number of treatment arms
  successes= : Space-separated list of successes per arm
  failures= : Space-separated list of failures per arm
  method= : Randomization method (THOMPSON, PROBABILITY_MATCH)
******************************************************************************/
%macro bayesian_adaptive_randomization(
    n_arms=,
    successes=,
    failures=,
    method=THOMPSON
);
    
    %put NOTE: Calculating Bayesian adaptive randomization probabilities;
    
    data work.adaptive_rand;
        /* Parse input */
        array succ[&n_arms] _temporary_;
        array fail[&n_arms] _temporary_;
        array prob[&n_arms];
        
        %do i = 1 %to &n_arms;
            succ[&i] = %scan(&successes, &i);
            fail[&i] = %scan(&failures, &i);
        %end;
        
        /* Thompson sampling */
        %if &method = THOMPSON %then %do;
            /* Generate samples from posterior */
            do sim = 1 to 10000;
                %do i = 1 %to &n_arms;
                    theta&i = rand('beta', succ[&i] + 1, fail[&i] + 1);
                %end;
                
                /* Find best arm */
                best_arm = 1;
                best_theta = theta1;
                %do i = 2 %to &n_arms;
                    if theta&i > best_theta then do;
                        best_arm = &i;
                        best_theta = theta&i;
                    end;
                %end;
                
                /* Update counts */
                prob[best_arm] + 1;
            end;
            
            /* Calculate probabilities */
            do i = 1 to &n_arms;
                prob[i] = prob[i] / 10000;
            end;
        %end;
        
        /* Output results */
        do arm = 1 to &n_arms;
            success = succ[arm];
            failure = fail[arm];
            n_total = success + failure;
            response_rate = success / n_total;
            rand_probability = prob[arm];
            output;
        end;
        
        format response_rate rand_probability percent10.2;
        keep arm success failure n_total response_rate rand_probability;
    run;
    
    proc print data=work.adaptive_rand;
        title1 "Bayesian Adaptive Randomization Probabilities";
        title2 "Method: &method";
    run;
    
    /* Plot randomization probabilities */
    proc sgplot data=work.adaptive_rand;
        vbar arm / response=rand_probability;
        xaxis label="Treatment Arm";
        yaxis label="Randomization Probability" values=(0 to 1 by 0.1);
        title "Adaptive Randomization Probabilities by Arm";
    run;
    
%mend bayesian_adaptive_randomization;

/******************************************************************************
MACRO: bayesian_predictive_probability
PURPOSE: Calculate predictive probability of trial success
PARAMETERS:
  current_success= : Current number of successes
  current_n= : Current sample size
  final_n= : Final planned sample size
  success_threshold= : Success threshold (e.g., 0.3 for 30%)
  n_simulations= : Number of simulations (default=10000)
******************************************************************************/
%macro bayesian_predictive_probability(
    current_success=,
    current_n=,
    final_n=,
    success_threshold=,
    n_simulations=10000
);
    
    %put NOTE: Calculating predictive probability of success;
    
    /* Calculate remaining patients */
    %let n_remaining = %eval(&final_n - &current_n);
    
    /* Current posterior parameters */
    %let post_alpha = %sysevalf(&current_success + 1);
    %let post_beta = %sysevalf(&current_n - &current_success + 1);
    
    /* Simulate trial completions */
    data work.predictive_sim;
        do sim = 1 to &n_simulations;
            /* Sample true response rate from current posterior */
            true_rate = rand('beta', &post_alpha, &post_beta);
            
            /* Simulate remaining patients */
            future_success = rand('binomial', true_rate, &n_remaining);
            
            /* Total successes at end of trial */
            total_success = &current_success + future_success;
            
            /* Final posterior mean */
            final_post_mean = (total_success + 1) / (&final_n + 2);
            
            /* Check if success criterion met */
            success = (final_post_mean > &success_threshold);
            
            output;
        end;
    run;
    
    /* Calculate predictive probability */
    proc means data=work.predictive_sim noprint;
        var success;
        output out=work.pred_prob mean=predictive_probability;
    run;
    
    /* Display results */
    data work.pred_results;
        set work.pred_prob;
        
        current_rate = &current_success / &current_n;
        patients_enrolled = &current_n;
        patients_remaining = &n_remaining;
        success_criterion = &success_threshold;
        
        format current_rate success_criterion predictive_probability percent10.2;
        keep current_rate patients_enrolled patients_remaining 
             success_criterion predictive_probability;
    run;
    
    proc print data=work.pred_results noobs;
        title1 "Predictive Probability Analysis";
        title2 "Current: &current_success/&current_n, Target: >&success_threshold";
    run;
    
    /* Plot distribution of final response rates */
    proc sgplot data=work.predictive_sim;
        histogram final_post_mean / binwidth=0.01;
        refline &success_threshold / axis=x label="Success Threshold" 
                                    lineattrs=(pattern=dash);
        xaxis label="Final Posterior Mean Response Rate";
        yaxis label="Frequency";
        title "Distribution of Final Response Rates";
    run;
    
%mend bayesian_predictive_probability;

/******************************************************************************
SECTION 4: BAYESIAN SAMPLE SIZE DETERMINATION
******************************************************************************/

/******************************************************************************
MACRO: bayesian_sample_size
PURPOSE: Determine sample size for Bayesian trial design
PARAMETERS:
  design_type= : Type of design (SINGLE_ARM, TWO_ARM)
  null_rate= : Null hypothesis rate
  alt_rate= : Alternative hypothesis rate
  power= : Desired power (default=0.80)
  type1_error= : Type I error rate (default=0.025)
  max_n= : Maximum sample size to consider
******************************************************************************/
%macro bayesian_sample_size(
    design_type=SINGLE_ARM,
    null_rate=0.3,
    alt_rate=0.5,
    power=0.80,
    type1_error=0.025,
    max_n=100
);
    
    %put NOTE: Bayesian sample size determination;
    
    data work.sample_size_calc;
        do n = 10 to &max_n by 5;
            
            /* Type I error calculation - data generated under null */
            type1_count = 0;
            do sim = 1 to 1000;
                successes = rand('binomial', &null_rate, n);
                
                /* Posterior probability that rate > null */
                post_prob = 1 - cdf('beta', &null_rate, successes + 1, 
                                   n - successes + 1);
                
                if post_prob > 0.975 then type1_count + 1;
            end;
            type1_error_rate = type1_count / 1000;
            
            /* Power calculation - data generated under alternative */
            power_count = 0;
            do sim = 1 to 1000;
                successes = rand('binomial', &alt_rate, n);
                
                /* Posterior probability that rate > null */
                post_prob = 1 - cdf('beta', &null_rate, successes + 1, 
                                   n - successes + 1);
                
                if post_prob > 0.975 then power_count + 1;
            end;
            power_achieved = power_count / 1000;
            
            /* Check if criteria met */
            if type1_error_rate <= &type1_error and power_achieved >= &power then do;
                criteria_met = 'Yes';
                output;
                leave; /* Stop at first n meeting criteria */
            end;
            else do;
                criteria_met = 'No';
                output;
            end;
        end;
        
        format type1_error_rate power_achieved percent10.2;
    run;
    
    /* Display results */
    proc print data=work.sample_size_calc;
        title1 "Bayesian Sample Size Calculation";
        title2 "Null Rate: &null_rate, Alternative Rate: &alt_rate";
        title3 "Target Power: %sysevalf(&power*100)%, Type I Error: %sysevalf(&type1_error*100)%";
        var n type1_error_rate power_achieved criteria_met;
    run;
    
    /* Plot power curve */
    proc sgplot data=work.sample_size_calc;
        series x=n y=power_achieved / markers markerattrs=(symbol=circlefilled);
        refline &power / axis=y label="Target Power" lineattrs=(pattern=dash);
        refline &type1_error / axis=y label="Type I Error" 
                             lineattrs=(pattern=dash color=red);
        xaxis label="Sample Size" grid;
        yaxis label="Probability" values=(0 to 1 by 0.1) grid;
        title "Power and Type I Error by Sample Size";
    run;
    
%mend bayesian_sample_size;

/******************************************************************************
SECTION 5: BAYESIAN HIERARCHICAL MODELS
******************************************************************************/

/******************************************************************************
MACRO: bayesian_hierarchical_meta
PURPOSE: Bayesian hierarchical model for meta-analysis
PARAMETERS:
  data= : Dataset with study-level results
  study_var= : Study identifier variable
  n_events_var= : Number of events variable
  n_total_var= : Total sample size variable
  output_path= : Path for output
******************************************************************************/
%macro bayesian_hierarchical_meta(
    data=,
    study_var=,
    n_events_var=,
    n_total_var=,
    output_path=
);
    
    %put NOTE: Performing Bayesian hierarchical meta-analysis;
    
    /* Prepare data */
    data work.meta_data;
        set &data;
        study_id = _n_;
    run;
    
    /* Run hierarchical model */
    proc mcmc data=work.meta_data nbi=10000 nmc=50000 plots=all
              outpost=work.posterior;
        array theta[10]; /* Adjust size based on number of studies */
        
        /* Hyperpriors */
        parms mu_logit 0 tau2 1;
        prior mu_logit ~ normal(0, var=10);
        prior tau2 ~ igamma(0.001, scale=0.001);
        
        /* Study-specific parameters */
        parms theta: 0;
        prior theta: ~ normal(mu_logit, var=tau2);
        
        /* Likelihood */
        p = logistic(theta[study_id]);
        model &n_events_var ~ binomial(n=&n_total_var, p=p);
        
        /* Derived parameters */
        tau = sqrt(tau2);
        mu = logistic(mu_logit); /* Overall rate */
        
        title1 "Bayesian Hierarchical Meta-Analysis";
    run;
    
    /* Summarize results */
    proc means data=work.posterior mean std p5 p25 p50 p75 p95;
        var mu tau;
        title2 "Posterior Summary of Hyperparameters";
    run;
    
    /* Forest plot data preparation */
    proc sql;
        create table work.forest_data as
        select distinct a.&study_var,
               a.&n_events_var as events,
               a.&n_total_var as total,
               a.&n_events_var / a.&n_total_var as observed_rate,
               mean(b.theta1) as posterior_mean /* Adjust for multiple studies */
        from work.meta_data as a, work.posterior as b
        group by a.&study_var;
    quit;
    
%mend bayesian_hierarchical_meta;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Single-arm binary endpoint
%bayesian_binary_single_arm(
    n_success=15,
    n_total=40,
    prior_alpha=1,
    prior_beta=1,
    target_rate=0.3,
    credible_level=0.95
);

Example 2: Two-arm comparison
%bayesian_binary_two_arm(
    n1_success=18,
    n1_total=50,
    n2_success=12,
    n2_total=50,
    prior_alpha=1,
    prior_beta=1,
    n_simulations=10000
);

Example 3: Continuous endpoint with MCMC
%bayesian_continuous_mcmc(
    data=mydata,
    response_var=change_from_baseline,
    treatment_var=treatment,
    covariates=age sex baseline,
    n_burnin=5000,
    n_mc=20000
);

Example 4: Adaptive randomization
%bayesian_adaptive_randomization(
    n_arms=3,
    successes=8 12 15,
    failures=22 18 15,
    method=THOMPSON
);

Example 5: Predictive probability
%bayesian_predictive_probability(
    current_success=15,
    current_n=40,
    final_n=80,
    success_threshold=0.35,
    n_simulations=10000
);

Example 6: Sample size calculation
%bayesian_sample_size(
    design_type=SINGLE_ARM,
    null_rate=0.2,
    alt_rate=0.4,
    power=0.80,
    type1_error=0.025,
    max_n=150
);
*/

%put NOTE: Bayesian examples loaded successfully;
%put NOTE: Available macros: bayesian_binary_single_arm, bayesian_binary_two_arm,;
%put NOTE:                  bayesian_continuous_mcmc, bayesian_adaptive_randomization,;
%put NOTE:                  bayesian_predictive_probability, bayesian_sample_size,;
%put NOTE:                  bayesian_hierarchical_meta;