# ADaM Dataset Specification Templates

## ADSL Specification Template

### Dataset Overview
```
Dataset Name: ADSL (Subject-Level Analysis Dataset)
Purpose: Subject-level analysis variables and population flags
Structure: One record per subject
Source Data: SDTM domains (DM, EX, DS, etc.)
Population: All subjects who signed informed consent
```

### Variable Specifications

#### Identifier Variables
```
Variable: STUDYID
Label: Study Identifier  
Type: Character
Length: 200
Source: SDTM DM.STUDYID
Logic: Direct mapping from DM domain
Required: Yes
Controlled Terminology: None

Variable: USUBJID  
Label: Unique Subject Identifier
Type: Character
Length: 40
Source: SDTM DM.USUBJID
Logic: Direct mapping from DM domain
Required: Yes
Format: STUDYID-SITEID-SUBJID

Variable: SUBJID
Label: Subject Identifier for the Study
Type: Character  
Length: 20
Source: SDTM DM.SUBJID
Logic: Direct mapping from DM domain
Required: Yes

Variable: SITEID
Label: Study Site Identifier
Type: Character
Length: 10
Source: SDTM DM.SITEID  
Logic: Direct mapping from DM domain
Required: Yes
```

#### Treatment Variables
```
Variable: TRT01P
Label: Planned Treatment for Period 1
Type: Character
Length: 200
Source: SDTM DM.ARM
Logic: Planned treatment assignment from randomization
Required: Yes (for randomized studies)
Values: [Study-specific treatment descriptions]

Variable: TRT01PN
Label: Planned Treatment for Period 1 (N)
Type: Numeric
Length: 8
Source: Derived from TRT01P
Logic: Numeric coding of planned treatment
Required: Yes (for randomized studies)
Format: Treatment codes 1, 2, 3, etc.

Variable: TRT01A
Label: Actual Treatment for Period 1  
Type: Character
Length: 200
Source: SDTM EX.EXTRT (first treatment received)
Logic: First actual treatment with non-zero dose
Required: Yes (for treated subjects)
Values: [Study-specific treatment descriptions]

Variable: TRT01AN
Label: Actual Treatment for Period 1 (N)
Type: Numeric
Length: 8
Source: Derived from TRT01A
Logic: Numeric coding of actual treatment
Required: Yes (for treated subjects)
Format: Treatment codes 1, 2, 3, etc.
```

#### Population Flags
```
Variable: SAFFL
Label: Safety Population Flag
Type: Character
Length: 1
Source: Derived from SDTM EX
Logic: 'Y' if subject received at least one dose of study treatment
Required: Yes
Values: 'Y' = Yes, null = No
Derivation: If any EX.EXDOSE > 0 then SAFFL = 'Y'

Variable: ITTFL
Label: Intent-to-Treat Population Flag
Type: Character
Length: 1
Source: Derived from randomization status
Logic: 'Y' if subject was randomized to treatment
Required: Yes
Values: 'Y' = Yes, null = No
Derivation: If DM.ARM not missing then ITTFL = 'Y'

Variable: EFFFL
Label: Efficacy Population Flag
Type: Character
Length: 1
Source: Derived from baseline and post-baseline assessments
Logic: 'Y' if subject has baseline and ≥1 post-baseline efficacy assessment
Required: Study-specific
Values: 'Y' = Yes, null = No

Variable: COMPLFL
Label: Completers Population Flag
Type: Character
Length: 1  
Source: Derived from study completion status
Logic: 'Y' if subject completed study per protocol
Required: Study-specific
Values: 'Y' = Yes, null = No
```

