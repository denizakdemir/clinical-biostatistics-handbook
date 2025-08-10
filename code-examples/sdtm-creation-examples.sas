/******************************************************************************
PROGRAM: sdtm-creation-examples.sas
PURPOSE: SDTM domain creation examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides practical examples for creating CDISC SDTM domains
from raw clinical data, including proper variable derivations, formats,
and compliance with SDTM Implementation Guide standards.

SECTIONS INCLUDED:
1. Demographics (DM) Domain Creation
2. Adverse Events (AE) Domain Creation
3. Laboratory (LB) Domain Creation
4. Vital Signs (VS) Domain Creation
5. Exposure (EX) Domain Creation
6. Disposition (DS) Domain Creation
******************************************************************************/

/******************************************************************************
SECTION 1: DEMOGRAPHICS (DM) DOMAIN CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_dm_domain
PURPOSE: Create Demographics (DM) SDTM domain from raw data
PARAMETERS:
  raw_data= : Raw demographics dataset
  study_id= : Study identifier
  domain= : Domain code (DM)
  output= : Output SDTM dataset
******************************************************************************/
%macro create_dm_domain(
    raw_data=,
    study_id=,
    domain=DM,
    output=
);
    
    %put NOTE: Creating DM domain from raw data;
    
    data &output;
        set &raw_data;
        
        /* Standard SDTM variables */
        length studyid domain usubjid subjid $20;
        studyid = "&study_id";
        domain = "&domain";
        usubjid = cats(studyid, '-', subject);
        subjid = subject;
        
        /* Demographics variables with proper lengths and formats */
        length siteid $10 invid $20 invnam $200;
        siteid = site_id;
        invid = investigator_id;
        invnam = investigator_name;
        
        /* Reference dates */
        length rfstdtc rfendtc $19;
        if not missing(consent_date) then 
            rfstdtc = put(consent_date, yymmdd10.) || 'T' || put(consent_time, time8.);
        if not missing(last_contact_date) then
            rfendtc = put(last_contact_date, yymmdd10.);
        
        /* Informed consent */
        length rficdtc $19;
        if not missing(consent_date) then
            rficdtc = put(consent_date, yymmdd10.);
        
        /* Date of birth handling */
        length brthdtc $10;
        if not missing(birth_date) then
            brthdtc = put(birth_date, yymmdd10.);
        
        /* Age */
        if not missing(birth_date) and not missing(consent_date) then do;
            age = int((consent_date - birth_date) / 365.25);
        end;
        
        /* Age units */
        length ageu $8;
        if not missing(age) then ageu = 'YEARS';
        
        /* Sex */
        length sex $1;
        sex = upcase(substr(gender, 1, 1));
        if sex not in ('M', 'F') then sex = '';
        
        /* Race */
        length race $100;
        select (upcase(race_raw));
            when ('WHITE', 'CAUCASIAN') race = 'WHITE';
            when ('BLACK', 'AFRICAN AMERICAN') race = 'BLACK OR AFRICAN AMERICAN';
            when ('ASIAN') race = 'ASIAN';
            when ('HISPANIC', 'LATINO') race = 'HISPANIC OR LATINO';
            when ('AMERICAN INDIAN', 'NATIVE AMERICAN') race = 'AMERICAN INDIAN OR ALASKA NATIVE';
            when ('PACIFIC ISLANDER') race = 'NATIVE HAWAIIAN OR OTHER PACIFIC ISLANDER';
            when ('OTHER') race = 'OTHER';
            when ('MULTIPLE') race = 'MULTIPLE';
            when ('NOT REPORTED') race = 'NOT REPORTED';
            otherwise race = 'UNKNOWN';
        end;
        
        /* Ethnicity */
        length ethnic $100;
        select (upcase(ethnicity_raw));
            when ('HISPANIC OR LATINO') ethnic = 'HISPANIC OR LATINO';
            when ('NOT HISPANIC OR LATINO') ethnic = 'NOT HISPANIC OR LATINO';
            when ('NOT REPORTED') ethnic = 'NOT REPORTED';
            otherwise ethnic = 'UNKNOWN';
        end;
        
        /* Randomization information */
        length armcd arm actarmcd actarm $40;
        armcd = planned_treatment_code;
        arm = planned_treatment;
        actarmcd = actual_treatment_code;
        actarm = actual_treatment;
        
        /* Country and demographic information */
        length country $3;
        country = upcase(country_code);
        
        /* Disposition */
        length dmdtc $19 dmdy 8;
        if not missing(disposition_date) then do;
            dmdtc = put(disposition_date, yymmdd10.);
            if not missing(consent_date) then
                dmdy = disposition_date - consent_date + 1;
        end;
        
        /* Labels for variables */
        label studyid = "Study Identifier"
              domain = "Domain Abbreviation"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              siteid = "Study Site Identifier"
              invid = "Investigator Identifier"
              invnam = "Investigator Name"
              brthdtc = "Date/Time of Birth"
              age = "Age"
              ageu = "Age Units"
              sex = "Sex"
              race = "Race"
              ethnic = "Ethnicity"
              armcd = "Planned Arm Code"
              arm = "Description of Planned Arm"
              actarmcd = "Actual Arm Code"
              actarm = "Description of Actual Arm"
              country = "Country"
              dmdtc = "Date/Time of Collection"
              dmdy = "Study Day of Collection"
              rfstdtc = "Subject Reference Start Date/Time"
              rfendtc = "Subject Reference End Date/Time"
              rficdtc = "Date/Time of Informed Consent";
        
        /* Keep only SDTM variables */
        keep studyid domain usubjid subjid siteid invid invnam
             brthdtc age ageu sex race ethnic armcd arm actarmcd actarm
             country dmdtc dmdy rfstdtc rfendtc rficdtc;
    run;
    
    /* Sort by required keys */
    proc sort data=&output;
        by studyid usubjid;
    run;
    
    %put NOTE: DM domain created with %sysfunc(nobs(&output)) observations;
    
