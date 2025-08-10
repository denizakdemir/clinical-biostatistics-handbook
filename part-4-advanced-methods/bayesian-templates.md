# Bayesian Analysis Templates for Clinical Trials

## Foundation: Bayesian Framework for Clinical Trials

### Prior Selection Guidelines

```
PRIOR SELECTION DECISION TREE

Prior Information Available?
├── Extensive Historical Data
│   ├── Informative Priors
│   │   ├── Conjugate Priors (when possible)
│   │   │   ├── Normal-Normal for continuous data
│   │   │   ├── Beta-Binomial for binary data
│   │   │   └── Gamma-Poisson for count data
│   │   ├── Meta-Analysis Priors
│   │   │   ├── Random effects estimates
│   │   │   ├── Between-study heterogeneity
│   │   │   └── Publication bias adjustment
│   │   └── Power Priors
│   │       ├── Historical data weighted by α₀
│   │       ├── 0 ≤ α₀ ≤ 1 (discount parameter)
│   │       └── Dynamic borrowing approaches
├── Limited Historical Information  
│   ├── Weakly Informative Priors
│   │   ├── Expert elicitation
│   │   ├── Conservative assumptions
│   │   └── Regularization focus
│   └── Skeptical Priors
│       ├── Center on null effect
│       ├── Require strong evidence
│       └── Conservative Type I error
└── No Prior Information
    ├── Non-informative Priors
    │   ├── Uniform priors (bounded parameters)
    │   ├── Jeffreys priors (scale invariant)
    │   └── Reference priors
    └── Default Priors
        ├── Weakly informative normal priors
        ├── Inverse-gamma for variances
        └── Software default specifications
```

## Basic Bayesian Analysis Templates

### Two-Sample Continuous Outcome

```sas
/******************************************************************************
ANALYSIS: Bayesian Two-Sample Comparison (Continuous Outcome)
DESIGN: Parallel group comparison with normal endpoints
******************************************************************************/

/* Template 1: Non-informative Analysis */
proc mcmc data=trial_data nbi=2000 nmc=10000 seed=54321
          plots=(trace autocorr density) diagnostics=all;
    
    /* Parameters */
    parms mu_control 0 mu_treatment 0 sigma2 1;
    
    /* Non-informative priors */
    prior mu_control ~ normal(0, var=1000);    /* Vague prior */
    prior mu_treatment ~ normal(0, var=1000);  /* Vague prior */
    prior sigma2 ~ igamma(0.001, s=0.001);     /* Non-informative for variance */
    
    /* Likelihood */
    if treatment = 'Control' then
        model outcome ~ normal(mu_control, var=sigma2);
    else if treatment = 'Treatment' then  
        model outcome ~ normal(mu_treatment, var=sigma2);
    
    /* Derived quantities */
    treatment_effect = mu_treatment - mu_control;
    
    /* Probability statements */
    prob_positive = (treatment_effect > 0);
    prob_clinically_meaningful = (treatment_effect > 2.0);
    prob_harm = (treatment_effect < -1.0);
    
    title "Bayesian Two-Sample Analysis - Non-informative Priors";
run;

/* Template 2: Informative Analysis with Historical Data */
proc mcmc data=trial_data nbi=3000 nmc=15000 seed=12345;
    
    /* Parameters */  
    parms mu_control 0 mu_treatment 0 sigma2 1;
    
    /* Informative priors based on historical data */
    /* Historical control: mean=10.5, n=50, sd=3.2 */
    historical_precision = 50 / (3.2**2);
    prior mu_control ~ normal(10.5, var=1/historical_precision);
    
    /* Conservative prior for treatment (centered on control) */
    prior mu_treatment ~ normal(10.5, var=16);  /* SD = 4.0 */
    
    /* Informative prior for variance */
    prior sigma2 ~ igamma(25, s=200);  /* Based on historical variance */
    
    if treatment = 'Control' then
        model outcome ~ normal(mu_control, var=sigma2);
    else if treatment = 'Treatment' then
        model outcome ~ normal(mu_treatment, var=sigma2);
    
    treatment_effect = mu_treatment - mu_control;
    
    /* Decision criteria */
    efficacy_threshold = 3.0;
    futility_threshold = -1.0;
    
    prob_efficacy = (treatment_effect > efficacy_threshold);
    prob_futility = (treatment_effect < futility_threshold);
    
    title "Bayesian Analysis - Informative Historical Priors";
run;

/* Template 3: Hierarchical Model for Multi-Site Trial */
proc mcmc data=multi_site_data nbi=4000 nmc=20000 seed=98765;
    
    /* Site-specific parameters */
    array mu_control_site[10];   /* 10 sites */
    array mu_treatment_site[10];
    
    /* Overall parameters */
    parms mu_control_overall 0 mu_treatment_overall 0;
    parms tau_control 1 tau_treatment 1 sigma2 1;
    
    /* Hyperpriors */
    prior mu_control_overall ~ normal(0, var=100);
    prior mu_treatment_overall ~ normal(0, var=100);
    prior tau_control ~ igamma(0.001, s=0.001);
    prior tau_treatment ~ igamma(0.001, s=0.001);
    prior sigma2 ~ igamma(0.001, s=0.001);
    
    /* Site-specific priors (hierarchical) */
    do i = 1 to 10;
        prior mu_control_site[i] ~ normal(mu_control_overall, var=tau_control);
        prior mu_treatment_site[i] ~ normal(mu_treatment_overall, var=tau_treatment);
    end;
    
    /* Likelihood */
    if treatment = 'Control' then
        model outcome ~ normal(mu_control_site[site], var=sigma2);
    else if treatment = 'Treatment' then
        model outcome ~ normal(mu_treatment_site[site], var=sigma2);
    
    /* Overall treatment effect */
    overall_effect = mu_treatment_overall - mu_control_overall;
    
    title "Hierarchical Bayesian Analysis - Multi-Site Trial";
run;
```

