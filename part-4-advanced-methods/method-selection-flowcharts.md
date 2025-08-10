# Statistical Method Selection Flowcharts

## Master Decision Flowchart

```
STATISTICAL METHOD SELECTION
├── What is the primary endpoint type?
│   ├── Time-to-Event
│   │   ├── Single Event Type
│   │   │   ├── Proportional Hazards Assumption Met?
│   │   │   │   ├── Yes → Cox Proportional Hazards Model
│   │   │   │   │   ├── Stratification needed? → Stratified Cox
│   │   │   │   │   ├── Time-dependent effects? → Time-dependent Cox
│   │   │   │   │   └── Multiple covariates? → Multivariable Cox
│   │   │   │   └── No → Alternative Approaches
│   │   │   │       ├── Parametric assumptions met? → AFT Models
│   │   │   │       │   ├── Weibull distribution
│   │   │   │       │   ├── Log-normal distribution  
│   │   │   │       │   └── Generalized gamma
│   │   │   │       ├── Non-parametric needed? → Kaplan-Meier
│   │   │   │       └── Flexible modeling? → Spline-based models
│   │   │   └── Multiple Event Types → Competing Risks Analysis
│   │   │       ├── Cause-specific hazards
│   │   │       ├── Fine-Gray subdistribution
│   │   │       └── Multi-state models
│   │   └── Recurrent Events
│   │       ├── Frailty models
│   │       ├── Marginal approaches (WLW, PWP)
│   │       └── Joint frailty models
│   ├── Continuous Outcomes
│   │   ├── Single Measurement per Subject
│   │   │   ├── Two Groups → t-test or Wilcoxon rank-sum
│   │   │   ├── Multiple Groups → ANOVA or Kruskal-Wallis
│   │   │   └── Covariate Adjustment → ANCOVA or Regression
│   │   └── Repeated Measurements → Longitudinal Analysis
│   │       ├── Normal Distribution Reasonable?
│   │       │   ├── Yes → Mixed Models for Repeated Measures (MMRM)
│   │       │   │   ├── Random intercept model
│   │       │   │   ├── Random slope model
│   │       │   │   └── Unstructured covariance
│   │       │   └── No → Transformation or Non-parametric
│   │       ├── Missing Data Pattern?
│   │       │   ├── MCAR → Complete case analysis acceptable
│   │       │   ├── MAR → MMRM or Multiple Imputation
│   │       │   └── MNAR → Pattern-mixture or Selection models
│   │       └── Population-Level Inference? → GEE Approach
│   ├── Binary Outcomes
│   │   ├── Single Measurement
│   │   │   ├── Two Groups → Fisher's Exact or Chi-square
│   │   │   ├── Multiple Groups → Chi-square test of independence
│   │   │   └── Covariate Adjustment → Logistic Regression
│   │   └── Repeated Measurements
│   │       ├── Subject-Specific → Generalized Mixed Models (GLMM)
│   │       └── Population-Average → GEE with Binomial
│   ├── Count Outcomes
│   │   ├── Poisson Assumptions Met? → Poisson Regression
│   │   ├── Overdispersion Present? → Negative Binomial
│   │   ├── Zero-Inflation? → Zero-Inflated Models
│   │   └── Repeated Counts → GEE or GLMM
│   └── Categorical Outcomes
│       ├── Ordinal → Proportional Odds Model
│       ├── Nominal → Multinomial Logistic
│       └── Repeated → GEE with Multinomial
└── Special Design Considerations?
    ├── Adaptive Features Needed?
    │   ├── Early Efficacy Stopping → Group Sequential Design
    │   ├── Futility Monitoring → Beta Spending Functions
    │   ├── Sample Size Uncertainty → Sample Size Re-estimation
    │   ├── Population Selection → Enrichment Design
    │   ├── Treatment Selection → Multi-arm Platform
    │   └── Dose Finding → Bayesian Adaptive Methods
    ├── Prior Information Available?
    │   ├── Historical Controls → Bayesian Borrowing
    │   ├── External Data → Power Priors
    │   ├── Expert Opinion → Informative Priors
    │   └── Meta-Analysis Data → Hierarchical Models
    ├── Clustering Present?
    │   ├── Cluster Randomization → Cluster-Adjusted Methods
    │   ├── Center Effects → Mixed Models with Random Centers
    │   └── Matched Pairs → Stratified or Paired Analysis
    └── Special Populations?
        ├── Pediatric Studies → Age-Appropriate Methods
        ├── Rare Diseases → Small Sample Methods
        └── Precision Medicine → Biomarker-Guided Analysis
```

