# Part 4: Advanced Statistical Methods in Clinical Trials
## Beyond the t-test: Advanced Statistical Methods for Modern Clinical Trials

### Overview

Modern clinical trials require sophisticated statistical methods to address complex research questions, handle challenging data structures, and meet evolving regulatory expectations. This section provides biostatisticians with comprehensive guidance on advanced methods including survival analysis, longitudinal data modeling, adaptive designs, and Bayesian approaches.

---

## 1. Survival Analysis in Clinical Trials

### 1.1 Fundamental Concepts

**Key Terminology:**
- **Event**: The outcome of interest (death, disease progression, toxicity)
- **Censoring**: Incomplete observation of event time
- **Hazard function**: Instantaneous risk of event at time t
- **Survival function**: Probability of surviving beyond time t

**Types of Censoring:**
- **Right censoring**: Most common in clinical trials
- **Left censoring**: Event occurred before observation period
- **Interval censoring**: Event occurred within a time interval
- **Informative vs. non-informative**: Censoring related to outcome

### 1.2 Kaplan-Meier Estimation

#### Method Overview
```
Non-parametric estimator of survival function:

Ŝ(t) = ∏(i:ti≤t) [1 - di/ni]

where:
- di = number of events at time ti
- ni = number at risk at time ti
- Product taken over all event times ≤ t
```

#### SAS Implementation
```sas
/* Basic Kaplan-Meier Analysis */
proc lifetest data=survival_data plots=survival;
    time survtime*censor(1);
    strata treatment;
    
    /* Options for enhanced output */
    ods select SurvivalPlot ProductLimitEstimates;
run;

/* Advanced Kaplan-Meier with confidence intervals */
proc lifetest data=survival_data plots=(survival(atrisk=0 to 60 by 12)) 
              conftype=loglog alpha=0.05;
    time survtime*censor(1);
    strata treatment / test=(logrank wilcoxon tarone);
    
    /* Median survival and quartiles */
    ods select Quartiles HomTests;
run;
```

#### Interpretation Guidelines
```
Key Statistics to Report:

1. Median Survival Time
   - Point estimate with 95% CI
   - "Not reached" if <50% events observed
   
2. Survival Rates at Key Timepoints
   - 1-year, 2-year, 5-year rates
   - With 95% confidence intervals
   
3. Number at Risk Tables
   - At regular time intervals
   - Essential for interpretation

4. Statistical Tests
   - Log-rank test for overall difference
   - Wilcoxon test if early differences expected
```

### 1.3 Cox Proportional Hazards Model

#### Model Specification
```
Hazard function: h(t|X) = h₀(t) × exp(β₁X₁ + β₂X₂ + ... + βₚXₚ)

where:
- h₀(t) = baseline hazard function
- β = regression coefficients (log hazard ratios)
- X = covariates
```

#### SAS Implementation
```sas
/* Basic Cox Regression */
proc phreg data=survival_data;
    model survtime*censor(1) = treatment age sex;
    
    /* Hazard ratios with confidence intervals */
    hazardratio 'Treatment Effect' treatment / diff=ref;
    
    /* Assess proportional hazards assumption */
    assess ph / resample;
run;

/* Stratified Cox Model */
proc phreg data=survival_data;
    model survtime*censor(1) = treatment age;
    strata site; /* Stratify by site to control for site effects */
    
    /* Test for treatment by covariate interactions */
    treatment_age = treatment * age;
    model survtime*censor(1) = treatment age treatment_age;
    
    test treatment_age; /* Test interaction term */
run;

/* Time-dependent covariates */
proc phreg data=survival_data;
    model survtime*censor(1) = treatment trt_time;
    
    /* Create time-dependent treatment effect */
    if treatment=1 then trt_time = treatment * survtime;
    else trt_time = 0;
run;
```

#### Model Assumptions and Diagnostics
```
Proportional Hazards Assumption:

1. Graphical Assessment:
   - Log-log survival plots should be parallel
   - Schoenfeld residuals vs. time should show no pattern

2. Statistical Tests:
   - Global test of proportional hazards
   - Individual covariate tests

3. Solutions if Violated:
   - Stratification by violating covariate
   - Time-dependent covariates
   - Parametric models
   - Accelerated failure time models
```

### 1.4 Advanced Survival Methods

