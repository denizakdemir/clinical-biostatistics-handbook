/******************************************************************************
PROGRAM: format-library.sas
PURPOSE: Comprehensive format library for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program creates a comprehensive library of SAS formats commonly used
in clinical biostatistics, following CDISC standards and industry best practices.

SECTIONS INCLUDED:
1. Treatment and Study Design Formats
2. Demographics and Baseline Formats
3. Visit and Timepoint Formats
4. Clinical Assessment Formats
5. Laboratory and Vital Signs Formats
6. Adverse Event Formats
7. Statistical and Reporting Formats
******************************************************************************/

/* Create format library location */
libname fmtlib './formats';

/******************************************************************************
SECTION 1: TREATMENT AND STUDY DESIGN FORMATS
******************************************************************************/

proc format library=fmtlib;
    
    /* Treatment formats - customize for your study */
    value $trt01p
        'PLACEBO' = 'Placebo'
        'ACTIVE_LOW' = 'Active Low Dose'
        'ACTIVE_HIGH' = 'Active High Dose'
        'ACTIVE' = 'Active Treatment'
        'CONTROL' = 'Control';
    
    value trt01pn
        0 = 'Placebo'
        1 = 'Active Low Dose'
        2 = 'Active High Dose'
        3 = 'Active Treatment'
        99 = 'Control';
    
    value $trt01a
        'PLACEBO' = 'Placebo'
        'ACTIVE_LOW' = 'Active Low Dose'  
        'ACTIVE_HIGH' = 'Active High Dose'
        'ACTIVE' = 'Active Treatment'
        'NOT_TREATED' = 'Not Treated';
    
    value trt01an
        0 = 'Placebo'
        1 = 'Active Low Dose'
        2 = 'Active High Dose' 
        3 = 'Active Treatment'
        -1 = 'Not Treated';
    
    /* Study phases */
    value $phase
        'I' = 'Phase I'
        'II' = 'Phase II'
        'III' = 'Phase III'
        'IV' = 'Phase IV'
        'I/II' = 'Phase I/II'
        'II/III' = 'Phase II/III';
    
    /* Randomization strata */
    value $strat1
        'MALE' = 'Male'
        'FEMALE' = 'Female';
    
    value $strat2
        'AGE_LT_65' = 'Age <65'
        'AGE_GE_65' = 'Age ≥65';

/******************************************************************************
SECTION 2: DEMOGRAPHICS AND BASELINE FORMATS
******************************************************************************/
    
    /* Sex */
    value $sex
        'M' = 'Male'
        'F' = 'Female'
        'U' = 'Unknown'
        'UNDIFFERENTIATED' = 'Undifferentiated';
    
    /* Race - CDISC controlled terminology */
    value $race
        'WHITE' = 'White'
        'BLACK OR AFRICAN AMERICAN' = 'Black or African American'
        'ASIAN' = 'Asian'
        'AMERICAN INDIAN OR ALASKA NATIVE' = 'American Indian or Alaska Native'
        'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER' = 'Native Hawaiian or Other Pacific Islander'
        'OTHER' = 'Other'
        'MULTIPLE' = 'Multiple'
        'UNKNOWN' = 'Unknown'
        'NOT REPORTED' = 'Not Reported';
    
    /* Ethnicity - CDISC controlled terminology */
    value $ethnic
        'HISPANIC OR LATINO' = 'Hispanic or Latino'
        'NOT HISPANIC OR LATINO' = 'Not Hispanic or Latino'
        'NOT REPORTED' = 'Not Reported'
        'UNKNOWN' = 'Unknown';
    
    /* Age groups */
    value $agegr1
        '<18' = '<18 years'
        '18-64' = '18-64 years'
        '>=65' = '≥65 years'
        '<65' = '<65 years';
    
    value agegr1n
        1 = '<18 years'
        2 = '18-64 years'
        3 = '≥65 years';
    
    /* BMI categories */
    value $bmigr1
        'UNDERWEIGHT' = 'Underweight (<18.5)'
        'NORMAL' = 'Normal (18.5-24.9)'
        'OVERWEIGHT' = 'Overweight (25.0-29.9)'  
        'OBESE' = 'Obese (≥30.0)';
    
    value bmigr1n
        1 = 'Underweight (<18.5)'
        2 = 'Normal (18.5-24.9)'
        3 = 'Overweight (25.0-29.9)'
        4 = 'Obese (≥30.0)';