%mend create_dm_domain;

/******************************************************************************
SECTION 2: ADVERSE EVENTS (AE) DOMAIN CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_ae_domain
PURPOSE: Create Adverse Events (AE) SDTM domain from raw data
PARAMETERS:
  raw_data= : Raw AE dataset
  study_id= : Study identifier
  dm_data= : DM domain for reference dates
  output= : Output SDTM dataset
******************************************************************************/
%macro create_ae_domain(
    raw_data=,
    study_id=,
    dm_data=,
    output=
);
    
    %put NOTE: Creating AE domain from raw data;
    
    /* Get reference dates from DM */
    data work.dm_ref;
        set &dm_data;
        keep usubjid rfstdtc;
    run;
    
    data &output;
        merge &raw_data work.dm_ref;
        by usubjid;
        
        /* Standard SDTM variables */
        length studyid domain usubjid subjid $20;
        studyid = "&study_id";
        domain = "AE";
        /* usubjid already from merge */
        subjid = scan(usubjid, -1, '-');
        
        /* Sequence number */
        length aeseq 8;
        aeseq = ae_sequence;
        
        /* Adverse event term */
        length aeterm $200;
        aeterm = propcase(strip(adverse_event_term));
        
        /* Modified term */
        length aemodify $200;
        if not missing(modified_term) then
            aemodify = propcase(strip(modified_term));
        
        /* Decode (Preferred Term) */
        length aedecod $100;
        if not missing(preferred_term) then
            aedecod = upcase(strip(preferred_term));
        else
            aedecod = upcase(strip(aeterm));
        
        /* System Organ Class */
        length aesoc $100;
        aesoc = upcase(strip(system_organ_class));
        
        /* High Level Term */
        length aehlt $100;
        if not missing(high_level_term) then
            aehlt = upcase(strip(high_level_term));
        
        /* High Level Group Term */
        length aehlgt $100;
        if not missing(high_level_group_term) then
            aehlgt = upcase(strip(high_level_group_term));
        
        /* Category and subcategory */
        length aecat $100 aescat $100;
        aecat = "PRIMARY SYSTEM ORGAN CLASS";
        if not missing(ae_category) then
            aescat = upcase(strip(ae_category));
        
        /* Severity/Intensity */
        length aesev $100;
        select (upcase(strip(severity)));
            when ('1', 'MILD') aesev = 'MILD';
            when ('2', 'MODERATE') aesev = 'MODERATE';
            when ('3', 'SEVERE') aesev = 'SEVERE';
            otherwise aesev = strip(severity);
        end;
        
        /* Relationship to study medication */
        length aerel $100;
        select (upcase(strip(relationship)));
            when ('NOT RELATED', 'UNRELATED') aerel = 'NOT RELATED';
            when ('UNLIKELY') aerel = 'UNLIKELY RELATED';
            when ('POSSIBLY') aerel = 'POSSIBLY RELATED';
            when ('PROBABLY') aerel = 'PROBABLY RELATED';
            when ('DEFINITELY', 'RELATED') aerel = 'RELATED';
            otherwise aerel = strip(relationship);
        end;
        
        /* Action taken */
        length aeacn $100;
        select (upcase(strip(action_taken)));
            when ('NONE', 'NO ACTION TAKEN') aeacn = 'NONE';
            when ('DRUG WITHDRAWN') aeacn = 'DRUG WITHDRAWN';
            when ('DOSE REDUCED') aeacn = 'DOSE REDUCED';
            when ('DOSE INCREASED') aeacn = 'DOSE INCREASED';
            when ('INTERRUPTED') aeacn = 'DRUG INTERRUPTED';
            when ('UNKNOWN') aeacn = 'UNKNOWN';
            otherwise aeacn = strip(action_taken);
        end;
        
        /* Outcome */
        length aeout $100;
        select (upcase(strip(outcome)));
            when ('RECOVERED', 'RESOLVED') aeout = 'RECOVERED/RESOLVED';
            when ('RECOVERING', 'RESOLVING') aeout = 'RECOVERING/RESOLVING';
            when ('NOT RECOVERED', 'ONGOING') aeout = 'NOT RECOVERED/NOT RESOLVED';
            when ('SEQUELAE') aeout = 'RECOVERED/RESOLVED WITH SEQUELAE';
            when ('FATAL', 'DEATH') aeout = 'FATAL';
            when ('UNKNOWN') aeout = 'UNKNOWN';
            otherwise aeout = strip(outcome);
        end;
        
        /* Serious event flag */
        length aeser $1;
        if upcase(serious) in ('Y', 'YES', '1') then aeser = 'Y';
        else if upcase(serious) in ('N', 'NO', '0') then aeser = 'N';
        
        /* Life threatening */
        length aeslife $1;
        if upcase(life_threatening) in ('Y', 'YES', '1') then aeslife = 'Y';
        else if upcase(life_threatening) in ('N', 'NO', '0') then aeslife = 'N';
        
        /* Hospitalization */
        length aeshosp $1;
        if upcase(hospitalization) in ('Y', 'YES', '1') then aeshosp = 'Y';
        else if upcase(hospitalization) in ('N', 'NO', '0') then aeshosp = 'N';
        
        /* Disability */
        length aesdisab $1;
        if upcase(disability) in ('Y', 'YES', '1') then aesdisab = 'Y';
        else if upcase(disability) in ('N', 'NO', '0') then aesdisab = 'N';
        
        /* Congenital anomaly */
        length aescong $1;
        if upcase(congenital_anomaly) in ('Y', 'YES', '1') then aescong = 'Y';
        else if upcase(congenital_anomaly) in ('N', 'NO', '0') then aescong = 'N';
        
        /* Death */
        length aesdth $1;
        if upcase(death) in ('Y', 'YES', '1') or aeout = 'FATAL' then aesdth = 'Y';
        else if upcase(death) in ('N', 'NO', '0') then aesdth = 'N';
        
        /* Start date/time */
        length aestdtc $19;
        if not missing(onset_date) then do;
            if not missing(onset_time) then
                aestdtc = put(onset_date, yymmdd10.) || 'T' || put(onset_time, time8.);
            else
                aestdtc = put(onset_date, yymmdd10.);
        end;
        
        /* End date/time */
        length aeendtc $19;
        if not missing(resolution_date) then do;
            if not missing(resolution_time) then
                aeendtc = put(resolution_date, yymmdd10.) || 'T' || put(resolution_time, time8.);
            else
                aeendtc = put(resolution_date, yymmdd10.);
        end;
        
        /* Study day calculations */
        length aestdy aeendy 8;
        if not missing(aestdtc) and not missing(rfstdtc) then do;
            ae_start_date = input(substr(aestdtc, 1, 10), yymmdd10.);
            ref_start_date = input(substr(rfstdtc, 1, 10), yymmdd10.);
            
            if ae_start_date >= ref_start_date then
                aestdy = ae_start_date - ref_start_date + 1;
            else
                aestdy = ae_start_date - ref_start_date;
        end;
        
        if not missing(aeendtc) and not missing(rfstdtc) then do;
            ae_end_date = input(substr(aeendtc, 1, 10), yymmdd10.);
            ref_start_date = input(substr(rfstdtc, 1, 10), yymmdd10.);
            
            if ae_end_date >= ref_start_date then
                aeendy = ae_end_date - ref_start_date + 1;
            else
                aeendy = ae_end_date - ref_start_date;
        end;
        
        /* Duration */
        length aedur 8;
        if not missing(ae_start_date) and not missing(ae_end_date) then
            aedur = ae_end_date - ae_start_date + 1;
        
        /* Labels */
        label studyid = "Study Identifier"
              domain = "Domain Abbreviation"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              aeseq = "Sequence Number"
              aeterm = "Reported Term for the Adverse Event"
              aemodify = "Modified Reported Term"
              aedecod = "Dictionary-Derived Term"
              aesoc = "Primary System Organ Class"
              aehlt = "High Level Term"
              aehlgt = "High Level Group Term"
              aecat = "Category for Adverse Event"
              aescat = "Subcategory for Adverse Event"
              aesev = "Severity/Intensity"
              aerel = "Causality"
              aeacn = "Action Taken with Study Treatment"
              aeout = "Outcome of Adverse Event"
              aeser = "Serious Event"
              aeslife = "Results in Death"
              aeshosp = "Requires or Prolongs Hospitalization"
              aesdisab = "Results in Persistent or Significant Disability/Incapacity"
              aescong = "Congenital Anomaly or Birth Defect"
              aesdth = "Results in Death"
              aestdtc = "Start Date/Time of Adverse Event"
              aeendtc = "End Date/Time of Adverse Event"
              aestdy = "Study Day of Start of Adverse Event"
              aeendy = "Study Day of End of Adverse Event"
              aedur = "Duration of Adverse Event";
        
        /* Keep only SDTM variables */
        keep studyid domain usubjid subjid aeseq aeterm aemodify aedecod
             aesoc aehlt aehlgt aecat aescat aesev aerel aeacn aeout
             aeser aeslife aeshosp aesdisab aescong aesdth
             aestdtc aeendtc aestdy aeendy aedur;
    run;
    
    /* Sort by required keys */
    proc sort data=&output;
        by studyid usubjid aeseq;
    run;
    
    %put NOTE: AE domain created with %sysfunc(nobs(&output)) observations;
    