### Binary Outcome Analysis

```sas
/******************************************************************************
ANALYSIS: Bayesian Binary Outcome Comparison
DESIGN: Response rate comparison between treatments
******************************************************************************/

/* Template 1: Beta-Binomial Model */
proc mcmc data=binary_data nbi=3000 nmc=15000 seed=11111;
    
    /* Parameters (response rates) */
    parms p_control 0.3 p_treatment 0.4;
    
    /* Beta priors */
    /* Weakly informative: Beta(1,1) = Uniform(0,1) */
    prior p_control ~ beta(1, 1);
    prior p_treatment ~ beta(1, 1);
    
    /* Likelihood */
    if treatment = 'Control' then
        model response ~ bernoulli(p_control);
    else if treatment = 'Treatment' then
        model response ~ bernoulli(p_treatment);
    
    /* Derived quantities */
    risk_difference = p_treatment - p_control;
    relative_risk = p_treatment / p_control;
    odds_ratio = (p_treatment/(1-p_treatment)) / (p_control/(1-p_control));
    
    /* Number needed to treat */
    if risk_difference > 0 then nnt = 1 / risk_difference;
    else nnt = .;
    
    /* Probability statements */
    prob_superiority = (risk_difference > 0);
    prob_clinically_meaningful = (risk_difference > 0.10);  /* 10% improvement */
    prob_non_inferiority = (risk_difference > -0.05);      /* 5% NI margin */
    
    title "Bayesian Binary Outcome Analysis";
run;

/* Template 2: Informative Beta Priors from Historical Data */
proc mcmc data=binary_data nbi=3000 nmc=15000;
    
    parms p_control 0.25 p_treatment 0.35;
    
    /* Historical control data: 15 responses in 60 patients */
    /* Beta(15+1, 60-15+1) = Beta(16, 46) */
    prior p_control ~ beta(16, 46);
    
    /* Skeptical prior for treatment (slightly better than control) */
    /* Beta(a,b) with mean = 0.30, effective sample size = 20 */
    /* a = 0.30*20 = 6, b = 0.70*20 = 14 */
    prior p_treatment ~ beta(6, 14);
    
    if treatment = 'Control' then
        model response ~ bernoulli(p_control);
    else if treatment = 'Treatment' then  
        model response ~ bernoulli(p_treatment);
    
    risk_difference = p_treatment - p_control;
    odds_ratio = (p_treatment/(1-p_treatment)) / (p_control/(1-p_control));
    
    /* Decision thresholds */
    prob_benefit = (risk_difference > 0.05);    /* Minimal benefit */
    prob_substantial_benefit = (risk_difference > 0.15);  /* Substantial benefit */
    
    title "Bayesian Binary Analysis - Informative Priors";
run;

/* Template 3: Logistic Regression with Covariates */
proc mcmc data=binary_covariate_data nbi=4000 nmc=20000;
    
    /* Regression parameters */
    parms intercept 0 beta_treatment 0 beta_age 0 beta_sex 0;
    
    /* Priors */
    prior intercept ~ normal(0, var=100);
    prior beta_treatment ~ normal(0, var=4);     /* Key parameter */
    prior beta_age ~ normal(0, var=1);           /* Age in decades */  
    prior beta_sex ~ normal(0, var=4);           /* Sex effect */
    
    /* Logistic model */
    linear_predictor = intercept + beta_treatment*treatment_numeric + 
                      beta_age*age_decades + beta_sex*sex_numeric;
    
    p = logistic(linear_predictor);
    model response ~ bernoulli(p);
    
    /* Treatment effect (odds ratio) */
    treatment_or = exp(beta_treatment);
    
    /* Covariate-adjusted probabilities */
    /* For reference patient: age=60, male */
    ref_control_logit = intercept + beta_age*6 + beta_sex*1;  
    ref_treatment_logit = intercept + beta_treatment + beta_age*6 + beta_sex*1;
    
    ref_p_control = logistic(ref_control_logit);
    ref_p_treatment = logistic(ref_treatment_logit);
    ref_risk_diff = ref_p_treatment - ref_p_control;
    
    title "Bayesian Logistic Regression";
run;
```

## Time-to-Event Bayesian Analysis

### Exponential and Weibull Models

