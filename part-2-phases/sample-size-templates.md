# Sample Size Calculation Templates by Phase

## Phase I Sample Size Considerations

### Traditional 3+3 Design
**Sample Size Range**: 18-24 patients (typical)
**Deterministic Approach**: No formal sample size calculation required

```
Expected Sample Size by DLT Scenarios:
- All dose levels safe: 18 patients
- One DLT at some level: 21 patients  
- Two DLTs requiring de-escalation: 15-18 patients
- Multiple dose levels tested: 18-30 patients
```

**Documentation Template:**
```
Study Population: Patients with [indication]
Design: Traditional 3+3 dose escalation
Planned Dose Levels: [list doses]
Expected Sample Size: 18-24 patients
Rationale: Standard phase I approach for MTD determination
```

### Continual Reassessment Method (CRM)
**Sample Size**: Typically 15-30 patients
**Operating Characteristics Driven**

**Template Calculation:**
```
Target DLT Rate: 30%
Prior Distribution: [specify]
Dose Levels: [d1, d2, d3, d4, d5]
Cohort Size: 1-3 patients
Expected Sample Size: 20-25 patients
Maximum Sample Size: 30 patients

Operating Characteristics (via simulation):
- P(select MTD): 65%
- P(select dose within ±1 level of MTD): 85%
- Average # patients at MTD: 8-12
```

## Phase II Sample Size Calculations

### Single-Arm Simon's Two-Stage Design

#### Template for Binary Endpoint
```
Primary Endpoint: Overall Response Rate (ORR)
Historical Response Rate (p0): [X]%
Target Response Rate (p1): [Y]%
Type I Error (α): 5% (one-sided)
Type II Error (β): 20% (Power = 80%)

Optimal Design:
- Stage 1: n1 = [X] patients, stop if ≤ r1 = [X] responses
- Stage 2: n2 = [X] additional patients (total N = [X])
- Reject H0 if ≥ r = [X] total responses
- Expected sample size under H0: [X] patients
- Probability of early termination under H0: [X]%

Minimax Design:
- Stage 1: n1 = [X] patients, stop if ≤ r1 = [X] responses  
- Stage 2: n2 = [X] additional patients (total N = [X])
- Reject H0 if ≥ r = [X] total responses
```

#### SAS Code Template for Simon's Design:
```sas
/* Simon's Two-Stage Design Calculation */
proc seqdesign;
   TwoStagePW: design nstages=2
      method=whitehead
      alpha=0.05 beta=0.20
      ;
   samplesize model=twosample(nullprop=0.20 altprop=0.40);
run;

/* Alternative using exact binomial */
proc power;
   twosamplefreq test=pchi
      alpha=0.05 power=0.80
      nullproportion=0.20
      proportion=0.40
      ntotal=.;
run;
```

#### R Code Template:
```r
library(clinfun)

# Simon's Two-Stage Design
ph2simon(pu=0.20, pa=0.40, ep1=0.05, ep2=0.20)

# Output interpretation:
# r1: number of responses to continue to stage 2
# n1: stage 1 sample size  
# r: total responses needed for efficacy
# n: total sample size
# EN(p0): expected sample size under null
# PET(p0): probability early termination under null
```

### Randomized Phase II Designs

#### Two-Arm Comparison Template
```
Primary Endpoint: [Response Rate/PFS/OS]
Control Arm Response Rate: [X]%
Experimental Arm Response Rate: [Y]% 
Difference to Detect: [Y-X]%
Randomization Ratio: 1:1
Type I Error (α): 10% (one-sided) or 20% (two-sided)
Type II Error (β): 20% (Power = 80%)

Sample Size Calculation:
Using normal approximation for proportions:
n = 2 × (Z_α + Z_β)² × p(1-p) / δ²
where p = (p1 + p2)/2, δ = p1 - p2

Results:
- Per arm sample size: [X] patients
- Total sample size: [2X] patients
- Including 10% dropout: [X] patients per arm
```