## Survival Analysis Method Selection

```
SURVIVAL ANALYSIS DECISION TREE
├── Data Structure Assessment
│   ├── Single Event per Subject?
│   │   ├── Yes → Standard Survival Analysis
│   │   └── No → Recurrent Event Methods
│   ├── Competing Events Present?
│   │   ├── Yes → Competing Risks Methods
│   │   └── No → Standard Methods
│   └── Administrative Censoring Only?
│       ├── Yes → Most methods appropriate
│       └── No → Assess informative censoring
├── Distributional Assumptions
│   ├── Proportional Hazards Reasonable?
│   │   ├── Test via:
│   │   │   ├── Log-log survival plots
│   │   │   ├── Schoenfeld residuals
│   │   │   └── Scaled Schoenfeld residuals
│   │   ├── Yes → Cox Regression Family
│   │   │   ├── Basic Cox Model
│   │   │   │   ├── Single covariate
│   │   │   │   ├── Multiple covariates
│   │   │   │   └── Interaction terms
│   │   │   ├── Stratified Cox
│   │   │   │   ├── Stratify by violating variable
│   │   │   │   ├── Common treatment effect
│   │   │   │   └── Different baseline hazards
│   │   │   └── Time-Dependent Cox
│   │   │       ├── Time-varying coefficients
│   │   │       ├── Time-dependent covariates
│   │   │       └── Piecewise constant hazards
│   │   └── No → Alternative Methods
│   │       ├── Accelerated Failure Time Models
│   │       │   ├── Weibull AFT
│   │       │   │   ├── Constant shape parameter
│   │       │   │   ├── Monotonic hazard
│   │       │   │   └── Proportional hazards special case
│   │       │   ├── Log-normal AFT
│   │       │   │   ├── Non-monotonic hazard
│   │       │   │   ├── Log-normal residuals
│   │       │   │   └── QQ plots for checking
│   │       │   ├── Log-logistic AFT
│   │       │   │   ├── Odds ratio interpretation
│   │       │   │   ├── Non-monotonic hazard
│   │       │   │   └── Proportional odds model
│   │       │   └── Generalized Gamma AFT
│   │       │       ├── Most flexible
│   │       │       ├── Includes Weibull, log-normal
│   │       │       └── Extra shape parameter
│   │       └── Non-parametric Methods
│   │           ├── Kaplan-Meier estimation
│   │           ├── Log-rank test
│   │           └── Wilcoxon test
├── Competing Risks Specific
│   ├── Interest in Specific Event?
│   │   ├── Yes → Cause-Specific Hazards
│   │   │   ├── Cox model for event of interest
│   │   │   ├── Treat competing events as censored
│   │   │   └── Hazard ratio interpretation
│   │   └── Also interested in cumulative incidence?
│   │       └── Yes → Fine-Gray Subdistribution
│   │           ├── Modified risk sets
│   │           ├── Cumulative incidence focus
│   │           └── Subdistribution hazard ratio
│   ├── Multiple Transitions Possible?
│   │   └── Yes → Multi-State Models
│   │       ├── Markov models
│   │       ├── Semi-Markov models
│   │       └── Transition-specific hazards
│   └── Joint Modeling Needed?
│       └── Yes → Joint Models
│           ├── Survival and longitudinal data
│           ├── Shared parameter models
│           └── Dynamic predictions
└── Sample Size Considerations
    ├── Large Sample (>100 events)?
    │   ├── Yes → Most methods appropriate
    │   └── No → Consider exact methods
    ├── Very Small Sample (<50 total)?
    │   ├── Yes → Non-parametric methods preferred
    │   └── No → Parametric methods acceptable
    └── Many Covariates Relative to Events?
        ├── Yes → Variable selection methods
        │   ├── Stepwise selection
        │   ├── LASSO regularization
        │   └── Ridge regression
        └── No → Standard methods appropriate
```

## Longitudinal Data Analysis Selection