```sas
/******************************************************************************
ANALYSIS: Bayesian Survival Analysis
DESIGN: Time-to-event comparison with parametric models
******************************************************************************/

/* Template 1: Exponential Model */
proc mcmc data=survival_data nbi=3000 nmc=15000 seed=24680;
    
    /* Parameters (hazard rates) */
    parms lambda_control 0.01 lambda_treatment 0.008;
    
    /* Priors for hazard rates */
    prior lambda_control ~ gamma(0.01, s=0.01);     /* Vague gamma prior */
    prior lambda_treatment ~ gamma(0.01, s=0.01);
    
    /* Likelihood for exponential distribution */
    if treatment = 'Control' then do;
        if censor = 0 then  /* Event observed */
            loglik = log(lambda_control) - lambda_control*time;
        else  /* Censored */
            loglik = -lambda_control*time;
        loglj loglik;
    end;
    else if treatment = 'Treatment' then do;
        if censor = 0 then
            loglik = log(lambda_treatment) - lambda_treatment*time;
        else
            loglik = -lambda_treatment*time;
        loglj loglik;
    end;
    
    /* Derived quantities */
    hazard_ratio = lambda_treatment / lambda_control;
    median_control = log(2) / lambda_control;
    median_treatment = log(2) / lambda_treatment;
    median_difference = median_treatment - median_control;
    
    /* Probability statements */
    prob_hr_less_than_1 = (hazard_ratio < 1.0);
    prob_hr_less_than_075 = (hazard_ratio < 0.75);
    prob_median_improvement = (median_difference > 0);
    
    title "Bayesian Exponential Survival Model";
run;

/* Template 2: Weibull AFT Model */
proc mcmc data=survival_data nbi=4000 nmc=20000 seed=13579;
    
    /* Parameters */
    parms mu_control 0 mu_treatment 0 sigma 1;  /* AFT parameterization */
    
    /* Priors */
    prior mu_control ~ normal(0, var=100);
    prior mu_treatment ~ normal(0, var=100);
    prior sigma ~ igamma(0.01, s=0.01);
    
    /* Weibull AFT likelihood */
    if treatment = 'Control' then do;
        if censor = 0 then do;
            z = (log(time) - mu_control) / sigma;
            loglik = -log(sigma) + z - exp(z);
        end;
        else do;
            z = (log(time) - mu_control) / sigma;
            loglik = -exp(z);
        end;
        loglj loglik;
    end;
    else if treatment = 'Treatment' then do;
        if censor = 0 then do;
            z = (log(time) - mu_treatment) / sigma;
            loglik = -log(sigma) + z - exp(z);
        end;
        else do;
            z = (log(time) - mu_treatment) / sigma;
            loglik = -exp(z);
        end;
        loglj loglik;
    end;
    
    /* Derived quantities */
    /* Acceleration factor */
    acceleration_factor = exp(mu_treatment - mu_control);
    
    /* Median survival times */
    median_control = exp(mu_control + sigma * log(log(2)));
    median_treatment = exp(mu_treatment + sigma * log(log(2)));
    
    /* Hazard ratio (Weibull specific) */
    hazard_ratio = exp(-(mu_treatment - mu_control) / sigma);
    
    title "Bayesian Weibull AFT Model";
run;

/* Template 3: Piecewise Exponential Model */
proc mcmc data=piecewise_survival nbi=5000 nmc=25000;
    
    /* Time intervals: 0-6, 6-12, 12+ months */
    array lambda_control[3];  /* Hazards by interval */
    array lambda_treatment[3];
    
    /* Priors for each interval */
    do i = 1 to 3;
        prior lambda_control[i] ~ gamma(0.1, s=0.1);
        prior lambda_treatment[i] ~ gamma(0.1, s=0.1);
    end;
    
    /* Determine interval for each observation */
    if time <= 6 then interval = 1;
    else if time <= 12 then interval = 2;  
    else interval = 3;
    
    /* Piecewise exponential likelihood */
    if treatment = 'Control' then do;
        if censor = 0 then
            loglik = log(lambda_control[interval]) - lambda_control[interval]*time;
        else  
            loglik = -lambda_control[interval]*time;
        loglj loglik;
    end;
    else if treatment = 'Treatment' then do;
        if censor = 0 then
            loglik = log(lambda_treatment[interval]) - lambda_treatment[interval]*time;
        else
            loglik = -lambda_treatment[interval]*time;  
        loglj loglik;
    end;
    
    /* Hazard ratios by interval */
    hr_0_6 = lambda_treatment[1] / lambda_control[1];
    hr_6_12 = lambda_treatment[2] / lambda_control[2];
    hr_12plus = lambda_treatment[3] / lambda_control[3];
    
    /* Time-varying effect test */
    hr_constant = (abs(hr_0_6 - hr_6_12) < 0.1 and abs(hr_6_12 - hr_12plus) < 0.1);
    
    title "Bayesian Piecewise Exponential Model";
run;
```

## Adaptive Bayesian Designs

### Response-Adaptive Randomization

