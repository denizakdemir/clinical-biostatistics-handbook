# Part 3: CDISC Standards and Data Structures
## CDISC Mastery for Biostatisticians: From SDTM to ADaM to TLFs

### Overview

Clinical Data Interchange Standards Consortium (CDISC) standards are essential for regulatory submissions and efficient data analysis in clinical trials. This section provides biostatisticians with comprehensive guidance on SDTM (Study Data Tabulation Model), ADaM (Analysis Data Model), and associated metadata standards.

---

## 1. CDISC Foundation and Regulatory Context

### 1.1 CDISC Standards Overview

**Core Standards:**
- **SDTM**: Study Data Tabulation Model - Raw data organization
- **ADaM**: Analysis Data Model - Analysis-ready datasets
- **Define-XML**: Metadata documentation standard
- **ODM**: Operational Data Model - Data collection standard
- **Protocol Representation Model**: Structured protocol content

**Regulatory Landscape:**
- **FDA**: Required for NDAs/BLAs since 2016
- **EMA**: Recommended, increasing adoption
- **PMDA**: Required for certain submissions
- **Other agencies**: Growing international adoption

### 1.2 Benefits for Biostatisticians

**Standardization Benefits:**
- Consistent variable names and structures
- Reduced learning curve across studies
- Enhanced data quality and traceability
- Automated quality control procedures
- Improved reviewer efficiency

**Regulatory Advantages:**
- Accelerated review timelines
- Reduced data queries
- Enhanced transparency
- Improved submission quality
- Global harmonization

---

## 2. SDTM (Study Data Tabulation Model)

### 2.1 SDTM Principles and Structure

**Core Principles:**
- **One fact per record**: Each observation represents a single data point
- **Traceability**: Clear link to source data
- **Standardization**: Common variables across domains
- **Controlled terminology**: Standardized coding
- **Relationship modeling**: Links between domains

**Domain Types:**
- **Special Purpose**: DM (Demographics), CO (Comments)
- **Interventions**: EX (Exposure), CM (Concomitant Medications)
- **Events**: AE (Adverse Events), MH (Medical History)
- **Findings**: VS (Vital Signs), LB (Laboratory), QS (Questionnaires)
- **Trial Design**: TE (Trial Elements), TV (Trial Visits)

### 2.2 Key SDTM Domains for Analysis

#### Demographics Domain (DM)
```
Essential Variables:
STUDYID    - Study identifier
DOMAIN     - Domain abbreviation (DM)
USUBJID    - Unique subject identifier
SUBJID     - Subject identifier for the study
RFSTDTC    - Reference start date/time
RFENDTC    - Reference end date/time
RFXSTDTC   - Date/time of first study treatment
RFXENDTC   - Date/time of last study treatment
RFICDTC    - Date/time of informed consent
RFPENDTC   - Date/time of end of participation
DTHDTC     - Date/time of death
DTHFL      - Subject death flag
SITEID     - Study site identifier
AGE        - Age
AGEU       - Age units
SEX        - Sex
RACE       - Race
ETHNIC     - Ethnicity
ARMCD      - Planned arm code
ARM        - Description of planned arm
ACTARMCD   - Actual arm code
ACTARM     - Description of actual arm
COUNTRY    - Country
DMDTC      - Date/time of collection
DMDY       - Study day of collection
```

#### Adverse Events Domain (AE)
```
Essential Variables:
STUDYID    - Study identifier
DOMAIN     - Domain abbreviation (AE)
USUBJID    - Unique subject identifier
AESEQ      - Sequence number
AESPID     - Sponsor-defined identifier
AETERM     - Reported term for the adverse event
AELLT      - Lowest level term
AELLTCD    - Lowest level term code
AEDECOD    - Dictionary-derived term
AEPTCD     - Preferred term code
AEHLT      - High level term
AEHLTCD    - High level term code
AEHLGT     - High level group term
AEHLGTCD   - High level group term code
AESOC      - Primary system organ class
AESOCCD    - Primary system organ class code
AESEV      - Severity/intensity
AESER      - Serious event
AEACN      - Action taken with study treatment
AEREL      - Causality
AEOUT      - Outcome of adverse event
AESTDTC    - Start date/time of adverse event
AEENDTC    - End date/time of adverse event
AESTDY     - Study day of start of adverse event
AEENDY     - Study day of end of adverse event
```