```
LONGITUDINAL ANALYSIS DECISION TREE
├── Outcome Type Assessment
│   ├── Continuous Outcomes
│   │   ├── Normally Distributed?
│   │   │   ├── Check via:
│   │   │   │   ├── Histograms/Q-Q plots
│   │   │   │   ├── Shapiro-Wilk test
│   │   │   │   └── Residual analysis
│   │   │   ├── Yes → Linear Mixed Models
│   │   │   │   ├── Random Intercept Model
│   │   │   │   │   ├── Subjects vary in baseline
│   │   │   │   │   ├── Common slope
│   │   │   │   │   └── Simple covariance structure
│   │   │   │   ├── Random Intercept and Slope
│   │   │   │   │   ├── Individual trajectories
│   │   │   │   │   ├── Correlation between intercept/slope
│   │   │   │   │   └── More complex covariance
│   │   │   │   └── Unstructured Covariance
│   │   │   │       ├── Most flexible
│   │   │   │       ├── Estimates all variances/covariances
│   │   │   │       └── Requires adequate sample size
│   │   │   └── No → Transform or Alternative Methods
│   │   │       ├── Log Transformation
│   │   │       ├── Square Root Transformation
│   │   │       ├── Box-Cox Transformation
│   │   │       └── Generalized Linear Mixed Models
│   │   └── Non-normal Continuous
│   │       ├── Bounded (0,1) → Beta Mixed Models
│   │       ├── Positive Continuous → Gamma Mixed Models
│   │       └── Heavy-tailed → Robust Mixed Models
│   ├── Binary Outcomes
│   │   ├── Interpretation Preference?
│   │   │   ├── Subject-Specific → GLMM with Binomial
│   │   │   │   ├── Random intercept logistic
│   │   │   │   ├── Random slope logistic
│   │   │   │   └── Individual-level interpretation
│   │   │   └── Population-Average → GEE with Binomial
│   │   │       ├── Marginal model
│   │   │       ├── Population-level effects
│   │   │       └── Robust sandwich estimator
│   │   └── Rare Events?
│   │       ├── Yes → Exact methods or Firth correction
│   │       └── No → Standard logistic methods
│   ├── Count Outcomes
│   │   ├── Overdispersion Present?
│   │   │   ├── Test via deviance/df ratio
│   │   │   ├── Yes → Negative Binomial Mixed Models
│   │   │   └── No → Poisson Mixed Models
│   │   ├── Zero-Inflation?
│   │   │   ├── Many structural zeros?
│   │   │   ├── Yes → Zero-Inflated Mixed Models
│   │   │   └── No → Standard count models
│   │   └── Exposure Time Varies?
│   │       ├── Yes → Include offset term
│   │       └── No → Standard count analysis
│   └── Ordinal Outcomes
│       ├── Proportional Odds Assumption Met?
│       │   ├── Yes → Mixed Effects Proportional Odds
│       │   └── No → Partial Proportional Odds
│       └── Many Categories?
│           ├── Yes → Consider as continuous
│           └── No → Ordinal methods appropriate
├── Missing Data Pattern Analysis
│   ├── Assess Missing Data Mechanism
│   │   ├── Missing Completely at Random (MCAR)?
│   │   │   ├── Test via Little's MCAR test
│   │   │   ├── Yes → Any method valid
│   │   │   └── No → Assess MAR vs MNAR
│   │   ├── Missing at Random (MAR)?
│   │   │   ├── Missingness related to observed data only
│   │   │   ├── Yes → Mixed Models or Multiple Imputation
│   │   │   │   ├── Mixed Models (MMRM)
│   │   │   │   │   ├── Uses all available data
│   │   │   │   │   ├── Valid under MAR
│   │   │   │   │   └── No imputation needed
│   │   │   │   └── Multiple Imputation
│   │   │   │       ├── Impute missing values
│   │   │   │       ├── Analyze each dataset
│   │   │   │       └── Pool results via Rubin's rules
│   │   │   └── No → MNAR methods needed
│   │   └── Missing Not at Random (MNAR)?
│   │       ├── Sensitivity Analysis Required
│   │       ├── Pattern-Mixture Models
│   │       │   ├── Model by dropout pattern
│   │       │   ├── Make assumptions about missing data
│   │       │   └── Test sensitivity to assumptions
│   │       └── Selection Models
│   │           ├── Joint model for outcome and missingness
│   │           ├── Identify missing data mechanism
│   │           └── Estimate parameters jointly
│   ├── Dropout Patterns
│   │   ├── Monotone Dropout?
│   │   │   ├── Yes → Monotone imputation methods
│   │   │   └── No → General imputation methods
│   │   ├── Intermittent Missingness?
│   │   │   ├── Yes → MMRM handles naturally
│   │   │   └── No → Standard methods
│   │   └── High Dropout Rate (>30%)?
│   │       ├── Yes → Careful sensitivity analysis
│   │       └── No → Standard MAR methods
│   └── Covariate Missingness
│       ├── Missing Covariates Present?
│       │   ├── Yes → Multiple Imputation for covariates
│       │   └── No → Standard analysis
│       └── Auxiliary Variables Available?
│           ├── Yes → Include in imputation model
│           └── No → Use available data methods
├── Covariance Structure Selection
│   ├── Visit Schedule
│   │   ├── Equally Spaced Visits?
│   │   │   ├── Yes → Consider structured covariance
│   │   │   │   ├── Compound Symmetry (CS)
│   │   │   │   │   ├── Constant correlation
│   │   │   │   │   ├── Simple structure
│   │   │   │   │   └── Often too restrictive
│   │   │   │   ├── Autoregressive AR(1)
│   │   │   │   │   ├── Correlation decays with time
│   │   │   │   │   ├── One parameter
│   │   │   │   │   └── Good for many timepoints
│   │   │   │   └── Toeplitz (TOEP)
│   │   │   │       ├── Correlation by time separation
│   │   │   │       ├── More flexible than AR(1)
│   │   │   │       └── Good compromise
│   │   │   └── No → Unstructured covariance
│   │   │       ├── Most flexible
│   │   │       ├── No assumptions about correlation pattern
│   │   │       └── Requires adequate sample size
│   │   ├── Few Timepoints (<5)?
│   │   │   ├── Yes → Unstructured covariance
│   │   │   └── No → Consider structured alternatives
│   │   └── Many Subjects, Many Timepoints?
│   │       ├── Yes → Structured covariance may be necessary
│   │       └── No → Unstructured preferred
│   └── Model Comparison
│       ├── Use Information Criteria
│       │   ├── AIC for model selection
│       │   ├── BIC penalizes complexity more
│       │   └── Compare using ML estimation
│       └── Likelihood Ratio Tests
│           ├── Nested models only
│           ├── Use ML estimation
│           └── Chi-square test with df difference
└── Sample Size and Power Considerations
    ├── Cluster/Center Effects?
    │   ├── Yes → Account for clustering
    │   │   ├── Mixed models with random center effects
    │   │   ├── GEE with exchangeable correlation
    │   │   └── Inflate sample size for design effect
    │   └── No → Standard longitudinal methods
    ├── Baseline Covariate Adjustment?
    │   ├── Yes → Include baseline as covariate
    │   │   ├── Improves power
    │   │   ├── Reduces variability
    │   │   └── Controls for baseline imbalance
    │   └── No → Standard analysis
    └── Multiple Endpoints?
        ├── Yes → Consider multiplicity adjustment
        │   ├── Hierarchical testing
        │   ├── Bonferroni correction
        │   └── False discovery rate
        └── No → Standard analysis
```