#### Accelerated Failure Time (AFT) Models
```sas
/* Parametric AFT Models */

/* Weibull AFT Model */
proc lifereg data=survival_data;
    model survtime*censor(1) = treatment age sex / distribution=weibull;
    
    /* Output parameter estimates and survival predictions */
    output out=aft_results predicted=pred_surv;
run;

/* Log-normal AFT Model */
proc lifereg data=survival_data;
    model survtime*censor(1) = treatment age sex / distribution=lognormal;
    
    /* Likelihood ratio test for model comparison */
    contrast 'Treatment Effect' treatment 1;
run;

/* Generalized Gamma Model (most flexible) */
proc lifereg data=survival_data;
    model survtime*censor(1) = treatment age sex / distribution=gamma;
run;
```

#### Competing Risks Analysis
```
When Multiple Event Types Possible:

Cumulative Incidence Function (CIF):
- Probability of experiencing event k by time t
- Accounts for competing events

Fine-Gray Subdistribution Hazards:
- Modified Cox model for competing risks
- Treats competing events as continued observation
```

```sas
/* Competing Risks Analysis */
proc lifetest data=competing_risks plots=cif;
    time time_to_event*censor(0) / eventcode=1; /* Event of interest */
    strata treatment;
    
    /* Specify competing event codes */
    eventcode (code=1 'Disease Progression')
             (code=2 'Death without Progression')
             (code=3 'Second Primary Cancer');
run;

/* Fine-Gray Model */
proc phreg data=competing_risks;
    class treatment;
    model time_to_event*censor(0) = treatment age sex / eventcode=1;
    
    /* Subdistribution hazard ratios */
    hazardratio 'Treatment vs Control' treatment / diff=ref;
run;
```

### 1.5 Regulatory Considerations for Survival Analysis

#### FDA Guidance Alignment
```
Key Requirements:

1. Primary Analysis Population:
   - Intent-to-treat for confirmatory trials
   - Per-protocol as supportive analysis

2. Censoring Rules:
   - Pre-specified in statistical analysis plan
   - Consistent application across treatment groups
   - Document reasons for censoring

3. Follow-up Requirements:
   - Adequate follow-up for maturity
   - Minimum follow-up specified
   - Administrative censoring clearly defined

4. Multiplicity Considerations:
   - Multiple time-to-event endpoints
   - Interim analyses impact
   - Subgroup analyses pre-specified
```

---

## 2. Longitudinal Data Analysis

### 2.1 Mixed Models for Repeated Measures (MMRM)

#### Model Framework
```
Linear Mixed Model:
Y = Xβ + Zu + ε

where:
- Y = response vector
- X = fixed effects design matrix  
- β = fixed effects parameters
- Z = random effects design matrix
- u = random effects (subject-specific)
- ε = residual error
```

#### SAS Implementation
```sas
/* Basic MMRM Analysis */
proc mixed data=longitudinal_data method=reml;
    class usubjid treatment visit;
    model response = treatment visit treatment*visit baseline / ddfm=kr;
    repeated visit / subject=usubjid type=un; /* Unstructured covariance */
    
    /* LSMeans for treatment differences at each visit */
    lsmeans treatment*visit / pdiff cl;
    
    /* Contrasts for specific comparisons */
    contrast 'Treatment at Week 12' treatment*visit 1 0 0 -1 0 0;
run;

/* Model with Baseline Covariate */
proc mixed data=longitudinal_data method=reml;
    class usubjid treatment visit;
    model response = treatment visit treatment*visit baseline 
                     baseline*visit / ddfm=kr;
    repeated visit / subject=usubjid type=un;
    
    /* Control baseline imbalance */
    estimate 'Treatment Effect at Week 12' 
             treatment 1 -1 treatment*visit 0 0 1 0 0 -1;
run;
```

#### Covariance Structure Selection
```
Common Covariance Structures:

1. Unstructured (UN):
   - Most flexible, estimates all variances/covariances
   - Use when sample size adequate
   - Gold standard for regulatory submissions

2. Compound Symmetry (CS):
   - Assumes constant correlation between timepoints
   - Restrictive assumption

3. Autoregressive AR(1):
   - Correlation decreases with time separation
   - Good for equally spaced visits

4. Toeplitz (TOEP):
   - Correlation depends only on time separation
   - More flexible than AR(1)

5. Spatial Power (SP(POW)):
   - For unequally spaced visits
   - Correlation = ρ^|ti-tj|
```