#### Laboratory Domain (LB)
```
Essential Variables:
STUDYID    - Study identifier
DOMAIN     - Domain abbreviation (LB)
USUBJID    - Unique subject identifier
LBSEQ      - Sequence number
LBSPID     - Sponsor-defined identifier
LBTESTCD   - Lab test short name
LBTEST     - Lab test name
LBCAT      - Category for lab test
LBSCAT     - Subcategory for lab test
LBORRES    - Result or finding in original units
LBORRESU   - Original units
LBORNRLO   - Reference range lower limit in orig unit
LBORNRHI   - Reference range upper limit in orig unit
LBSTRESC   - Character result/finding in std format
LBSTRESN   - Numeric result/finding in standard units
LBSTRESU   - Standard units
LBSTNRLO   - Reference range lower limit-std units
LBSTNRHI   - Reference range upper limit-std units
LBNRIND    - Reference range indicator
LBNAM      - Vendor name
LBSPEC     - Specimen type
LBMETHOD   - Method of test or examination
LBBLFL     - Baseline flag
LBFAST     - Fasting status
LBDRVFL    - Derived flag
LBDTC      - Date/time of specimen collection
LBDY       - Study day of specimen collection
LBTM       - Time of specimen collection
```

### 2.3 SDTM Implementation Guidelines

#### Variable Naming Conventions
```
Standard Format: [Domain][Qualifier][Variable]

Examples:
AESTDTC    - AE Start Date/Time Character
AEENDY     - AE End Study Day
LBSTRESN   - LB Standard Result Numeric
VSTESTCD   - VS Test Short Name
EXDOSE     - EX Dose
```

#### Date/Time Standards
```
ISO 8601 Format: YYYY-MM-DDTHH:MM:SS

Complete: 2023-03-15T14:30:00
Date only: 2023-03-15
Partial: 2023-03
Unknown: 2023-03-UNK
```

#### Study Day Calculations
```
Study Day Rules:
- Day 1 = first dose date (RFXSTDTC)
- Days before first dose are negative
- No Day 0
- Formula: DY = DATE - RFXSTDT + 1 (if DATE >= RFXSTDT)
         DY = DATE - RFXSTDT (if DATE < RFXSTDT)
```

---

## 3. ADaM (Analysis Data Model)

### 3.1 ADaM Principles and Standards

**Core Principles:**
- **Analysis-ready**: No further manipulation needed
- **Traceability**: Clear derivation from SDTM
- **One record per subject per parameter per analysis timepoint**
- **Standardized structure** across studies and sponsors
- **Comprehensive metadata** documentation

**Dataset Types:**
- **ADSL**: Subject-Level Analysis Dataset
- **BDS**: Basic Data Structure (ADAE, ADLB, ADVS, etc.)
- **OCCDS**: Occurrence Data Structure
- **Custom**: Study-specific analysis datasets

### 3.2 ADSL (Subject-Level Analysis Dataset)