## Adaptive Design Method Selection

```
ADAPTIVE DESIGN SELECTION
├── Primary Objective of Adaptation
│   ├── Early Efficacy Stopping
│   │   ├── Group Sequential Design
│   │   │   ├── Efficacy Boundaries Only
│   │   │   │   ├── O'Brien-Fleming
│   │   │   │   │   ├── Conservative early stopping
│   │   │   │   │   ├── Maintains Type I error well
│   │   │   │   │   └── Most common in regulatory submissions
│   │   │   │   ├── Pocock
│   │   │   │   │   ├── Equal boundaries across analyses  
│   │   │   │   │   ├── Higher early stopping probability
│   │   │   │   │   └── Less commonly used
│   │   │   │   └── Lan-DeMets Alpha Spending
│   │   │   │       ├── Flexible analysis timing
│   │   │   │       ├── Pre-specified spending function
│   │   │   │       └── Regulatory preference for flexibility
│   │   │   ├── Combined Efficacy and Futility
│   │   │   │   ├── Symmetric boundaries
│   │   │   │   ├── Beta spending functions
│   │   │   │   └── Two-sided monitoring
│   │   │   └── Non-binding Futility
│   │   │       ├── Recommendations only
│   │   │       ├── Preserve Type I error
│   │   │       └── Operational flexibility
│   │   └── Bayesian Monitoring
│   │       ├── Posterior Probability Monitoring
│   │       ├── Predictive Probability
│   │       └── Decision-theoretic approaches
│   ├── Sample Size Uncertainty
│   │   ├── Variance Unknown
│   │   │   ├── Blinded Sample Size Re-estimation
│   │   │   │   ├── Pool data across arms
│   │   │   │   ├── Re-estimate nuisance parameters
│   │   │   │   ├── Maintains blinding
│   │   │   │   └── Type I error preserved
│   │   │   └── Internal Pilot Study
│   │   │       ├── Pre-specified interim analysis
│   │   │       ├── Variance re-estimation
│   │   │       └── Sample size adjustment
│   │   └── Treatment Effect Uncertain
│   │       ├── Unblinded Sample Size Re-estimation
│   │       │   ├── Observe treatment effect
│   │       │   ├── Conditional power calculation
│   │       │   ├── Type I error inflation possible
│   │       │   └── Statistical penalty may be needed
│   │       └── Group Sequential with SSR
│   │           ├── Combine efficacy monitoring with SSR
│   │           ├── Complex Type I error control
│   │           └── Simulation validation required
│   ├── Treatment/Dose Selection
│   │   ├── Multi-Arm Multi-Stage (MAMS)
│   │   │   ├── Multiple experimental arms
│   │   │   ├── Drop inferior arms at interim
│   │   │   ├── Maintain overall Type I error
│   │   │   └── Efficient screening design
│   │   ├── Seamless Phase II/III
│   │   │   ├── Treatment selection in Phase II portion
│   │   │   ├── Confirmatory testing in Phase III portion
│   │   │   ├── Complex multiplicity control
│   │   │   └── Regulatory pre-agreement essential
│   │   └── Platform Trials
│   │       ├── Multiple arms vs shared control
│   │       ├── Arms can enter/exit dynamically
│   │       ├── Control information borrowing
│   │       └── Time trend adjustments
│   ├── Population Enrichment
│   │   ├── Biomarker-Guided Enrichment
│   │   │   ├── Start with broader population
│   │   │   ├── Interim biomarker analysis
│   │   │   ├── Continue with responsive subgroup
│   │   │   └── Pre-specify enrichment rules
│   │   ├── Adaptive Signature Design
│   │   │   ├── Develop predictive signature during trial
│   │   │   ├── Validate signature in separate cohort
│   │   │   └── Complex validation requirements
│   │   └── Cross-Validated Adaptive Signature
│   │       ├── Training and validation sets
│   │       ├── Cross-validation procedures
│   │       └── Reduced bias vs adaptive signature
│   └── Response-Adaptive Randomization
│       ├── Outcome-Adaptive Randomization
│       │   ├── Allocate more patients to better arm
│       │   ├── Ethical considerations
│       │   ├── May reduce statistical power
│       │   └── Operational complexity
│       ├── Covariate-Adaptive Randomization
│       │   ├── Balance prognostic factors
│       │   ├── Minimization procedures
│       │   └── Stratified randomization
│       └── Bayesian Adaptive Randomization
│           ├── Posterior probability-based allocation
│           ├── Continuous adaptation
│           └── Decision-theoretic optimization
├── Regulatory and Operational Considerations
│   ├── Regulatory Acceptance
│   │   ├── FDA Experience with Design Type?
│   │   │   ├── High (Group Sequential) → Standard approach
│   │   │   ├── Medium (SSR) → Additional justification
│   │   │   └── Low (Complex Adaptive) → Extensive validation
│   │   ├── EMA/Other Agencies?
│   │   │   ├── Check regional preferences
│   │   │   ├── Scientific advice recommended
│   │   │   └── Harmonized approach preferred
│   │   └── Breakthrough Therapy/Fast Track?
│   │       ├── May enable more complex designs
│   │       ├── Risk-benefit considerations
│   │       └── Enhanced regulatory interaction
│   ├── Operational Feasibility
│   │   ├── Data Management System Capability?
│   │   │   ├── Real-time data availability
│   │   │   ├── Interim database locks
│   │   │   └── System validation requirements
│   │   ├── Statistical Team Expertise?
│   │   │   ├── Adaptive design experience
│   │   │   ├── Simulation capabilities
│   │   │   └── Interim analysis procedures
│   │   └── Study Team Training?
│   │       ├── Investigator understanding
│   │       ├── Site coordinator training
│   │       └── Patient communication
│   └── Timeline Considerations
│       ├── Development Timeline Pressure?
│       │   ├── High → Simple adaptive designs
│       │   ├── Medium → Moderate complexity acceptable
│       │   └── Low → Complex designs feasible
│       ├── Recruitment Rate Predictable?
│       │   ├── Yes → Calendar time monitoring possible
│       │   └── No → Information-based monitoring
│       └── Endpoint Assessment Timing?
│           ├── Immediate → Rapid adaptation possible
│           ├── Short delay → Standard interim timing
│           └── Long delay → Limited adaptation benefit
└── Statistical Validation Requirements
    ├── Type I Error Control
    │   ├── Analytical Methods Available?
    │   │   ├── Yes → Use established theory
    │   │   └── No → Simulation validation required
    │   ├── Multiple Testing Complexity?
    │   │   ├── Simple → Standard adjustments
    │   │   └── Complex → Advanced methods needed
    │   └── Interim Analysis Frequency?
    │       ├── Few → Standard group sequential
    │       └── Many → Continuous monitoring methods
    ├── Power and Sample Size
    │   ├── Operating Characteristics Simulation
    │   │   ├── Multiple scenarios
    │   │   ├── Null and alternative hypotheses
    │   │   └── Sensitivity analysis
    │   ├── Adaptive Features Impact?
    │   │   ├── Power preservation
    │   │   ├── Sample size efficiency
    │   │   └── Timeline advantages
    │   └── Worst-Case Scenarios?
    │       ├── No adaptation occurs
    │       ├── All arms similar
    │       └── Early futility stopping
    └── Regulatory Submission Package
        ├── Statistical Analysis Plan Detail
        │   ├── All adaptation rules pre-specified
        │   ├── Decision criteria defined
        │   └── Type I error control demonstrated
        ├── Simulation Study Report
        │   ├── Operating characteristics
        │   ├── Sensitivity analyses
        │   └── Robustness assessments
        └── Independent Statistical Review?
            ├── Complex designs benefit from external review
            ├── Regulatory consultation recommended
            └── Advisory committee presentation possible
```