```sas
/******************************************************************************
ANALYSIS: Bayesian Response-Adaptive Randomization
DESIGN: Allocation probabilities updated based on accumulating data
******************************************************************************/

/* Template 1: Binary Outcome RAR */
%macro bayesian_rar_binary(current_data=, n_total=, allocation_rule=sqrt);

    /* Analyze current data */
    proc mcmc data=&current_data nbi=1000 nmc=5000 noprint
              seed=54321 outpost=posterior_samples;
        
        parms p_control 0.3 p_treatment 0.4;
        
        /* Weakly informative priors */
        prior p_control ~ beta(1, 1);
        prior p_treatment ~ beta(1, 1);
        
        if treatment = 'Control' then
            model response ~ bernoulli(p_control);
        else if treatment = 'Treatment' then
            model response ~ bernoulli(p_treatment);
        
        /* Probability treatment is better */
        prob_treatment_better = (p_treatment > p_control);
    run;
    
    /* Calculate allocation probabilities */
    proc means data=posterior_samples noprint;
        var prob_treatment_better;
        output out=prob_summary mean=prob_trt_better;
    run;
    
    data allocation_probs;
        set prob_summary;
        
        prob_ctrl_better = 1 - prob_trt_better;
        
        %if &allocation_rule = sqrt %then %do;
            /* Square root rule */
            alloc_trt = sqrt(prob_trt_better) / 
                       (sqrt(prob_trt_better) + sqrt(prob_ctrl_better));
        %end;
        %else %if &allocation_rule = power %then %do;
            /* Power rule with exponent */
            power_param = 0.5;
            alloc_trt = (prob_trt_better**power_param) / 
                       (prob_trt_better**power_param + prob_ctrl_better**power_param);
        %end;
        
        /* Ensure minimum allocation (e.g., 10%) */
        alloc_trt = max(min(alloc_trt, 0.90), 0.10);
        alloc_ctrl = 1 - alloc_trt;
        
        /* Number of patients to allocate to each arm */
        remaining_n = &n_total - current_n;
        n_trt = round(alloc_trt * remaining_n);
        n_ctrl = remaining_n - n_trt;
        
        put "Probability treatment better: " prob_trt_better percent8.1;
        put "Allocation to treatment: " alloc_trt percent8.1;
        put "Next allocation - Treatment: " n_trt " Control: " n_ctrl;
    run;

%mend bayesian_rar_binary;
```

### Bayesian Interim Monitoring

```sas
/******************************************************************************
ANALYSIS: Bayesian Interim Analysis for Efficacy and Futility
DESIGN: Probability-based stopping rules
******************************************************************************/

/* Template 1: Efficacy and Futility Monitoring */
%macro bayesian_interim_monitoring(interim_data=, final_n=, 
                                  efficacy_threshold=0.975,
                                  futility_threshold=0.05);

    /* Current analysis */
    proc mcmc data=&interim_data nbi=2000 nmc=10000 seed=98765
              outpost=interim_posterior noprint;
        
        parms mu_control 0 mu_treatment 0 sigma2 1;
        
        /* Priors */
        prior mu_control ~ normal(0, var=100);
        prior mu_treatment ~ normal(0, var=100);  
        prior sigma2 ~ igamma(0.01, s=0.01);
        
        if treatment = 'Control' then
            model outcome ~ normal(mu_control, var=sigma2);
        else if treatment = 'Treatment' then
            model outcome ~ normal(mu_treatment, var=sigma2);
        
        treatment_effect = mu_treatment - mu_control;
        
        /* Clinical thresholds */
        prob_positive = (treatment_effect > 0);
        prob_clinically_meaningful = (treatment_effect > 2.0);
        prob_substantial = (treatment_effect > 3.0);
    run;
    
    /* Posterior probabilities */
    proc means data=interim_posterior noprint;
        var prob_positive prob_clinically_meaningful prob_substantial;
        output out=posterior_probs 
               mean(prob_positive)=prob_pos_mean
               mean(prob_clinically_meaningful)=prob_clin_mean  
               mean(prob_substantial)=prob_subst_mean;
    run;
    
    /* Predictive probability calculation */
    data _null_;
        set interim_posterior nobs=nobs;
        
        /* Current sample sizes */
        current_n_trt = &interim_n_trt;
        current_n_ctrl = &interim_n_ctrl;  
        
        /* Final sample sizes */
        final_n_trt = &final_n / 2;
        final_n_ctrl = &final_n / 2;
        
        /* Additional patients needed */
        add_n_trt = final_n_trt - current_n_trt;
        add_n_ctrl = final_n_ctrl - current_n_ctrl;
        
        /* Predictive distribution parameters */
        pred_mean_diff = mu_treatment - mu_control;
        pred_var = sigma2 * (1/add_n_trt + 1/add_n_ctrl);
        pred_se = sqrt(pred_var);
        
        /* Critical value for significance at final analysis */
        critical_value = 1.96 * sqrt(sigma2 * (1/final_n_trt + 1/final_n_ctrl));
        
        /* Predictive probability of success */
        pred_prob_success = 1 - probnorm(critical_value, pred_mean_diff, pred_se);
        
        if _n_ = 1 then call symputx('pred_prob_mean', pred_prob_success);
    run;
    
    /* Decision rules */
    data interim_decision;
        set posterior_probs;
        
        pred_prob_success = &pred_prob_mean;
        
        /* Efficacy stopping */
        if prob_subst_mean >= &efficacy_threshold then 
            efficacy_decision = 'Stop for Efficacy';
        else if prob_clin_mean >= 0.90 then
            efficacy_decision = 'Consider Stopping for Efficacy';
        else
            efficacy_decision = 'Continue';
        
        /* Futility stopping */
        if pred_prob_success <= &futility_threshold then
            futility_decision = 'Stop for Futility';
        else if pred_prob_success <= 0.20 then
            futility_decision = 'Consider Stopping for Futility';
        else
            futility_decision = 'Continue';
        
        /* Overall recommendation */
        if efficacy_decision = 'Stop for Efficacy' then 
            recommendation = 'STOP - Efficacy Demonstrated';
        else if futility_decision = 'Stop for Futility' then
            recommendation = 'STOP - Futility';
        else if efficacy_decision = 'Consider Stopping for Efficacy' then
            recommendation = 'CONSIDER STOPPING - Strong Efficacy Signal';
        else if futility_decision = 'Consider Stopping for Futility' then
            recommendation = 'CONSIDER STOPPING - Low Success Probability';
        else
            recommendation = 'CONTINUE';
        
        format prob_pos_mean prob_clin_mean prob_subst_mean pred_prob_success percent8.1;
    run;
    
    proc print data=interim_decision noobs;
        title "Bayesian Interim Monitoring Decision";
        var prob_pos_mean prob_clin_mean prob_subst_mean pred_prob_success 
            efficacy_decision futility_decision recommendation;
    run;

%mend bayesian_interim_monitoring;
```