#### Essential ADSL Variables
```
Identifiers and Demographics:
STUDYID    - Study identifier
USUBJID    - Unique subject identifier  
SUBJID     - Subject identifier for the study
SITEID     - Study site identifier
AGE        - Age at reference timepoint
AGEGR1     - Age group 1 (e.g., <65, >=65)
AGEGR1N    - Age group 1 (N)
SEX        - Sex
RACE       - Race
RACEN      - Race (N)
ETHNIC     - Ethnicity
ETHNICN    - Ethnicity (N)
COUNTRY    - Country
REGION1    - Geographic region 1

Treatment Variables:
ACTARM     - Description of actual arm
ACTARMCD   - Actual arm code
ARM        - Description of planned arm
ARMCD      - Planned arm code
TRT01P     - Planned treatment for period 1
TRT01PN    - Planned treatment for period 1 (N)
TRT01A     - Actual treatment for period 1
TRT01AN    - Actual treatment for period 1 (N)

Dates and Times:
RFSTDTC    - Subject reference start date/time
RFENDTC    - Subject reference end date/time
RFXSTDTC   - Date/time of first study treatment
RFXENDTC   - Date/time of last study treatment
RFICDTC    - Date/time of informed consent
RFPENDTC   - Date/time end of participation
DTHDTC     - Date/time of death
DTHDT      - Date of death
LSTALVDT   - Date last known alive

Study Participation:
RANDDT     - Date of randomization
TRTSDT     - Date of first exposure to treatment
TRTEDT     - Date of last exposure to treatment
DCREASCD   - Reason for discontinuation from study
DTHFL      - Subject death flag
SAFFL      - Safety population flag
ITTFL      - Intent-to-treat population flag
EFFFL      - Efficacy population flag
COMPLFL    - Completers population flag
```

#### Population Flags in ADSL
```
Analysis Population Definitions:

Safety Population (SAFFL):
- All subjects who received at least one dose of study treatment
- Primary population for safety analyses

Intent-to-Treat Population (ITTFL):  
- All randomized subjects (Phase II/III studies)
- All treated subjects (Phase I studies)
- Primary population for efficacy analyses

Per-Protocol Population (COMPLFL):
- Subjects who completed study per protocol
- Excludes major protocol violations
- Supportive population for non-inferiority studies

Efficacy Population (EFFFL):
- Subjects with at least one post-baseline efficacy assessment
- May exclude subjects with no opportunity for efficacy evaluation
```

### 3.3 Basic Data Structure (BDS) Datasets

#### ADAE (Analysis Dataset Adverse Events)
```
BDS Structure Variables:
STUDYID    - Study identifier
USUBJID    - Unique subject identifier
AEDECOD    - Dictionary-derived term
AESOC      - Primary system organ class
AEBODSYS   - Body system or organ class
AEHLT      - High level term
AETERM     - Reported term for adverse event

Analysis Variables:
PARAMCD    - Parameter code
PARAM      - Parameter
AVAL       - Analysis value
AVALC      - Analysis value (character)
ABLFL      - Baseline record flag
ANL01FL    - Analysis record flag 01
DTYPE      - Derivation type

Timing Variables:
ADT        - Analysis date
ADTM       - Analysis datetime
ADY        - Analysis relative day
AVISIT     - Analysis visit
AVISITN    - Analysis visit (N)
ATPT       - Analysis timepoint
ATPTN      - Analysis timepoint (N)

Treatment and Severity:
TRTA       - Actual treatment
TRTAN      - Actual treatment (N)
AETOXGR    - Standard toxicity grade
AETOXGRN   - Standard toxicity grade (N)
AESEV      - Severity/intensity
AESEVN     - Severity/intensity (N)
AESER      - Serious event
AESERN     - Serious event (N)
AEREL      - Causality
AERELN     - Causality (N)
```

#### ADLB (Analysis Dataset Laboratory)
```
BDS Laboratory Structure:
STUDYID    - Study identifier
USUBJID    - Unique subject identifier
PARAMCD    - Parameter code (e.g., ALT, CREAT, HGB)
PARAM      - Parameter description
PARAMN     - Parameter (N)

Analysis Values:
AVAL       - Analysis value (numeric)
AVALC      - Analysis value (character)  
BASE       - Baseline value
BASEC      - Baseline value (character)
CHG        - Change from baseline
PCHG       - Percent change from baseline
SHIFT1     - Shift from baseline (e.g., N-H-N)

Reference Ranges:
A1LO       - Analysis range 1 lower limit
A1HI       - Analysis range 1 upper limit
R2A1LO     - Ratio to analysis range 1 lower limit
R2A1HI     - Ratio to analysis range 1 upper limit
ANRIND     - Analysis reference range indicator
BNRIND     - Baseline reference range indicator

Flags and Categories:
LBCAT      - Category for lab test
LBSCAT     - Subcategory for lab test
ABLFL      - Baseline record flag
ANL01FL    - Analysis record flag 01
WORS01FL   - Worst case post-baseline flag 01
```

