/******************************************************************************
PROGRAM: adam-dataset-template.sas
PURPOSE: Template for creating ADaM analysis datasets
AUTHOR: [Your Name]
DATE: [Creation Date]
VERSION: 1.0

STUDY: [Study ID]
PROTOCOL: [Protocol Number]
DATASET: [Dataset Name - e.g., ADSL, ADAE, ADLB]

MODIFICATIONS:
Date        Author      Description
----------  ----------  --------------------------------------------------
[Date]      [Author]    Initial template creation

NOTES:
- This template follows CDISC ADaM Implementation Guide standards
- Customize macro parameters and variable derivations for your study
- Include appropriate validation and QC checks
- Document all derivation logic and assumptions
******************************************************************************/

/* Set up environment and options */
options nofmterr mprint mlogic symbolgen;

/* Define study-specific macro variables */
%let study_id = [STUDY_ID];
%let protocol = [PROTOCOL_NUMBER];
%let data_cutoff = [DATA_CUTOFF_DATE];
%let adam_lib = [ADAM_LIBRARY_PATH];
%let sdtm_lib = [SDTM_LIBRARY_PATH];
%let output_path = [OUTPUT_PATH];

/* Set library references */
libname adam "&adam_lib";
libname sdtm "&sdtm_lib";

/******************************************************************************
DATASET CREATION MACRO
******************************************************************************/
%macro create_adam_dataset(
    dataset_name=,      /* ADaM dataset name (e.g., ADSL, ADAE) */
    description=,       /* Dataset description */
    source_domains=,    /* Source SDTM domains (space-separated) */
    key_variables=,     /* Key variables for merging */
    debug=N             /* Debug mode (Y/N) */
);

    %put NOTE: Creating ADaM dataset &dataset_name;
    %put NOTE: Description: &description;
    %put NOTE: Source domains: &source_domains;

    /* Step 1: Read and merge source SDTM data */
    data work.source_data;
        %let domain_count = %sysfunc(countw(&source_domains));
        %do i = 1 %to &domain_count;
            %let domain = %scan(&source_domains, &i);
            %if &i = 1 %then %do;
                set sdtm.&domain;
            %end;
            %else %do;
                merge work.source_data(in=a) sdtm.&domain(in=b);
                by &key_variables;
                if a; /* Keep only records from first domain */
            %end;
        %end;
        
        /* Add dataset identifier */
        length studyid $20;
        studyid = "&study_id";
    run;

    /* Step 2: Create standard ADaM variables */
    data work.adam_base;
        set work.source_data;
        
        /* Standard ADaM variables - customize as needed */
        length studyid usubjid subjid $20;
        
        /* Subject identifiers */
        studyid = "&study_id";
        if missing(usubjid) then usubjid = cats(studyid, '-', subjid);
        
        /* Analysis date variables */
        if not missing(--dtc) then do; /* Replace --dtc with actual date variable */
            adt = input(substr(--dtc, 1, 10), yymmdd10.);
            format adt date9.;
        end;
        
        /* Study day calculation */
        if not missing(adt) and not missing(trtsdt) then do;
            if adt >= trtsdt then ady = adt - trtsdt + 1;
            else ady = adt - trtsdt;
        end;
        
        /* Analysis flags - customize based on study requirements */
        length saffl ittfl pprotfl $1;
        
        /* Safety population flag */
        if not missing(trtsdt) then saffl = 'Y';
        else saffl = 'N';
        
        /* ITT population flag */
        if randfl = 'Y' then ittfl = 'Y';
        else ittfl = 'N';
        
        /* Per-protocol population flag - add study-specific criteria */
        pprotfl = 'N'; /* Default to No, customize logic */
        
        /* Labels for variables */
        label studyid = "Study Identifier"
              usubjid = "Unique Subject Identifier"
              subjid = "Subject Identifier for the Study"
              adt = "Analysis Date"
              ady = "Analysis Day"
              saffl = "Safety Population Flag"
              ittfl = "Intent-To-Treat Population Flag"
              pprotfl = "Per-Protocol Population Flag";
    run;

    /* Step 3: Dataset-specific derivations */
    %if &dataset_name = ADSL %then %do;
        %include "&output_path/adsl_derivations.sas";
    %end;
    %else %if &dataset_name = ADAE %then %do;
        %include "&output_path/adae_derivations.sas";
    %end;
    %else %if &dataset_name = ADLB %then %do;
        %include "&output_path/adlb_derivations.sas";
    %end;
    /* Add more dataset-specific logic as needed */

    /* Step 4: Apply formats and final processing */
    data adam.&dataset_name;
        set work.adam_base;
        
        /* Apply study-specific formats */
        format _character_ $200. _numeric_ best12.;
        
        /* Sort by standard keys */
        proc sort;
            by studyid usubjid;
        run;
    run;

    /* Step 5: Generate dataset metadata */
    proc contents data=adam.&dataset_name out=work.contents_&dataset_name noprint;
    run;
    
    /* Step 6: Validation checks */
    %put NOTE: Running validation checks for &dataset_name;
    
    /* Check for required variables */
    %let required_vars = studyid usubjid;
    %do i = 1 %to %sysfunc(countw(&required_vars));
        %let var = %scan(&required_vars, &i);
        proc sql noprint;
            select count(*) into :var_exists
            from work.contents_&dataset_name
            where upcase(name) = upcase("&var");
        quit;
        
        %if &var_exists = 0 %then %do;
            %put ERROR: Required variable &var not found in &dataset_name;
        %end;
    %end;
    
    /* Check for duplicate records */
    proc sql noprint;
        select count(*) as total_records,
               count(distinct usubjid) as unique_subjects
        into :total_recs, :unique_subj
        from adam.&dataset_name;
    quit;
    
    %put NOTE: &dataset_name contains &total_recs records for &unique_subj subjects;
    
    /* Debug output */
    %if &debug = Y %then %do;
        proc print data=adam.&dataset_name(obs=10);
            title "First 10 records of &dataset_name";
        run;
        
        proc freq data=adam.&dataset_name;
            tables saffl ittfl pprotfl / missing;
            title "Population flags in &dataset_name";
        run;
    %end;
    
    /* Clean up work datasets */
    proc datasets library=work nolist;
        delete source_data adam_base contents_&dataset_name;
    quit;
    
    %put NOTE: ADaM dataset &dataset_name creation completed;

