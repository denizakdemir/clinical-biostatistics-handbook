/******************************************************************************
PROGRAM: listing-template.sas
PURPOSE: Template for generating regulatory-compliant listings
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This template provides a standardized framework for creating clinical trial
listings that comply with regulatory requirements and ICH E3 guidelines.
Includes templates for common listing types with proper formatting.

SECTIONS INCLUDED:
1. Environment Setup and Standards
2. Demographics and Baseline Listings
3. Adverse Event Listings
4. Concomitant Medication Listings
5. Protocol Deviation Listings
6. Laboratory Listings
7. Data Verification Listings
8. Utility Macros for Listing Generation
******************************************************************************/

/******************************************************************************
SECTION 1: ENVIRONMENT SETUP AND STANDARDS
******************************************************************************/

/* Study parameters - MODIFY AS NEEDED */
%let study_id = [STUDY_ID];
%let protocol = [PROTOCOL_NUMBER];
%let data_cutoff = [DATA_CUTOFF_DATE];
%let analysis_date = %sysfunc(today(), date9.);

/* File paths - MODIFY AS NEEDED */
%let adam_path = [ADAM_DATA_PATH];
%let sdtm_path = [SDTM_DATA_PATH];
%let output_path = [OUTPUT_PATH];

/* Listing standards */
%let page_size = 66;
%let line_size = 132;
%let font_name = Courier;
%let font_size = 8pt;

/* Set up listing environment */
options orientation=landscape papersize=letter
        leftmargin=0.5in rightmargin=0.5in
        topmargin=0.5in bottommargin=0.5in
        nodate pageno=1;

ods listing;
ods escapechar='^';

/* Define global title and footnote macros */
%macro set_listing_titles(listing_title=, listing_number=);
    title1 j=l "Study: &study_id" j=r "Page ^{pageof}";
    title2 j=l "Protocol: &protocol" j=r "&analysis_date";
    title3 j=c "&listing_title";
    title4 j=c "Listing &listing_number";
    title5;
    
    footnote1 j=l "Data Cutoff: &data_cutoff" j=r "Confidential";
    footnote2 j=l "Generated: %sysfunc(datetime(), datetime20.)" j=r "Page ^{pageof}";
%mend set_listing_titles;

/******************************************************************************
SECTION 2: DEMOGRAPHICS AND BASELINE LISTINGS
******************************************************************************/

/******************************************************************************
MACRO: create_demographics_listing
PURPOSE: Generate demographics and baseline characteristics listing
PARAMETERS:
  data= : ADSL dataset
  output_file= : Output file name
  title= : Listing title
******************************************************************************/
%macro create_demographics_listing(
    data=,
    output_file=Demographics_Listing,
    title=Subject Demographics and Baseline Characteristics
);
    
    %put NOTE: Creating demographics listing;
    
    /* Prepare data for listing */
    data work.demo_list;
        set &data;
        where SAFFL = 'Y'; /* Safety population */
        
        /* Format variables for listing display */
        length AGE_DISP SEX_DISP RACE_DISP $20;
        length TRT_DISP $50;
        length SITE_DISP $15;
        
        AGE_DISP = put(AGE, 3.);
        if missing(AGE) then AGE_DISP = '';
        
        SEX_DISP = SEX;
        RACE_DISP = RACE;
        TRT_DISP = TRT01P;
        SITE_DISP = SITEID;
        
        /* Randomization date */
        length RAND_DATE $10;
        if not missing(RANDDT) then RAND_DATE = put(RANDDT, yymmdd10.);
        
        /* Country/Region */
        length COUNTRY_DISP $20;
        if not missing(COUNTRY) then COUNTRY_DISP = COUNTRY;
        else COUNTRY_DISP = 'Unknown';
    run;
    
    /* Sort by treatment, then by subject */
    proc sort data=work.demo_list;
        by TRT01PN USUBJID;
    run;
    
    /* Generate listing */
    ods rtf file="&output_path/&output_file..rtf" 
        style=minimal
        bodytitle
        fontsize=&font_size;
    
    %set_listing_titles(
        listing_title=&title,
        listing_number=1.1
    );
    
    proc report data=work.demo_list nowd split='|' spacing=1;
        column USUBJID SITE_DISP TRT_DISP AGE_DISP SEX_DISP RACE_DISP 
               COUNTRY_DISP RAND_DATE;
        
        define USUBJID / order "Subject ID" width=15 left;
        define SITE_DISP / display "Site" width=8 left;
        define TRT_DISP / display "Treatment" width=20 left;
        define AGE_DISP / display "Age" width=5 center;
        define SEX_DISP / display "Sex" width=5 center;
        define RACE_DISP / display "Race" width=15 left;
        define COUNTRY_DISP / display "Country" width=12 left;
        define RAND_DATE / display "Randomization|Date" width=12 center;
        
        break after TRT01PN / skip;
        
        compute before TRT01PN;
            line @1 "Treatment Group: " TRT_DISP;
            line @1 " ";
        endcomp;
    run;
    
    ods rtf close;
    
    %put NOTE: Demographics listing created: &output_file..rtf;
    