```sas
/* Compare Covariance Structures */
%macro fit_covariance_structure(structure);
    proc mixed data=longitudinal_data method=ml; /* Use ML for comparison */
        class usubjid treatment visit;
        model response = treatment visit treatment*visit baseline;
        repeated visit / subject=usubjid type=&structure;
        ods output FitStatistics=fit_&structure;
    run;
%mend;

%fit_covariance_structure(un);
%fit_covariance_structure(ar(1));
%fit_covariance_structure(cs);
%fit_covariance_structure(toep);

/* Compare AIC/BIC values to select best structure */
data compare_structures;
    set fit_un fit_ar fit_cs fit_toep;
run;
```

### 2.2 Generalized Estimating Equations (GEE)

#### When to Use GEE vs. Mixed Models
```
GEE Advantages:
- Population-averaged interpretation
- Robust to misspecification of correlation structure
- Handles missing data under MAR assumption
- Computationally stable

Mixed Models Advantages:
- Subject-specific interpretation
- Handle missing data under MAR/MNAR
- Allows random effects
- Better for prediction
```

#### SAS Implementation
```sas
/* GEE for Continuous Outcomes */
proc genmod data=longitudinal_data;
    class usubjid treatment visit;
    model response = treatment visit treatment*visit baseline / 
          dist=normal link=identity;
    repeated subject=usubjid / withinsubject=visit type=unstr corrw;
    
    /* Robust sandwich estimator */
    ods output GEEEmpPEst=gee_estimates;
run;

/* GEE for Binary Outcomes */
proc genmod data=binary_longitudinal;
    class usubjid treatment visit;
    model response(event='1') = treatment visit treatment*visit / 
          dist=binomial link=logit;
    repeated subject=usubjid / withinsubject=visit type=exch corrw;
    
    /* Output odds ratios */
    estimate 'Treatment OR at Week 12' treatment 1 treatment*visit 0 0 1 / exp;
run;

/* GEE for Count Data */
proc genmod data=count_longitudinal;
    class usubjid treatment visit;
    model count = treatment visit treatment*visit offset=log_offset / 
          dist=poisson link=log;
    repeated subject=usubjid / withinsubject=visit type=ar(1) corrw;
run;
```

### 2.3 Missing Data Handling

#### Missing Data Mechanisms
```
1. Missing Completely at Random (MCAR):
   - Missingness unrelated to observed or unobserved data
   - Complete case analysis valid but inefficient

2. Missing at Random (MAR):
   - Missingness depends only on observed data
   - Mixed models and GEE valid under MAR
   - Multiple imputation appropriate

3. Missing Not at Random (MNAR):
   - Missingness depends on unobserved data
   - Requires sensitivity analyses
   - Pattern mixture models or selection models
```

#### Multiple Imputation
```sas
/* Multiple Imputation for Longitudinal Data */
proc mi data=longitudinal_missing nimpute=20 seed=54321 out=imputed_data;
    class treatment visit;
    monotone logistic response1 response2 response3 = treatment baseline;
    var treatment baseline response1 response2 response3;
run;

/* Analyze each imputed dataset */
proc mixed data=imputed_data;
    by _imputation_;
    class usubjid treatment visit;
    model response = treatment visit treatment*visit baseline;
    repeated visit / subject=usubjid type=un;
    ods output SolutionF=mixed_results;
run;

/* Combine results using Rubin's rules */
proc mianalyze parms(classvar=full)=mixed_results;
    class effect;
    modeleffects intercept treatment visit treatment*visit baseline;
    ods output ParameterEstimates=final_results;
run;
```

#### Pattern-Mixture Models
```sas
/* Pattern-Mixture Model Approach */
proc freq data=longitudinal_data;
    tables usubjid / out=subject_patterns noprint;
    /* Identify dropout patterns */
run;

data pattern_data;
    merge longitudinal_data subject_patterns;
    by usubjid;
    
    /* Define dropout pattern groups */
    if last_visit = 1 then dropout_pattern = 'Early';
    else if last_visit <= 3 then dropout_pattern = 'Middle'; 
    else dropout_pattern = 'Complete';
run;

proc mixed data=pattern_data;
    class usubjid treatment visit dropout_pattern;
    model response = treatment visit treatment*visit 
                     dropout_pattern dropout_pattern*treatment
                     dropout_pattern*visit;
    repeated visit / subject=usubjid type=un;
    
    /* Test sensitivity to dropout pattern assumptions */
    contrast 'Dropout Pattern Effect' dropout_pattern 1 -1 0;
run;
```

---

## 3. Adaptive Trial Designs

### 3.1 Group Sequential Designs

#### Design Framework
```
Sequential Monitoring:
- Pre-planned interim analyses at information times t₁, t₂, ..., tₖ
- Efficacy and/or futility boundaries
- Type I error control via spending functions
- Early stopping for overwhelming benefit or futility
```