## Historical Data Borrowing

### Power Prior Implementation

```sas
/******************************************************************************
ANALYSIS: Power Prior for Historical Data Borrowing
DESIGN: Discounts historical data by power parameter α₀
******************************************************************************/

/* Template 1: Fixed Power Prior */
proc mcmc data=current_data nbi=3000 nmc=15000 seed=24680;
    
    /* Current study parameters */
    parms mu_current 0 sigma2_current 1;
    
    /* Historical data parameters (fixed) */
    mu_historical = 12.5;          /* Historical mean */
    n_historical = 60;             /* Historical sample size */  
    sigma2_historical = 16.0;      /* Historical variance */
    
    /* Power prior parameter */
    a0 = 0.3;  /* Discount historical data to 30% */
    
    /* Effective historical precision */
    effective_n = a0 * n_historical;
    historical_precision = effective_n / sigma2_historical;
    
    /* Power prior */
    prior mu_current ~ normal(mu_historical, var=1/historical_precision);
    prior sigma2_current ~ igamma(0.01, s=0.01);
    
    /* Likelihood for current data */
    model outcome ~ normal(mu_current, var=sigma2_current);
    
    title "Fixed Power Prior Analysis (α₀ = 0.3)";
run;

/* Template 2: Adaptive Power Prior */
proc mcmc data=combined_data nbi=4000 nmc=20000 seed=97531;
    
    /* Parameters */
    parms mu_current 0 mu_historical 0 sigma2 1 a0 0.5;
    
    /* Priors */
    prior mu_current ~ normal(0, var=100);
    prior mu_historical ~ normal(0, var=100);
    prior sigma2 ~ igamma(0.01, s=0.01);
    prior a0 ~ beta(1, 1);  /* Adaptive power parameter */
    
    /* Effective sample size constraint */
    if a0 < 0 then a0 = 0;
    if a0 > 1 then a0 = 1;
    
    /* Power prior likelihood for historical data */
    if study_type = 'Historical' then do;
        /* Raised to power a0 */
        loglik = a0 * (-0.5 * log(2*constant('PI')*sigma2) - 
                      (outcome - mu_historical)**2 / (2*sigma2));
        loglj loglik;
    end;
    else if study_type = 'Current' then do;
        /* Full likelihood for current data */
        model outcome ~ normal(mu_current, var=sigma2);
    end;
    
    /* Compatibility measure */
    compatibility = exp(-0.5 * (mu_current - mu_historical)**2 / sigma2);
    
    /* Treatment effect (if current data has treatment) */
    if study_type = 'Current' and treatment = 'Treatment' then
        treatment_effect = mu_current - mu_historical;
    
    title "Adaptive Power Prior Analysis";
run;

/* Template 3: Hierarchical Power Prior */
proc mcmc data=multi_historical_data nbi=5000 nmc=25000;
    
    /* Current study parameter */
    parms mu_current 0 sigma2 1;
    
    /* Historical study parameters */
    array mu_hist[3];  /* 3 historical studies */
    array a0[3];       /* Power parameters for each study */
    
    /* Population parameters */  
    parms mu_pop 0 tau2 1;
    
    /* Hyperpriors */
    prior mu_pop ~ normal(0, var=100);
    prior tau2 ~ igamma(0.01, s=0.01);
    prior sigma2 ~ igamma(0.01, s=0.01);
    
    /* Historical study priors */
    do i = 1 to 3;
        prior mu_hist[i] ~ normal(mu_pop, var=tau2);
        prior a0[i] ~ beta(1, 1);
    end;
    
    /* Current study prior */  
    prior mu_current ~ normal(mu_pop, var=tau2);
    
    /* Power prior likelihoods */
    if study_id <= 3 then do;  /* Historical studies */
        i = study_id;
        loglik = a0[i] * (-0.5 * log(2*constant('PI')*sigma2) -
                         (outcome - mu_hist[i])**2 / (2*sigma2));
        loglj loglik;
    end;
    else do;  /* Current study */
        model outcome ~ normal(mu_current, var=sigma2);
    end;
    
    /* Overall treatment effect vs population */
    treatment_vs_population = mu_current - mu_pop;
    
    title "Hierarchical Power Prior Analysis";
run;
```