#### Time-to-Event Endpoints Template
```
Primary Endpoint: Progression-Free Survival (PFS)
Control Arm Median PFS: [X] months
Experimental Arm Median PFS: [Y] months
Hazard Ratio: [HR] 
Type I Error (α): 10% (one-sided)
Power: 80%
Accrual Period: [X] months
Follow-up Period: [Y] months

Events Required:
E = 4(Z_α + Z_β)² / [ln(HR)]²
E = [calculated number] events

Sample Size Calculation:
Assumes exponential distribution
Expected event rate in control: [X]%
Required sample size: [N] patients per arm
Total sample size: [2N] patients
```

## Phase III Sample Size Calculations

### Superiority Trial Templates

#### Binary Primary Endpoint
```
Study Design: Randomized, double-blind, placebo-controlled
Primary Endpoint: [Endpoint name]
Statistical Hypothesis: Two-sided superiority test

Control Response Rate (p1): [X]%
Experimental Response Rate (p2): [Y]%
Difference: [Y-X]% (relative risk = [RR])
Type I Error (α): 5% (two-sided)
Power (1-β): 90%
Randomization Ratio: 1:1

Sample Size Formula:
n = 2 × [Z_α/2 + Z_β]² × [p1(1-p1) + p2(1-p2)] / (p2-p1)²

Calculation:
- Per arm: [X] evaluable patients
- Total: [2X] evaluable patients  
- With 10% dropout: [X] patients per arm
- Total enrollment: [2X] patients

Statistical Power Verification:
- Detectable difference: [X]%
- 95% Confidence interval half-width: ±[X]%
```

#### Time-to-Event Primary Endpoint
```
Study Design: Randomized, controlled trial
Primary Endpoint: Overall Survival
Statistical Hypothesis: Two-sided test of hazard ratio

Control Median Survival: [X] months
Experimental Median Survival: [Y] months
Hazard Ratio (HR): [Z] 
Type I Error (α): 5% (two-sided)
Power: 90%
Randomization Ratio: 1:1

Accrual:
- Accrual period: [X] months
- Uniform accrual rate
- Follow-up period: [Y] months after last patient

Events Required:
E = 4(Z_α/2 + Z_β)² / [ln(HR)]²
E = [calculated] deaths

Sample Size:
Based on exponential survival distribution
Control arm event probability: [X]%
Required enrollment: [N] patients per arm
Total enrollment: [2N] patients

Timeline:
- Accrual completion: Month [X]
- Primary analysis: Month [Y]
- Expected events at analysis: [E] events
```

### Non-Inferiority Trial Templates

#### Binary Endpoint Non-Inferiority
```
Study Design: Randomized, active-controlled, non-inferiority
Primary Endpoint: [Clinical cure rate]
Statistical Hypothesis: One-sided non-inferiority test

Active Control Response Rate: [X]%
Non-Inferiority Margin (δ): [Y]%
Lower Bound of Active vs Historical Placebo: [Z]%
Preservation of Effect: 50% of historical effect

Type I Error (α): 2.5% (one-sided)  
Power: 80%
Randomization Ratio: 1:1

Margin Justification:
- Historical placebo rate: [A]%
- Historical active rate: [B]%
- Historical difference: [B-A]%
- Margin = 50% × [B-A]% = [Y]%

Sample Size Calculation:
n = 2 × (Z_α + Z_β)² × p(1-p) / δ²
where p is assumed common response rate

Results:
- Per arm: [X] patients
- Total: [2X] patients
- With 5% dropout: [X] per arm
- Total enrollment: [2X] patients
```

#### Time-to-Event Non-Inferiority
```
Study Design: Non-inferiority trial
Primary Endpoint: Disease-Free Survival
Non-Inferiority Margin: HR ≤ 1.3

Control Median DFS: [X] months  
Non-Inferiority HR Margin: 1.3
Type I Error (α): 2.5% (one-sided)
Power: 80%

Events Required:
E = (Z_α + Z_β)² / [ln(HR_margin)]²
E = (1.96 + 0.84)² / [ln(1.3)]²
E = [calculated] events

Sample Size:
- Expected event rate: [X]%
- Required sample size: [N] per arm
- Total enrollment: [2N] patients

Non-Inferiority Conclusion:
Conclude non-inferiority if upper limit of 95% CI 
for HR is < 1.3
```

