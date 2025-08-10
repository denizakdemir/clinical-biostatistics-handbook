# Statistical Method Decision Trees for Clinical Trials

## Phase I Design Selection Decision Tree

```
PHASE I DESIGN SELECTION
├── What is the primary goal?
│   ├── Find Maximum Tolerated Dose (MTD)
│   │   ├── Traditional cytotoxic agent?
│   │   │   ├── Yes → Consider 3+3 Design
│   │   │   │   ├── Pros: Simple, well-accepted, safe
│   │   │   │   ├── Cons: Inefficient, poor MTD selection
│   │   │   │   └── Use when: Simple implementation needed
│   │   │   └── No → Consider Model-Based Design
│   │   │       ├── CRM (Continual Reassessment Method)
│   │   │       │   ├── Pros: Efficient, better MTD selection
│   │   │       │   ├── Cons: Complex, prior specification critical
│   │   │       │   └── Use when: Statistical expertise available
│   │   │       ├── EWOC (Escalation with Overdose Control)
│   │   │       │   ├── Pros: Conservative, good safety
│   │   │       │   ├── Cons: May underdose patients
│   │   │       │   └── Use when: High toxicity concern
│   │   │       └── mTPI (modified Toxicity Probability Interval)
│   │   │           ├── Pros: Simple rules, good performance
│   │   │           ├── Cons: Less flexible than CRM
│   │   │           └── Use when: Balance of simplicity and efficiency
│   │   └── Combination therapy?
│   │       ├── Drug A + Drug B escalation
│   │       │   ├── POCRM (Partial Order CRM)
│   │       │   ├── BOIN-COMB
│   │       │   └── Product of Independent Beta Probabilities
│   │       └── Drug A (fixed) + Drug B (escalation)
│   │           └── Standard approaches with safety run-in
│   └── Find Recommended Phase II Dose (RP2D)
│       ├── Based on PK/PD endpoints
│       ├── Expansion cohort at MTD
│       └── Biomarker-driven dose selection

Special Considerations:
├── Late-onset toxicity expected?
│   ├── Yes → TITE-CRM (Time-to-Event CRM)
│   └── No → Standard approaches
├── Pediatric population?
│   ├── Yes → PIPE design or modified CRM
│   └── No → Standard approaches
└── First-in-human study?
    ├── Yes → Conservative approach (3+3 or EWOC)
    └── No → More aggressive approaches acceptable
```

## Phase II Design Selection Decision Tree

```
PHASE II DESIGN SELECTION
├── Is there a standard of care/historical control?
│   ├── Historical Control Available
│   │   ├── Single-Arm Design Options
│   │   │   ├── Fixed Sample Size
│   │   │   │   ├── Pros: Simple analysis
│   │   │   │   ├── Cons: No early stopping
│   │   │   │   └── Use when: Small, short studies
│   │   │   ├── Simon's Two-Stage Design
│   │   │   │   ├── Optimal Design
│   │   │   │   │   ├── Pros: Minimizes expected N under H0
│   │   │   │   │   └── Use when: High prior probability of inefficacy
│   │   │   │   └── Minimax Design
│   │   │   │       ├── Pros: Minimizes maximum N
│   │   │   │       └── Use when: Want to limit total sample size
│   │   │   └── Bayesian Adaptive Design
│   │   │       ├── Pros: Continuous monitoring, incorporates prior
│   │   │       ├── Cons: More complex
│   │   │       └── Use when: Strong prior information available
│   │   └── Historical Control Quality?
│   │       ├── High Quality → Single-arm acceptable
│   │       ├── Moderate Quality → Consider randomized control
│   │       └── Poor Quality → Randomized control required
│   └── No Adequate Historical Control
│       ├── Randomized Phase II Options
│       │   ├── Two-Arm Design
│       │   │   ├── Experimental vs Control
│       │   │   ├── α = 0.10-0.20 (two-sided)
│   │   │   │   ├── Power = 80%
│   │   │   │   └── Use when: Direct comparison needed
│   │   │   ├── Multi-Arm Design
│   │   │   │   ├── Pick-the-Winner Design
│   │   │   │   │   ├── Multiple experimental arms vs control
│   │   │   │   │   └── Select best arm for Phase III
│   │   │   │   ├── Screening Design
│   │   │   │   │   ├── Multiple doses/schedules
│   │   │   │   │   └── Dose-finding objective
│   │   │   │   └── Seamless Phase II/III
│   │   │   │       ├── Adaptive transition
│   │   │   │       └── Regulatory pre-agreement needed

Endpoint Considerations:
├── Primary Endpoint Type?
│   ├── Binary (Response Rate)
│   │   ├── Use exact binomial methods
│   │   ├── Consider enrichment strategies
│   │   └── Plan for confirmatory biomarker analysis
│   ├── Time-to-Event (PFS, OS)
│   │   ├── Event-driven analysis
│   │   ├── Hazard ratio estimation
│   │   └── Consider competing risks
│   └── Continuous (Change from baseline)
│       ├── t-test or ANCOVA
│       ├── Mixed-effects models for repeated measures
│       └── Handle missing data appropriately

Special Population Considerations:
├── Biomarker Strategy?
│   ├── Enrichment Design
│   │   ├── Biomarker-positive only
│   │   ├── Higher treatment effect expected
│   │   └── Companion diagnostic development
│   ├── Biomarker-Stratified Design
│   │   ├── Test biomarker interaction
│   │   ├── Co-primary objectives
│   │   └── Larger sample size needed
│   └── All-Comers Design
│       ├── Exploratory biomarker analysis
│       ├── Post-hoc subgroup analyses
│       └── Generate hypotheses for Phase III
├── Rare Disease?
│   ├── Yes → Minimize sample size with single-arm
│   └── No → Consider randomized approach
└── Regulatory Path?
    ├── Accelerated Approval → Single-arm may be acceptable
    └── Traditional Approval → Randomized preferred
```