## Model Assessment and Validation

### Model Checking Templates

```sas
/******************************************************************************
ANALYSIS: Bayesian Model Checking and Validation
DESIGN: Posterior predictive checks and model comparison
******************************************************************************/

/* Template 1: Posterior Predictive Checks */
proc mcmc data=model_data nbi=2000 nmc=10000 seed=13579
          outpost=model_posterior;
    
    /* Model parameters */
    parms mu 0 sigma2 1;
    
    /* Priors */
    prior mu ~ normal(0, var=100);
    prior sigma2 ~ igamma(0.01, s=0.01);
    
    /* Likelihood */
    model outcome ~ normal(mu, var=sigma2);
    
    /* Posterior predictive quantities */
    /* Generate replicated data from posterior predictive distribution */
    y_rep = normal(mu, sqrt(sigma2));
    
    /* Test quantities */
    T_obs = (outcome - mu)**2 / sigma2;     /* Squared standardized residual */
    T_rep = (y_rep - mu)**2 / sigma2;       /* For replicated data */
    
    /* Extreme value indicators */
    extreme_low = (outcome < mu - 2*sqrt(sigma2));
    extreme_high = (outcome > mu + 2*sqrt(sigma2));
    
    title "Posterior Predictive Model Checking";
run;

/* Check model fit */
proc means data=model_posterior;
    var T_obs T_rep extreme_low extreme_high;
    title "Posterior Predictive Check Summary";
run;

/* P-value calculation */
data ppp_value;
    set model_posterior end=last;
    retain count_T_rep_gt_T_obs 0 total_obs 0;
    
    if T_rep > T_obs then count_T_rep_gt_T_obs + 1;
    total_obs + 1;
    
    if last then do;
        ppp_value = count_T_rep_gt_T_obs / total_obs;
        put "Posterior Predictive P-value: " ppp_value 6.3;
        
        if ppp_value < 0.05 or ppp_value > 0.95 then
            put "WARNING: Model may not fit well (extreme p-value)";
    end;
run;

/* Template 2: Model Comparison via Information Criteria */
%macro bayesian_model_comparison(models=model1 model2 model3, data=);

    %let nmodels = %sysfunc(countw(&models));
    
    data model_comparison;
        length model $20;
        DIC = .; WAIC = .; pD = .;
        stop;
    run;
    
    %do i = 1 %to &nmodels;
        %let model = %scan(&models, &i);
        
        /* Fit model and calculate DIC */
        ods output PostSummaryStatistics=&model._summary
                   DIC=&model._dic;
        
        proc mcmc data=&data nbi=2000 nmc=10000 dic;
            /* Include model-specific code here */
            %if &model = model1 %then %do;
                /* Simple normal model */
                parms mu 0 sigma2 1;
                prior mu ~ normal(0, var=100);
                prior sigma2 ~ igamma(0.01, s=0.01);
                model outcome ~ normal(mu, var=sigma2);
            %end;
            %else %if &model = model2 %then %do;
                /* Normal model with covariate */
                parms intercept 0 beta 0 sigma2 1;
                prior intercept ~ normal(0, var=100);
                prior beta ~ normal(0, var=100);
                prior sigma2 ~ igamma(0.01, s=0.01);
                model outcome ~ normal(intercept + beta*covariate, var=sigma2);
            %end;
            /* Add more models as needed */
            
            title "Bayesian Model &i: &model";
        run;
        
        /* Extract DIC */
        data _null_;
            set &model._dic;
            if Label = 'DIC';
            call symputx("dic_&model", Value);
        run;
        
        /* Add to comparison table */
        data temp_&model;
            model = "&model";
            DIC = &&dic_&model;
            output;
        run;
        
        proc append base=model_comparison data=temp_&model;
        run;
        
    %end;
    
    /* Rank models */
    proc sort data=model_comparison;
        by DIC;
    run;
    
    data model_comparison;
        set model_comparison;
        by DIC;
        
        retain best_dic;
        if _n_ = 1 then best_dic = DIC;
        
        delta_dic = DIC - best_dic;
        
        /* Model weights (rough approximation) */
        if delta_dic = 0 then weight = 1;
        else if delta_dic < 2 then weight = 0.8;
        else if delta_dic < 7 then weight = 0.2;
        else weight = 0.05;
        
        format DIC delta_dic 8.1 weight percent8.1;
    run;
    
    proc print data=model_comparison noobs;
        title "Bayesian Model Comparison";
        var model DIC delta_dic weight;
    run;

%mend bayesian_model_comparison;
```