#### Date Variables
```
Variable: TRTSDT
Label: Date of First Exposure to Treatment
Type: Numeric (Date)
Length: 8
Source: SDTM EX.EXSTDTC (earliest date with dose > 0)
Logic: First date with non-zero study treatment dose
Required: Yes (for treated subjects)
Format: DATE9.

Variable: TRTEDT
Label: Date of Last Exposure to Treatment
Type: Numeric (Date)
Length: 8
Source: SDTM EX.EXENDTC (latest date with dose > 0)
Logic: Last date with non-zero study treatment dose
Required: Yes (for treated subjects)
Format: DATE9.

Variable: RANDDT
Label: Date of Randomization
Type: Numeric (Date)
Length: 8
Source: Derived from randomization data or DM.RFICDTC
Logic: Date subject was randomized to treatment
Required: Study-specific
Format: DATE9.

Variable: DTHDT
Label: Date of Death
Type: Numeric (Date)
Length: 8
Source: SDTM DM.DTHDTC or DS domain
Logic: Date of death if subject died
Required: When applicable
Format: DATE9.

Variable: LSTALVDT
Label: Date Last Known Alive
Type: Numeric (Date)
Length: 8
Source: Latest non-death contact date across domains
Logic: Latest date subject known to be alive
Required: For survival analyses
Format: DATE9.
```

#### Demographic Variables
```
Variable: AGE
Label: Age
Type: Numeric
Length: 8
Source: SDTM DM.AGE
Logic: Age at reference timepoint (typically informed consent)
Required: Yes
Format: 3.

Variable: AGEGR1
Label: Pooled Age Group 1
Type: Character
Length: 20
Source: Derived from AGE
Logic: Age grouping for analysis
Required: Study-specific
Values: '<65', '>=65' or study-specific groupings

Variable: AGEGR1N
Label: Pooled Age Group 1 (N)
Type: Numeric
Length: 8
Source: Derived from AGEGR1
Logic: Numeric version of age grouping
Required: Study-specific
Format: Age group codes 1, 2, 3, etc.

Variable: SEX
Label: Sex
Type: Character
Length: 1
Source: SDTM DM.SEX
Logic: Direct mapping from DM
Required: Yes
Values: 'F', 'M', 'U'

Variable: RACE
Label: Race
Type: Character
Length: 100
Source: SDTM DM.RACE
Logic: Direct mapping from DM
Required: Yes
Values: Per CDISC controlled terminology

Variable: RACEN
Label: Race (N)
Type: Numeric
Length: 8
Source: Derived from RACE
Logic: Numeric coding of race
Required: Study-specific
Format: Race codes 1, 2, 3, etc.
```

---

## BDS Dataset Specification Template

### ADLB (Analysis Dataset Laboratory) Specification

#### Dataset Overview
```
Dataset Name: ADLB (Analysis Dataset Laboratory)
Purpose: Laboratory analysis data
Structure: BDS (Basic Data Structure)
Records: One record per subject per parameter per analysis timepoint
Source Data: SDTM LB domain
Population: Safety population with laboratory data
```

#### Core BDS Variables
```
Variable: STUDYID
Label: Study Identifier
Type: Character
Length: 200
Source: SDTM LB.STUDYID
Logic: Direct mapping
Required: Yes

Variable: USUBJID
Label: Unique Subject Identifier
Type: Character
Length: 40
Source: SDTM LB.USUBJID
Logic: Direct mapping
Required: Yes

Variable: PARAMCD
Label: Parameter Code
Type: Character
Length: 8
Source: SDTM LB.LBTESTCD
Logic: Standardized laboratory parameter codes
Required: Yes
Values: ALB, ALT, AST, BILI, BUN, CREAT, etc.

Variable: PARAM
Label: Parameter
Type: Character
Length: 200
Source: SDTM LB.LBTEST
Logic: Parameter description
Required: Yes
Values: Albumin (g/L), Alanine Aminotransferase (U/L), etc.

Variable: PARAMN
Label: Parameter (N)
Type: Numeric
Length: 8
Source: Derived from PARAMCD
Logic: Numeric parameter code for sorting/analysis
Required: Yes
Format: Parameter codes 1, 2, 3, etc.
```