## Phase III Design Selection Decision Tree

```
PHASE III DESIGN SELECTION
├── What type of comparison?
│   ├── Superiority Trial
│   │   ├── New Drug vs Placebo
│   │   │   ├── Ethical Considerations
│   │   │   │   ├── No standard of care available
│   │   │   │   ├── Add-on to standard of care
│   │   │   │   └── Short treatment duration acceptable
│   │   │   ├── Statistical Considerations
│   │   │   │   ├── Two-sided test (α = 0.05)
│   │   │   │   ├── Power = 80-90%
│   │   │   │   └── Effect size clinically meaningful
│   │   │   └── Regulatory Advantages
│   │   │       ├── Clear efficacy demonstration
│   │   │       ├── Straightforward interpretation
│   │   │       └── Gold standard for approval
│   │   └── New Drug vs Active Control
│   │       ├── Standard of care exists
│   │       ├── Direct comparison needed
│   │       ├── Market access considerations
│   │       └── Head-to-head efficacy data
│   ├── Non-Inferiority Trial
│   │   ├── When to Use?
│   │   │   ├── New drug offers other advantages
│   │   │   │   ├── Better safety profile
│   │   │   │   ├── Improved convenience (oral vs IV)
│   │   │   │   ├── Lower cost
│   │   │   │   └── Fewer drug interactions
│   │   │   ├── Ethical issues with placebo
│   │   │   └── Regulatory requirement for active control
│   │   ├── Margin Justification
│   │   │   ├── Historical Evidence Required
│   │   │   │   ├── Active vs placebo data
│   │   │   │   ├── Consistent effect across studies
│   │   │   │   └── Similar patient populations
│   │   │   ├── Clinical Reasoning
│   │   │   │   ├── Preserve ≥50% of effect
│   │   │   │   ├── Clinically acceptable loss
│   │   │   │   └── Regulatory precedent
│   │   │   └── Statistical Methods
│   │   │       ├── Fixed margin approach
│   │   │       ├── Confidence interval method
│   │   │       └── Bayesian approaches
│   │   └── Analysis Populations
│   │       ├── Intent-to-Treat (ITT)
│   │       │   ├── Primary for safety
│   │       │   ├── Conservative for non-inferiority
│   │       │   └── Regulatory preference
│   │       └── Per-Protocol (PP)
│   │           ├── Supportive for non-inferiority
│   │           ├── Excludes major violations
│   │           └── Must be pre-specified
│   └── Equivalence Trial
│       ├── Biosimilar studies
│       ├── Generic formulations
│       ├── Route of administration changes
│       └── Two-sided equivalence bounds

Adaptive Features?
├── Group Sequential Design
│   ├── Efficacy Monitoring
│   │   ├── O'Brien-Fleming boundaries
│   │   │   ├── Conservative early stopping
│   │   │   ├── Maintains alpha
│   │   │   └── Most commonly used
│   │   ├── Pocock boundaries
│   │   │   ├── Equal boundaries
│   │   │   ├── Higher early stopping probability
│   │   │   └── Less commonly used
│   │   └── Lan-DeMets alpha spending
│   │       ├── Flexible analysis timing
│   │       ├── Alpha spending function
│   │       └── Most regulatory flexibility
│   ├── Futility Monitoring
│   │   ├── Conditional power < 20%
│   │   ├── Predictive power approaches
│   │   └── Beta spending functions
│   └── Combined Efficacy/Futility
│       ├── Symmetric boundaries
│       ├── Asymmetric boundaries
│       └── Binding vs non-binding futility
├── Sample Size Re-estimation
│   ├── Blinded SSR
│   │   ├── Nuisance parameter re-estimation
│   │   ├── Variance re-estimation
│   │   └── Event rate re-estimation
│   ├── Unblinded SSR
│   │   ├── Treatment effect re-estimation
│   │   ├── Regulatory interaction required
│   │   └── Bias minimization critical
│   └── Implementation
│       ├── Interim analysis timing
│       ├── Statistical penalties
│       └── Maximum sample size limits
└── Population Enrichment
    ├── Adaptive Enrichment
    │   ├── Biomarker-defined populations
    │   ├── Responder identification
    │   └── Futility in overall population
    ├── Seamless Phase II/III
    │   ├── Dose selection and confirmation
    │   ├── Population selection
    │   └── Operational complexity high
    └── Regulatory Considerations
        ├── Type I error control
        ├── Pre-specification requirements
        └── Agency interaction needed

Special Design Considerations:
├── Time-to-Event Primary Endpoint?
│   ├── Event-driven analysis
│   │   ├── Hazard ratio estimation
│   │   ├── Proportional hazards assumption
│   │   └── Competing risks considerations
│   ├── Information-based monitoring
│   │   ├── Information fraction
│   │   ├── Event accumulation
│   │   └── Calendar time secondary
│   └── Survival Analysis Methods
│       ├── Cox proportional hazards
│       ├── Accelerated failure time
│       ├── Flexible parametric models
│       └── Restricted mean survival time
├── Composite Primary Endpoint?
│   ├── Component Weighting
│   │   ├── Clinical importance
│   │   ├── Frequency of events
│   │   └── Statistical power
│   ├── Interpretation Challenges
│   │   ├── Driven by single component?
│   │   ├── Competing risks effects
│   │   └── Clinical meaningfulness
│   └── Alternative Approaches
│       ├── Hierarchical testing
│       ├── Win ratio methods
│       └── Multiple primary endpoints
└── Global Registration Strategy?
    ├── Regional Requirements
    │   ├── FDA guidance alignment
    │   ├── EMA scientific advice
    │   ├── ICH harmonization
    │   └── Local regulatory needs
    ├── Ethnic Bridging Studies
    │   ├── PK/PD differences
    │   ├── Disease characteristics
    │   └── Standard of care variations
    └── Regulatory Interactions
        ├── Pre-submission meetings
        ├── Protocol assistance
        ├── Scientific advice
        └── Breakthrough designations
```