#### Alpha Spending Functions
```sas
/* O'Brien-Fleming Boundaries */
proc seqdesign altref=1.5;
    OBrienFleming: design nstages=4
                  method=errfuncobf
                  alpha=0.025 beta=0.1
                  ;
    samplesize model=twosamplemean(stddev=2);
    ods output boundary=ob_boundaries;
run;

/* Pocock Boundaries */
proc seqdesign altref=1.5;
    Pocock: design nstages=4
            method=errfuncpoc  
            alpha=0.025 beta=0.1
            ;
    samplesize model=twosamplemean(stddev=2);
run;

/* Lan-DeMets with O'Brien-Fleming-type spending */
proc seqdesign altref=1.5;
    LanDeMets: design nstages=4
               method=errfunclandomets
               alpha=0.025 beta=0.1
               ;
    samplesize model=twosamplemean(stddev=2);
    
    /* Custom alpha spending function */
    alphaspend=alpha*power(info, 3);
run;
```

#### Interim Analysis Implementation
```sas
/* Sequential Testing */
proc seqtest Boundary=ob_boundaries;
    TwoSampleMean: test statistic=(4.2, 3.8, 2.1)
                  info=(0.25, 0.5, 0.75)
                  ;
run;

/* Conditional Power Calculation */
proc seqtest Boundary=ob_boundaries;
    TwoSampleMean: test statistic=2.1
                  info=0.75
                  cref=1.5  /* Continue under alternative */
                  ;
    /* Output conditional power for futility assessment */
    ods output ConditionalPower=cond_power;
run;

/* Futility Analysis with Beta Spending */
proc seqdesign altref=1.5;
    BetaSpending: design nstages=4
                  method=errfuncobf
                  alpha=0.025 beta=0.1
                  betaspend=beta*power(info, 1.5)
                  ;
run;
```

### 3.2 Adaptive Sample Size Re-estimation

#### Blinded Sample Size Re-estimation
```sas
/* Variance Re-estimation (Blinded) */
proc mixed data=interim_data method=ml;
    class treatment;
    model response = treatment;
    
    /* Estimate pooled variance */
    ods output CovParms=variance_estimates;
run;

data _null_;
    set variance_estimates;
    if CovParm = 'Residual';
    
    /* Recalculate sample size with observed variance */
    observed_sd = sqrt(Estimate);
    
    /* Original assumptions */
    assumed_sd = 2.0;
    original_n = 100;
    effect_size = 1.5;
    alpha = 0.025;
    beta = 0.1;
    
    /* Inflation factor */
    inflation = (observed_sd / assumed_sd)**2;
    new_n = ceil(original_n * inflation);
    
    put "Observed SD: " observed_sd;
    put "Inflation Factor: " inflation;
    put "New Sample Size: " new_n;
run;
```

#### Unblinded Sample Size Re-estimation
```sas
/* Treatment Effect Re-estimation */
proc ttest data=interim_data;
    class treatment;
    var response;
    ods output TTests=ttest_results;
run;

data _null_;
    set ttest_results;
    if Method = 'Pooled';
    
    observed_effect = Estimate;
    observed_se = StdErr;
    
    /* Original assumptions */
    target_effect = 1.5;
    original_power = 0.9;
    alpha = 0.025;
    
    /* Calculate conditional power */
    z_alpha = probit(1 - alpha);
    z_beta = probit(original_power);
    
    /* Sample size adjustment */
    if observed_effect > 0 then do;
        new_power = 1 - probnorm(z_alpha - observed_effect/observed_se);
        
        if new_power < 0.8 then do;
            /* Increase sample size */
            inflation = (target_effect / observed_effect)**2;
            put "Recommended inflation factor: " inflation;
        end;
    end;
run;
```

### 3.3 Population Enrichment Designs

#### Biomarker-Driven Adaptation
```sas
/* Interim Analysis for Population Selection */
proc mixed data=biomarker_interim;
    class treatment biomarker_status;
    model response = treatment biomarker_status treatment*biomarker_status;
    
    /* Test treatment effect in biomarker subgroups */
    lsmeans treatment*biomarker_status / pdiff;
    
    /* Interaction test */
    contrast 'Biomarker Interaction' treatment*biomarker_status 1 -1 -1 1;
    
    ods output Diffs=treatment_effects;
run;

/* Decision Rule for Enrichment */
data enrichment_decision;
    set treatment_effects;
    
    if biomarker_status = 'Positive' and Estimate > 1.0 and Probt < 0.1 then do;
        recommendation = 'Enrich for biomarker positive';
        continue_all = 'No';
    end;
    else if biomarker_status = 'Negative' and Estimate > 0.5 then do;
        recommendation = 'Continue both populations';
        continue_all = 'Yes';
    end;
    else do;
        recommendation = 'Stop for futility';
        continue_all = 'No';
    end;
    
    output;
run;
```