%mend create_adam_dataset;

/******************************************************************************
EXAMPLE USAGE - CUSTOMIZE FOR YOUR STUDY
******************************************************************************/

/*
%create_adam_dataset(
    dataset_name=ADSL,
    description=Subject-Level Analysis Dataset,
    source_domains=DM SV DS,
    key_variables=studyid usubjid,
    debug=Y
);

%create_adam_dataset(
    dataset_name=ADAE,
    description=Adverse Events Analysis Dataset,
    source_domains=AE DM,
    key_variables=studyid usubjid,
    debug=Y
);
*/

/******************************************************************************
VALIDATION MACRO - RUN AFTER DATASET CREATION
******************************************************************************/
%macro validate_adam_dataset(dataset=);
    
    %put NOTE: Validating ADaM dataset &dataset;
    
    /* Check dataset exists */
    %if not %sysfunc(exist(adam.&dataset)) %then %do;
        %put ERROR: Dataset adam.&dataset does not exist;
        %return;
    %end;
    
    /* Basic statistics */
    proc sql;
        title "Dataset Summary for &dataset";
        select count(*) as Total_Records,
               count(distinct usubjid) as Unique_Subjects,
               min(adt) as Min_Analysis_Date format=date9.,
               max(adt) as Max_Analysis_Date format=date9.
        from adam.&dataset;
    quit;
    
    /* Missing data summary */
    proc means data=adam.&dataset n nmiss;
        title "Missing Data Summary for &dataset";
    run;
    
    /* Population flag summary */
    proc freq data=adam.&dataset;
        tables saffl ittfl pprotfl / missing;
        title "Population Flags Summary for &dataset";
    run;
    
    %put NOTE: Validation completed for &dataset;
    
%mend validate_adam_dataset;

/******************************************************************************
TEMPLATE CUSTOMIZATION NOTES:

1. Replace all [PLACEHOLDER] values with study-specific information
2. Customize source domains and key variables for each dataset type  
3. Add study-specific derivation logic in the dataset-specific sections
4. Update population flag derivations based on study protocol
5. Add additional validation checks as needed
6. Include proper documentation and version control
7. Test thoroughly with sample data before production use

QUALITY CONTROL CHECKLIST:
□ All placeholders replaced with actual values
□ Source domains and variables verified
□ Population flags logic reviewed and approved
□ Validation checks added and tested
□ Code reviewed by independent programmer
□ Output datasets meet ADaM standards
□ Documentation complete and accurate
******************************************************************************/