#### ADTTE (Analysis Dataset Time-to-Event)
```
Time-to-Event Structure:
STUDYID    - Study identifier
USUBJID    - Unique subject identifier
PARAMCD    - Parameter code (e.g., OS, PFS, DFS)
PARAM      - Parameter description

Analysis Variables:
AVAL       - Analysis value (time to event in days)
AVALC      - Analysis value (character)
CNSR       - Censor (0=event, 1=censored)
EVNTDESC   - Event description
SRCDOM     - Source domain
SRCVAR     - Source variable
SRCSEQ     - Source sequence number

Time Variables:
STARTDT    - Time to event origin date for subject
STARTDTM   - Time to event origin datetime for subject
ADT        - Analysis date (event/censor date)
ADTM       - Analysis datetime (event/censor datetime)
```

### 3.4 ADaM Implementation Guidelines

#### Variable Naming Conventions
```
Core BDS Variables:
AVAL       - Analysis value (numeric)
AVALC      - Analysis value (character)
BASE       - Baseline value
CHG        - Change from baseline
PCHG       - Percent change from baseline

Timing Variables:
ADT        - Analysis date
ADY        - Analysis relative day
AVISIT     - Analysis visit
AVISITN    - Analysis visit (N)

Flag Variables:
ABLFL      - Baseline record flag (Y/null)
ANL01FL    - Analysis record flag 01 (Y/null)
WORS01FL   - Worst case post-baseline flag 01 (Y/null)
```

#### Baseline Methodology
```
Baseline Definition Options:

Last Non-Missing Before First Dose:
- Most common approach
- Clinically interpretable
- Handles pre-dose assessments

Last Non-Missing On or Before First Dose:
- Includes same-day assessments
- May include post-dose values
- Requires careful timing

Study-Specific Rules:
- Multiple baseline approaches
- Therapeutic area considerations
- Regulatory guidance alignment
```

#### Visit Windowing
```
Analysis Visit Assignment:

Window Approach:
- Pre-defined visit windows
- Nominal day ± window
- Multiple records handled by priority

Actual Visit Approach:  
- Use actual visit assignments
- Map unscheduled visits
- Handle early termination visits

Hybrid Approach:
- Combine windowing with actual visits
- Handle unscheduled assessments
- Maintain analysis visit structure
```

---

## 4. Define-XML and Metadata Standards

### 4.1 Define-XML Overview

**Purpose:**
- Document dataset and variable metadata
- Provide traceability and derivations
- Support regulatory review efficiency
- Enable automated data validation

**Components:**
- Dataset metadata
- Variable definitions
- Value level metadata
- Controlled terminology
- Computational methods
- Analysis datasets documentation

### 4.2 Define-XML Structure

#### Dataset Level Metadata
```xml
<ItemGroupDef OID="IG.DM" Name="DM" Label="Demographics" 
              Repeating="No" IsReferenceData="No" 
              SASDatasetName="DM" Domain="DM" 
              Purpose="Tabulation" Class="SPECIAL PURPOSE">
  <Description>
    <TranslatedText xml:lang="en">Demographics</TranslatedText>
  </Description>
  <ItemRef ItemOID="IT.DM.STUDYID" OrderNumber="1" Mandatory="Yes"/>
  <ItemRef ItemOID="IT.DM.DOMAIN" OrderNumber="2" Mandatory="Yes"/>
  <ItemRef ItemOID="IT.DM.USUBJID" OrderNumber="3" Mandatory="Yes"/>
  <!-- Additional variable references -->
</ItemGroupDef>
```