/******************************************************************************
SECTION 3: VISIT AND TIMEPOINT FORMATS
******************************************************************************/
    
    /* Analysis visits */
    value $avisit
        'SCREENING' = 'Screening'
        'BASELINE' = 'Baseline'
        'WEEK 2' = 'Week 2'
        'WEEK 4' = 'Week 4'
        'WEEK 8' = 'Week 8'
        'WEEK 12' = 'Week 12'
        'WEEK 24' = 'Week 24'
        'WEEK 48' = 'Week 48'
        'END OF TREATMENT' = 'End of Treatment'
        'FOLLOW-UP' = 'Follow-up'
        'EARLY TERMINATION' = 'Early Termination'
        'UNSCHEDULED' = 'Unscheduled';
    
    value avisitn
        -2 = 'Pre-screening'
        -1 = 'Screening'
        0 = 'Baseline'
        2 = 'Week 2'
        4 = 'Week 4'
        8 = 'Week 8'
        12 = 'Week 12'
        24 = 'Week 24'
        48 = 'Week 48'
        99 = 'End of Treatment'
        999 = 'Follow-up'
        9999 = 'Unscheduled';
    
    /* Visit windows */
    value $visitwin
        'SCREENING' = 'Day -28 to -1'
        'BASELINE' = 'Day 1'
        'WEEK2' = 'Day 11 to 17'
        'WEEK4' = 'Day 25 to 31'
        'WEEK8' = 'Day 53 to 59'
        'WEEK12' = 'Day 81 to 87'
        'WEEK24' = 'Day 165 to 171';

/******************************************************************************
SECTION 4: CLINICAL ASSESSMENT FORMATS
******************************************************************************/
    
    /* ECOG Performance Status */
    value $ecog
        '0' = '0 - Fully active'
        '1' = '1 - Restricted in strenuous activity'
        '2' = '2 - Ambulatory, up >50% of waking hours'
        '3' = '3 - Capable of limited self-care'
        '4' = '4 - Completely disabled'
        '5' = '5 - Dead';
    
    value ecogn
        0 = '0 - Fully active'
        1 = '1 - Restricted in strenuous activity'
        2 = '2 - Ambulatory, up >50% of waking hours'
        3 = '3 - Capable of limited self-care'
        4 = '4 - Completely disabled'
        5 = '5 - Dead';
    
    /* Karnofsky Performance Scale */
    value karnof
        100 = '100 - Normal, no complaints'
        90 = '90 - Normal activity, minor symptoms'
        80 = '80 - Normal activity with effort'
        70 = '70 - Cares for self, unable to work'
        60 = '60 - Requires occasional assistance'
        50 = '50 - Requires considerable assistance'
        40 = '40 - Disabled, requires special care'
        30 = '30 - Severely disabled'
        20 = '20 - Very sick, active support required'
        10 = '10 - Moribund';
    
    /* Response evaluation (RECIST) */
    value $response
        'CR' = 'Complete Response'
        'PR' = 'Partial Response'
        'SD' = 'Stable Disease'
        'PD' = 'Progressive Disease'
        'NE' = 'Not Evaluable'
        'ND' = 'Not Done';