%mend create_demographics_listing;

/******************************************************************************
SECTION 3: ADVERSE EVENT LISTINGS
******************************************************************************/

/******************************************************************************
MACRO: create_ae_listing
PURPOSE: Generate adverse events listing
PARAMETERS:
  adsl_data= : ADSL dataset
  adae_data= : ADAE dataset  
  ae_type= : Type of AEs (ALL, SAE, RELATED, LEADING_TO_DC)
  output_file= : Output file name
******************************************************************************/
%macro create_ae_listing(
    adsl_data=,
    adae_data=,
    ae_type=ALL,
    output_file=AE_Listing
);
    
    %put NOTE: Creating adverse events listing for &ae_type;
    
    /* Filter AEs based on type */
    data work.ae_subset;
        set &adae_data;
        
        /* Apply filters based on AE type */
        %if &ae_type = SAE %then %do;
            where SAFFL = 'Y' and TEAEFL = 'Y' and upcase(AESER) = 'Y';
        %end;
        %else %if &ae_type = RELATED %then %do;
            where SAFFL = 'Y' and TEAEFL = 'Y' and 
                  upcase(AREL) in ('POSSIBLY RELATED', 'PROBABLY RELATED', 'RELATED');
        %end;
        %else %if &ae_type = LEADING_TO_DC %then %do;
            where SAFFL = 'Y' and TEAEFL = 'Y' and 
                  upcase(AEACN) in ('DRUG WITHDRAWN', 'DRUG INTERRUPTED');
        %end;
        %else %do;
            where SAFFL = 'Y' and TEAEFL = 'Y';
        %end;
    run;
    
    /* Merge with ADSL for treatment information */
    proc sql;
        create table work.ae_list as
        select a.USUBJID, a.AESEQ, a.AETERM, a.AEDECOD, a.AESOC,
               a.AESTDT, a.AEENDT, a.AESEV, a.AREL, a.AESER, a.AEOUT, a.AEACN,
               a.AETOXGR, a.ASTDT, a.AENDT,
               b.TRT01A, b.TRT01AN, b.SITEID
        from work.ae_subset as a
        left join &adsl_data as b
        on a.USUBJID = b.USUBJID
        order by b.TRT01AN, a.USUBJID, a.ASTDT, a.AESEQ;
    quit;
    
    /* Format variables for display */
    data work.ae_list_fmt;
        set work.ae_list;
        
        length ONSET_DATE END_DATE $10;
        length DURATION_DAYS $8;
        length OUTCOME_DISP $15;
        length ACTION_DISP $15;
        
        /* Format dates */
        if not missing(ASTDT) then ONSET_DATE = put(ASTDT, yymmdd10.);
        if not missing(AENDT) then END_DATE = put(AENDT, yymmdd10.);
        
        /* Calculate duration */
        if not missing(ASTDT) and not missing(AENDT) then do;
            duration_num = AENDT - ASTDT + 1;
            DURATION_DAYS = put(duration_num, 3.);
        end;
        else if not missing(ASTDT) then DURATION_DAYS = 'Ongoing';
        
        /* Format outcome and action */
        OUTCOME_DISP = propcase(AEOUT);
        ACTION_DISP = propcase(AEACN);
        
        /* Preferred term and system organ class */
        length PT_DISPLAY $50 SOC_DISPLAY $40;
        PT_DISPLAY = propcase(AEDECOD);
        SOC_DISPLAY = propcase(AESOC);
    run;
    
    /* Generate listing */
    %let title_text = ;
    %if &ae_type = SAE %then %let title_text = Serious Adverse Events;
    %else %if &ae_type = RELATED %then %let title_text = Treatment-Related Adverse Events;
    %else %if &ae_type = LEADING_TO_DC %then %let title_text = AEs Leading to Treatment Discontinuation;
    %else %let title_text = All Treatment-Emergent Adverse Events;
    
    ods rtf file="&output_path/&output_file..rtf" 
        style=minimal
        bodytitle
        fontsize=&font_size;
    
    %set_listing_titles(
        listing_title=&title_text,
        listing_number=2.1
    );
    
    proc report data=work.ae_list_fmt nowd split='|' spacing=1;
        column USUBJID SITEID PT_DISPLAY SOC_DISPLAY ONSET_DATE END_DATE 
               DURATION_DAYS AESEV AREL OUTCOME_DISP ACTION_DISP;
        
        define USUBJID / order "Subject ID" width=15 left;
        define SITEID / display "Site" width=6 center;
        define PT_DISPLAY / display "Preferred Term" width=25 left flow;
        define SOC_DISPLAY / display "System Organ Class" width=20 left flow;
        define ONSET_DATE / display "Onset|Date" width=10 center;
        define END_DATE / display "End|Date" width=10 center;
        define DURATION_DAYS / display "Duration|(Days)" width=8 center;
        define AESEV / display "Severity" width=8 left;
        define AREL / display "Relationship" width=12 left;
        define OUTCOME_DISP / display "Outcome" width=12 left;
        define ACTION_DISP / display "Action Taken" width=12 left;
        
        break after USUBJID / skip;
        
        compute before USUBJID;
            line @1 "Subject: " USUBJID " Site: " SITEID " Treatment: " TRT01A;
        endcomp;
    run;
    
    ods rtf close;
    
    %put NOTE: AE listing created: &output_file..rtf;
    