#### Variable Level Metadata
```xml
<ItemDef OID="IT.DM.AGE" Name="AGE" Label="Age" 
         DataType="integer" Length="3" SignificantDigits="3">
  <Description>
    <TranslatedText xml:lang="en">Age</TranslatedText>
  </Description>
  <Question>
    <TranslatedText xml:lang="en">Age</TranslatedText>
  </Question>
  <RangeCheck Comparator="GE" SoftHard="Soft">
    <CheckValue>18</CheckValue>
    <ErrorMessage>
      <TranslatedText xml:lang="en">Age should be 18 or greater</TranslatedText>
    </ErrorMessage>
  </RangeCheck>
</ItemDef>
```

#### Computational Methods
```xml
<MethodDef OID="MT.CHG" Name="Change from Baseline" Type="Computation">
  <Description>
    <TranslatedText xml:lang="en">Change from Baseline Calculation</TranslatedText>
  </Description>
  <FormalExpression Context="SAS">
    CHG = AVAL - BASE;
    if missing(BASE) then CHG = .;
  </FormalExpression>
</MethodDef>
```

### 4.3 Controlled Terminology

#### CDISC Controlled Terminology Sources
```
NCI Thesaurus (NCIt):
- Primary source for CDISC CT
- Quarterly updates
- Concept codes and preferred terms
- Extensible for sponsor-specific terms

Examples:
RACE:
- AMERICAN INDIAN OR ALASKA NATIVE
- ASIAN  
- BLACK OR AFRICAN AMERICAN
- NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER
- WHITE
- OTHER
- NOT REPORTED
- UNKNOWN

SEX:
- F (Female)
- M (Male)
- U (Unknown)
- UNDIFFERENTIATED
```

#### Custom Controlled Terminology
```
Sponsor Extensions:

AEDECOD (Adverse Event Decoded Term):
- Use MedDRA preferred terms
- Maintain version consistency
- Document coding decisions

CMDECOD (Concomitant Medication Decoded Term):
- Use WHODrug preferred terms
- Handle combination products
- Maintain therapeutic classification

Study-Specific Terms:
- VISITNUM assignments
- EPOCH definitions  
- Custom categories
- Biomarker classifications
```

---

## 5. Quality Control and Validation

### 5.1 SDTM Quality Control Procedures

#### Domain Validation Checks
```
Demographics Domain (DM):
□ One record per subject
□ USUBJID is unique and non-missing
□ RFSTDTC format validation (ISO 8601)
□ Age calculations consistent with birth date
□ Required variables populated
□ Controlled terminology compliance
□ Date consistency (RFSTDTC ≤ RFENDTC)

Adverse Events Domain (AE):
□ USUBJID exists in DM domain
□ AESEQ is unique within subject
□ AESTDTC ≤ AEENDTC when both present
□ MedDRA coding consistency
□ AESEV, AESER, AEREL populated
□ Serious AE criteria alignment
□ AESTDY/AEENDY calculations correct
```

#### Cross-Domain Validation
```
Exposure vs. Adverse Events:
□ AE start dates within exposure period
□ Treatment-emergent AE identification
□ Dose modification relationships

Demographics vs. All Domains:
□ USUBJID consistency across domains
□ Subject exists in DM for all other domains
□ STUDYID consistency
□ Date ranges within study participation

Laboratory vs. Reference Ranges:
□ Reference range assignments by age/sex
□ Unit conversions validated
□ Normal range indicators correct
```

### 5.2 ADaM Quality Control Procedures

#### ADSL Validation
```
Population Flags:
□ SAFFL logic documented and validated
□ ITTFL/EFFFL definitions implemented correctly
□ Flag consistency (ITTFL ⊆ SAFFL typically)
□ Population counts match expectations

Treatment Variables:
□ TRT01P/TRT01A consistency
□ Randomization vs. actual treatment
□ Treatment duration calculations
□ Exposure summaries align with SDTM EX

Date Variables:
□ Date derivations documented
□ Missing date handling specified
□ Date consistency checks
□ Study day calculations validated
```

#### BDS Dataset Validation
```
Analysis Values:
□ AVAL derivation from SDTM documented
□ Baseline methodology implemented correctly
□ Change from baseline calculations
□ Unit conversions validated
□ Missing value handling specified

Visit Structure:
□ Analysis visit assignments documented
□ Visit windowing rules applied consistently
□ Unscheduled visit handling
□ Early termination visit assignment

Flags and Indicators:
□ ABLFL assignment logic
□ ANL01FL analysis record identification
□ Worst-case flag derivations
□ Population subset flags
```