#### Analysis Value Variables
```
Variable: AVAL
Label: Analysis Value
Type: Numeric
Length: 8
Source: SDTM LB.LBSTRESN
Logic: Numeric result in standard units
Required: When non-missing result available
Derivation: Direct from LBSTRESN or unit conversion

Variable: AVALC
Label: Analysis Value (C)
Type: Character
Length: 200
Source: SDTM LB.LBSTRESC
Logic: Character result for non-numeric results
Required: When AVAL is missing and character result available

Variable: BASE
Label: Baseline Value
Type: Numeric
Length: 8
Source: Derived from AVAL where ABLFL='Y'
Logic: Baseline value for parameter
Required: When baseline available
Derivation: AVAL where ABLFL='Y' for same USUBJID and PARAMCD

Variable: BASEC
Label: Baseline Value (C)
Type: Character
Length: 200
Source: Derived from AVALC where ABLFL='Y'
Logic: Baseline character value
Required: When baseline available and character

Variable: CHG
Label: Change from Baseline
Type: Numeric
Length: 8
Source: Calculated from AVAL and BASE
Logic: Change from baseline calculation
Required: When both AVAL and BASE available
Derivation: CHG = AVAL - BASE

Variable: PCHG
Label: Percent Change from Baseline
Type: Numeric
Length: 8
Source: Calculated from CHG and BASE
Logic: Percent change from baseline
Required: When CHG and BASE available and BASE ≠ 0
Derivation: PCHG = (CHG / BASE) * 100
```

#### Timing Variables
```
Variable: ADT
Label: Analysis Date
Type: Numeric (Date)
Length: 8
Source: SDTM LB.LBDTC
Logic: Date of laboratory assessment
Required: When date available
Format: DATE9.

Variable: ADTM
Label: Analysis Datetime
Type: Numeric (Datetime)
Length: 8
Source: SDTM LB.LBDTC
Logic: Date and time of assessment
Required: When datetime available
Format: DATETIME20.

Variable: ADY
Label: Analysis Relative Day
Type: Numeric
Length: 8
Source: Calculated from ADT and TRTSDT
Logic: Study day relative to first treatment
Required: When ADT and TRTSDT available
Derivation: Standard study day calculation

Variable: AVISIT
Label: Analysis Visit
Type: Character
Length: 200
Source: Visit mapping from SDTM LB.VISIT
Logic: Standardized analysis visit
Required: Yes
Values: Baseline, Week 2, Week 4, etc.

Variable: AVISITN
Label: Analysis Visit (N)
Type: Numeric
Length: 8
Source: Derived from AVISIT
Logic: Numeric visit for sorting
Required: Yes
Format: Visit numbers 0, 1, 2, etc.
```

#### Reference Range Variables
```
Variable: A1LO
Label: Analysis Range 1 Lower Limit
Type: Numeric
Length: 8
Source: SDTM LB.LBSTNRLO
Logic: Lower limit of normal range
Required: When available

Variable: A1HI
Label: Analysis Range 1 Upper Limit  
Type: Numeric
Length: 8
Source: SDTM LB.LBSTNRHI
Logic: Upper limit of normal range
Required: When available

Variable: ANRIND
Label: Analysis Reference Range Indicator
Type: Character
Length: 10
Source: SDTM LB.LBNRIND or derived
Logic: Reference range indicator
Required: When reference ranges available
Values: NORMAL, HIGH, LOW, ABNORMAL

Variable: BNRIND
Label: Baseline Reference Range Indicator
Type: Character
Length: 10
Source: ANRIND where ABLFL='Y'
Logic: Baseline reference range status
Required: When baseline available
Values: NORMAL, HIGH, LOW, ABNORMAL

Variable: SHIFT1
Label: Shift from Baseline Reference Range
Type: Character
Length: 10
Source: Concatenation of BNRIND and ANRIND
Logic: Shift in reference range status
Required: When both baseline and post-baseline available
Values: N-N, N-H, H-N, etc. (Normal/High/Low combinations)
```