%mend create_ae_domain;

/******************************************************************************
SECTION 3: LABORATORY (LB) DOMAIN CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_lb_domain
PURPOSE: Create Laboratory (LB) SDTM domain from raw data
PARAMETERS:
  raw_data= : Raw laboratory dataset
  study_id= : Study identifier
  dm_data= : DM domain for reference dates
  output= : Output SDTM dataset
******************************************************************************/
%macro create_lb_domain(
    raw_data=,
    study_id=,
    dm_data=,
    output=
);
    
    %put NOTE: Creating LB domain from raw data;
    
    /* Get reference dates from DM */
    data work.dm_ref;
        set &dm_data;
        keep usubjid rfstdtc;
    run;
    
    data &output;
        merge &raw_data work.dm_ref;
        by usubjid;
        
        /* Standard SDTM variables */
        length studyid domain usubjid subjid $20;
        studyid = "&study_id";
        domain = "LB";
        subjid = scan(usubjid, -1, '-');
        
        /* Sequence number */
        length lbseq 8;
        lbseq = lab_sequence;
        
        /* Test information */
        length lbtestcd $8 lbtest $40;
        lbtestcd = upcase(test_code);
        lbtest = propcase(test_name);
        
        /* Category and subcategory */
        length lbcat $100 lbscat $100;
        select (upcase(lab_category));
            when ('HEMATOLOGY') lbcat = 'HEMATOLOGY';
            when ('CHEMISTRY', 'CLINICAL CHEMISTRY') lbcat = 'CHEMISTRY';
            when ('URINALYSIS') lbcat = 'URINALYSIS';
            when ('IMMUNOLOGY') lbcat = 'IMMUNOLOGY';
            when ('MICROBIOLOGY') lbcat = 'MICROBIOLOGY';
            otherwise lbcat = upcase(lab_category);
        end;
        
        if not missing(lab_subcategory) then
            lbscat = upcase(lab_subcategory);
        
        /* Original results */
        length lborres $200 lborresu $20;
        lborres = strip(original_result);
        lborresu = strip(original_units);
        
        /* Standardized results */
        length lbstresc $200 lbstresn 8 lbstresu $20;
        
        /* Numeric standardization */
        if notdigit(strip(compress(lborres, '.<>'))) = 0 and 
           not missing(lborres) then do;
            lbstresn = input(compress(lborres, '<>'), best.);
            lbstresc = strip(put(lbstresn, best.));
        end;
        else do;
            lbstresc = strip(lborres);
        end;
        
        /* Standardize units */
        select (upcase(strip(lborresu)));
            when ('G/DL', 'GM/DL') lbstresu = 'g/dL';
            when ('G/L') lbstresu = 'g/L';
            when ('MG/DL') lbstresu = 'mg/dL';
            when ('MMOL/L') lbstresu = 'mmol/L';
            when ('UMOL/L') lbstresu = 'umol/L';
            when ('U/L', 'IU/L') lbstresu = 'U/L';
            when ('10^9/L', '10E9/L') lbstresu = '10^9/L';
            when ('10^12/L', '10E12/L') lbstresu = '10^12/L';
            when ('%') lbstresu = '%';
            when ('SEC', 'SECONDS') lbstresu = 'sec';
            when ('RATIO') lbstresu = '';
            otherwise lbstresu = strip(lborresu);
        end;
        
        /* Reference range */
        length lbornrlo lbornrhi 8 lbstnrlo lbstnrhi 8;
        if not missing(ref_range_low) then do;
            lbornrlo = ref_range_low;
            lbstnrlo = ref_range_low;
        end;
        
        if not missing(ref_range_high) then do;
            lbornrhi = ref_range_high;
            lbstnrhi = ref_range_high;
        end;
        
        /* Normal range indicator */
        length lbnrind $100;
        if not missing(lbstresn) and not missing(lbstnrlo) and not missing(lbstnrhi) then do;
            if lbstresn < lbstnrlo then lbnrind = 'LOW';
            else if lbstresn > lbstnrhi then lbnrind = 'HIGH';
            else lbnrind = 'NORMAL';
        end;
        else if not missing(normal_abnormal_flag) then do;
            select (upcase(normal_abnormal_flag));
                when ('L', 'LOW') lbnrind = 'LOW';
                when ('H', 'HIGH') lbnrind = 'HIGH';
                when ('N', 'NORMAL') lbnrind = 'NORMAL';
                when ('A', 'ABNORMAL') lbnrind = 'ABNORMAL';
                otherwise lbnrind = upcase(normal_abnormal_flag);
            end;
        end;
        
        /* Specimen information */
        length lbspec $200;
        select (upcase(specimen_type));
            when ('SERUM') lbspec = 'SERUM';
            when ('PLASMA') lbspec = 'PLASMA';
            when ('WHOLE BLOOD', 'BLOOD') lbspec = 'WHOLE BLOOD';
            when ('URINE') lbspec = 'URINE';
            when ('CSF') lbspec = 'CEREBROSPINAL FLUID';
            otherwise lbspec = propcase(specimen_type);
        end;
        
        /* Method */
        length lbmethod $200;
        if not missing(test_method) then
            lbmethod = propcase(test_method);
        
        /* Visit information */
        length visitnum 8 visit $100;
        visitnum = visit_number;
        visit = propcase(visit_name);
        
        /* Date/time of collection */
        length lbdtc $19;
        if not missing(collection_date) then do;
            if not missing(collection_time) then
                lbdtc = put(collection_date, yymmdd10.) || 'T' || put(collection_time, time8.);
            else
                lbdtc = put(collection_date, yymmdd10.);
        end;
        
        /* Study day */
        length lbdy 8;
        if not missing(lbdtc) and not missing(rfstdtc) then do;
            collection_dt = input(substr(lbdtc, 1, 10), yymmdd10.);
            ref_start_dt = input(substr(rfstdtc, 1, 10), yymmdd10.);
            
            if collection_dt >= ref_start_dt then
                lbdy = collection_dt - ref_start_dt + 1;
            else
                lbdy = collection_dt - ref_start_dt;
        end;
        
        /* Fasting status */
        length lbfast $1;
        if upcase(fasting_status) in ('Y', 'YES', 'FASTING') then lbfast = 'Y';
        else if upcase(fasting_status) in ('N', 'NO', 'NON-FASTING') then lbfast = 'N';
        else if upcase(fasting_status) = 'UNKNOWN' then lbfast = 'U';
        
        /* Labels */
        label studyid = "Study Identifier"
              domain = "Domain Abbreviation"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              lbseq = "Sequence Number"
              lbtestcd = "Lab Test or Examination Short Name"
              lbtest = "Lab Test or Examination Name"
              lbcat = "Category for Lab Test"
              lbscat = "Subcategory for Lab Test"
              lborres = "Result or Finding in Original Units"
              lborresu = "Original Units"
              lbornrlo = "Reference Range Lower Limit in Orig Unit"
              lbornrhi = "Reference Range Upper Limit in Orig Unit"
              lbstresc = "Character Result/Finding in Std Format"
              lbstresn = "Numeric Result/Finding in Standard Units"
              lbstresu = "Standard Units"
              lbstnrlo = "Reference Range Lower Limit-Std Units"
              lbstnrhi = "Reference Range Upper Limit-Std Units"
              lbnrind = "Reference Range Indicator"
              lbspec = "Specimen Material Type"
              lbmethod = "Method of Test or Examination"
              lbfast = "Fasting Status"
              visitnum = "Visit Number"
              visit = "Visit Name"
              lbdtc = "Date/Time of Specimen Collection"
              lbdy = "Study Day of Specimen Collection";
        
        /* Keep only SDTM variables */
        keep studyid domain usubjid subjid lbseq lbtestcd lbtest lbcat lbscat
             lborres lborresu lbornrlo lbornrhi lbstresc lbstresn lbstresu
             lbstnrlo lbstnrhi lbnrind lbspec lbmethod lbfast
             visitnum visit lbdtc lbdy;
    run;
    
    /* Sort by required keys */
    proc sort data=&output;
        by studyid usubjid lbtestcd lbdtc;
    run;
    
    %put NOTE: LB domain created with %sysfunc(nobs(&output)) observations;
    