### 5.3 Traceability Documentation

#### SDTM to Source Traceability
```
Documentation Requirements:
□ Source dataset specifications
□ Variable mapping specifications
□ Derivation algorithms documented
□ Controlled terminology mapping
□ Data cleaning decisions
□ Protocol deviation handling

Tools and Methods:
- Mapping specifications
- Annotated CRFs
- Programming specifications
- Define-XML documentation
- Reviewer guides
```

#### ADaM to SDTM Traceability
```
Analysis Dataset Specifications:
□ SDTM source identification
□ Derivation methodology
□ Population definitions
□ Visit windowing procedures
□ Baseline definitions
□ Analysis flag derivations

Documentation Components:
- Analysis Data Reviewer Guide (ADRG)
- Dataset specifications
- Derivation documentation
- Define-XML computational methods
- Programming specifications
```

---

## 6. Implementation Tools and Templates

### 6.1 Programming Specifications Template

#### SDTM Programming Specification
```
Dataset: DM (Demographics)
Purpose: Subject demographics and characteristics
Source: Raw datasets (demographic, randomization, disposition)

Variable Specifications:
STUDYID:
- Source: Protocol number
- Logic: Constant value
- Format: Character
- Length: 200

USUBJID:
- Source: Subject identifier  
- Logic: STUDYID || "-" || SITEID || "-" || SUBJID
- Format: Character
- Length: 40
- Required: Yes

AGE:
- Source: Birth date, informed consent date
- Logic: FLOOR((RFICDTC - birth_date) / 365.25)
- Format: Numeric
- Length: 3
- Range: 18-100

ARM/ARMCD:
- Source: Randomization dataset
- Logic: Treatment assignment per randomization
- Format: Character  
- Length: 200/20
- Controlled Terminology: Protocol-specific
```

#### ADaM Programming Specification  
```
Dataset: ADSL (Subject-Level Analysis Dataset)
Purpose: Subject-level analysis variables and population flags

Derivation Logic:
SAFFL (Safety Population Flag):
- Logic: If subject received at least one dose of study treatment
- Source: SDTM EX domain
- Values: 'Y' = Yes, null = No

ITTFL (Intent-to-Treat Population Flag):
- Logic: If subject was randomized to treatment
- Source: SDTM DM domain (ARM not null)
- Values: 'Y' = Yes, null = No

TRT01A (Actual Treatment):
- Logic: First actual treatment received
- Source: SDTM EX domain
- Mapping: EX.EXTRT where EXDOSFRQ not missing
- Format: Character, Length: 200

TRTSDT/TRTEDT (Treatment Start/End Date):
- Source: SDTM EX domain
- Logic: First/last non-missing EXSTDTC where EXDOSE > 0
- Format: Numeric date (SAS date value)
```

### 6.2 Define-XML Generation Templates

#### Automated Define-XML Creation
```sas
/* Define-XML Generation Template */

/* Step 1: Create dataset metadata */
data dataset_meta;
    length dataset $32 label $256 class $32 purpose $32;
    dataset = 'DM'; label = 'Demographics'; 
    class = 'SPECIAL PURPOSE'; purpose = 'Tabulation'; output;
    
    dataset = 'AE'; label = 'Adverse Events'; 
    class = 'EVENTS'; purpose = 'Tabulation'; output;
    
    dataset = 'ADSL'; label = 'Subject Level Analysis Dataset'; 
    class = 'SUBJECT LEVEL'; purpose = 'Analysis'; output;
run;

/* Step 2: Create variable metadata */
data variable_meta;
    length dataset $32 variable $32 label $256 type $32 length 8;
    /* DM variables */
    dataset='DM'; variable='STUDYID'; label='Study Identifier'; 
    type='text'; length=12; output;
    
    dataset='DM'; variable='USUBJID'; label='Unique Subject Identifier'; 
    type='text'; length=40; output;
    
    /* Continue for all variables... */
run;

/* Step 3: Generate Define-XML */
%include "define_xml_macro.sas";
%create_define(
    study_name=XYZ-001,
    datasets=dataset_meta,
    variables=variable_meta,
    output_path=/studies/xyz001/define/define.xml
);
```

