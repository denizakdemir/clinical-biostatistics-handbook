/******************************************************************************
PROGRAM: environment-setup.sas
PURPOSE: Standard environment setup for clinical biostatistics projects
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides a standardized setup for clinical biostatistics projects,
including library assignments, global options, format definitions, and 
macro variable initialization.

SECTIONS INCLUDED:
1. Global SAS Options Setup
2. Library Reference Setup
3. Clinical Trial Format Definitions
4. Global Macro Variables
5. Validation and Quality Control Setup
6. Output Destinations Setup
******************************************************************************/

/******************************************************************************
SECTION 1: GLOBAL SAS OPTIONS SETUP
******************************************************************************/

/* Standard SAS options for clinical trials */
options nodate nonumber
        orientation=landscape 
        papersize=letter
        leftmargin=0.5in rightmargin=0.5in
        topmargin=0.75in bottommargin=0.75in
        formchar="|----|+|---+=|-/\\<>*"
        missing=' '
        fmterr
        mprint mlogic symbolgen
        compress=yes
        reuse=yes
        bufno=20
        bufsize=64k;

/* Suppress certain notes and warnings */
options nonotes;
options notes;

/* Error handling */
options errorabend;
options cleanup;

/* Set locale for international studies */
options locale=en_US;

/* Set random seed for reproducibility */
options seed=12345;

%put NOTE: Standard SAS options set for clinical trials;

/******************************************************************************
SECTION 2: LIBRARY REFERENCE SETUP
******************************************************************************/

/******************************************************************************
MACRO: setup_libraries
PURPOSE: Set up standard library references for clinical projects
PARAMETERS:
  project_root= : Root directory for the project
  study_id= : Study identifier for folder naming
******************************************************************************/
%macro setup_libraries(project_root=, study_id=);
    
    %put NOTE: Setting up library references for study &study_id;
    
    /* Define standard paths */
    %global g_project_root g_study_id;
    %let g_project_root = &project_root;
    %let g_study_id = &study_id;
    
    /* Raw data library */
    %if %sysfunc(exist(&project_root/data/raw)) %then %do;
        libname rawdata "&project_root/data/raw";
        %put NOTE: Raw data library assigned: &project_root/data/raw;
    %end;
    
    /* SDTM library */
    %if %sysfunc(exist(&project_root/data/sdtm)) %then %do;
        libname sdtm "&project_root/data/sdtm";
        %put NOTE: SDTM library assigned: &project_root/data/sdtm;
    %end;
    
    /* ADaM library */
    %if %sysfunc(exist(&project_root/data/adam)) %then %do;
        libname adam "&project_root/data/adam";
        %put NOTE: ADaM library assigned: &project_root/data/adam;
    %end;
    
    /* TLF datasets library */
    %if %sysfunc(exist(&project_root/data/tlf)) %then %do;
        libname tlfdata "&project_root/data/tlf";
        %put NOTE: TLF data library assigned: &project_root/data/tlf;
    %end;
    
    /* Output library */
    libname output "&project_root/output";
    %put NOTE: Output library assigned: &project_root/output;
    
    /* Formats library */
    libname formats "&project_root/programs/formats";
    %put NOTE: Formats library assigned: &project_root/programs/formats;
    
    /* Set format search order */
    options fmtsearch=(formats.clinical_formats work library);
    
    /* Validation library for QC programs */
    libname valid "&project_root/validation";
    %put NOTE: Validation library assigned: &project_root/validation;
    
%mend setup_libraries;

/******************************************************************************
SECTION 3: CLINICAL TRIAL FORMAT DEFINITIONS
******************************************************************************/

