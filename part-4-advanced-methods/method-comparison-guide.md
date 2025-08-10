# Statistical Method Comparison Guide

## Survival Analysis Method Comparison

### Cox vs. Parametric Models

| Aspect | Cox Proportional Hazards | Accelerated Failure Time | Parametric Models |
|--------|-------------------------|------------------------|-------------------|
| **Assumptions** | Proportional hazards | Accelerated failure time | Specific distribution |
| **Flexibility** | Semi-parametric | Semi-parametric | Fully parametric |
| **Baseline Hazard** | Unspecified | Unspecified | Fully specified |
| **Interpretation** | Hazard ratios | Acceleration factors | Various parameters |
| **Extrapolation** | Limited | Limited | Good if correct distribution |
| **Model Checking** | PH assumption testable | AFT assumption testable | Goodness-of-fit tests |

#### When to Use Each Method

```
Cox Proportional Hazards:
✓ Primary interest in treatment comparisons
✓ Proportional hazards assumption reasonable  
✓ No need for survival curve prediction
✓ Regulatory preference for hazard ratios
✓ Multiple covariates to adjust for

Accelerated Failure Time:
✓ Proportional hazards violated
✓ Interest in time ratios vs. hazard ratios
✓ Treatment affects timing, not risk
✓ More intuitive interpretation needed

Parametric Models:
✓ Need survival curve extrapolation
✓ Health economic modeling
✓ Clear distributional assumptions
✓ Small sample sizes
✓ Interval-censored data
```

#### SAS Implementation Comparison

```sas
/* Cox Model */
proc phreg data=survival_data;
    model time*censor(0) = treatment age sex;
    hazardratio 'Treatment Effect' treatment / diff=ref;
run;

/* AFT Model */  
proc lifereg data=survival_data;
    model time*censor(0) = treatment age sex / distribution=weibull;
run;

/* Parametric PH Model */
proc phreg data=survival_data;
    model time*censor(0) = treatment age sex / distribution=weibull;
run;
```

### Competing Risks Methods Comparison

| Method | Use Case | Interpretation | SAS Implementation |
|--------|----------|----------------|-------------------|
| **Cause-Specific Hazards** | Etiology focus | Hazard ratios for specific causes | `proc phreg` with censoring |
| **Fine-Gray Subdistribution** | Clinical prediction | Cumulative incidence focus | `proc phreg` with `eventcode=` |
| **Multi-State Models** | Complex transitions | Transition probabilities | Custom programming or `proc lifetest` |

## Longitudinal Data Analysis Comparison

### MMRM vs. GEE

| Feature | Mixed Models (MMRM) | Generalized Estimating Equations |
|---------|-------------------|----------------------------------|
| **Interpretation** | Subject-specific (conditional) | Population-average (marginal) |
| **Missing Data** | Likelihood-based (MAR) | Complete cases or imputation |
| **Correlation Structure** | Random effects + residual | Working correlation |
| **Efficiency** | Optimal under correct model | Robust but less efficient |
| **Inference** | Model-based | Sandwich estimator |
| **Software** | `PROC MIXED` | `PROC GENMOD` |

#### Mathematical Frameworks

**Mixed Model:**
```
Y_ij = X_ij β + Z_ij b_i + ε_ij

Where:
- b_i ~ N(0, G) (random effects)
- ε_ij ~ N(0, R) (residual errors)
```

**GEE:**
```
g(μ_ij) = X_ij β
Var(Y_i) = V_i^{1/2} R_i(α) V_i^{1/2} φ

Where:
- g() is link function
- R_i(α) is working correlation
```

#### Decision Framework

```sas
/* Mixed Model - Subject-specific inference */
proc mixed data=longitudinal_data;
    class subject treatment visit;
    model response = treatment visit treatment*visit baseline;
    repeated visit / subject=subject type=un;
    
    /* Subject-specific interpretation */
    lsmeans treatment*visit / pdiff;
run;

/* GEE - Population-average inference */  
proc genmod data=longitudinal_data;
    class subject treatment visit;
    model response = treatment visit treatment*visit baseline;
    repeated subject=subject / withinsubject=visit type=unstr corrw;
    
    /* Population-average interpretation */
    lsmeans treatment*visit / pdiff;
run;
```

### Covariance Structure Selection

| Structure | When to Use | Parameters | SAS Code |
|-----------|-------------|------------|----------|
| **Unstructured (UN)** | Default choice, adequate sample size | t(t+1)/2 | `type=un` |
| **Compound Symmetry (CS)** | Constant correlation assumption | 2 | `type=cs` |
| **AR(1)** | Equally spaced, declining correlation | 2 | `type=ar(1)` |
| **Toeplitz** | Correlation by time distance | t | `type=toep` |
| **Spatial Power** | Unequally spaced visits | 2 | `type=sp(pow)` |