### 3.4 Platform and Umbrella Trials

#### Master Protocol Statistical Framework
```
Platform Trial Design:
- Multiple experimental arms vs shared control
- Adaptive randomization based on performance
- Arms can enter/exit during trial
- Borrowing of control information

Key Statistical Challenges:
- Type I error control across multiple arms
- Time trends in shared control
- Operational bias from adaptive features
```

```sas
/* Bayesian Adaptive Randomization */
proc mcmc data=platform_data nbi=1000 nmc=5000 seed=54321;
    parms theta1 0 theta2 0 theta_control 0;
    
    /* Priors */
    prior theta1 ~ normal(0, var=100);
    prior theta2 ~ normal(0, var=100); 
    prior theta_control ~ normal(0, var=100);
    
    /* Likelihood for each arm */
    if arm = 'Control' then
        model response ~ normal(theta_control, var=1);
    else if arm = 'Arm1' then  
        model response ~ normal(theta1, var=1);
    else if arm = 'Arm2' then
        model response ~ normal(theta2, var=1);
    
    ods output PostSummaries=posterior_summaries;
run;

/* Adaptive Randomization Probabilities */
data randomization_probs;
    set posterior_summaries;
    
    /* Probability of being best arm */
    if Parameter = 'theta1' then prob_best_1 = (Mean > max_other_arms);
    
    /* Response-adaptive allocation */
    allocation_prob = prob_best ** allocation_power;
    
    /* Ensure minimum allocation */
    allocation_prob = max(allocation_prob, 0.10);
run;
```

---

## 4. Bayesian Methods in Clinical Trials

### 4.1 Bayesian Framework

#### Bayes' Theorem Application
```
Posterior ∝ Likelihood × Prior

π(θ|data) ∝ L(data|θ) × π(θ)

where:
- π(θ|data) = posterior distribution of parameter θ
- L(data|θ) = likelihood function
- π(θ) = prior distribution
```

#### Prior Selection Guidelines
```
Types of Priors:

1. Informative Priors:
   - Incorporate external data
   - Historical controls
   - Expert opinion
   - Meta-analyses

2. Weakly Informative Priors:
   - Regularize estimates
   - Prevent extreme values
   - Improve convergence

3. Non-informative Priors:
   - Minimize prior influence
   - Let data dominate
   - Uniform or reference priors

4. Skeptical Priors:
   - Conservative approach
   - Center on null effect
   - Require strong evidence
```

### 4.2 Bayesian Analysis Implementation

#### SAS PROC MCMC Implementation
```sas
/* Bayesian Two-Sample Comparison */
proc mcmc data=bayesian_trial nbi=2000 nmc=10000 seed=12345
          plots=(trace autocorr);
    
    /* Parameters */
    parms mu_trt 0 mu_ctrl 0 sigma2 1;
    
    /* Priors */
    prior mu_trt ~ normal(0, var=100);    /* Weakly informative */
    prior mu_ctrl ~ normal(0, var=100);   /* Weakly informative */
    prior sigma2 ~ igamma(0.01, s=0.01);  /* Non-informative */
    
    /* Likelihood */
    if treatment = 'Active' then
        model response ~ normal(mu_trt, var=sigma2);
    else
        model response ~ normal(mu_ctrl, var=sigma2);
    
    /* Derived quantities */
    treatment_effect = mu_trt - mu_ctrl;
    
    ods output PostSummaries=posterior_results;
run;

/* Posterior Probability Calculations */
data posterior_probabilities;
    set posterior_results;
    
    if Parameter = 'treatment_effect';
    
    /* Probability of positive effect */
    prob_positive = 1 - probnorm(0, Mean, StdDev);
    
    /* Probability of clinically meaningful effect (>1.0) */
    prob_meaningful = 1 - probnorm(1.0, Mean, StdDev);
    
    /* Probability of harm (<-0.5) */
    prob_harm = probnorm(-0.5, Mean, StdDev);
    
    output;
run;
```