## Implementation Best Practices

### Prior Sensitivity Analysis

```sas
/******************************************************************************
ANALYSIS: Prior Sensitivity Analysis
DESIGN: Assess robustness to prior specifications
******************************************************************************/

%macro prior_sensitivity_analysis(data=, priors=prior1 prior2 prior3);

    %let npriors = %sysfunc(countw(&priors));
    
    data sensitivity_results;
        length prior_specification $30;
        treatment_effect_mean = .; 
        treatment_effect_std = .;
        prob_positive = .;
        stop;
    run;
    
    %do i = 1 %to &npriors;
        %let prior_name = %scan(&priors, &i);
        
        ods output PostSummaries=post_&prior_name noprint;
        
        proc mcmc data=&data nbi=2000 nmc=10000 seed=54321;
            
            parms mu_control 0 mu_treatment 0 sigma2 1;
            
            %if &prior_name = prior1 %then %do;
                /* Non-informative priors */
                prior mu_control ~ normal(0, var=1000);
                prior mu_treatment ~ normal(0, var=1000);
            %end;
            %else %if &prior_name = prior2 %then %do;
                /* Weakly informative priors */  
                prior mu_control ~ normal(0, var=100);
                prior mu_treatment ~ normal(0, var=100);
            %end;
            %else %if &prior_name = prior3 %then %do;
                /* Informative priors */
                prior mu_control ~ normal(10, var=4);
                prior mu_treatment ~ normal(12, var=9);
            %end;
            
            prior sigma2 ~ igamma(0.01, s=0.01);
            
            if treatment = 'Control' then
                model outcome ~ normal(mu_control, var=sigma2);
            else if treatment = 'Treatment' then
                model outcome ~ normal(mu_treatment, var=sigma2);
            
            treatment_effect = mu_treatment - mu_control;
            prob_positive = (treatment_effect > 0);
            
            title "Prior Sensitivity: &prior_name";
        run;
        
        /* Extract key results */
        data temp_&prior_name;
            set post_&prior_name;
            if Parameter = 'treatment_effect';
            
            prior_specification = "&prior_name";
            treatment_effect_mean = Mean;
            treatment_effect_std = StdDev;
            
            keep prior_specification treatment_effect_mean treatment_effect_std;
        run;
        
        /* Calculate probability */
        proc means data=mcmc_&prior_name noprint;
            var prob_positive;
            output out=prob_&prior_name mean=prob_pos_mean;
        run;
        
        data temp_&prior_name;
            merge temp_&prior_name prob_&prior_name;
            prob_positive = prob_pos_mean;
            drop prob_pos_mean;
        run;
        
        proc append base=sensitivity_results data=temp_&prior_name;
        run;
        
    %end;
    
    /* Display sensitivity results */
    proc print data=sensitivity_results noobs;
        title "Prior Sensitivity Analysis Results";
        format treatment_effect_mean treatment_effect_std 8.3 
               prob_positive percent8.1;
    run;
    
    /* Calculate sensitivity measures */
    proc means data=sensitivity_results;
        var treatment_effect_mean treatment_effect_std prob_positive;
        output out=sensitivity_summary
               range(treatment_effect_mean)=effect_range
               range(prob_positive)=prob_range;
    run;
    
    data _null_;
        set sensitivity_summary;
        put "Sensitivity Analysis Summary:";
        put "Treatment effect range across priors: " effect_range 6.3;
        put "Probability positive range: " prob_range percent8.1;
        
        if effect_range < 0.5 then 
            put "LOW sensitivity to prior specification";
        else if effect_range < 1.0 then
            put "MODERATE sensitivity to prior specification";
        else
            put "HIGH sensitivity to prior specification";
    run;

%mend prior_sensitivity_analysis;
```

### Regulatory Reporting Template