#### Analysis Flags
```
Variable: ABLFL
Label: Baseline Record Flag
Type: Character
Length: 1
Source: Derived based on baseline definition
Logic: Identifies baseline record for each parameter
Required: Yes
Values: 'Y' = Baseline record, null = Non-baseline
Derivation: Last non-missing value on or before first dose

Variable: ANL01FL
Label: Analysis Record Flag 01
Type: Character
Length: 1
Source: Derived based on analysis criteria
Logic: Records included in primary analysis
Required: Study-specific
Values: 'Y' = Analysis record, null = Excluded

Variable: WORS01FL
Label: Worst Case Post-Baseline Flag 01
Type: Character
Length: 1
Source: Derived for safety analyses
Logic: Worst post-baseline value by criteria
Required: For safety parameters
Values: 'Y' = Worst case record, null = Not worst
```

---

## ADTTE Specification Template

### Time-to-Event Analysis Dataset

#### Dataset Overview
```
Dataset Name: ADTTE (Analysis Dataset Time-to-Event)
Purpose: Time-to-event analysis endpoints
Structure: BDS with time-to-event specific variables
Records: One record per subject per time-to-event parameter
Source Data: Multiple SDTM domains (DS, AE, etc.)
Population: Typically ITT or Safety population
```

#### Core Variables
```
Variable: PARAMCD
Label: Parameter Code
Type: Character
Length: 8
Source: Derived based on endpoint
Logic: Standardized time-to-event parameter codes
Required: Yes
Values: OS, PFS, DFS, TTR, TTNT, etc.

Variable: PARAM
Label: Parameter
Type: Character
Length: 200
Source: Derived based on endpoint
Logic: Parameter description
Required: Yes
Values: Overall Survival, Progression-Free Survival, etc.

Variable: AVAL
Label: Analysis Value
Type: Numeric
Length: 8
Source: Calculated time in days
Logic: Time from start date to event/censor date
Required: Yes
Derivation: (Event/Censor Date - Start Date) + 1
Units: Days

Variable: CNSR
Label: Censor
Type: Numeric
Length: 8
Source: Derived based on event occurrence
Logic: Censoring indicator
Required: Yes
Values: 0 = Event occurred, 1 = Censored
```

#### Time-to-Event Specific Variables
```
Variable: STARTDT
Label: Time to Event Origin Date for Subject
Type: Numeric (Date)
Length: 8
Source: Typically TRTSDT or RANDDT
Logic: Analysis start time reference
Required: Yes
Format: DATE9.

Variable: ADT
Label: Analysis Date
Type: Numeric (Date)
Length: 8
Source: Event date or censoring date
Logic: Date of event or last known status
Required: Yes
Format: DATE9.

Variable: EVNTDESC
Label: Event Description
Type: Character
Length: 200
Source: Description of event or censoring reason
Logic: What happened (event type or censor reason)
Required: Yes
Values: Death, Disease Progression, Lost to Follow-up, etc.

Variable: SRCDOM
Label: Source Domain
Type: Character
Length: 8
Source: SDTM domain where event information originated
Logic: Traceability to source data
Required: Yes
Values: DS, AE, TU, RS, etc.

Variable: SRCVAR
Label: Source Variable
Type: Character
Length: 32
Source: Variable name in source domain
Logic: Specific source variable
Required: When applicable

Variable: SRCSEQ
Label: Source Sequence Number
Type: Numeric
Length: 8
Source: Sequence number from source domain
Logic: Links to specific source record
Required: When applicable
```

---

## ADAE Specification Template

### Adverse Events Analysis Dataset

#### Dataset Overview
```
Dataset Name: ADAE (Analysis Dataset Adverse Events)
Purpose: Adverse events analysis data
Structure: OCCDS (Occurrence Data Structure)  
Records: One record per subject per adverse event occurrence
Source Data: SDTM AE domain
Population: Safety population
```

