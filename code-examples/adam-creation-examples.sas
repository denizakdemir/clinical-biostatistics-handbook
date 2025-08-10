/******************************************************************************
PROGRAM: adam-creation-examples.sas
PURPOSE: Comprehensive ADaM dataset creation examples
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides complete examples for creating ADaM datasets from SDTM
domains, including all standard variables, derivations, and quality checks
following CDISC ADaM Implementation Guide standards.

SECTIONS INCLUDED:
1. ADSL (Subject-Level Analysis Dataset) Creation
2. ADAE (Adverse Events Analysis Dataset) Creation
3. ADLB (Laboratory Analysis Dataset) Creation  
4. ADVS (Vital Signs Analysis Dataset) Creation
5. ADTTE (Time-to-Event Analysis Dataset) Creation
6. ADEG (ECG Analysis Dataset) Creation
******************************************************************************/

/******************************************************************************
SECTION 1: COMPREHENSIVE ADSL CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_comprehensive_adsl
PURPOSE: Create complete ADSL with all standard variables
PARAMETERS:
  dm_data= : Demographics SDTM domain
  ds_data= : Disposition SDTM domain
  ex_data= : Exposure SDTM domain
  sv_data= : Subject visits SDTM domain
  output= : Output ADSL dataset
  study_id= : Study identifier
******************************************************************************/
%macro create_comprehensive_adsl(
    dm_data=,
    ds_data=,
    ex_data=,
    sv_data=,
    output=,
    study_id=
);
    
    %put NOTE: Creating comprehensive ADSL dataset;
    
    /* Step 1: Start with Demographics */
    data work.adsl_base;
        set &dm_data;
        
        /* Standard identifiers */
        length studyid usubjid subjid $20;
        /* Already from DM */
        
        /* Site and investigator info */
        length siteid $10 sitegr1 $20;
        /* siteid already from DM */
        
        /* Create site groupings if needed */
        if input(siteid, best.) <= 100 then sitegr1 = 'Region 1';
        else if input(siteid, best.) <= 200 then sitegr1 = 'Region 2';
        else sitegr1 = 'Region 3';
        
        /* Demographics - enhanced */
        /* age, sex, race already from DM */
        
        /* Age groupings */
        length agegr1 agegr1n $20 8;
        if not missing(age) then do;
            if age < 18 then do;
                agegr1 = '<18';
                agegr1n = 1;
            end;
            else if age < 65 then do;
                agegr1 = '18-64';
                agegr1n = 2;
            end;
            else do;
                agegr1 = '>=65';
                agegr1n = 3;
            end;
        end;
        
        /* Race groupings for analysis */
        length racegr1 $50;
        if race = 'WHITE' then racegr1 = 'White';
        else if race = 'BLACK OR AFRICAN AMERICAN' then racegr1 = 'Black or African American';
        else if race = 'ASIAN' then racegr1 = 'Asian';
        else racegr1 = 'Other';
        
        /* Treatment assignment */
        /* armcd, arm, actarmcd, actarm already from DM */
        
        /* Planned treatment variables */
        length trt01p trt01pn 8 $50;
        trt01p = arm;
        
        select (upcase(armcd));
            when ('PLACEBO', 'PLC') trt01pn = 0;
            when ('ACTIVE_LOW', 'LOW') trt01pn = 1;
            when ('ACTIVE_HIGH', 'HIGH') trt01pn = 2;
            when ('ACTIVE') trt01pn = 1;
            otherwise trt01pn = 99;
        end;
        
        /* Actual treatment variables */
        length trt01a trt01an 8 $50;
        trt01a = actarm;
        
        select (upcase(actarmcd));
            when ('PLACEBO', 'PLC') trt01an = 0;
            when ('ACTIVE_LOW', 'LOW') trt01an = 1;
            when ('ACTIVE_HIGH', 'HIGH') trt01an = 2;
            when ('ACTIVE') trt01an = 1;
            otherwise trt01an = 99;
        end;
        
        /* Randomization information */
        length randfl $1 randdt 8;
        format randdt date9.;
        
        /* Determine if randomized */
        if not missing(arm) then randfl = 'Y';
        else randfl = 'N';
        
        /* Randomization date from reference start date */
        if not missing(rfstdtc) then 
            randdt = input(substr(rfstdtc, 1, 10), yymmdd10.);
        
        /* Labels for variables created so far */
        label studyid = "Study Identifier"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              siteid = "Study Site Identifier"
              sitegr1 = "Pooled Site Group 1"
              age = "Age"
              agegr1 = "Pooled Age Group 1"
              agegr1n = "Pooled Age Group 1 (N)"
              sex = "Sex"
              race = "Race"
              racegr1 = "Pooled Race Group 1"
              ethnic = "Ethnicity"
              trt01p = "Planned Treatment for Period 01"
              trt01pn = "Planned Treatment for Period 01 (N)"
              trt01a = "Actual Treatment for Period 01"
              trt01an = "Actual Treatment for Period 01 (N)"
              randfl = "Randomized Population Flag"
              randdt = "Date of Randomization";
    run;
    
    /* Step 2: Add exposure information */
    %if %length(&ex_data) > 0 %then %do;
        proc sql;
            create table work.exposure_summary as
            select usubjid,
                   min(case when not missing(exstdtc) 
                           then input(substr(exstdtc, 1, 10), yymmdd10.) 
                           else . end) as trtsdt format=date9.,
                   max(case when not missing(exendtc) 
                           then input(substr(exendtc, 1, 10), yymmdd10.) 
                           else . end) as trtedt format=date9.,
                   sum(exdose * exdur) as trtdur,
                   sum(case when exdose > 0 then 1 else 0 end) as dose_days,
                   mean(case when exdose > 0 then exdose else . end) as avg_dose
            from &ex_data
            where not missing(exdose)
            group by usubjid;
        quit;
        
        data work.adsl_exp;
            merge work.adsl_base(in=a) work.exposure_summary(in=b);
            by usubjid;
            if a;
            
            /* If no exposure data, set missing */
            if not b then do;
                trtsdt = .;
                trtedt = .;
                trtdur = .;
            end;
            
            /* Calculate duration if missing */
            if missing(trtdur) and not missing(trtsdt) and not missing(trtedt) then
                trtdur = trtedt - trtsdt + 1;
            
            /* Exposure duration categories */
            length trtdurg1 $20;
            if not missing(trtdur) then do;
                if trtdur < 7 then trtdurg1 = '<7 days';
                else if trtdur < 30 then trtdurg1 = '7-29 days';
                else if trtdur < 90 then trtdurg1 = '30-89 days';
                else trtdurg1 = '>=90 days';
            end;
            
            label trtsdt = "Date of First Exposure to Treatment"
                  trtedt = "Date of Last Exposure to Treatment"
                  trtdur = "Total Treatment Duration (Days)"
                  trtdurg1 = "Pooled Treatment Duration Group 1"
                  avg_dose = "Average Daily Dose";
        run;
    %end;
    %else %do;
        data work.adsl_exp;
            set work.adsl_base;
        run;
    %end;
    
    /* Step 3: Add disposition information */
    %if %length(&ds_data) > 0 %then %do;
        proc sql;
            create table work.disposition as
            select usubjid,
                   max(case when upcase(dscat) = 'DISPOSITION EVENT' and
                             upcase(dsscat) contains 'COMPLETION' 
                           then dsdecod else '' end) as completion_status length=200,
                   max(case when upcase(dscat) = 'DISPOSITION EVENT' and
                             upcase(dsscat) contains 'DISCONTINUATION'
                           then dsdecod else '' end) as dcsreas length=200,
                   max(case when upcase(dscat) = 'DISPOSITION EVENT' and
                             not missing(dsstdtc)
                           then input(substr(dsstdtc, 1, 10), yymmdd10.)
                           else . end) as dcsdt format=date9.
            from &ds_data
            group by usubjid;
        quit;
        
        data work.adsl_disp;
            merge work.adsl_exp(in=a) work.disposition(in=b);
            by usubjid;
            if a;
            
            /* Completion flag */
            length compfl $1;
            if upcase(completion_status) contains 'COMPLETED' or
               upcase(completion_status) = 'STUDY COMPLETION' then compfl = 'Y';
            else if not missing(dcsreas) then compfl = 'N';
            else compfl = '';
            
            /* Discontinuation reason grouping */
            length dcsreasg1 $100;
            select (upcase(strip(dcsreas)));
                when ('ADVERSE EVENT') dcsreasg1 = 'Adverse Event';
                when ('LACK OF EFFICACY') dcsreasg1 = 'Lack of Efficacy';
                when ('WITHDRAWAL BY SUBJECT') dcsreasg1 = 'Subject Choice';
                when ('LOST TO FOLLOW-UP') dcsreasg1 = 'Lost to Follow-up';
                when ('PROTOCOL VIOLATION') dcsreasg1 = 'Protocol Violation';
                when ('PHYSICIAN DECISION') dcsreasg1 = 'Physician Decision';
                when ('DEATH') dcsreasg1 = 'Death';
                otherwise if not missing(dcsreas) then dcsreasg1 = 'Other';
            end;
            
            label compfl = "Completion Flag"
                  dcsreas = "Reason for Discontinuation of Subject"
                  dcsreasg1 = "Pooled Reason for Discontinuation"
                  dcsdt = "Date of Discontinuation of Subject";
        run;
    %end;
    %else %do;
        data work.adsl_disp;
            set work.adsl_exp;
        run;
    %end;
    
    /* Step 4: Add visit information for analysis periods */
    %if %length(&sv_data) > 0 %then %do;
        proc sql;
            create table work.visit_summary as
            select usubjid,
                   min(case when visitnum > 0 and not missing(svstdtc)
                           then input(substr(svstdtc, 1, 10), yymmdd10.)
                           else . end) as ap01sdt format=date9.,
                   max(case when visitnum > 0 and not missing(svendtc) 
                           then input(substr(svendtc, 1, 10), yymmdd10.)
                           else . end) as ap01edt format=date9.
            from &sv_data
            where visitnum > 0
            group by usubjid;
        quit;
        
        data work.adsl_visits;
            merge work.adsl_disp(in=a) work.visit_summary(in=b);
            by usubjid;
            if a;
            
            label ap01sdt = "Period 01 Start Date"
                  ap01edt = "Period 01 End Date";
        run;
    %end;
    %else %do;
        data work.adsl_visits;
            set work.adsl_disp;
        run;
    %end;
    
    /* Step 5: Create analysis population flags */
    data work.adsl_populations;
        set work.adsl_visits;
        
        /* Intent-to-treat population */
        length ittfl $1;
        ittfl = randfl;
        
        /* Safety population: received at least one dose */
        length saffl $1;
        if not missing(trtsdt) then saffl = 'Y';
        else saffl = 'N';
        
        /* Efficacy population: typically same as ITT */
        length efffl $1;
        efffl = ittfl;
        
        /* Per-protocol population: completed without major violations */
        length pprotfl $1;
        if ittfl = 'Y' and compfl = 'Y' and 
           not (upcase(dcsreasg1) in ('PROTOCOL VIOLATION')) then pprotfl = 'Y';
        else pprotfl = 'N';
        
        /* Modified ITT: treated patients only */
        length mittfl $1;
        if ittfl = 'Y' and saffl = 'Y' then mittfl = 'Y';
        else mittfl = 'N';
        
        /* Pharmacokinetic population */
        length pkfl $1;
        if saffl = 'Y' and not missing(trtdur) and trtdur >= 1 then pkfl = 'Y';
        else pkfl = 'N';
        
        /* Population description for titles */
        length poptxt $200;
        if ittfl = 'Y' then poptxt = 'Intent-to-Treat Population';
        else if saffl = 'Y' then poptxt = 'Safety Population';
        else poptxt = 'All Subjects';
        
        label ittfl = "Intent-To-Treat Population Flag"
              saffl = "Safety Population Flag" 
              efffl = "Efficacy Population Flag"
              pprotfl = "Per-Protocol Population Flag"
              mittfl = "Modified Intent-To-Treat Population Flag"
              pkfl = "Pharmacokinetic Population Flag"
              poptxt = "Population Description Text";
    run;
    
    /* Step 6: Add baseline characteristics placeholders */
    data &output;
        set work.adsl_populations;
        
        /* Baseline weight/height/BMI placeholders */
        length weightbl heightbl bmibl 8;
        /* These would be populated from VS domain */
        
        /* Medical history flags */
        length mhfl $1;
        /* This would be populated from MH domain */
        
        /* Concomitant medication flag */
        length cmfl $1;
        /* This would be populated from CM domain */
        
        /* Create additional useful variables */
        length studyidn 8;
        studyidn = input(compress(studyid, , 'kd'), best.);
        
        /* Pooled country */
        length countryl1 $50;
        select (country);
            when ('USA') countryl1 = 'United States';
            when ('CAN') countryl1 = 'Canada';
            when ('GBR') countryl1 = 'United Kingdom';
            when ('DEU') countryl1 = 'Germany';
            when ('FRA') countryl1 = 'France';
            otherwise countryl1 = 'Other';
        end;
        
        /* Additional labels */
        label weightbl = "Baseline Weight (kg)"
              heightbl = "Baseline Height (cm)"
              bmibl = "Baseline Body Mass Index (kg/m^2)"
              mhfl = "Medical History Flag"
              cmfl = "Concomitant Medication Flag"
              studyidn = "Study Identifier (N)"
              countryl1 = "Pooled Country Level 1";
        
        /* Sort by key variables */
        proc sort;
            by studyid usubjid;
        run;
    run;
    
    /* Step 7: Validation and summary */
    proc means data=&output n nmiss min max;
        class ittfl saffl;
        var age trtdur;
        title "ADSL Population Summary";
    run;
    
    proc freq data=&output;
        tables ittfl*saffl*efffl*pprotfl / missing;
        title "Analysis Population Cross-tabulation";
    run;
    
    /* Clean up work datasets */
    proc datasets library=work nolist;
        delete adsl_base exposure_summary adsl_exp disposition adsl_disp
               visit_summary adsl_visits adsl_populations;
    quit;
    
    %put NOTE: Comprehensive ADSL created with %sysfunc(nobs(&output)) subjects;
    