## Implementation Guidelines

### Method Selection Checklist

```
□ Data Characteristics Assessment
  □ Outcome type identified (continuous, binary, time-to-event, count)
  □ Distribution assumptions checked
  □ Missing data pattern analyzed
  □ Clustering or correlation structure identified

□ Study Design Features
  □ Sample size and power considerations
  □ Number of treatment groups
  □ Stratification factors
  □ Interim analyses planned

□ Statistical Assumptions
  □ Independence assumptions reasonable
  □ Distributional assumptions verified
  □ Missing data mechanism assessed
  □ Model assumptions testable

□ Regulatory Requirements
  □ Regulatory precedent for chosen method
  □ Guidance document alignment
  □ Multiplicity considerations addressed
  □ Sensitivity analyses planned

□ Practical Considerations
  □ Software availability and expertise
  □ Computational requirements feasible
  □ Results interpretability
  □ Stakeholder understanding
```

### Common Method Selection Errors

| Situation | Wrong Choice | Better Choice | Rationale |
|-----------|-------------|---------------|-----------|
| Repeated measures with missing data | Complete case analysis | MMRM or Multiple Imputation | Preserves power, valid under MAR |
| Time-to-event with non-PH | Cox model only | AFT models or stratified Cox | Addresses assumption violation |
| Rare binary outcomes | Standard logistic regression | Exact logistic or Firth correction | Handles separation issues |
| Multiple endpoints | No multiplicity adjustment | Hierarchical testing or adjustment | Controls family-wise error rate |
| Clustered data | Ignore clustering | Mixed models or GEE | Accounts for correlation |
| Small sample survival | Cox regression | Non-parametric methods | More appropriate for small samples |

### Software-Specific Considerations

#### SAS Procedure Selection
```
Outcome Type → Recommended PROC → Alternative
Continuous Longitudinal → MIXED → GLIMMIX
Binary Longitudinal → GLIMMIX → GENMOD (GEE)
Time-to-Event → PHREG → LIFETEST, LIFEREG
Count Data → GENMOD → GLIMMIX
Adaptive Designs → SEQDESIGN/SEQTEST → Custom macros
Bayesian Analysis → MCMC → External software
Multiple Imputation → MI/MIANALYZE → MICE (R)
```

#### Model Validation Steps
```
1. Fit candidate models
2. Check assumptions via diagnostics
3. Compare models using information criteria
4. Validate selected model
5. Conduct sensitivity analyses
6. Document rationale and limitations
```

---

*These flowcharts provide systematic guidance for statistical method selection and should be used in conjunction with therapeutic area expertise, regulatory requirements, and study-specific considerations.*