## Endpoint Selection Decision Tree

```
PRIMARY ENDPOINT SELECTION
├── What is the study objective?
│   ├── Demonstrate Clinical Benefit
│   │   ├── Overall Survival (OS)
│   │   │   ├── Gold Standard
│   │   │   │   ├── Unambiguous endpoint
│   │   │   │   ├── Regulatory preference
│   │   │   │   ├── Clinical meaningfulness clear
│   │   │   │   └── No surrogate validation needed
│   │   │   ├── Considerations
│   │   │   │   ├── Large sample sizes needed
│   │   │   │   ├── Long follow-up required
│   │   │   │   ├── Competing causes of death
│   │   │   │   └── Subsequent therapy effects
│   │   │   └── When to Use
│   │   │       ├── Curative intent settings
│   │   │       ├── Life-threatening diseases
│   │   │       ├── Regulatory requirement
│   │   │       └── Adequate follow-up feasible
│   │   ├── Progression-Free Survival (PFS)
│   │   │   ├── Advantages
│   │   │   │   ├── Earlier readout than OS
│   │   │   │   ├── Smaller sample sizes
│   │   │   │   ├── Less confounding by subsequent therapy
│   │   │   │   └── Regulatory acceptance established
│   │   │   ├── Challenges
│   │   │   │   ├── Progression definition dependency
│   │   │   │   ├── Assessment schedule effects
│   │   │   │   ├── Investigator bias potential
│   │   │   │   └── Clinical benefit correlation varies
│   │   │   └── Requirements
│   │   │       ├── Blinded independent review (BIRC)
│   │   │       ├── Regular imaging schedule
│   │   │       ├── Clear progression criteria
│   │   │       └── Missing assessment handling
│   │   └── Disease-Free Survival (DFS)
│   │       ├── Adjuvant Settings
│   │       │   ├── Prevention of recurrence
│   │       │   ├── Curative intent treatment
│   │       │   └── Long-term benefit assessment
│   │       ├── Components
│   │       │   ├── Local recurrence
│   │       │   ├── Distant metastases
│   │       │   ├── Second primary malignancy
│   │       │   └── Death from any cause
│   │       └── Statistical Considerations
│   │           ├── Competing risk methods
│   │           ├── Cause-specific hazards
│   │           └── Gray's test for competing risks
│   ├── Show Activity/Proof of Concept
│   │   ├── Objective Response Rate (ORR)
│   │   │   ├── Advantages
│   │   │   │   ├── Direct measure of tumor shrinkage
│   │   │   │   ├── Relatively quick endpoint
│   │   │   │   ├── Smaller sample sizes
│   │   │   │   └── Good for Phase II studies
│   │   │   ├── Limitations
│   │   │   │   ├── Doesn't capture stable disease benefit
│   │   │   │   ├── Short-term endpoint
│   │   │   │   ├── Assessment bias potential
│   │   │   │   └── Correlation with survival varies
│   │   │   ├── Requirements
│   │   │   │   ├── Measurable disease (RECIST)
│   │   │   │   ├── Baseline imaging
│   │   │   │   ├── Response confirmation
│   │   │   │   └── Independent review
│   │   │   └── Variants
│   │   │       ├── Complete response rate
│   │   │       ├── Disease control rate (CR+PR+SD)
│   │   │       ├── Duration of response
│   │   │       └── Time to response
│   │   └── Biomarker Endpoints
│   │       ├── Pharmacodynamic Markers
│   │       │   ├── Target engagement
│   │       │   ├── Pathway modulation
│   │       │   ├── Mechanism confirmation
│   │       │   └── Dose-response relationships
│   │       ├── Predictive Biomarkers
│   │       │   ├── Treatment selection
│   │       │   ├── Companion diagnostics
│   │       │   ├── Precision medicine
│   │       │   └── Population enrichment
│   │       └── Considerations
│   │           ├── Analytical validation
│   │           ├── Clinical qualification
│   │           ├── Regulatory interaction
│   │           └── Statistical validation
│   └── Assess Safety and Tolerability
│       ├── Dose-Limiting Toxicities (DLTs)
│       │   ├── Phase I primary endpoint
│       │   ├── Pre-defined criteria
│       │   ├── Observation period specified
│       │   └── Attribution assessment
│       ├── Maximum Tolerated Dose (MTD)
│       │   ├── Traditional Phase I goal
│       │   ├── Dose escalation dependent
│       │   ├── DLT rate driven (typically 33%)
│       │   └── May not be optimal biological dose
│       └── Recommended Phase II Dose (RP2D)
│           ├── May be below MTD
│           ├── Incorporates PK/PD data
│           ├── Considers long-term tolerability
│           └── Biological activity evidence

ENDPOINT HIERARCHY PLANNING
├── Multiple Primary Endpoints
│   ├── Co-primary endpoints
│   │   ├── Both must be significant
│   │   ├── No multiplicity adjustment
│   │   ├── Higher risk of failure
│   │   └── Use when both outcomes essential
│   ├── Composite primary endpoints
│   │   ├── Single statistical test
│   │   ├── Component weighting issues
│   │   ├── Interpretation challenges
│   │   └── Regulatory acceptance varies
│   └── Single primary with hierarchy
│       ├── Controlled multiplicity
│       ├── Regulatory preference
│       ├── Clear testing sequence
│       └── Gatekeeping procedures
├── Secondary Endpoint Strategy
│   ├── Supportive of primary
│   ├── Additional benefit demonstration
│   ├── Safety characterization
│   ├── Quality of life assessment
│   ├── Biomarker exploration
│   └── Health economics
└── Exploratory Endpoints
    ├── Hypothesis generation
    ├── Future study design
    ├── Mechanism exploration
    ├── No multiplicity control
    └── Descriptive analysis only
```