%mend create_comprehensive_adsl;

/******************************************************************************
SECTION 2: COMPREHENSIVE ADAE CREATION
******************************************************************************/

/******************************************************************************
MACRO: create_comprehensive_adae
PURPOSE: Create complete ADAE with all standard variables and flags
PARAMETERS:
  ae_data= : Adverse Events SDTM domain
  adsl_data= : ADSL dataset
  output= : Output ADAE dataset
******************************************************************************/
%macro create_comprehensive_adae(
    ae_data=,
    adsl_data=,
    output=
);
    
    %put NOTE: Creating comprehensive ADAE dataset;
    
    /* Merge AE with ADSL */
    proc sort data=&ae_data; by studyid usubjid; run;
    proc sort data=&adsl_data; by studyid usubjid; run;
    
    data &output;
        merge &ae_data(in=ae) 
              &adsl_data(in=adsl keep=studyid usubjid trt01p trt01pn trt01a trt01an
                                     trtsdt trtedt saffl ittfl age sex race);
        by studyid usubjid;
        
        if ae and adsl; /* Keep only AEs for subjects in ADSL */
        
        /* Copy sequence number */
        length aeseq 8;
        /* aeseq already from AE domain */
        
        /* Parameter variables for BDS structure */
        length paramcd $8 param $100;
        paramcd = 'AOCCFL';
        param = 'Any Occurrence Flag';
        
        /* Analysis dates - copy from SDTM */
        length astdtc aendtc $19;
        astdtc = aestdtc;
        aendtc = aeendtc;
        
        /* Convert to numeric dates */
        length astdt aendt 8;
        format astdt aendt date9.;
        
        if not missing(astdtc) then
            astdt = input(substr(astdtc, 1, 10), yymmdd10.);
        if not missing(aendtc) then
            aendt = input(substr(aendtc, 1, 10), yymmdd10.);
        
        /* Analysis day calculations */
        length astdy aendy 8;
        if not missing(astdt) and not missing(trtsdt) then do;
            if astdt >= trtsdt then astdy = astdt - trtsdt + 1;
            else astdy = astdt - trtsdt;
        end;
        
        if not missing(aendt) and not missing(trtsdt) then do;
            if aendt >= trtsdt then aendy = aendt - trtsdt + 1;
            else aendy = aendt - trtsdt;
        end;
        
        /* Analysis severity (standardized from SDTM) */
        length asev $20;
        asev = aesev;
        
        /* Analysis relationship */
        length arel $30;
        if aerel in ('RELATED', 'PROBABLY RELATED', 'POSSIBLY RELATED') then
            arel = 'RELATED';
        else if aerel in ('NOT RELATED', 'UNLIKELY RELATED') then
            arel = 'NOT RELATED';
        else arel = aerel;
        
        /* Treatment-emergent flag */
        length trtemfl $1;
        if not missing(astdt) and not missing(trtsdt) then do;
            if astdt >= trtsdt then trtemfl = 'Y';
            else trtemfl = 'N';
        end;
        
        /* Treatment-emergent related flag */
        length trterelfl $1;
        if trtemfl = 'Y' and arel = 'RELATED' then trterelfl = 'Y';
        else trterelfl = 'N';
        
        /* Occurrence flags */
        length aoccfl aoccsfl aoccsifl aoccsevfl aoccserfl 
               aoccrelfl aoccrefl $1;
        
        /* Any occurrence */
        aoccfl = 'Y';
        
        /* Serious occurrence */
        if aeser = 'Y' then aoccserfl = 'Y';
        else aoccserfl = 'N';
        
        /* Severe occurrence */
        if asev = 'SEVERE' then aoccsevfl = 'Y';
        else aoccsevfl = 'N';
        
        /* Related occurrence */
        if arel = 'RELATED' then aoccrelfl = 'Y';
        else aoccrelfl = 'N';
        
        /* Treatment-emergent related occurrence */
        if trterelfl = 'Y' then aoccrefl = 'Y';
        else aoccrefl = 'N';
        
        /* Fatal outcome */
        length adthfl $1;
        if aeout = 'FATAL' or aesdth = 'Y' then adthfl = 'Y';
        else adthfl = 'N';
        
        /* Leading to discontinuation */
        length adisconfl $1;
        if upcase(aeacn) in ('DRUG WITHDRAWN', 'WITHDRAWN') then adisconfl = 'Y';
        else adisconfl = 'N';
        
        /* Hospitalization or prolonged hospitalization */
        length ahospfl $1;
        if aeshosp = 'Y' then ahospfl = 'Y';
        else ahospfl = 'N';
        
        /* Life-threatening */
        length alifefl $1;
        if aeslife = 'Y' then alifefl = 'Y';
        else alifefl = 'N';
        
        /* Disability or incapacity */
        length adisabfl $1;
        if aesdisab = 'Y' then adisabfl = 'Y';
        else adisabfl = 'N';
        
        /* Congenital anomaly */
        length acongfl $1;
        if aescong = 'Y' then acongfl = 'Y';
        else acongfl = 'N';
        
        /* Other medically important */
        length amifl $1;
        if aeser = 'Y' and aeslife = 'N' and aeshosp = 'N' and 
           aesdisab = 'N' and aescong = 'N' and aesdth = 'N' then amifl = 'Y';
        else amifl = 'N';
        
        /* Toxicity grade for oncology studies */
        length atoxgr $10;
        select (upcase(asev));
            when ('MILD') atoxgr = 'Grade 1';
            when ('MODERATE') atoxgr = 'Grade 2'; 
            when ('SEVERE') atoxgr = 'Grade 3';
            otherwise atoxgr = '';
        end;
        
        /* Duration of AE */
        length adurn 8;
        if not missing(astdt) and not missing(aendt) then
            adurn = aendt - astdt + 1;
        else if not missing(aedur) then
            adurn = aedur;
        
        /* Duration categories */
        length adurnp1 $20;
        if not missing(adurn) then do;
            if adurn = 1 then adurnp1 = '1 day';
            else if adurn <= 7 then adurnp1 = '2-7 days';
            else if adurn <= 30 then adurnp1 = '8-30 days';
            else adurnp1 = '>30 days';
        end;
        
        /* AE number within subject */
        retain ae_num 0;
        by studyid usubjid;
        if first.usubjid then ae_num = 0;
        ae_num + 1;
        
        /* Analysis visit - map from SDTM visit to analysis visit */
        length avisit $100;
        if not missing(astdy) then do;
            if astdy < 0 then avisit = 'PRE-TREATMENT';
            else if astdy <= 7 then avisit = 'WEEK 1';
            else if astdy <= 14 then avisit = 'WEEK 2';
            else if astdy <= 28 then avisit = 'WEEK 4';
            else if astdy <= 56 then avisit = 'WEEK 8';
            else if astdy <= 84 then avisit = 'WEEK 12';
            else avisit = 'POST WEEK 12';
        end;
        
        /* Labels for all variables */
        label aeseq = "Sequence Number"
              paramcd = "Parameter Code"
              param = "Parameter"
              astdtc = "Analysis Start Date/Time"
              aendtc = "Analysis End Date/Time"  
              astdt = "Analysis Start Date"
              aendt = "Analysis End Date"
              astdy = "Analysis Start Day"
              aendy = "Analysis End Day"
              asev = "Analysis Severity"
              arel = "Analysis Causality"
              trtemfl = "Treatment Emergent Analysis Flag"
              trterelfl = "Treatment Emergent Related Analysis Flag"
              aoccfl = "Any Occurrence Flag"
              aoccsfl = "1st Occurrence Flag"
              aoccsifl = "1st Occurrence Flag for SOC"
              aoccsevfl = "Severe Occurrence Flag"
              aoccserfl = "Serious Occurrence Flag"
              aoccrelfl = "Related Occurrence Flag"
              aoccrefl = "Treatment Emergent Related Occurrence Flag"
              adthfl = "Analysis Death Flag"
              adisconfl = "Analysis Discontinuation Flag"
              ahospfl = "Analysis Hospitalization Flag"
              alifefl = "Analysis Life Threatening Flag"
              adisabfl = "Analysis Disability Flag"
              acongfl = "Analysis Congenital Anomaly Flag"
              amifl = "Analysis Medically Important Flag"
              atoxgr = "Analysis Toxicity Grade"
              adurn = "Analysis Duration (N)"
              adurnp1 = "Analysis Duration Group 1"
              ae_num = "AE Number Within Subject"
              avisit = "Analysis Visit";
    run;
    
    /* Create first occurrence flags by subject and preferred term */
    proc sort data=&output;
        by studyid usubjid aedecod astdt astdy aeseq;
    run;
    
    data &output;
        set &output;
        by studyid usubjid aedecod;
        
        /* First occurrence by preferred term */
        if first.aedecod then aoccsfl = 'Y';
        else aoccsfl = 'N';
        
        /* First occurrence by SOC */
        by studyid usubjid aesoc;
        if first.aesoc then aoccsifl = 'Y';
        else aoccsifl = 'N';
    run;
    
    /* Sort by standard keys */
    proc sort data=&output;
        by studyid usubjid astdt aeseq;
    run;
    
    %put NOTE: Comprehensive ADAE created with %sysfunc(nobs(&output)) records;
    