%mend create_ae_listing;

/******************************************************************************
SECTION 4: CONCOMITANT MEDICATION LISTINGS
******************************************************************************/

/******************************************************************************
MACRO: create_cm_listing
PURPOSE: Generate concomitant medications listing
PARAMETERS:
  adsl_data= : ADSL dataset
  cm_data= : CM SDTM dataset
  output_file= : Output file name
******************************************************************************/
%macro create_cm_listing(
    adsl_data=,
    cm_data=,
    output_file=Concomitant_Medications_Listing
);
    
    %put NOTE: Creating concomitant medications listing;
    
    /* Merge with ADSL and filter for safety population */
    proc sql;
        create table work.cm_list as
        select a.USUBJID, a.CMSEQ, a.CMTRT, a.CMDECOD, a.CMINDC,
               a.CMSTDTC, a.CMENDTC, a.CMDOSE, a.CMDOSU, a.CMROUTE,
               a.CMFREQ, a.CMONGO,
               b.TRT01A, b.TRT01AN, b.SITEID, b.SAFFL
        from &cm_data as a
        left join &adsl_data as b
        on a.USUBJID = b.USUBJID
        where b.SAFFL = 'Y'
        order by b.TRT01AN, a.USUBJID, a.CMSTDTC, a.CMSEQ;
    quit;
    
    /* Format for display */
    data work.cm_list_fmt;
        set work.cm_list;
        
        length START_DATE END_DATE $10;
        length DOSE_DISP $20;
        length INDICATION_DISP $30;
        
        /* Format dates */
        if not missing(input(substr(CMSTDTC, 1, 10), yymmdd10.)) then 
            START_DATE = substr(CMSTDTC, 1, 10);
        if not missing(input(substr(CMENDTC, 1, 10), yymmdd10.)) then 
            END_DATE = substr(CMENDTC, 1, 10);
        else if upcase(CMONGO) = 'Y' then END_DATE = 'Ongoing';
        
        /* Format dose */
        if not missing(CMDOSE) and not missing(CMDOSU) then
            DOSE_DISP = cats(CMDOSE, ' ', CMDOSU);
        else if not missing(CMDOSE) then
            DOSE_DISP = put(CMDOSE, best.);
        
        /* Format indication */
        INDICATION_DISP = propcase(CMINDC);
        
        /* Clean medication name */
        length MED_NAME $50;
        MED_NAME = propcase(CMTRT);
    run;
    
    /* Generate listing */
    ods rtf file="&output_path/&output_file..rtf" 
        style=minimal
        bodytitle
        fontsize=&font_size;
    
    %set_listing_titles(
        listing_title=Concomitant Medications,
        listing_number=3.1
    );
    
    proc report data=work.cm_list_fmt nowd split='|' spacing=1;
        column USUBJID SITEID MED_NAME INDICATION_DISP START_DATE END_DATE 
               DOSE_DISP CMROUTE CMFREQ;
        
        define USUBJID / order "Subject ID" width=15 left;
        define SITEID / display "Site" width=6 center;
        define MED_NAME / display "Medication Name" width=25 left flow;
        define INDICATION_DISP / display "Indication" width=20 left flow;
        define START_DATE / display "Start Date" width=10 center;
        define END_DATE / display "End Date" width=10 center;
        define DOSE_DISP / display "Dose" width=12 left;
        define CMROUTE / display "Route" width=8 left;
        define CMFREQ / display "Frequency" width=12 left;
        
        break after USUBJID / skip;
        
        compute before USUBJID;
            line @1 "Subject: " USUBJID " Site: " SITEID " Treatment: " TRT01A;
        endcomp;
    run;
    
    ods rtf close;
    
    %put NOTE: Concomitant medications listing created: &output_file..rtf;
    