/******************************************************************************
SECTION 5: LABORATORY AND VITAL SIGNS FORMATS
******************************************************************************/
    
    /* Reference range indicators */
    value $nrind
        'NORMAL' = 'Normal'
        'ABNORMAL' = 'Abnormal'
        'HIGH' = 'High'
        'LOW' = 'Low'
        'UNKNOWN' = 'Unknown'
        '' = 'Missing';
    
    /* Toxicity grades (CTCAE) */
    value $toxgr
        'GRADE 1' = 'Grade 1 - Mild'
        'GRADE 2' = 'Grade 2 - Moderate'
        'GRADE 3' = 'Grade 3 - Severe'
        'GRADE 4' = 'Grade 4 - Life-threatening'
        'GRADE 5' = 'Grade 5 - Death';
    
    value toxgrn
        1 = 'Grade 1 - Mild'
        2 = 'Grade 2 - Moderate'
        3 = 'Grade 3 - Severe'
        4 = 'Grade 4 - Life-threatening'
        5 = 'Grade 5 - Death';
    
    /* Laboratory test categories */
    value $lbcat
        'HEMATOLOGY' = 'Hematology'
        'CHEMISTRY' = 'Chemistry'
        'URINALYSIS' = 'Urinalysis'
        'IMMUNOLOGY' = 'Immunology'
        'MICROBIOLOGY' = 'Microbiology'
        'PHARMACOKINETICS' = 'Pharmacokinetics';
    
    /* Vital signs position */
    value $vspos
        'SITTING' = 'Sitting'
        'STANDING' = 'Standing'
        'SUPINE' = 'Supine'
        'SEMI-RECUMBENT' = 'Semi-recumbent';

/******************************************************************************
SECTION 6: ADVERSE EVENT FORMATS
******************************************************************************/
    
    /* AE Severity/Intensity */
    value $aesev
        'MILD' = 'Mild'
        'MODERATE' = 'Moderate'
        'SEVERE' = 'Severe';
    
    value aesevn
        1 = 'Mild'
        2 = 'Moderate'
        3 = 'Severe';
    
    /* AE Relationship to study drug */
    value $aerel
        'NOT RELATED' = 'Not Related'
        'UNLIKELY RELATED' = 'Unlikely Related'
        'POSSIBLY RELATED' = 'Possibly Related'
        'PROBABLY RELATED' = 'Probably Related'
        'RELATED' = 'Related';
    
    value aereln
        1 = 'Not Related'
        2 = 'Unlikely Related'
        3 = 'Possibly Related'
        4 = 'Probably Related'
        5 = 'Related';
    
    /* AE Action taken */
    value $aeacn
        'NONE' = 'None'
        'DRUG WITHDRAWN' = 'Drug Withdrawn'
        'DOSE REDUCED' = 'Dose Reduced'
        'DOSE INCREASED' = 'Dose Increased'
        'DRUG INTERRUPTED' = 'Drug Interrupted'
        'UNKNOWN' = 'Unknown';
    
    /* AE Outcome */
    value $aeout
        'RECOVERED/RESOLVED' = 'Recovered/Resolved'
        'RECOVERING/RESOLVING' = 'Recovering/Resolving'
        'NOT RECOVERED/NOT RESOLVED' = 'Not Recovered/Not Resolved'
        'RECOVERED/RESOLVED WITH SEQUELAE' = 'Recovered/Resolved with Sequelae'
        'FATAL' = 'Fatal'
        'UNKNOWN' = 'Unknown';
    
    /* Serious AE criteria */
    value $aeser
        'Y' = 'Yes'
        'N' = 'No';

/******************************************************************************
SECTION 7: STATISTICAL AND REPORTING FORMATS
******************************************************************************/
    
    /* Population flags */
    value $popfl
        'Y' = 'Yes'
        'N' = 'No'
        '' = 'Missing';
    
    /* Analysis flags */
    value $anlfl
        'Y' = 'Yes'
        'N' = 'No'
        '' = 'Not Applicable';
    
    /* P-value formats */
    value pvalue
        . = ' '
        0-<0.001 = '<0.001'
        0.001-<0.01 = '0.001 to <0.01'
        0.01-<0.05 = '0.01 to <0.05'
        0.05-<0.1 = '0.05 to <0.1'
        0.1-high = '≥0.1';
    
    value pvalue6.4
        . = ' '
        0-<0.0001 = '<0.0001'
        other = [6.4];
    
    value pvalue_sig
        . = ' '
        0-<0.05 = '*'
        0.05-<0.1 = '.'
        0.1-high = ' ';
    
    /* Statistical significance levels */
    value $siglevel
        '0.05' = '5%'
        '0.01' = '1%'
        '0.001' = '0.1%';
    
    /* Confidence interval levels */
    value $cilevel
        '0.90' = '90%'
        '0.95' = '95%'
        '0.99' = '99%';
    
    /* Missing data indicators */
    value $missing
        '' = 'Missing'
        'NE' = 'Not Evaluable'
        'ND' = 'Not Done'
        'NA' = 'Not Applicable';