#### Event Identification Variables
```
Variable: AEDECOD
Label: Dictionary-Derived Term
Type: Character
Length: 100
Source: SDTM AE.AEDECOD
Logic: MedDRA Preferred Term
Required: Yes

Variable: AESOC
Label: Primary System Organ Class
Type: Character
Length: 100
Source: SDTM AE.AESOC
Logic: MedDRA System Organ Class
Required: Yes

Variable: AEBODSYS
Label: Body System or Organ Class
Type: Character
Length: 100
Source: SDTM AE.AESOC
Logic: Analysis grouping system
Required: Yes

Variable: AETERM
Label: Reported Term for the Adverse Event
Type: Character
Length: 200
Source: SDTM AE.AETERM
Logic: Investigator-reported term
Required: Yes
```

#### Analysis Variables
```
Variable: TRTEMFL
Label: Treatment Emergent Analysis Flag
Type: Character
Length: 1
Source: Derived based on AE timing
Logic: AE occurred during treatment period
Required: Yes
Values: 'Y' = Treatment emergent, null = Not treatment emergent
Derivation: AESTDT >= TRTSDT and AESTDT <= TRTEDT + safety follow-up

Variable: AETOXGRN
Label: Analysis Toxicity Grade (N)
Type: Numeric
Length: 8
Source: SDTM AE.AETOXGR or derived from AESEV
Logic: Numeric toxicity grade
Required: When applicable
Values: 1, 2, 3, 4, 5

Variable: AERELN
Label: Analysis Causality (N)
Type: Numeric
Length: 8
Source: Derived from SDTM AE.AEREL
Logic: Numeric causality assessment
Required: Yes
Values: 1=Not Related, 2=Possibly Related, 3=Probably Related, etc.

Variable: AESERN
Label: Analysis Serious Event (N)
Type: Numeric
Length: 8
Source: SDTM AE.AESER
Logic: Numeric serious event indicator
Required: Yes
Values: 0=No, 1=Yes
```

---

## Quality Control Specifications

### Validation Requirements
```
ADSL Validation Checks:
□ One record per subject (USUBJID unique)
□ All subjects in SDTM DM represented
□ Treatment variables consistent with randomization
□ Population flags mutually consistent
□ Date variables in proper sequence
□ Demographic variables consistent with SDTM

BDS Validation Checks:
□ Required BDS variables present
□ PARAMCD/PARAM consistency
□ AVAL/AVALC mutual exclusivity where specified
□ Baseline flag logic correctly implemented
□ Change calculations accurate
□ Visit structure consistent

ADTTE Validation Checks:
□ AVAL always positive
□ CNSR values only 0 or 1
□ Event dates after start dates
□ Source traceability complete
□ Competing events handled appropriately
```

### Documentation Requirements
```
For Each Dataset:
□ Dataset specification document
□ Variable-level derivation rules
□ Population definition documentation
□ Baseline methodology explanation
□ Visit windowing procedures
□ Quality control results
□ Define-XML computational methods
□ Analysis Data Reviewer Guide sections
```

---

## Implementation Notes

### Best Practices
- Start with ADSL as foundation for all other ADaM datasets
- Implement consistent naming conventions across datasets
- Document all derivation logic clearly
- Validate traceability to SDTM at each step
- Consider future analysis needs in design decisions
- Plan for multiple interim analyses if applicable

### Common Pitfalls to Avoid
- Inconsistent population definitions across datasets
- Missing baseline methodology documentation
- Inadequate visit windowing procedures  
- Incomplete traceability documentation
- Inconsistent handling of missing data
- Overly complex derivation logic

### Regulatory Considerations
- Ensure compatibility with analysis plans
- Consider reviewer efficiency in design
- Document any deviations from standard structures
- Plan for potential regulatory questions
- Maintain consistency with previous submissions (if applicable)

---

*These specifications should be customized based on study-specific requirements, therapeutic area considerations, and organizational standards. Regular review and updates are recommended to maintain alignment with current ADaM standards.*