#### Historical Data Integration
```sas
/* Power Prior for Historical Data Integration */
proc mcmc data=current_data nbi=2000 nmc=10000;
    
    /* Current study parameters */
    parms mu_current 0 sigma2_current 1;
    
    /* Historical data parameters (fixed) */
    mu_historical = 2.1;      /* Historical mean */
    n_historical = 50;        /* Historical sample size */
    sigma2_historical = 4.0;  /* Historical variance */
    
    /* Power prior weight (0 ≤ a₀ ≤ 1) */
    a0 = 0.5; /* Discount historical data by 50% */
    
    /* Power prior for current mean */
    prior_precision = a0 * n_historical / sigma2_historical;
    prior mu_current ~ normal(mu_historical, var=1/prior_precision);
    
    /* Non-informative prior for variance */
    prior sigma2_current ~ igamma(0.01, s=0.01);
    
    /* Likelihood for current data */
    model response ~ normal(mu_current, var=sigma2_current);
run;
```

### 4.3 Bayesian Adaptive Designs

#### Bayesian Response-Adaptive Randomization
```sas
/* Bayesian RAR Implementation */
%macro bayesian_rar(current_data=, allocation_rule=);
    
    /* Fit Bayesian model to current data */
    proc mcmc data=&current_data nbi=1000 nmc=5000 noprint;
        parms theta_control 0 theta_trt 0 sigma2 1;
        
        prior theta_control ~ normal(0, var=100);
        prior theta_trt ~ normal(0, var=100);
        prior sigma2 ~ igamma(0.01, s=0.01);
        
        if treatment = 'Control' then
            model response ~ normal(theta_control, var=sigma2);
        else
            model response ~ normal(theta_trt, var=sigma2);
        
        ods output PostSummaries=mcmc_results;
    run;
    
    /* Calculate allocation probabilities */
    data allocation_probs;
        set mcmc_results;
        
        if Parameter = 'theta_trt' then prob_trt_better = 1 - probnorm(0, Mean, StdDev);
        if Parameter = 'theta_control' then prob_ctrl_better = probnorm(0, Mean, StdDev);
        
        /* Square-root rule for allocation */
        %if &allocation_rule = sqrt %then %do;
            allocation_trt = sqrt(prob_trt_better) / 
                           (sqrt(prob_trt_better) + sqrt(prob_ctrl_better));
        %end;
        
        /* Ensure minimum allocation */
        allocation_trt = max(allocation_trt, 0.10);
        allocation_trt = min(allocation_trt, 0.90);
        
        output;
    run;
    
%mend bayesian_rar;
```

#### Bayesian Futility Monitoring
```sas
/* Predictive Probability of Success */
proc mcmc data=interim_data nbi=2000 nmc=10000;
    
    /* Current parameters */
    parms mu_diff 0 sigma2 1;
    
    /* Priors based on interim data */
    prior mu_diff ~ normal(interim_estimate, var=interim_variance);
    prior sigma2 ~ igamma(a_sigma, s=b_sigma);
    
    /* Likelihood */
    model diff_score ~ normal(mu_diff, var=sigma2);
    
    /* Predictive probability calculation */
    /* Simulate future data and calculate P(success at final analysis) */
    
    ods output PostSummaries=predictive_results;
run;

/* Decision Rules */
data futility_decision;
    set predictive_results;
    
    if Parameter = 'mu_diff';
    
    /* Calculate predictive probability of success */
    remaining_n = final_n - current_n;
    future_se = sqrt(sigma2 / remaining_n);
    
    /* Probability of positive result at final analysis */
    pred_prob_success = 1 - probnorm(critical_value, Mean, future_se);
    
    if pred_prob_success < 0.10 then recommendation = 'Stop for Futility';
    else if pred_prob_success < 0.20 then recommendation = 'Consider Stopping';
    else recommendation = 'Continue';
    
    output;
run;
```

### 4.4 Borrowing from External Controls

#### Hierarchical Modeling Approach
```sas
/* Hierarchical Model for External Control Borrowing */
proc mcmc data=combined_data nbi=3000 nmc=15000;
    
    /* Study-specific parameters */
    parms mu_current 0 mu_external 0;
    parms tau2 1;  /* Between-study variance */
    parms sigma2 1; /* Within-study variance */
    
    /* Hierarchical structure */
    prior mu_current ~ normal(mu_pop, var=tau2);
    prior mu_external ~ normal(mu_pop, var=tau2);
    prior mu_pop ~ normal(0, var=100);
    
    /* Variance priors */
    prior tau2 ~ igamma(0.01, s=0.01);
    prior sigma2 ~ igamma(0.01, s=0.01);
    
    /* Likelihoods */
    if study = 'Current' then
        model response ~ normal(mu_current, var=sigma2);
    else if study = 'External' then
        model response ~ normal(mu_external, var=sigma2);
    
    /* Treatment effect in current study */
    current_effect = mu_current - external_control_mean;
    
    ods output PostSummaries=hierarchical_results;
run;
```