/******************************************************************************
SECTION 8: STUDY-SPECIFIC FORMATS
******************************************************************************/
    
    /* Disposition reasons */
    value $dcsreas
        'ADVERSE EVENT' = 'Adverse Event'
        'LACK OF EFFICACY' = 'Lack of Efficacy'
        'WITHDRAWAL BY SUBJECT' = 'Subject Withdrawal'
        'LOST TO FOLLOW-UP' = 'Lost to Follow-up'
        'PROTOCOL VIOLATION' = 'Protocol Violation'
        'PHYSICIAN DECISION' = 'Physician Decision'
        'DEATH' = 'Death'
        'OTHER' = 'Other';
    
    /* Study completion status */
    value $compfl
        'Y' = 'Completed'
        'N' = 'Did Not Complete';
    
    /* Country groupings */
    value $country
        'USA' = 'United States'
        'CAN' = 'Canada'
        'GBR' = 'United Kingdom'
        'DEU' = 'Germany'
        'FRA' = 'France'
        'JPN' = 'Japan'
        'AUS' = 'Australia'
        other = 'Other';
    
    /* Region groupings */
    value $region
        'NORTH_AMERICA' = 'North America'
        'EUROPE' = 'Europe'
        'ASIA_PACIFIC' = 'Asia Pacific'
        'LATIN_AMERICA' = 'Latin America'
        'OTHER' = 'Other';

/******************************************************************************
SECTION 9: CUSTOM ANALYSIS FORMATS
******************************************************************************/
    
    /* Baseline categories */
    value $basecat
        'LOW' = 'Low'
        'NORMAL' = 'Normal'
        'HIGH' = 'High';
    
    /* Change categories */
    value $chgcat
        'DECREASE' = 'Decrease'
        'NO_CHANGE' = 'No Change'
        'INCREASE' = 'Increase';
    
    /* Shift categories */
    value $shift
        'NORMAL_TO_NORMAL' = 'Normal to Normal'
        'NORMAL_TO_LOW' = 'Normal to Low'
        'NORMAL_TO_HIGH' = 'Normal to High'
        'LOW_TO_NORMAL' = 'Low to Normal'
        'LOW_TO_LOW' = 'Low to Low'
        'LOW_TO_HIGH' = 'Low to High'
        'HIGH_TO_NORMAL' = 'High to Normal'
        'HIGH_TO_LOW' = 'High to Low'
        'HIGH_TO_HIGH' = 'High to High';
    
    /* Time-to-event censoring */
    value cnsr
        0 = 'Event'
        1 = 'Censored';
    
    /* Duration categories */
    value $durncat
        'SHORT' = 'Short (≤30 days)'
        'MEDIUM' = 'Medium (31-90 days)'
        'LONG' = 'Long (>90 days)';

/******************************************************************************
SECTION 10: QUALITY CONTROL AND VALIDATION FORMATS
******************************************************************************/
    
    /* QC status */
    value $qcstat
        'PASS' = 'Pass'
        'FAIL' = 'Fail'
        'WARNING' = 'Warning'
        'REVIEW' = 'Needs Review';
    
    /* Data source */
    value $datasrc
        'CRF' = 'Case Report Form'
        'LAB' = 'Central Laboratory'
        'ECG' = 'Central ECG'
        'IMAGING' = 'Central Imaging'
        'IVRS' = 'Interactive Response System';
    
    /* Record status */
    value $recstat
        'ACTIVE' = 'Active'
        'DELETED' = 'Deleted'
        'MODIFIED' = 'Modified'
        'NEW' = 'New';
    
run;

/* Set format search order */
options fmtsearch=(fmtlib.formats work library);

%put NOTE: Clinical trial format library created successfully;
%put NOTE: Format library location: fmtlib.formats;
%put NOTE: Format search order set to: fmtlib.formats work library;