## Statistical Method Selection by Endpoint Type

```
ANALYSIS METHOD BY ENDPOINT
├── Binary Endpoints
│   ├── Single Proportion
│   │   ├── Exact binomial test
│   │   ├── Wilson score confidence interval
│   │   ├── Clopper-Pearson CI
│   │   └── Agresti-Coull CI
│   ├── Two Proportions
│   │   ├── Fisher's exact test
│   │   ├── Chi-square test
│   │   ├── Cochran-Mantel-Haenszel test
│   │   └── Logistic regression
│   └── Multiple Proportions
│       ├── Cochran-Armitage trend test
│       ├── Multiple logistic regression
│       └── GEE for correlated data
├── Continuous Endpoints
│   ├── Single Sample
│   │   ├── One-sample t-test
│   │   ├── Wilcoxon signed-rank test
│   │   └── Bootstrap confidence intervals
│   ├── Two Samples
│   │   ├── Independent t-test
│   │   ├── Welch's t-test (unequal variances)
│   │   ├── Mann-Whitney U test
│   │   └── ANCOVA with baseline adjustment
│   └── Multiple Samples
│       ├── ANOVA
│       ├── Kruskal-Wallis test
│       ├── Mixed-effects models
│       └── GEE approaches
├── Time-to-Event Endpoints
│   ├── Single Group
│   │   ├── Kaplan-Meier estimation
│   │   ├── Life table methods
│   │   ├── Parametric survival models
│   │   └── Restricted mean survival time
│   ├── Two Groups
│   │   ├── Log-rank test
│   │   ├── Wilcoxon test (early differences)
│   │   ├── Cox proportional hazards
│   │   └── Accelerated failure time models
│   └── Multiple Groups/Covariates
│       ├── Stratified log-rank test
│       ├── Cox regression
│       ├── Parametric regression models
│       └── Competing risks analysis
└── Count Endpoints
    ├── Poisson regression
    ├── Negative binomial regression
    ├── Zero-inflated models
    └── GEE for repeated counts
```