---

## 5. Specialized Statistical Designs

### 5.1 Crossover Trials

#### Statistical Model for Crossover
```
Mixed Model for 2×2 Crossover:

Yijk = μ + πj + τk + γi + δi×j + εijk

where:
- Yijk = response for subject i in period j receiving treatment k
- πj = period effect
- τk = treatment effect  
- γi = subject effect (random)
- δi×j = carryover effect
- εijk = residual error
```

#### SAS Implementation
```sas
/* 2x2 Crossover Analysis */
proc mixed data=crossover_data;
    class subject period treatment sequence;
    model response = period treatment / ddfm=kr;
    random subject(sequence);
    
    /* Test for carryover effects */
    lsmeans treatment / pdiff cl;
    
    /* Period and sequence effects */
    lsmeans period / pdiff;
    contrast 'Sequence Effect' sequence 1 -1;
run;

/* Test for Carryover Effects */
proc mixed data=crossover_data;
    class subject period treatment sequence;
    model response = period treatment carryover / ddfm=kr;
    random subject(sequence);
    
    /* If significant carryover, analyze first period only */
    contrast 'Carryover Effect' carryover 1;
run;

/* Higher-Order Crossover (Williams Square) */
proc mixed data=williams_square;
    class subject period treatment sequence;
    model response = sequence period treatment / ddfm=kr;
    random subject(sequence);
    
    /* Estimate treatment effects */
    lsmeans treatment / pdiff adjust=tukey;
run;
```

### 5.2 Cluster Randomized Trials

#### Intracluster Correlation Impact
```
Design Effect = 1 + (m-1)ρ

where:
- m = cluster size
- ρ = intracluster correlation coefficient
- Effective sample size = actual sample size / design effect
```

#### Statistical Analysis
```sas
/* GEE Analysis for Cluster Randomized Trial */
proc genmod data=cluster_trial;
    class cluster treatment;
    model outcome = treatment baseline_cluster / dist=binomial link=logit;
    repeated subject=cluster / withinsubject=subject_id type=exch corrw;
    
    /* Cluster-level covariates */
    estimate 'Treatment OR' treatment 1 / exp;
run;

/* Mixed Effects Analysis */
proc glimmix data=cluster_trial;
    class cluster treatment;
    model outcome(event='Yes') = treatment baseline_cluster / 
          dist=binomial link=logit;
    random intercept / subject=cluster;
    
    /* ICC estimation */
    covtest 'ICC > 0' . / lower;
run;

/* Cluster-Level Analysis */
proc summary data=cluster_trial;
    class cluster treatment;
    var outcome;
    output out=cluster_means mean=cluster_mean n=cluster_size;
run;

proc mixed data=cluster_means;
    class treatment;
    model cluster_mean = treatment;
    weight cluster_size;
    
    /* Weighted analysis by cluster size */
    lsmeans treatment / pdiff;
run;
```

### 5.3 N-of-1 Trials

#### Statistical Framework
```
Individual Patient Analysis:
- Multiple treatment periods per patient
- Randomized treatment sequences
- Washout periods between treatments
- Patient serves as own control
```

#### SAS Implementation
```sas
/* N-of-1 Trial Analysis */
proc mixed data=nof1_trial;
    by patient_id; /* Separate analysis per patient */
    class period treatment;
    model response = treatment period / ddfm=kr;
    
    /* Individual patient treatment effects */
    lsmeans treatment / pdiff;
    ods output Diffs=individual_effects;
run;

/* Meta-analysis across N-of-1 trials */
proc mixed data=individual_effects;
    model estimate = / ddfm=kr;
    weight 1/(stderr**2); /* Inverse variance weighting */
    
    /* Overall treatment effect */
    ods output SolutionF=pooled_effect;
run;

/* Bayesian Hierarchical N-of-1 Analysis */
proc mcmc data=nof1_trial nbi=2000 nmc=10000;
    by patient_id;
    
    parms mu_i 0 sigma2_i 1; /* Patient-specific parameters */
    
    /* Patient-specific priors */
    prior mu_i ~ normal(mu_pop, var=tau2);
    prior sigma2_i ~ igamma(a_sigma, s=b_sigma);
    
    /* Population parameters */
    prior mu_pop ~ normal(0, var=100);
    prior tau2 ~ igamma(0.01, s=0.01);
    
    /* Likelihood */
    if treatment = 'Active' then
        model response ~ normal(mu_i + delta_i, var=sigma2_i);
    else
        model response ~ normal(mu_i, var=sigma2_i);
run;
```