%mend create_cm_listing;

/******************************************************************************
SECTION 5: PROTOCOL DEVIATION LISTINGS
******************************************************************************/

/******************************************************************************
MACRO: create_dv_listing
PURPOSE: Generate protocol deviations listing
PARAMETERS:
  adsl_data= : ADSL dataset
  dv_data= : DV SDTM dataset
  output_file= : Output file name
******************************************************************************/
%macro create_dv_listing(
    adsl_data=,
    dv_data=,
    output_file=Protocol_Deviations_Listing
);
    
    %put NOTE: Creating protocol deviations listing;
    
    /* Merge with ADSL */
    proc sql;
        create table work.dv_list as
        select a.USUBJID, a.DVSEQ, a.DVTERM, a.DVCAT, a.DVSCAT,
               a.DVSTDTC, a.DVENDTC, a.DVDECOD,
               b.TRT01A, b.TRT01AN, b.SITEID, b.SAFFL
        from &dv_data as a
        left join &adsl_data as b
        on a.USUBJID = b.USUBJID
        where b.SAFFL = 'Y'
        order by b.TRT01AN, a.USUBJID, a.DVSTDTC, a.DVSEQ;
    quit;
    
    /* Format for display */
    data work.dv_list_fmt;
        set work.dv_list;
        
        length DEV_DATE $10;
        length CATEGORY_DISP $25;
        length TERM_DISP $40;
        
        /* Format date */
        if not missing(input(substr(DVSTDTC, 1, 10), yymmdd10.)) then 
            DEV_DATE = substr(DVSTDTC, 1, 10);
        
        /* Format category and subcategory */
        if not missing(DVSCAT) then
            CATEGORY_DISP = cats(DVCAT, ': ', DVSCAT);
        else
            CATEGORY_DISP = DVCAT;
        
        /* Format deviation term */
        TERM_DISP = propcase(DVTERM);
    run;
    
    /* Generate listing */
    ods rtf file="&output_path/&output_file..rtf" 
        style=minimal
        bodytitle
        fontsize=&font_size;
    
    %set_listing_titles(
        listing_title=Protocol Deviations,
        listing_number=4.1
    );
    
    proc report data=work.dv_list_fmt nowd split='|' spacing=1;
        column USUBJID SITEID DEV_DATE CATEGORY_DISP TERM_DISP;
        
        define USUBJID / order "Subject ID" width=15 left;
        define SITEID / display "Site" width=6 center;
        define DEV_DATE / display "Date" width=10 center;
        define CATEGORY_DISP / display "Category" width=30 left flow;
        define TERM_DISP / display "Deviation Description" width=40 left flow;
        
        break after USUBJID / skip;
        
        compute before USUBJID;
            line @1 "Subject: " USUBJID " Site: " SITEID " Treatment: " TRT01A;
        endcomp;
    run;
    
    ods rtf close;
    
    %put NOTE: Protocol deviations listing created: &output_file..rtf;
    
%mend create_dv_listing;

/******************************************************************************
SECTION 6: LABORATORY LISTINGS
******************************************************************************/