## Implementation Checklist

### Decision Tree Usage
- [ ] **Study Phase Identified**
  - [ ] Phase I: Safety and dose finding
  - [ ] Phase II: Efficacy signal detection
  - [ ] Phase III: Confirmatory evidence
  - [ ] Phase IV: Post-marketing studies

- [ ] **Design Objectives Clear**
  - [ ] Primary objective specific and measurable
  - [ ] Secondary objectives prioritized
  - [ ] Regulatory intent defined
  - [ ] Commercial considerations included

- [ ] **Population Characteristics**
  - [ ] Disease characteristics understood
  - [ ] Patient population size estimated
  - [ ] Biomarker strategy defined
  - [ ] Feasibility assessed

### Method Selection Validation
- [ ] **Statistical Assumptions**
  - [ ] Distribution assumptions verified
  - [ ] Independence assumptions reasonable
  - [ ] Missing data mechanisms considered
  - [ ] Multiplicity issues addressed

- [ ] **Regulatory Alignment**
  - [ ] Guidance documents reviewed
  - [ ] Precedent studies identified
  - [ ] Agency interactions planned
  - [ ] Global requirements considered

- [ ] **Operational Feasibility**
  - [ ] Site capabilities assessed
  - [ ] Timeline realistic
  - [ ] Resource requirements estimated
  - [ ] Technology needs identified

---

*These decision trees provide guidance for statistical method selection and should be used in conjunction with therapeutic area expertise, regulatory guidance, and operational considerations.*