#### Model Selection Example

```sas
/* Compare covariance structures */
%macro compare_cov_structures;
    %let structures = un cs ar(1) toep sp(pow);
    %let n = %sysfunc(countw(&structures));
    
    %do i = 1 %to &n;
        %let struct = %scan(&structures, &i);
        
        proc mixed data=data method=ml;
            class subject visit treatment;
            model response = treatment visit treatment*visit;
            repeated visit / subject=subject type=&struct;
            ods output FitStatistics=fit_&i;
        run;
    %end;
    
    /* Compare AIC/BIC values */
%mend;
```

## Adaptive Design Methods

### Group Sequential vs. Adaptive Designs

| Feature | Group Sequential | Sample Size Re-estimation | Population Enrichment |
|---------|-----------------|-------------------------|----------------------|
| **Complexity** | Low | Medium | High |
| **Regulatory Acceptance** | High | Medium | Emerging |
| **Type I Error Control** | Established theory | Some inflation | Complex methods |
| **Operational Burden** | Low | Medium | High |
| **Timeline Impact** | Potential reduction | Neutral to positive | Variable |

#### Implementation Comparison

```sas
/* Group Sequential Design */
proc seqdesign altref=2.0;
    design1: design nstages=3 method=errfuncobf alpha=0.025;
    samplesize model=twosamplemean(stddev=5);
run;

/* Sample Size Re-estimation */
proc power;
    twosamplemean test=diff
                 meandiff=2.0  
                 stddev=6.5    /* Observed at interim */
                 alpha=0.025
                 power=0.90
                 ntotal=.;
run;

/* Monitoring Implementation */
proc seqtest boundary=design1;
    test1: test statistic=(2.8, 2.1) info=(0.5, 0.75);
run;
```

## Bayesian vs. Frequentist Approaches

### Philosophical and Practical Differences

| Aspect | Frequentist | Bayesian |
|--------|------------|----------|
| **Probability** | Long-run frequency | Degree of belief |
| **Parameters** | Fixed but unknown | Random variables |
| **Inference** | Sampling distribution | Posterior distribution |
| **Prior Information** | Not formally incorporated | Explicitly modeled |
| **Interpretation** | Confidence intervals | Credible intervals |
| **Decision Making** | Hypothesis testing | Probability statements |

### Method Selection Criteria

#### Frequentist Advantages
```
When to Choose Frequentist Methods:
✓ Regulatory standard in therapeutic area
✓ Well-established Type I error control
✓ Simple interpretation needed
✓ No meaningful prior information
✓ Large sample sizes available
✓ Standard statistical training sufficient

Examples:
- Confirmatory Phase III trials
- Regulatory submissions
- Simple superiority comparisons
- Well-powered studies
```

#### Bayesian Advantages
```
When to Choose Bayesian Methods:
✓ Historical data available for borrowing
✓ Adaptive design features needed
✓ Complex decision making required
✓ Probability statements desired
✓ Small sample situations
✓ Multiple sources of information

Examples:
- Adaptive trials with interim decisions
- Historical control borrowing
- Rare disease studies
- Platform/basket trials
- Medical device trials
```

### Implementation Comparison

```sas
/* Frequentist Two-Sample Test */
proc ttest data=trial_data;
    class treatment;
    var outcome;
    title "Frequentist Analysis";
run;

/* Bayesian Two-Sample Analysis */
proc mcmc data=trial_data nbi=2000 nmc=10000;
    parms mu_control 0 mu_treatment 0 sigma2 1;
    
    prior mu_control ~ normal(0, var=100);
    prior mu_treatment ~ normal(0, var=100);
    prior sigma2 ~ igamma(0.01, s=0.01);
    
    if treatment='Control' then 
        model outcome ~ normal(mu_control, var=sigma2);
    else 
        model outcome ~ normal(mu_treatment, var=sigma2);
    
    treatment_effect = mu_treatment - mu_control;
    prob_positive = (treatment_effect > 0);
    
    title "Bayesian Analysis";
run;
```

## Missing Data Methods Comparison

### Approach Selection by Missing Data Mechanism

| Method | MCAR | MAR | MNAR | Complexity | Assumptions |
|--------|------|-----|------|------------|-------------|
| **Complete Case** | Valid | Biased | Biased | Low | MCAR |
| **LOCF** | Biased | Biased | Biased | Low | Strong |
| **Mixed Models** | Valid | Valid | Biased | Medium | MAR |
| **Multiple Imputation** | Valid | Valid | Valid* | High | Depends on model |
| **Pattern-Mixture** | Valid | Valid | Valid | High | MNAR assumptions |