/******************************************************************************
MACRO: create_clinical_formats
PURPOSE: Create standard formats used in clinical trials
******************************************************************************/
%macro create_clinical_formats();
    
    %put NOTE: Creating standard clinical trial formats;
    
    proc format library=formats.clinical_formats;
        
        /* Treatment formats */
        value $trt01p
            "PLACEBO" = "Placebo"
            "ACTIVE_LOW" = "Active Low Dose"
            "ACTIVE_HIGH" = "Active High Dose"
            "ACTIVE" = "Active Treatment";
            
        value trt01pn
            0 = "Placebo"
            1 = "Active Low Dose"
            2 = "Active High Dose"
            9 = "Active Treatment";
        
        /* Visit formats */
        value $avisit
            "SCREENING" = "Screening"
            "BASELINE" = "Baseline"
            "WEEK 2" = "Week 2"
            "WEEK 4" = "Week 4"
            "WEEK 8" = "Week 8"
            "WEEK 12" = "Week 12"
            "WEEK 24" = "Week 24"
            "END OF TREATMENT" = "End of Treatment"
            "FOLLOW-UP" = "Follow-up";
        
        value avisitn
            -1 = "Screening"
            0 = "Baseline"
            2 = "Week 2"
            4 = "Week 4"
            8 = "Week 8"
            12 = "Week 12"
            24 = "Week 24"
            99 = "End of Treatment"
            999 = "Follow-up";
        
        /* Demographics formats */
        value $sex
            "M" = "Male"
            "F" = "Female"
            "U" = "Unknown";
        
        value $agegr1
            "<65" = "<65 years"
            ">=65" = ">=65 years";
        
        /* Population flag formats */
        value $popfl
            "Y" = "Yes"
            "N" = "No"
            " " = "Missing";
        
        /* Adverse event severity */
        value $aesev
            "MILD" = "Mild"
            "MODERATE" = "Moderate"
            "SEVERE" = "Severe";
        
        /* Relationship to study drug */
        value $aerel
            "NOT RELATED" = "Not Related"
            "UNLIKELY RELATED" = "Unlikely Related"
            "POSSIBLY RELATED" = "Possibly Related"
            "PROBABLY RELATED" = "Probably Related"
            "RELATED" = "Related";
        
        /* Serious AE flag */
        value $aeser
            "Y" = "Yes"
            "N" = "No";
        
        /* Outcome */
        value $aeout
            "RECOVERED/RESOLVED" = "Recovered/Resolved"
            "RECOVERING/RESOLVING" = "Recovering/Resolving"
            "NOT RECOVERED/NOT RESOLVED" = "Not Recovered/Not Resolved"
            "RECOVERED/RESOLVED WITH SEQUELAE" = "Recovered/Resolved with Sequelae"
            "FATAL" = "Fatal"
            "UNKNOWN" = "Unknown";
        
        /* CDISC CNSR format for time-to-event */
        value cnsr
            0 = "Event"
            1 = "Censored";
        
        /* P-value formats */
        value pvalue
            . = " "
            0-<0.001 = "<0.001"
            0.001-<0.01 = "0.001 to <0.01"
            0.01-<0.05 = "0.01 to <0.05"  
            0.05-<0.1 = "0.05 to <0.1"
            0.1-high = "≥0.1";
            
        value pvalue6.4
            . = " "
            0-<0.0001 = "<0.0001"
            other = [6.4];
    
    run;
    
    %put NOTE: Clinical trial formats created successfully;
    
%mend create_clinical_formats;

/******************************************************************************
SECTION 4: GLOBAL MACRO VARIABLES
******************************************************************************/

/******************************************************************************
MACRO: set_global_variables
PURPOSE: Set up global macro variables for the study
PARAMETERS:
  study_id= : Study identifier
  protocol= : Protocol number
  compound= : Study compound name
  indication= : Therapeutic indication
  phase= : Study phase
  data_cutoff= : Data cutoff date
******************************************************************************/
%macro set_global_variables(
    study_id=,
    protocol=,
    compound=,
    indication=,
    phase=,
    data_cutoff=
);
    
    %put NOTE: Setting global macro variables;
    
    /* Study identification */
    %global g_study_id g_protocol g_compound g_indication g_phase;
    %let g_study_id = &study_id;
    %let g_protocol = &protocol;
    %let g_compound = &compound;
    %let g_indication = &indication;
    %let g_phase = &phase;
    
    /* Data cutoff information */
    %global g_data_cutoff g_data_cutoff_fmt;
    %let g_data_cutoff = &data_cutoff;
    %let g_data_cutoff_fmt = %sysfunc(inputn(&data_cutoff, date9.), date9.);
    
    /* Current date/time for footers */
    %global g_current_date g_current_time g_current_datetime;
    %let g_current_date = %sysfunc(today(), date9.);
    %let g_current_time = %sysfunc(time(), time8.);
    %let g_current_datetime = %sysfunc(datetime(), datetime20.);
    
    /* SAS version information */
    %global g_sas_version;
    %let g_sas_version = &sysver;
    
    /* Standard footnote text */
    %global g_standard_footnote;
    %let g_standard_footnote = Generated on &g_current_date at &g_current_time using SAS &g_sas_version;
    
    /* Study title components */
    %global g_study_title;
    %if %length(&compound) > 0 and %length(&indication) > 0 %then %do;
        %let g_study_title = A Phase &phase Study of &compound in &indication;
    %end;
    %else %do;
        %let g_study_title = &study_id;
    %end;
    
    %put NOTE: Global variables set for study &study_id;
    %put NOTE: Study Title: &g_study_title;
    %put NOTE: Data Cutoff: &g_data_cutoff_fmt;
    
%mend set_global_variables;

/******************************************************************************
SECTION 5: VALIDATION AND QUALITY CONTROL SETUP
******************************************************************************/