/******************************************************************************
MACRO: create_lab_listing
PURPOSE: Generate laboratory abnormalities listing
PARAMETERS:
  adlb_data= : ADLB dataset
  abnormal_only= : Y/N flag for abnormal values only
  output_file= : Output file name
******************************************************************************/
%macro create_lab_listing(
    adlb_data=,
    abnormal_only=Y,
    output_file=Laboratory_Abnormalities_Listing
);
    
    %put NOTE: Creating laboratory listing;
    
    /* Filter data */
    data work.lab_list;
        set &adlb_data;
        
        %if &abnormal_only = Y %then %do;
            where SAFFL = 'Y' and (upcase(ANRIND) in ('HIGH', 'LOW', 'ABNORMAL') or
                                  not missing(ABTOXGR) and ABTOXGR ne '0');
        %end;
        %else %do;
            where SAFFL = 'Y';
        %end;
    run;
    
    /* Format for display */
    data work.lab_list_fmt;
        set work.lab_list;
        
        length TEST_DATE $10;
        length VALUE_DISP $15;
        length RANGE_DISP $20;
        
        /* Format date */
        if not missing(ADT) then TEST_DATE = put(ADT, yymmdd10.);
        
        /* Format value with units */
        if not missing(AVAL) and not missing(AVALU) then
            VALUE_DISP = cats(put(AVAL, best12.), ' ', AVALU);
        else if not missing(AVAL) then
            VALUE_DISP = put(AVAL, best12.);
        
        /* Format reference range */
        if not missing(ANRLO) and not missing(ANRHI) then
            RANGE_DISP = cats(put(ANRLO, best8.), '-', put(ANRHI, best8.));
    run;
    
    /* Sort by treatment, subject, parameter, date */
    proc sort data=work.lab_list_fmt;
        by TRT01AN USUBJID PARAM ADT;
    run;
    
    /* Generate listing */
    ods rtf file="&output_path/&output_file..rtf" 
        style=minimal
        bodytitle
        fontsize=&font_size;
    
    %set_listing_titles(
        listing_title=Laboratory Abnormalities,
        listing_number=5.1
    );
    
    proc report data=work.lab_list_fmt nowd split='|' spacing=1;
        column USUBJID PARAM TEST_DATE VALUE_DISP RANGE_DISP ANRIND ABTOXGR;
        
        define USUBJID / order "Subject ID" width=15 left;
        define PARAM / display "Parameter" width=25 left flow;
        define TEST_DATE / display "Test Date" width=10 center;
        define VALUE_DISP / display "Value" width=12 right;
        define RANGE_DISP / display "Reference|Range" width=15 center;
        define ANRIND / display "Range|Indicator" width=8 center;
        define ABTOXGR / display "Toxicity|Grade" width=8 center;
        
        break after USUBJID / skip;
        
        compute before USUBJID;
            line @1 "Subject: " USUBJID " Treatment: " TRT01A;
        endcomp;
    run;
    
    ods rtf close;
    
    %put NOTE: Laboratory listing created: &output_file..rtf;
    
%mend create_lab_listing;

/******************************************************************************
SECTION 7: EXAMPLE USAGE
******************************************************************************/

/*
Example usage of listing templates:

1. Demographics listing:
%create_demographics_listing(
    data=adam.adsl,
    output_file=Demographics_Listing,
    title=Subject Demographics and Baseline Characteristics
);

2. All adverse events:
%create_ae_listing(
    adsl_data=adam.adsl,
    adae_data=adam.adae,
    ae_type=ALL,
    output_file=All_AE_Listing
);

3. Serious adverse events only:
%create_ae_listing(
    adsl_data=adam.adsl,
    adae_data=adam.adae,
    ae_type=SAE,
    output_file=SAE_Listing
);

4. Concomitant medications:
%create_cm_listing(
    adsl_data=adam.adsl,
    cm_data=sdtm.cm,
    output_file=ConMed_Listing
);

5. Protocol deviations:
%create_dv_listing(
    adsl_data=adam.adsl,
    dv_data=sdtm.dv,
    output_file=Protocol_Deviations_Listing
);

6. Laboratory abnormalities:
%create_lab_listing(
    adlb_data=adam.adlb,
    abnormal_only=Y,
    output_file=Lab_Abnormalities_Listing
);
*/

/******************************************************************************
TEMPLATE COMPLETION
******************************************************************************/

%put NOTE: Listing template completed;
%put NOTE: Review all [PLACEHOLDER] values and modify as needed for your study;
%put NOTE: Key areas to customize:;
%put NOTE: - Study parameters (lines 15-19);
%put NOTE: - File paths (lines 21-25);  
%put NOTE: - Listing formatting standards (lines 27-31);
%put NOTE: - Population selection criteria in each macro;
%put NOTE: - Variable names and labels to match your datasets;

/* Log completion */
%put NOTE: Template execution completed at %sysfunc(datetime(), datetime20.);