%mend create_comprehensive_adae;

/******************************************************************************
SECTION 3: COMPREHENSIVE ADLB CREATION  
******************************************************************************/

/******************************************************************************
MACRO: create_comprehensive_adlb
PURPOSE: Create complete ADLB with all BDS variables
PARAMETERS:
  lb_data= : Laboratory SDTM domain
  adsl_data= : ADSL dataset
  output= : Output ADLB dataset
******************************************************************************/
%macro create_comprehensive_adlb(
    lb_data=,
    adsl_data=,
    output=
);
    
    %put NOTE: Creating comprehensive ADLB dataset;
    
    /* Merge LB with ADSL */
    proc sort data=&lb_data; by studyid usubjid; run;
    proc sort data=&adsl_data; by studyid usubjid; run;
    
    data work.adlb_merged;
        merge &lb_data(in=lb)
              &adsl_data(in=adsl keep=studyid usubjid trt01p trt01pn 
                                     trtsdt trtedt saffl ittfl);
        by studyid usubjid;
        
        if lb and adsl;
    run;
    
    /* Create BDS structure */
    data work.adlb_bds;
        set work.adlb_merged;
        
        /* BDS key variables */
        length paramcd $8 param $100;
        paramcd = lbtestcd;
        param = lbtest;
        
        /* Analysis values */
        length aval avalc $200;
        aval = lbstresn;
        if not missing(lbstresc) then avalc = lbstresc;
        else if not missing(aval) then avalc = put(aval, best.);
        
        /* Analysis units */
        length avalu $20;
        avalu = lbstresu;
        
        /* Analysis date and day */
        length adt 8 ady 8;
        format adt date9.;
        
        if not missing(lbdtc) then
            adt = input(substr(lbdtc, 1, 10), yymmdd10.);
            
        if not missing(adt) and not missing(trtsdt) then do;
            if adt >= trtsdt then ady = adt - trtsdt + 1;
            else ady = adt - trtsdt;
        end;
        
        /* Visit mapping */
        length avisitn 8 avisit $100;
        
        /* Map SDTM visit to analysis visit */
        select (upcase(visit));
            when ('SCREENING') do;
                avisitn = -1;
                avisit = 'Screening';
            end;
            when ('BASELINE', 'DAY 1') do;
                avisitn = 0;
                avisit = 'Baseline';
            end;
            when ('WEEK 2', 'DAY 15') do;
                avisitn = 2;
                avisit = 'Week 2';
            end;
            when ('WEEK 4', 'DAY 29') do;
                avisitn = 4;
                avisit = 'Week 4';
            end;
            when ('WEEK 8', 'DAY 57') do;
                avisitn = 8;
                avisit = 'Week 8';
            end;
            when ('WEEK 12', 'DAY 85') do;
                avisitn = 12;
                avisit = 'Week 12';
            end;
            when ('END OF TREATMENT', 'EARLY TERMINATION') do;
                avisitn = 99;
                avisit = 'End of Treatment';
            end;
            otherwise do;
                avisitn = visitnum;
                avisit = propcase(visit);
            end;
        end;
        
        /* Analysis reference range */
        length a1lo a1hi 8;
        a1lo = lbstnrlo;
        a1hi = lbstnrhi;
        
        /* Analysis reference range indicator */
        length anrind $100;
        anrind = lbnrind;
        
        /* Shift from baseline */
        length bnrind $100;
        /* Will be derived later after baseline identification */
        
        label paramcd = "Parameter Code"
              param = "Parameter"
              aval = "Analysis Value"
              avalc = "Analysis Value (C)"
              avalu = "Analysis Unit"
              adt = "Analysis Date"
              ady = "Analysis Day"
              avisitn = "Analysis Visit (N)"
              avisit = "Analysis Visit"
              a1lo = "Analysis Range 1 Lower Limit"
              a1hi = "Analysis Range 1 Upper Limit"
              anrind = "Analysis Reference Range Indicator"
              bnrind = "Baseline Reference Range Indicator";
    run;
    
    /* Sort for baseline processing */
    proc sort data=work.adlb_bds;
        by studyid usubjid paramcd avisitn adt;
    run;
    
    /* Derive baseline and change variables */
    data &output;
        set work.adlb_bds;
        by studyid usubjid paramcd;
        
        /* Analysis flags */
        length ablfl anlfl anl01fl anl02fl lastfl $1;
        
        /* Baseline flag */
        if avisitn = 0 or upcase(avisit) = 'BASELINE' then ablfl = 'Y';
        else ablfl = 'N';
        
        /* Analysis flag */
        if not missing(aval) then anlfl = 'Y';
        else anlfl = 'N';
        
        /* Post-baseline analysis flag */
        if anlfl = 'Y' and ablfl = 'N' and avisitn > 0 then anl01fl = 'Y';
        else anl01fl = 'N';
        
        /* On-treatment analysis flag */
        if anlfl = 'Y' and not missing(adt) and not missing(trtsdt) then do;
            if adt >= trtsdt and (missing(trtedt) or adt <= trtedt) then
                anl02fl = 'Y';
            else anl02fl = 'N';
        end;
        else anl02fl = 'N';
        
        /* Baseline value derivation */
        length base basec $200;
        retain base basec;
        
        if first.paramcd then do;
            base = .;
            basec = '';
        end;
        
        if ablfl = 'Y' and anlfl = 'Y' then do;
            base = aval;
            basec = avalc;
            bnrind = anrind; /* Baseline reference range indicator */
        end;
        
        /* Change from baseline */
        length chg pchg 8;
        if not missing(aval) and not missing(base) and ablfl = 'N' then do;
            chg = aval - base;
            
            if base ne 0 then pchg = (chg / base) * 100;
        end;
        
        /* Shift table variables */
        length shift1 $100;
        if not missing(bnrind) and not missing(anrind) then
            shift1 = cats(strip(bnrind), ' to ', strip(anrind));
        
        /* Analysis criteria */
        length crit1fl crit1 $200;
        /* Example: Flag values above upper limit of normal */
        if anrind = 'HIGH' then do;
            crit1fl = 'Y';
            crit1 = 'Above Upper Limit of Normal';
        end;
        else do;
            crit1fl = 'N';
            crit1 = 'Within or Below Normal Range';
        end;
        
        /* Treatment high/low flags */
        length lothifl $1;
        if not missing(aval) and not missing(a1hi) then do;
            if aval > a1hi then lothifl = 'H';
            else if not missing(a1lo) and aval < a1lo then lothifl = 'L';
            else lothifl = 'N';
        end;
        
        /* Extreme values flag */
        length ex1fl $1;
        if not missing(aval) and not missing(a1hi) then do;
            if aval > 3 * a1hi then ex1fl = 'Y'; /* 3x ULN */
            else ex1fl = 'N';
        end;
        
        /* Additional labels */
        label ablfl = "Baseline Record Flag"
              anlfl = "Analysis Flag"
              anl01fl = "Analysis Flag 01"
              anl02fl = "Analysis Flag 02"
              lastfl = "Last Record Flag"
              base = "Baseline Value"
              basec = "Baseline Value (C)"
              bnrind = "Baseline Reference Range Indicator"
              chg = "Change from Baseline"
              pchg = "Percent Change from Baseline"
              shift1 = "Shift 1"
              crit1 = "Analysis Criterion 1"
              crit1fl = "Criterion 1 Evaluation Result Flag"
              lothifl = "Low/High/Normal Flag"
              ex1fl = "Extreme Value Flag 1";
    run;
    
    /* Derive last observation flag */
    proc sort data=&output;
        by studyid usubjid paramcd descending adt descending avisitn;
    run;
    
    data &output;
        set &output;
        by studyid usubjid paramcd;
        
        if first.paramcd and anlfl = 'Y' then lastfl = 'Y';
        else lastfl = 'N';
    run;
    
    /* Sort back to chronological order */
    proc sort data=&output;
        by studyid usubjid paramcd avisitn adt;
    run;
    
    %put NOTE: Comprehensive ADLB created with %sysfunc(nobs(&output)) records;
    
%mend create_comprehensive_adlb;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Create comprehensive ADSL
%create_comprehensive_adsl(
    dm_data=sdtm.dm,
    ds_data=sdtm.ds,
    ex_data=sdtm.ex,
    sv_data=sdtm.sv,
    output=adam.adsl,
    study_id=ABC-001
);

Example 2: Create comprehensive ADAE
%create_comprehensive_adae(
    ae_data=sdtm.ae,
    adsl_data=adam.adsl,
    output=adam.adae
);

Example 3: Create comprehensive ADLB
%create_comprehensive_adlb(
    lb_data=sdtm.lb,
    adsl_data=adam.adsl,
    output=adam.adlb
);
*/

%put NOTE: ADaM creation examples loaded successfully;
%put NOTE: Available macros: create_comprehensive_adsl, create_comprehensive_adae, create_comprehensive_adlb;