/******************************************************************************
MACRO: setup_validation_environment
PURPOSE: Set up environment for validation and quality control
******************************************************************************/
%macro setup_validation_environment();
    
    %put NOTE: Setting up validation environment;
    
    /* Create validation log directory */
    %let validation_log_path = &g_project_root/validation/logs;
    %let rc = %sysfunc(dcreate(logs, &g_project_root/validation));
    
    /* Set up validation-specific options */
    options source source2 notes mprint mlogic symbolgen;
    
    /* Global validation flags */
    %global g_validation_mode g_debug_mode g_independent_programming;
    %let g_validation_mode = Y;
    %let g_debug_mode = N;
    %let g_independent_programming = N;
    
    /* Validation metadata */
    %global g_programmer g_reviewer g_validator g_validation_date;
    %let g_programmer = %sysfunc(getoption(sysin));
    %let g_validator = ;
    %let g_validation_date = &g_current_date;
    
    %put NOTE: Validation environment setup completed;
    
%mend setup_validation_environment;

/******************************************************************************
SECTION 6: OUTPUT DESTINATIONS SETUP
******************************************************************************/

/******************************************************************************
MACRO: setup_output_destinations
PURPOSE: Set up standard output destinations for different deliverable types
PARAMETERS:
  output_type= : Type of output (DEVELOPMENT, VALIDATION, SUBMISSION)
******************************************************************************/
%macro setup_output_destinations(output_type=DEVELOPMENT);
    
    %put NOTE: Setting up output destinations for &output_type;
    
    /* Close all existing destinations */
    ods _all_ close;
    
    /* Set up based on output type */
    %if %upcase(&output_type) = DEVELOPMENT %then %do;
        /* Development mode - listing and HTML */
        ods listing;
        ods html path="&g_project_root/output/development" 
                 body="development_output.html"
                 style=statistical;
    %end;
    
    %else %if %upcase(&output_type) = VALIDATION %then %do;
        /* Validation mode - listing only for clean output */
        ods listing path="&g_project_root/output/validation";
    %end;
    
    %else %if %upcase(&output_type) = SUBMISSION %then %do;
        /* Submission mode - RTF and PDF */
        ods rtf path="&g_project_root/output/submission"
                style=styles.rtf;
        ods pdf path="&g_project_root/output/submission"
                style=styles.journal;
    %end;
    
    /* Set graphics options */
    ods graphics / reset=all imagefmt=png width=8in height=6in dpi=300;
    
    %put NOTE: Output destinations configured for &output_type mode;
    
%mend setup_output_destinations;

/******************************************************************************
MAIN SETUP MACRO - CALL THIS TO INITIALIZE EVERYTHING
******************************************************************************/

/******************************************************************************
MACRO: initialize_clinical_environment
PURPOSE: Complete environment initialization for clinical projects
PARAMETERS:
  project_root= : Root directory for the project
  study_id= : Study identifier
  protocol= : Protocol number
  compound= : Study compound name (optional)
  indication= : Therapeutic indication (optional)  
  phase= : Study phase (optional)
  data_cutoff= : Data cutoff date (DDmmmYYYY format)
  output_type= : Output type (DEVELOPMENT, VALIDATION, SUBMISSION)
******************************************************************************/
%macro initialize_clinical_environment(
    project_root=,
    study_id=,
    protocol=,
    compound=,
    indication=,
    phase=,
    data_cutoff=,
    output_type=DEVELOPMENT
);
    
    %put;
    %put ====================================================================;
    %put INITIALIZING CLINICAL BIOSTATISTICS ENVIRONMENT;
    %put Study: &study_id;
    %put Protocol: &protocol;
    %put ====================================================================;
    %put;
    
    /* Step 1: Set up libraries */
    %setup_libraries(project_root=&project_root, study_id=&study_id);
    
    /* Step 2: Create standard formats */
    %create_clinical_formats();
    
    /* Step 3: Set global variables */
    %set_global_variables(
        study_id=&study_id,
        protocol=&protocol,
        compound=&compound,
        indication=&indication,
        phase=&phase,
        data_cutoff=&data_cutoff
    );
    
    /* Step 4: Set up validation environment */
    %setup_validation_environment();
    
    /* Step 5: Configure output destinations */
    %setup_output_destinations(output_type=&output_type);
    
    %put;
    %put ====================================================================;
    %put CLINICAL ENVIRONMENT INITIALIZATION COMPLETED;
    %put Ready for analysis and programming;
    %put ====================================================================;
    %put;
    
%mend initialize_clinical_environment;

/******************************************************************************
EXAMPLE USAGE:

%initialize_clinical_environment(
    project_root=/projects/study_xyz,
    study_id=XYZ-001,
    protocol=XYZ-PROTO-001,
    compound=Compound XYZ,
    indication=Oncology,
    phase=3,
    data_cutoff=15FEB2024,
    output_type=DEVELOPMENT
);

******************************************************************************/

%put NOTE: Clinical environment setup macros loaded successfully;
%put NOTE: Use %initialize_clinical_environment() to set up your project;