%mend create_lb_domain;

/******************************************************************************
SECTION 4: VITAL SIGNS (VS) DOMAIN CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_vs_domain
PURPOSE: Create Vital Signs (VS) SDTM domain from raw data
PARAMETERS:
  raw_data= : Raw vital signs dataset
  study_id= : Study identifier
  dm_data= : DM domain for reference dates
  output= : Output SDTM dataset
******************************************************************************/
%macro create_vs_domain(
    raw_data=,
    study_id=,
    dm_data=,
    output=
);
    
    %put NOTE: Creating VS domain from raw data;
    
    /* Get reference dates from DM */
    data work.dm_ref;
        set &dm_data;
        keep usubjid rfstdtc;
    run;
    
    data &output;
        merge &raw_data work.dm_ref;
        by usubjid;
        
        /* Standard SDTM variables */
        length studyid domain usubjid subjid $20;
        studyid = "&study_id";
        domain = "VS";
        subjid = scan(usubjid, -1, '-');
        
        /* Sequence number */
        length vsseq 8;
        vsseq = vs_sequence;
        
        /* Test information */
        length vstestcd $8 vstest $40;
        select (upcase(vs_test));
            when ('SYSBP', 'SBP') do;
                vstestcd = 'SYSBP';
                vstest = 'Systolic Blood Pressure';
            end;
            when ('DIABP', 'DBP') do;
                vstestcd = 'DIABP';
                vstest = 'Diastolic Blood Pressure';
            end;
            when ('PULSE', 'HR') do;
                vstestcd = 'PULSE';
                vstest = 'Pulse Rate';
            end;
            when ('TEMP', 'TEMPERATURE') do;
                vstestcd = 'TEMP';
                vstest = 'Temperature';
            end;
            when ('RESP', 'RR') do;
                vstestcd = 'RESP';
                vstest = 'Respiratory Rate';
            end;
            when ('HEIGHT') do;
                vstestcd = 'HEIGHT';
                vstest = 'Height';
            end;
            when ('WEIGHT') do;
                vstestcd = 'WEIGHT';
                vstest = 'Weight';
            end;
            when ('BMI') do;
                vstestcd = 'BMI';
                vstest = 'Body Mass Index';
            end;
            otherwise do;
                vstestcd = upcase(vs_test);
                vstest = propcase(vs_test);
            end;
        end;
        
        /* Category */
        length vscat $100;
        vscat = 'VITAL SIGNS';
        
        /* Original results */
        length vsorres $200 vsorresu $20;
        vsorres = strip(put(vs_value, best.));
        
        /* Original units */
        select (vstestcd);
            when ('SYSBP', 'DIABP') vsorresu = 'mmHg';
            when ('PULSE', 'RESP') vsorresu = 'beats/min';
            when ('TEMP') do;
                if upcase(temp_units) = 'F' then vsorresu = 'F';
                else vsorresu = 'C';
            end;
            when ('HEIGHT') do;
                if upcase(height_units) = 'IN' then vsorresu = 'in';
                else vsorresu = 'cm';
            end;
            when ('WEIGHT') do;
                if upcase(weight_units) = 'LB' then vsorresu = 'lb';
                else vsorresu = 'kg';
            end;
            when ('BMI') vsorresu = 'kg/m^2';
            otherwise vsorresu = strip(original_units);
        end;
        
        /* Standardized results */
        length vsstresc $200 vsstresn 8 vsstresu $20;
        vsstresn = vs_value;
        vsstresc = strip(put(vsstresn, best.));
        
        /* Standard units conversion */
        select (vstestcd);
            when ('SYSBP', 'DIABP') do;
                vsstresu = 'mmHg';
                /* No conversion needed */
            end;
            when ('PULSE') do;
                vsstresu = 'beats/min';
            end;
            when ('RESP') do;
                vsstresu = 'breaths/min';
            end;
            when ('TEMP') do;
                vsstresu = 'C';
                if upcase(vsorresu) = 'F' then
                    vsstresn = (vs_value - 32) * 5/9;
            end;
            when ('HEIGHT') do;
                vsstresu = 'cm';
                if upcase(vsorresu) = 'IN' then
                    vsstresn = vs_value * 2.54;
            end;
            when ('WEIGHT') do;
                vsstresu = 'kg';
                if upcase(vsorresu) = 'LB' then
                    vsstresn = vs_value * 0.453592;
            end;
            when ('BMI') do;
                vsstresu = 'kg/m^2';
            end;
            otherwise do;
                vsstresu = vsorresu;
            end;
        end;
        
        /* Update standardized character result */
        vsstresc = strip(put(vsstresn, 8.1));
        
        /* Position */
        length vspos $100;
        select (upcase(position));
            when ('SITTING') vspos = 'SITTING';
            when ('STANDING') vspos = 'STANDING';
            when ('SUPINE', 'LYING') vspos = 'SUPINE';
            otherwise if not missing(position) then vspos = upcase(position);
        end;
        
        /* Location */
        length vsloc $100;
        select (upcase(location));
            when ('LEFT ARM') vsloc = 'ARM LEFT';
            when ('RIGHT ARM') vsloc = 'ARM RIGHT';
            when ('LEFT LEG') vsloc = 'LEG LEFT';
            when ('RIGHT LEG') vsloc = 'LEG RIGHT';
            when ('ORAL') vsloc = 'ORAL';
            when ('AXILLARY') vsloc = 'AXILLA';
            otherwise if not missing(location) then vsloc = upcase(location);
        end;
        
        /* Visit information */
        length visitnum 8 visit $100;
        visitnum = visit_number;
        visit = propcase(visit_name);
        
        /* Date/time */
        length vsdtc $19;
        if not missing(vs_date) then do;
            if not missing(vs_time) then
                vsdtc = put(vs_date, yymmdd10.) || 'T' || put(vs_time, time8.);
            else
                vsdtc = put(vs_date, yymmdd10.);
        end;
        
        /* Study day */
        length vsdy 8;
        if not missing(vsdtc) and not missing(rfstdtc) then do;
            vs_dt = input(substr(vsdtc, 1, 10), yymmdd10.);
            ref_start_dt = input(substr(rfstdtc, 1, 10), yymmdd10.);
            
            if vs_dt >= ref_start_dt then
                vsdy = vs_dt - ref_start_dt + 1;
            else
                vsdy = vs_dt - ref_start_dt;
        end;
        
        /* Labels */
        label studyid = "Study Identifier"
              domain = "Domain Abbreviation"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              vsseq = "Sequence Number"
              vstestcd = "Vital Signs Test Short Name"
              vstest = "Vital Signs Test Name"
              vscat = "Category for Vital Signs"
              vsorres = "Result or Finding in Original Units"
              vsorresu = "Original Units"
              vsstresc = "Character Result/Finding in Std Format"
              vsstresn = "Numeric Result/Finding in Standard Units"
              vsstresu = "Standard Units"
              vspos = "Vital Signs Position of Subject"
              vsloc = "Location of Vital Signs Measurement"
              visitnum = "Visit Number"
              visit = "Visit Name"
              vsdtc = "Date/Time of Measurements"
              vsdy = "Study Day of Vital Signs";
        
        /* Keep only SDTM variables */
        keep studyid domain usubjid subjid vsseq vstestcd vstest vscat
             vsorres vsorresu vsstresc vsstresn vsstresu vspos vsloc
             visitnum visit vsdtc vsdy;
    run;
    
    /* Sort by required keys */
    proc sort data=&output;
        by studyid usubjid vstestcd vsdtc;
    run;
    
    %put NOTE: VS domain created with %sysfunc(nobs(&output)) observations;
    
%mend create_vs_domain;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Create DM domain
%create_dm_domain(
    raw_data=raw.demographics,
    study_id=ABC-001,
    output=sdtm.dm
);

Example 2: Create AE domain
%create_ae_domain(
    raw_data=raw.adverse_events,
    study_id=ABC-001,
    dm_data=sdtm.dm,
    output=sdtm.ae
);

Example 3: Create LB domain
%create_lb_domain(
    raw_data=raw.laboratory,
    study_id=ABC-001,
    dm_data=sdtm.dm,
    output=sdtm.lb
);

Example 4: Create VS domain
%create_vs_domain(
    raw_data=raw.vital_signs,
    study_id=ABC-001,
    dm_data=sdtm.dm,
    output=sdtm.vs
);
*/

%put NOTE: SDTM creation examples loaded successfully;
%put NOTE: Available macros: create_dm_domain, create_ae_domain, create_lb_domain, create_vs_domain;