---

## Implementation Guidelines and Best Practices

### Method Selection Framework

#### Decision Tree for Advanced Methods
```
Data Structure Assessment:
├── Time-to-Event Outcome?
│   ├── Yes → Survival Analysis Methods
│   │   ├── Proportional hazards hold? → Cox Regression
│   │   ├── Parametric assumptions met? → AFT Models  
│   │   └── Competing events present? → Competing Risks
│   └── No → Continue Assessment
├── Repeated Measures?
│   ├── Yes → Longitudinal Methods
│   │   ├── Normal distribution? → MMRM
│   │   ├── Binary/Count outcomes? → GEE or GLMM
│   │   └── Missing data pattern? → Multiple Imputation
│   └── No → Continue Assessment
├── Adaptive Features Needed?
│   ├── Yes → Adaptive Design Methods
│   │   ├── Efficacy monitoring? → Group Sequential
│   │   ├── Sample size uncertainty? → SSR
│   │   └── Population selection? → Enrichment Design
│   └── No → Standard Methods
└── Prior Information Available?
    ├── Yes → Consider Bayesian Methods
    ├── External controls? → Historical Borrowing
    └── No → Frequentist Approach
```

### Regulatory Considerations

#### FDA Guidance Alignment
```
Key Requirements by Method:

Survival Analysis:
□ Censoring assumptions documented
□ Proportional hazards assessed
□ Sensitivity analyses for key assumptions
□ Adequate follow-up demonstrated

Longitudinal Analysis:
□ Missing data mechanism assumed
□ Sensitivity analyses for MNAR
□ Covariance structure justified
□ Multiple imputation validation

Adaptive Designs:
□ Type I error control demonstrated
□ Operational bias minimized
□ Pre-specified adaptation rules
□ Simulation studies provided

Bayesian Methods:
□ Prior justification provided
□ Sensitivity to prior assessed
□ Frequentist properties evaluated
□ Regulatory precedent considered
```

### Software and Implementation

#### SAS Procedures Summary
| Method | Primary PROC | Alternative | Key Options |
|--------|-------------|-------------|-------------|
| Survival Analysis | LIFETEST, PHREG | LIFEREG | plots=, test=, hazardratio |
| Mixed Models | MIXED | GLIMMIX | method=reml, type=un, ddfm=kr |
| GEE | GENMOD | | repeated, type=, corrw |
| Sequential Design | SEQDESIGN | SEQTEST | method=, alpha=, beta= |
| Bayesian Analysis | MCMC | | nbi=, nmc=, prior |
| Multiple Imputation | MI | MIANALYZE | nimpute=, monotone |

#### Quality Control Checklist
```
□ Model Assumptions Verified
  □ Distributional assumptions checked
  □ Independence assumptions reasonable  
  □ Missing data mechanism assessed
  □ Outliers and influential points identified

□ Model Diagnostics Performed
  □ Residual analysis completed
  □ Goodness-of-fit assessed
  □ Convergence achieved (Bayesian/iterative methods)
  □ Sensitivity analyses conducted

□ Results Interpretation
  □ Clinical significance assessed
  □ Confidence intervals reported
  □ Effect sizes clinically interpretable
  □ Regulatory requirements met

□ Documentation Complete  
  □ Analysis methods justified
  □ Code documented and validated
  □ Results reproducible
  □ Assumptions clearly stated
```

---

## Resources and Next Steps

### Implementation Templates Available:
1. [Statistical Method Selection Flowcharts](./method-selection-flowcharts.md)
2. [SAS Macro Library for Advanced Methods](./sas-macro-library.md)
3. [Bayesian Analysis Templates](./bayesian-templates.md)
4. [Method Comparison Guidelines](./method-comparison-guide.md)

### Recommended Reading:
- ICH E9(R1): Statistical Principles for Clinical Trials (Addendum on Estimands)
- FDA Guidance: Adaptive Designs for Clinical Trials
- Regulatory guidance on missing data in clinical trials
- Bayesian methods in pharmaceutical research

### Next Section:
Proceed to [Part 5: SAS Programming Excellence](../part-5-sas-programming/) for implementation details and programming best practices.

---

*This content provides framework guidance for advanced statistical methods and should be adapted based on specific study requirements, therapeutic areas, and regulatory expectations.*