*With appropriate imputation model

### Implementation Examples

```sas
/* Mixed Model Approach (MAR) */
proc mixed data=longitudinal_data;
    class subject visit treatment;
    model response = treatment visit treatment*visit baseline;
    repeated visit / subject=subject type=un;
run;

/* Multiple Imputation */
proc mi data=longitudinal_data nimpute=20 out=imputed_data;
    class treatment visit;
    var response1-response4 treatment baseline;
    monotone regression;
run;

/* Pattern-Mixture Model */
proc mixed data=longitudinal_data;
    class subject visit treatment dropout_pattern;
    model response = treatment visit treatment*visit 
                     dropout_pattern dropout_pattern*treatment;
    repeated visit / subject=subject type=un;
run;
```

## Software and Implementation Considerations

### SAS vs. R Capabilities

| Method | SAS Strength | R Strength | Recommendation |
|--------|-------------|------------|----------------|
| **Survival Analysis** | PHREG, LIFETEST | survival, survminer | Both excellent |
| **Mixed Models** | MIXED, GLIMMIX | lme4, nlme | SAS for complex structures |
| **Bayesian Analysis** | MCMC | Stan, JAGS, brms | R for complex models |
| **Adaptive Designs** | SEQDESIGN | gsDesign | SAS for regulatory |
| **Missing Data** | MI, MIANALYZE | mice, VIM | Both good |

### Computational Performance Comparison

| Method | Typical Runtime | Memory Usage | Scalability |
|--------|----------------|--------------|-------------|
| **Cox Regression** | Fast | Low | Excellent |
| **Mixed Models** | Medium | Medium | Good |
| **Bayesian MCMC** | Slow | High | Poor |
| **Multiple Imputation** | Medium | Medium | Good |
| **Group Sequential** | Fast | Low | Excellent |

### Validation Requirements

#### Method Validation Checklist
```
□ Statistical Theory Validation
  □ Published methodology referenced
  □ Assumptions clearly stated
  □ Limitations documented
  □ Regulatory precedent identified

□ Implementation Validation  
  □ Software version documented
  □ Code reviewed and tested
  □ Results reproducible
  □ Edge cases handled

□ Clinical Validation
  □ Results clinically interpretable
  □ Sensitivity analyses conducted
  □ Robustness to assumptions assessed
  □ Medical team review completed

□ Regulatory Validation
  □ Guidance alignment verified
  □ Submission precedents reviewed
  □ Agency interactions documented
  □ Statistical reviewer preparation
```

## Method Selection Decision Tools

### Integrated Decision Framework

```sas
%macro method_selection_advisor(
    endpoint_type=,
    study_phase=,
    sample_size=,
    missing_data_expected=,
    historical_data=,
    adaptive_features=,
    regulatory_preference=
);

    data method_recommendation;
        length endpoint $20 phase $10 recommendation $100 rationale $300;
        
        endpoint = "&endpoint_type";
        phase = "&study_phase";
        
        /* Survival analysis */
        if endpoint = "time_to_event" then do;
            if &sample_size >= 100 and "&regulatory_preference" = "standard" then do;
                recommendation = "Cox Proportional Hazards Model";
                rationale = "Large sample, regulatory acceptance, standard approach";
            end;
            else if &sample_size < 50 then do;
                recommendation = "Kaplan-Meier with log-rank test";  
                rationale = "Small sample size, non-parametric approach safer";
            end;
            else do;
                recommendation = "Cox model with diagnostics, consider AFT if PH violated";
                rationale = "Moderate sample size, check assumptions carefully";
            end;
        end;
        
        /* Longitudinal analysis */
        else if endpoint = "longitudinal" then do;
            if "&missing_data_expected" = "high" then do;
                recommendation = "Mixed Model for Repeated Measures (MMRM)";
                rationale = "Handles missing data well under MAR assumption";
            end;
            else if "&study_phase" = "early" and &sample_size < 100 then do;
                recommendation = "GEE with robust standard errors";
                rationale = "Population-average effects, robust to model misspecification";
            end;
            else do;
                recommendation = "MMRM with unstructured covariance";
                rationale = "Most flexible approach for confirmatory trials";
            end;
        end;
        
        /* Adaptive designs */
        if "&adaptive_features" = "yes" then do;
            if "&study_phase" = "III" and "&regulatory_preference" = "conservative" then do;
                recommendation = "Group Sequential Design";
                rationale = "Well-established theory, regulatory acceptance";
            end;
            else if "&historical_data" = "available" then do;
                recommendation = "Bayesian adaptive approach";
                rationale = "Can incorporate historical information";
            end;
        end;
        
        /* Final recommendation priority */
        if recommendation = "" then do;
            recommendation = "Standard frequentist approach";
            rationale = "Default choice for well-powered confirmatory studies";
        end;
        
        output;
    run;
    
    proc print data=method_recommendation noobs;
        title "Statistical Method Recommendation";
        var endpoint phase recommendation rationale;
    run;

%mend method_selection_advisor;

/* Example usage */
%method_selection_advisor(
    endpoint_type=time_to_event,
    study_phase=III,
    sample_size=350,
    missing_data_expected=moderate,
    historical_data=available,
    adaptive_features=yes,
    regulatory_preference=standard
);
```