### 6.3 Validation Programs Template

#### SDTM Validation Checks
```sas
/* SDTM Domain Validation Template */

%macro validate_sdtm_domain(domain=);
    
    /* Check 1: Required variables present */
    proc contents data=sdtm.&domain out=contents noprint;
    run;
    
    data req_vars;
        set contents;
        if upcase(name) in ('STUDYID' 'DOMAIN' 'USUBJID');
    run;
    
    /* Check 2: USUBJID uniqueness (for Special Purpose domains) */
    %if %upcase(&domain) in (DM CO) %then %do;
        proc freq data=sdtm.&domain;
            tables usubjid / noprint out=usubjid_freq;
        run;
        
        data usubjid_check;
            set usubjid_freq;
            if count > 1;
        run;
    %end;
    
    /* Check 3: Date format validation */
    data date_check;
        set sdtm.&domain;
        array dates _character_;
        do over dates;
            if index(vname(dates), 'DTC') and not missing(dates) then do;
                if not prxmatch('/^\d{4}(-\d{2}(-\d{2}(T\d{2}:\d{2}(:\d{2})?)?)?)?$/', dates) then
                    put "WARNING: Invalid date format in " vname(dates) "=" dates;
            end;
        end;
    run;
    
%mend validate_sdtm_domain;

/* Execute validation */
%validate_sdtm_domain(domain=dm);
%validate_sdtm_domain(domain=ae);
%validate_sdtm_domain(domain=lb);
```

#### ADaM Validation Checks
```sas
/* ADaM Dataset Validation Template */

%macro validate_adam_bds(dataset=);
    
    /* Check 1: Required BDS variables */
    %let req_vars = STUDYID USUBJID PARAM PARAMCD AVAL ADT ADY VISIT VISITNUM;
    
    proc contents data=adam.&dataset out=contents noprint;
    run;
    
    /* Check 2: One record per subject per parameter per timepoint */
    proc freq data=adam.&dataset;
        tables usubjid*paramcd*adt / noprint out=dup_check;
    run;
    
    data duplicates;
        set dup_check;
        if count > 1;
        if _n_ = 1 then put "WARNING: Duplicate records found:";
        put usubjid= paramcd= adt= count=;
    run;
    
    /* Check 3: Baseline flag validation */
    proc freq data=adam.&dataset;
        tables paramcd*ablfl / missing;
        where not missing(ablfl);
    run;
    
    /* Check 4: Change from baseline calculations */
    data chg_check;
        set adam.&dataset;
        if not missing(base) and not missing(aval) then do;
            calc_chg = aval - base;
            if abs(chg - calc_chg) > 1e-10 then do;
                put "WARNING: CHG calculation error for " usubjid= paramcd= adt=;
                put "  Calculated: " calc_chg " Stored: " chg;
            end;
        end;
    run;
    
%mend validate_adam_bds;

/* Execute validation */
%validate_adam_bds(dataset=adlb);
%validate_adam_bds(dataset=advs);
```

---

## 7. Regulatory Submission Requirements

### 7.1 eCTD Module 5 Dataset Requirements

