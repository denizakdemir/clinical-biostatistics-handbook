# CDISC Standards Quick Reference Guide

## SDTM (Study Data Tabulation Model)

### Core Domains

#### Special Purpose Domains
| Domain | Description | Key Variables |
|--------|-------------|---------------|
| **DM** | Demographics | STUDYID, USUBJID, AGE, SEX, RACE |
| **CO** | Comments | STUDYID, DOMAIN, USUBJID, COVAL |
| **SV** | Subject Visits | STUDYID, USUBJID, VISITNUM, VISIT |
| **SE** | Subject Elements | STUDYID, USUBJID, ETCD, SESTDTC |

#### Interventions Domains
| Domain | Description | Key Variables |
|--------|-------------|---------------|
| **EX** | Exposure | STUDYID, USUBJID, EXTRT, EXDOSE, EXDOSU |
| **CM** | Concomitant Medications | STUDYID, USUBJID, CMTRT, CMDOSE |
| **SU** | Substance Use | STUDYID, USUBJID, SUTRT, SUSTDTC |

#### Events Domains
| Domain | Description | Key Variables |
|--------|-------------|---------------|
| **AE** | Adverse Events | STUDYID, USUBJID, AETERM, AEDECOD, AESEV |
| **DS** | Disposition | STUDYID, USUBJID, DSCAT, DSDECOD |
| **MH** | Medical History | STUDYID, USUBJID, MHTERM, MHDECOD |

#### Findings Domains
| Domain | Description | Key Variables |
|--------|-------------|---------------|
| **LB** | Laboratory | STUDYID, USUBJID, LBTESTCD, LBORRES, LBORNRLO, LBORNRHI |
| **VS** | Vital Signs | STUDYID, USUBJID, VSTESTCD, VSORRES, VSPOS |
| **EG** | ECG | STUDYID, USUBJID, EGTESTCD, EGORRES |
| **PE** | Physical Exam | STUDYID, USUBJID, PETESTCD, PEORRES |
| **QS** | Questionnaires | STUDYID, USUBJID, QSCAT, QSTESTCD, QSORRES |

### Variable Naming Conventions

#### Standard Suffixes
- **--TESTCD**: Short name of measurement/finding
- **--TEST**: Long name of measurement/finding  
- **--ORRES**: Result as originally received
- **--ORRESU**: Original units
- **--STRESC**: Standardized result in character format
- **--STRESN**: Standardized result in numeric format
- **--STRESU**: Standardized units
- **--STAT**: Completion status
- **--REASND**: Reason not done
- **--DTC**: Date/time of collection (ISO 8601)
- **--DY**: Study day

#### Timing Variables
- **--STDTC**: Start date/time
- **--ENDTC**: End date/time
- **--DUR**: Duration
- **--STDY**: Start study day
- **--ENDY**: End study day

## ADaM (Analysis Data Model)

### Standard Datasets

#### Subject-Level Analysis Dataset (ADSL)
**Required Variables:**
- STUDYID, USUBJID, SUBJID
- TRT01P, TRT01A (Planned/Actual Treatment)
- RANDDT (Randomization Date)
- TRTSDT, TRTEDT (Treatment Start/End Date)
- Safety/Efficacy Analysis Flags

#### Basic Data Structure (BDS)
**Key Variables:**
- PARAMCD, PARAM (Parameter Code/Description)
- AVAL, AVALC (Analysis Value Numeric/Character)
- BASE, BASEC (Baseline Value)
- CHG (Change from Baseline)
- PCHG (Percent Change from Baseline)
- VISIT, VISITNUM
- ADT (Analysis Date)
- ADY (Analysis Day)

#### Analysis Flags
- ANLzzFL (Analysis Flag)
- SAFFL (Safety Population Flag)
- ITTFL (Intent-to-Treat Population Flag)
- PPROTFL (Per-Protocol Population Flag)
- CRITyFL (Criteria Flags)

### Common ADaM Datasets

| Dataset | Purpose | Key Features |
|---------|---------|--------------|
| **ADSL** | Subject-Level | Demographics, treatment, disposition |
| **ADAE** | Adverse Events | Safety analysis, preferred terms |
| **ADLB** | Laboratory | Lab parameters, reference ranges |
| **ADVS** | Vital Signs | Vital signs parameters |
| **ADTTE** | Time-to-Event | Survival analysis variables |
| **ADEG** | ECG | ECG parameters and interpretations |

## Define-XML

### Study Metadata
```xml
<Study OID="CDISC01">
  <GlobalVariables>
    <StudyName>Protocol CDISC01</StudyName>
    <StudyDescription>Example Clinical Trial</StudyDescription>
    <ProtocolName>CDISC01</ProtocolName>
  </GlobalVariables>
</Study>
```

### Dataset Definition
```xml
<ItemGroupDef OID="DM" Name="Demographics" Repeating="No" 
             Purpose="Tabulation" Class="SPECIAL PURPOSE">
  <Description>
    <TranslatedText>Demographics</TranslatedText>
  </Description>
</ItemGroupDef>
```

### Variable Definition
```xml
<ItemDef OID="DM.USUBJID" Name="USUBJID" DataType="text" Length="20">
  <Description>
    <TranslatedText>Unique Subject Identifier</TranslatedText>
  </Description>
</ItemDef>
```

## Controlled Terminology

### Common Code Lists

#### Sex (C66731)
- M: Male
- F: Female  
- U: Unknown
- UNDIFFERENTIATED: Undifferentiated

#### Race (C74457)
- WHITE: White
- BLACK OR AFRICAN AMERICAN: Black or African American
- ASIAN: Asian
- AMERICAN INDIAN OR ALASKA NATIVE: American Indian or Alaska Native
- NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER: Native Hawaiian or Other Pacific Islander
- OTHER: Other
- MULTIPLE: Multiple
- UNKNOWN: Unknown
- NOT REPORTED: Not Reported

#### Adverse Event Severity (C78605)
- MILD: Mild
- MODERATE: Moderate  
- SEVERE: Severe

#### Causality (C78604)
- NOT RELATED: Not Related
- UNLIKELY RELATED: Unlikely Related
- POSSIBLY RELATED: Possibly Related
- PROBABLY RELATED: Probably Related
- RELATED: Related

## Implementation Checklist

### SDTM Implementation
- [ ] Domain selection and justification
- [ ] Variable implementation according to IG
- [ ] Controlled terminology application
- [ ] Cross-domain consistency checks
- [ ] Define-XML generation and validation

### ADaM Implementation
- [ ] Analysis dataset specifications
- [ ] Derivation documentation
- [ ] Traceability to SDTM
- [ ] Analysis-ready variables
- [ ] Metadata documentation

### Quality Control
- [ ] Data lineage verification
- [ ] Cross-domain relationship validation
- [ ] Controlled terminology compliance
- [ ] Define-XML validation against XSD
- [ ] Regulatory submission readiness

## Common Validation Rules

### SDTM Rules
1. All required variables present
2. Controlled terminology compliance
3. ISO 8601 date/time formats
4. Cross-domain key relationships maintained
5. Domain-specific business rules applied

### ADaM Rules
1. Traceability to SDTM maintained
2. Analysis variables properly derived
3. Population flags consistent
4. Missing data handling documented
5. Analysis-ready format confirmed

## Resources and References

- **CDISC Website**: https://www.cdisc.org/
- **SDTM Implementation Guide**: Latest version from CDISC
- **ADaM Implementation Guide**: Latest version from CDISC  
- **Define-XML Specification**: Latest version from CDISC
- **Controlled Terminology**: NCI EVS CDISC Terminology