### Quick Reference Decision Matrix

| Study Characteristics | Recommended Method | Alternative | Key Considerations |
|----------------------|-------------------|-------------|-------------------|
| **Small survival study** | Kaplan-Meier + log-rank | Exact tests | Non-parametric preferred |
| **Large survival study** | Cox regression | Parametric if PH violated | Check assumptions |
| **Repeated measures** | MMRM | GEE | Missing data pattern |
| **High dropout rate** | Multiple imputation | Pattern-mixture models | MNAR sensitivity |
| **Historical controls** | Bayesian borrowing | Propensity score matching | Bias considerations |
| **Adaptive interim** | Group sequential | Bayesian monitoring | Regulatory acceptance |
| **Multiple endpoints** | Hierarchical testing | Bonferroni | Control strategy |
| **Small rare disease** | Bayesian approach | Exact methods | Information borrowing |

## Regulatory Considerations by Method

### FDA Acceptance by Method Category

| Method Category | Acceptance Level | Documentation Required | Precedent Needed |
|----------------|-----------------|----------------------|------------------|
| **Standard Frequentist** | High | Standard | No |
| **Group Sequential** | High | Boundary justification | No |
| **MMRM/GEE** | High | Missing data strategy | No |
| **Multiple Imputation** | Medium | Sensitivity analysis | Some |
| **Bayesian with Historical Data** | Medium | Prior justification | Yes |
| **Complex Adaptive** | Low | Extensive simulation | Yes |

### Common Regulatory Questions by Method

#### Cox Regression
- Proportional hazards assumption assessment
- Handling of ties in event times  
- Censoring assumptions and patterns
- Covariate selection and interactions

#### Mixed Models
- Missing data mechanism assumptions
- Covariance structure justification
- Sensitivity to distributional assumptions
- Treatment of unscheduled visits

#### Bayesian Methods
- Prior specification and justification
- Sensitivity to prior assumptions
- Operating characteristics under various scenarios
- Comparison with frequentist analysis

### Method-Specific Submission Requirements

```
Documentation Requirements by Method:

Standard Methods:
□ Statistical analysis plan section
□ Analysis dataset specifications  
□ Programming and validation
□ Results interpretation

Advanced Methods:
□ All standard requirements plus:
□ Method justification and references
□ Simulation studies (if applicable)
□ Sensitivity analyses
□ Comparison with standard approaches
□ Expert statistical review

Adaptive Designs:
□ All advanced method requirements plus:
□ Detailed simulation study report
□ Type I error control demonstration
□ Operating characteristics
□ Decision rules and procedures
□ Independent statistical review recommended
```

---

## Summary Guidelines

### Method Selection Priorities

1. **Regulatory Acceptability**: Will the chosen method be accepted by regulatory agencies?

2. **Scientific Validity**: Does the method appropriately address the research question?

3. **Assumption Validity**: Are the required assumptions reasonable for the data?

4. **Practical Feasibility**: Can the method be properly implemented and interpreted?

5. **Resource Requirements**: Are adequate statistical expertise and computational resources available?

### Best Practices for Method Comparison

- **Document Decision Rationale**: Clearly explain why specific methods were chosen
- **Conduct Sensitivity Analyses**: Test robustness to method assumptions
- **Compare with Standard Approaches**: Show consistency or explain differences  
- **Validate Implementation**: Ensure correct software usage and interpretation
- **Plan for Regulatory Review**: Anticipate questions and prepare responses

### When in Doubt

- **Choose Conservative Approaches**: Well-established methods over novel ones
- **Seek Expert Consultation**: Engage experienced biostatisticians
- **Review Regulatory Guidance**: Check for method-specific requirements
- **Examine Precedents**: Look for similar studies in therapeutic area
- **Plan Early**: Method selection should occur during protocol development

---

*This comparison guide provides systematic approaches to statistical method selection. Regular updates are recommended to reflect evolving statistical practice and regulatory guidance.*