#### Dataset Submission Structure
```
Module 5.3.5.1: Tabulation Datasets
├── SDTM Datasets
│   ├── Domain datasets (DM, AE, CM, EX, LB, VS, etc.)
│   ├── Special Purpose datasets (CO, SE, etc.)
│   └── Trial Design datasets (TE, TA, TV, TI)
├── Define-XML v2.1
│   ├── define.xml (metadata)
│   ├── define.pdf (stylesheet output)
│   └── External dictionaries (if applicable)
└── Reviewer Guides
    ├── Study Data Reviewer Guide (sdrg.pdf)
    └── Data Definition Tables (if applicable)

Module 5.3.5.3: Analysis Datasets  
├── ADaM Datasets
│   ├── ADSL (Subject-Level Analysis Dataset)
│   ├── BDS datasets (ADAE, ADLB, ADVS, ADTTE, etc.)
│   └── Custom analysis datasets
├── Define-XML v2.1
│   ├── define.xml (analysis metadata)
│   ├── define.pdf (stylesheet output)  
│   └── Analysis derivations documentation
└── Reviewer Guides
    ├── Analysis Data Reviewer Guide (adrg.pdf)
    └── Analysis Results Metadata (arm.pdf)
```

### 7.2 Study Data Reviewer Guide (SDRG) Template

#### SDRG Content Requirements
```
Study Data Reviewer Guide Template:

1. INTRODUCTION
   - Study overview and objectives  
   - Study design summary
   - Data collection overview
   - CDISC standards implementation

2. STUDY DESIGN AND CONDUCT
   - Protocol deviations and amendments
   - Data management procedures
   - Database locks and clean file dates
   - Quality control procedures

3. STUDY DATA STRUCTURE
   - SDTM domain descriptions
   - Naming conventions used
   - Special considerations or customizations
   - Controlled terminology exceptions

4. DATA QUALITY AND INTEGRITY
   - Data cleaning procedures
   - Query management process
   - Missing data handling
   - Protocol deviation impact

5. KNOWN DATA ISSUES
   - Identified data quality issues
   - Impact on analysis interpretation
   - Mitigation strategies implemented
   - Reviewer notification items

6. CONCLUSION
   - Data quality assessment summary
   - Fitness for regulatory review
   - Contact information for queries
```

### 7.3 Analysis Data Reviewer Guide (ADRG) Template

#### ADRG Content Structure
```
Analysis Data Reviewer Guide Template:

1. INTRODUCTION
   - Study background and rationale
   - Analysis objectives overview
   - ADaM implementation approach
   - Regulatory guidance alignment

2. STUDY DESIGN AND ANALYSIS DATASETS
   - Protocol design elements
   - Subject disposition and populations
   - Analysis datasets overview
   - Primary and secondary endpoints

3. ANALYSIS DATASET DESCRIPTIONS
   3.1 Subject-Level Analysis Dataset (ADSL)
       - Population definitions and flags
       - Treatment variables and coding
       - Important dates and derived variables
       - Subgroup classification variables
   
   3.2 Basic Data Structure (BDS) Datasets
       - Parameter definitions and coding
       - Visit structure and windowing
       - Baseline methodology
       - Derived endpoints and flags
   
   3.3 Time-to-Event Analysis Datasets  
       - Event definitions and censoring rules
       - Analysis start time definitions
       - Competing risk considerations
       - Multiple event handling

4. ANALYSIS CONSIDERATIONS
   - Missing data handling approach
   - Protocol deviation impact on analysis
   - Multiplicity adjustment strategies
   - Interim analysis considerations

5. CONCLUSION
   - Analysis dataset fitness summary
   - Key reviewer considerations
   - Contact information for questions
```

---

## Resources and Next Steps

### Implementation Checklist
- [ ] [CDISC Implementation Checklist](./cdisc-implementation-checklist.md)
- [ ] [ADaM Dataset Specification Templates](./adam-specification-templates.md) 
- [ ] [Quality Control Programs](./qc-programs.md)
- [ ] [Define-XML Generation Tools](./define-xml-tools.md)

### External Resources
- **CDISC Website**: [www.cdisc.org](https://www.cdisc.org)
- **CDISC Implementation Guides**: Therapeutic area user guides
- **FDA Study Data Standards**: Current guidance documents
- **PhUSE Working Groups**: Implementation best practices

### Next Section
Proceed to [Part 4: Advanced Statistical Methods](../part-4-advanced-methods/) for complex analysis approaches in clinical trials.

---

*This content provides comprehensive CDISC implementation guidance and should be supplemented with current regulatory requirements and organizational standards.*