### Group Sequential Design Templates

#### Efficacy Monitoring Template
```
Design: Group sequential with efficacy monitoring
Number of Interim Analyses: 2
Information Times: 50%, 75%, 100%
Alpha Spending Function: O'Brien-Fleming
Overall Type I Error: 5% (two-sided)
Power: 90%

Boundary Calculations:
Analysis 1 (50% information): 
- Z-boundary: ±2.963
- p-value boundary: 0.0031
- Conditional power threshold: <20% for futility

Analysis 2 (75% information):
- Z-boundary: ±2.359  
- p-value boundary: 0.0183
- Conditional power threshold: <30% for futility

Final Analysis (100% information):
- Z-boundary: ±2.014
- p-value boundary: 0.044

Sample Size Adjustment:
- Fixed design sample size: [N]
- Group sequential adjustment factor: 1.02
- Adjusted sample size: [1.02N] per arm
```

## Special Population Considerations

### Pediatric Study Templates

#### Pediatric Sample Size Adjustments
```
Adult Efficacy Data:
- Adult response rate: [X]%
- Expected pediatric response rate: [Y]%
- Rationale for difference: [developmental, PK, etc.]

Pediatric-Specific Considerations:
- Age stratification: [age groups]
- Weight-based dosing: [yes/no]
- Developmental endpoints: [if applicable]
- Safety run-in: [number] patients

Modified Sample Size:
- Adjusted for pediatric response rate
- Stratified by age group if needed
- Additional safety monitoring patients
- Total pediatric sample size: [N]
```

### Rare Disease Templates

#### Small Population Considerations
```
Disease Prevalence: [X] cases per 100,000
Annual Incidence: [Y] new cases per year
Available Patient Population: [Z] patients

Design Modifications:
- Single-arm design preferred
- Historical controls when available
- Bayesian approaches for small samples
- Adaptive designs for efficiency
- International collaboration needed

Sample Size Strategy:
- Maximum feasible sample size: [N]
- Power achievable: [X]%
- Minimum detectable effect: [Y]%
- Study duration: [Z] years
```

## Quality Control Checklist

### Sample Size Calculation Review
- [ ] **Assumptions Documented**
  - [ ] Primary endpoint clearly defined
  - [ ] Control group assumptions justified
  - [ ] Treatment effect size clinically meaningful
  - [ ] Dropout rate realistic

- [ ] **Statistical Parameters**
  - [ ] Type I error appropriate for phase/objective
  - [ ] Power adequate (typically ≥80%)
  - [ ] One-sided vs two-sided test justified
  - [ ] Multiple comparisons considered

- [ ] **Calculation Verification**
  - [ ] Independent calculation performed
  - [ ] Software/formula verified
  - [ ] Sensitivity analyses conducted
  - [ ] Regulatory precedents reviewed

- [ ] **Feasibility Assessment**
  - [ ] Patient population availability
  - [ ] Enrollment timeline realistic  
  - [ ] Center capabilities assessed
  - [ ] Budget and resource requirements

---

## Software Resources

### SAS Procedures
- `PROC POWER`: Sample size and power calculations
- `PROC SEQDESIGN`: Group sequential designs
- `PROC SEQTEST`: Sequential boundary testing

### R Packages
- `pwr`: Basic power calculations
- `gsDesign`: Group sequential designs  
- `clinfun`: Clinical trial design functions
- `OneArmPhaseTwoStudy`: Single-arm Phase II designs

### Commercial Software
- **nQuery**: Comprehensive sample size software
- **EAST**: Adaptive and sequential designs
- **PASS**: Power analysis and sample size software

---

*These templates should be customized based on specific study requirements, therapeutic area, and regulatory guidance. Always verify calculations independently and consider consulting statistical experts for complex designs.*