```sas
/******************************************************************************
ANALYSIS: Regulatory Reporting for Bayesian Analysis
DESIGN: Comprehensive reporting following regulatory guidance
******************************************************************************/

%macro bayesian_regulatory_report(data=, outpath=);

    /* Main Bayesian analysis */
    ods output PostSummaries=main_results
               PostIntervals=main_intervals;
    
    proc mcmc data=&data nbi=3000 nmc=15000 seed=12345
              plots=(trace autocorr density) diagnostics=all;
        
        /* Parameters and priors */
        parms mu_control 0 mu_treatment 0 sigma2 1;
        
        /* Document prior justification */
        prior mu_control ~ normal(0, var=100);  /* Weakly informative */
        prior mu_treatment ~ normal(0, var=100); /* Weakly informative */  
        prior sigma2 ~ igamma(0.01, s=0.01);    /* Non-informative */
        
        if treatment = 'Control' then
            model outcome ~ normal(mu_control, var=sigma2);
        else if treatment = 'Treatment' then
            model outcome ~ normal(mu_treatment, var=sigma2);
        
        /* Key estimands */
        treatment_effect = mu_treatment - mu_control;
        
        /* Regulatory decision criteria */
        prob_positive = (treatment_effect > 0);
        prob_clinically_meaningful = (treatment_effect > 3.0);  /* Pre-specified */
        prob_non_inferior = (treatment_effect > -1.0);         /* NI margin */
        
        title "Primary Bayesian Analysis for Regulatory Submission";
    run;
    
    /* Frequentist analysis for comparison */
    proc ttest data=&data cochran ci=equal umpu;
        class treatment;
        var outcome;
        ods output TTests=freq_results;
        title "Frequentist Analysis for Comparison";
    run;
    
    /* Prior sensitivity analysis */
    %prior_sensitivity_analysis(data=&data, 
                                priors=weakly_informative skeptical enthusiastic);
    
    /* Model checking */
    /* ... posterior predictive checks code ... */
    
    /* Comprehensive summary report */
    data regulatory_summary;
        length analysis_component $50 result $100;
        
        /* Key posterior summaries */
        analysis_component = 'Treatment Effect (Posterior Mean)';
        /* Extract from main_results */
        
        analysis_component = 'Treatment Effect (95% Credible Interval)';
        /* Extract from main_intervals */
        
        analysis_component = 'Probability of Positive Effect';
        /* Calculate from posterior samples */
        
        analysis_component = 'Probability of Clinical Benefit';
        /* Pre-specified threshold */
        
        /* Frequentist comparison */
        analysis_component = 'Frequentist p-value (two-sided)';
        /* Extract from freq_results */
        
        analysis_component = 'Frequentist 95% Confidence Interval';
        /* Extract from freq_results */
        
        output;
    run;
    
    /* Export all results */
    %if %length(&outpath) > 0 %then %do;
        
        ods pdf file="&outpath/bayesian_regulatory_report.pdf";
        
        proc print data=regulatory_summary noobs;
            title "Bayesian Analysis Summary for Regulatory Submission";
        run;
        
        proc print data=main_results;
            title "Posterior Summary Statistics";
        run;
        
        proc print data=sensitivity_results;  
            title "Prior Sensitivity Analysis";
        run;
        
        ods pdf close;
        
        /* Export datasets */
        proc export data=regulatory_summary
                    outfile="&outpath/bayesian_summary.xlsx"
                    dbms=xlsx replace;
        run;
        
    %end;

%mend bayesian_regulatory_report;
```

## Usage Guidelines

### When to Use Bayesian Methods

```
BAYESIAN METHOD SELECTION CRITERIA

Strong Candidates:
├── Historical Data Available
│   ├── Previous studies in indication
│   ├── Meta-analysis data  
│   └── External control data
├── Adaptive Design Features
│   ├── Response-adaptive randomization
│   ├── Interim monitoring
│   └── Dose finding studies
├── Complex Decision Making
│   ├── Multiple endpoints
│   ├── Benefit-risk assessment
│   └── Probability statements needed
└── Small Sample Situations
    ├── Rare diseases
    ├── Pediatric studies  
    └── Early phase trials

Consider Carefully:
├── Regulatory Acceptance
│   ├── Agency experience with approach
│   ├── Guidance document alignment
│   └── Precedent in therapeutic area
├── Stakeholder Understanding
│   ├── Medical team comfort
│   ├── Regulatory team experience
│   └── Commercial team interpretation
└── Computational Resources
    ├── Software availability
    ├── Statistical expertise
    └── Timeline constraints

Avoid When:
├── No Prior Information
│   └── Non-informative priors may not add value
├── Simple Analyses Sufficient  
│   └── Standard frequentist methods adequate
├── Regulatory Resistance
│   └── Agency skepticism in therapeutic area
└── Resource Constraints
    └── Limited statistical expertise or time
```

### Computational Considerations

```
SAS PROC MCMC Best Practices:

Chain Diagnostics:
□ Run multiple chains from different starting values
□ Check trace plots for mixing
□ Assess autocorrelation functions  
□ Monitor Gelman-Rubin diagnostics
□ Use effective sample size for inference

Burn-in and Iterations:
□ Adequate burn-in period (typically 1000-5000)
□ Sufficient post-burn-in samples (10000+)
□ Thin chains if high autocorrelation
□ Monitor Monte Carlo standard errors

Prior Specification:
□ Justify all prior distributions
□ Conduct sensitivity analysis
□ Check proper vs improper priors
□ Avoid overly informative priors without justification

Model Checking:
□ Posterior predictive checks
□ Compare to frequentist analyses
□ Assess model assumptions
□ Check for computational issues
```

---

*These Bayesian analysis templates provide comprehensive frameworks for clinical trial applications. Customize based on specific study requirements, regulatory expectations, and therapeutic area considerations. Always conduct thorough sensitivity analyses and validation.*