/******************************************************************************
PROGRAM: audit-trail-examples.sas
PURPOSE: Audit trail and documentation examples for clinical trials
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides comprehensive audit trail and documentation examples
for clinical trials, ensuring 21 CFR Part 11 compliance and regulatory
readiness for inspections and audits.

SECTIONS INCLUDED:
1. Audit Trail Framework Setup
2. Program Execution Tracking
3. Data Change Documentation
4. Output Generation Audit
5. User Activity Logging
6. Compliance Documentation
******************************************************************************/

/******************************************************************************
SECTION 1: AUDIT TRAIL FRAMEWORK SETUP
******************************************************************************/

/******************************************************************************
MACRO: initialize_audit_trail
PURPOSE: Initialize comprehensive audit trail system
PARAMETERS:
  study_id= : Study identifier
  user_name= : Current user name
  project_path= : Project base path
  audit_level= : Level of auditing (BASIC, DETAILED, COMPREHENSIVE)
******************************************************************************/
%macro initialize_audit_trail(
    study_id=,
    user_name=,
    project_path=,
    audit_level=DETAILED
);
    
    %put NOTE: Initializing audit trail system for &study_id;
    
    /* Create global audit variables */
    %global audit_study audit_user audit_path audit_level audit_session_id audit_start_time;
    %let audit_study = &study_id;
    %let audit_user = &user_name;
    %let audit_path = &project_path;
    %let audit_level = &audit_level;
    %let audit_session_id = %sysfunc(compress(%sysfunc(datetime(), hex16.), '.'));
    %let audit_start_time = %sysfunc(datetime(), datetime20.);
    
    /* Create audit directory structure */
    %let rc1 = %sysfunc(dcreate(audit_trail, &audit_path));
    %let rc2 = %sysfunc(dcreate(logs, &audit_path/audit_trail));
    %let rc3 = %sysfunc(dcreate(program_execution, &audit_path/audit_trail));
    %let rc4 = %sysfunc(dcreate(data_changes, &audit_path/audit_trail));
    %let rc5 = %sysfunc(dcreate(output_generation, &audit_path/audit_trail));
    %let rc6 = %sysfunc(dcreate(user_activity, &audit_path/audit_trail));
    
    /* Initialize master audit log */
    data work.master_audit_log;
        length session_id $32 study_id $20 user_name $50 
               timestamp 8 activity_type $50 object_name $100 
               action $50 status $20 details $500
               program_name $200 input_datasets $500 output_datasets $500;
        format timestamp datetime20.;
        delete;
    run;
    
    /* Initialize program execution log */
    data work.program_execution_log;
        length session_id $32 program_name $200 execution_start 8 execution_end 8
               execution_status $20 input_datasets $500 output_datasets $500
               log_file $200 errors_count 8 warnings_count 8 notes_count 8;
        format execution_start execution_end datetime20.;
        delete;
    run;
    
    /* Initialize data change log */
    data work.data_change_log;
        length session_id $32 dataset_name $100 change_type $50
               record_identifier $200 variable_name $32 
               old_value $200 new_value $200 change_reason $500
               timestamp 8;
        format timestamp datetime20.;
        delete;
    run;
    
    /* Log audit trail initialization */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "SYSTEM_INITIALIZATION";
        object_name = "AUDIT_TRAIL_SYSTEM";
        action = "INITIALIZE";
        status = "SUCCESS";
        details = "Audit trail system initialized with level: &audit_level";
        program_name = "audit-trail-examples.sas";
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
    /* Set up automatic logging options */
    options mprint mlogic symbolgen source2 notes;
    %if &audit_level = COMPREHENSIVE %then %do;
        options fullstimer;
    %end;
    
    %put NOTE: Audit trail system initialized for session &audit_session_id;
    
%mend initialize_audit_trail;

/******************************************************************************
SECTION 2: PROGRAM EXECUTION TRACKING
******************************************************************************/

/******************************************************************************
MACRO: start_program_audit
PURPOSE: Begin audit tracking for program execution
PARAMETERS:
  program_name= : Name of program being executed
  program_purpose= : Purpose of the program
  input_datasets= : Input datasets (space-separated)
  expected_outputs= : Expected output datasets (space-separated)
******************************************************************************/
%macro start_program_audit(
    program_name=,
    program_purpose=,
    input_datasets=,
    expected_outputs=
);
    
    %put NOTE: Starting audit for program: &program_name;
    
    /* Create unique program execution ID */
    %global current_program_id;
    %let current_program_id = %sysfunc(compress(%sysfunc(datetime(), hex16.), '.'));
    
    /* Log program start */
    data work.temp_program_start;
        session_id = "&audit_session_id";
        program_execution_id = "&current_program_id";
        program_name = "&program_name";
        program_purpose = "&program_purpose";
        execution_start = datetime();
        execution_status = "RUNNING";
        input_datasets = "&input_datasets";
        expected_outputs = "&expected_outputs";
        user_name = "&audit_user";
        
        /* Validate input datasets */
        length input_validation $500;
        input_validation = "";
        
        %if %length(&input_datasets) > 0 %then %do;
            %let input_count = %sysfunc(countw(&input_datasets));
            %do i = 1 %to &input_count;
                %let input_ds = %scan(&input_datasets, &i);
                %if %sysfunc(exist(&input_ds)) %then %do;
                    input_validation = cats(input_validation, "&input_ds:EXISTS ");
                %end;
                %else %do;
                    input_validation = cats(input_validation, "&input_ds:MISSING ");
                %end;
            %end;
        %end;
    run;
    
    proc append base=work.program_execution_log data=work.temp_program_start;
    run;
    
    /* Log to master audit log */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "PROGRAM_EXECUTION";
        object_name = "&program_name";
        action = "START";
        status = "RUNNING";
        details = "&program_purpose";
        program_name = "&program_name";
        input_datasets = "&input_datasets";
        output_datasets = "&expected_outputs";
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
    %put NOTE: Program audit started for &program_name (ID: &current_program_id);
    
%mend start_program_audit;

/******************************************************************************
MACRO: end_program_audit
PURPOSE: Complete audit tracking for program execution
PARAMETERS:
  execution_status= : Final execution status (SUCCESS, ERROR, WARNING)
  actual_outputs= : Actual outputs generated
  error_count= : Number of errors encountered
  warning_count= : Number of warnings encountered
******************************************************************************/
%macro end_program_audit(
    execution_status=SUCCESS,
    actual_outputs=,
    error_count=0,
    warning_count=0
);
    
    %put NOTE: Ending audit for program execution ID: &current_program_id;
    
    /* Update program execution log */
    data work.program_execution_log;
        set work.program_execution_log;
        
        if program_execution_id = "&current_program_id" then do;
            execution_end = datetime();
            execution_status = "&execution_status";
            actual_outputs = "&actual_outputs";
            errors_count = &error_count;
            warnings_count = &warning_count;
            
            /* Calculate execution time */
            if not missing(execution_start) then
                execution_duration = execution_end - execution_start;
        end;
    run;
    
    /* Validate actual outputs */
    data work.temp_output_validation;
        length output_validation $500;
        output_validation = "";
        
        %if %length(&actual_outputs) > 0 %then %do;
            %let output_count = %sysfunc(countw(&actual_outputs));
            %do i = 1 %to &output_count;
                %let output_ds = %scan(&actual_outputs, &i);
                %if %sysfunc(exist(&output_ds)) %then %do;
                    /* Get record count */
                    %let dsid = %sysfunc(open(&output_ds));
                    %let nobs = %sysfunc(attrn(&dsid, NOBS));
                    %let rc = %sysfunc(close(&dsid));
                    output_validation = cats(output_validation, "&output_ds:&nobs.obs ");
                %end;
                %else %do;
                    output_validation = cats(output_validation, "&output_ds:MISSING ");
                %end;
            %end;
        %end;
    run;
    
    /* Log to master audit log */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "PROGRAM_EXECUTION";
        object_name = strip(scan("&current_program_id", 1, "."));
        action = "END";
        status = "&execution_status";
        details = cats("Execution completed with ", &error_count, " errors and ", 
                      &warning_count, " warnings");
        output_datasets = "&actual_outputs";
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
    %put NOTE: Program audit completed for execution ID: &current_program_id;
    
%mend end_program_audit;

/******************************************************************************
SECTION 3: DATA CHANGE DOCUMENTATION
******************************************************************************/

/******************************************************************************
MACRO: log_data_change
PURPOSE: Log data changes for audit trail
PARAMETERS:
  dataset_name= : Name of dataset being modified
  change_type= : Type of change (INSERT, UPDATE, DELETE, DERIVE)
  record_id= : Record identifier
  variable_name= : Variable being changed
  old_value= : Previous value
  new_value= : New value
  change_reason= : Reason for change
******************************************************************************/
%macro log_data_change(
    dataset_name=,
    change_type=,
    record_id=,
    variable_name=,
    old_value=,
    new_value=,
    change_reason=
);
    
    /* Log data change */
    data work.temp_change;
        session_id = "&audit_session_id";
        dataset_name = "&dataset_name";
        change_type = "&change_type";
        record_identifier = "&record_id";
        variable_name = "&variable_name";
        old_value = "&old_value";
        new_value = "&new_value";
        change_reason = "&change_reason";
        timestamp = datetime();
        user_name = "&audit_user";
        program_execution_id = "&current_program_id";
    run;
    
    proc append base=work.data_change_log data=work.temp_change;
    run;
    
    /* Log to master audit log */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "DATA_CHANGE";
        object_name = "&dataset_name";
        action = "&change_type";
        status = "COMPLETED";
        details = cats("Variable: &variable_name, Record: &record_id, Reason: &change_reason");
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
%mend log_data_change;

/******************************************************************************
MACRO: audit_dataset_creation
PURPOSE: Audit the creation of a new dataset with full metadata
PARAMETERS:
  dataset_name= : Name of dataset created
  source_datasets= : Source datasets used
  derivation_logic= : Description of derivation logic
  record_count= : Number of records created
******************************************************************************/
%macro audit_dataset_creation(
    dataset_name=,
    source_datasets=,
    derivation_logic=,
    record_count=
);
    
    %put NOTE: Auditing dataset creation: &dataset_name;
    
    /* Get dataset metadata if it exists */
    %if %sysfunc(exist(&dataset_name)) %then %do;
        
        /* Get variable count and other metadata */
        proc contents data=&dataset_name out=work.dataset_metadata noprint;
        run;
        
        proc sql noprint;
            select count(*) into :var_count from work.dataset_metadata;
            select count(*) into :actual_record_count from &dataset_name;
        quit;
        
        /* Log dataset creation */
        data work.temp_audit;
            session_id = "&audit_session_id";
            study_id = "&audit_study";
            user_name = "&audit_user";
            timestamp = datetime();
            activity_type = "DATASET_CREATION";
            object_name = "&dataset_name";
            action = "CREATE";
            status = "SUCCESS";
            details = cats("Records: &actual_record_count, Variables: &var_count, ",
                          "Sources: &source_datasets");
            input_datasets = "&source_datasets";
            output_datasets = "&dataset_name";
        run;
        
        proc append base=work.master_audit_log data=work.temp_audit;
        run;
        
        /* Create detailed dataset documentation */
        data work.dataset_documentation;
            length dataset_name $100 variable_name $32 variable_type $10
                   variable_length 8 variable_label $256 derivation_notes $500;
            
            dataset_name = "&dataset_name";
            creation_timestamp = datetime();
            creation_user = "&audit_user";
            source_datasets = "&source_datasets";
            derivation_logic = "&derivation_logic";
            record_count = &actual_record_count;
            variable_count = &var_count;
            
            /* Add variable-level documentation */
            set work.dataset_metadata;
            variable_name = name;
            variable_type = type;
            variable_length = length;
            variable_label = label;
        run;
        
        /* Save documentation */
        data audit_trail.dataset_doc_&audit_study._&dataset_name;
            set work.dataset_documentation;
        run;
        
    %end;
    %else %do;
        /* Log failed dataset creation */
        data work.temp_audit;
            session_id = "&audit_session_id";
            study_id = "&audit_study";
            user_name = "&audit_user";
            timestamp = datetime();
            activity_type = "DATASET_CREATION";
            object_name = "&dataset_name";
            action = "CREATE";
            status = "FAILED";
            details = "Dataset creation failed - dataset does not exist";
        run;
        
        proc append base=work.master_audit_log data=work.temp_audit;
        run;
    %end;
    
%mend audit_dataset_creation;

/******************************************************************************
SECTION 4: OUTPUT GENERATION AUDIT
******************************************************************************/

/******************************************************************************
MACRO: audit_output_generation
PURPOSE: Audit generation of tables, listings, and figures
PARAMETERS:
  output_type= : Type of output (TABLE, LISTING, FIGURE)
  output_name= : Name of output
  output_file= : File path of generated output
  source_dataset= : Source dataset used
  population= : Analysis population
******************************************************************************/
%macro audit_output_generation(
    output_type=,
    output_name=,
    output_file=,
    source_dataset=,
    population=
);
    
    %put NOTE: Auditing &output_type generation: &output_name;
    
    /* Check if output file was created */
    %let file_exists = %sysfunc(fileexist(&output_file));
    %let file_size = 0;
    %if &file_exists %then %do;
        %let file_size = %sysfunc(finfo(%sysfunc(fopen(&output_file)), File Size (bytes)));
        %let rc = %sysfunc(fclose(%sysfunc(fopen(&output_file))));
    %end;
    
    /* Get source dataset information */
    %let source_records = 0;
    %if %sysfunc(exist(&source_dataset)) %then %do;
        proc sql noprint;
            select count(*) into :source_records from &source_dataset;
        quit;
    %end;
    
    /* Log output generation */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "OUTPUT_GENERATION";
        object_name = "&output_name";
        action = "GENERATE_&output_type";
        
        if &file_exists then do;
            status = "SUCCESS";
            details = cats("File created: &output_file, Size: &file_size bytes, ",
                          "Source records: &source_records, Population: &population");
        end;
        else do;
            status = "FAILED";
            details = "Output file was not created";
        end;
        
        input_datasets = "&source_dataset";
        output_datasets = "&output_file";
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
    /* Create output documentation */
    data work.output_documentation;
        length output_name $100 output_type $20 output_file $500
               source_dataset $100 population $50 generation_timestamp 8;
        format generation_timestamp datetime20.;
        
        output_name = "&output_name";
        output_type = "&output_type";
        output_file = "&output_file";
        source_dataset = "&source_dataset";
        population = "&population";
        generation_timestamp = datetime();
        generation_user = "&audit_user";
        file_size = &file_size;
        source_record_count = &source_records;
        generation_status = ifc(&file_exists, "SUCCESS", "FAILED");
    run;
    
    /* Append to output registry */
    proc append base=work.output_registry data=work.output_documentation;
    run;
    
%mend audit_output_generation;

/******************************************************************************
SECTION 5: USER ACTIVITY LOGGING
******************************************************************************/

/******************************************************************************
MACRO: log_user_activity  
PURPOSE: Log user activities for audit trail
PARAMETERS:
  activity= : Activity description
  object= : Object being accessed/modified
  details= : Additional details
******************************************************************************/
%macro log_user_activity(
    activity=,
    object=,
    details=
);
    
    /* Log user activity */
    data work.temp_user_activity;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity = "&activity";
        object_name = "&object";
        activity_details = "&details";
        
        /* System information */
        sas_version = "&sysvlong";
        operating_system = "&sysscp";
        userid = "&sysuserid";
    run;
    
    /* Append to user activity log */
    proc append base=work.user_activity_log data=work.temp_user_activity;
    run;
    
    /* Log to master audit log */
    data work.temp_audit;
        session_id = "&audit_session_id";
        study_id = "&audit_study";
        user_name = "&audit_user";
        timestamp = datetime();
        activity_type = "USER_ACTIVITY";
        object_name = "&object";
        action = "&activity";
        status = "COMPLETED";
        details = "&details";
    run;
    
    proc append base=work.master_audit_log data=work.temp_audit;
    run;
    
%mend log_user_activity;

/******************************************************************************
SECTION 6: COMPLIANCE DOCUMENTATION
******************************************************************************/

/******************************************************************************
MACRO: generate_audit_report
PURPOSE: Generate comprehensive audit trail report
PARAMETERS:
  report_title= : Title for the audit report
  output_file= : Output file name
  include_details= : Include detailed logs (Y/N)
******************************************************************************/
%macro generate_audit_report(
    report_title=Audit Trail Report,
    output_file=audit_trail_report,
    include_details=Y
);
    
    %put NOTE: Generating audit trail report;
    
    /* Create summary statistics */
    proc sql;
        create table work.audit_summary as
        select activity_type,
               count(*) as total_activities,
               sum(case when status = "SUCCESS" then 1 else 0 end) as successful_activities,
               sum(case when status = "FAILED" then 1 else 0 end) as failed_activities,
               sum(case when status = "ERROR" then 1 else 0 end) as error_activities
        from work.master_audit_log
        group by activity_type;
    quit;
    
    /* Generate report */
    ods rtf file="&audit_path/audit_trail/&output_file..rtf" style=minimal;
    
    title1 "&report_title";
    title2 "Study: &audit_study Session: &audit_session_id";
    title3 "User: &audit_user Period: &audit_start_time to %sysfunc(datetime(), datetime20.)";
    title4 "Report Generated: %sysfunc(datetime(), datetime20.)";
    
    /* Executive Summary */
    proc print data=work.audit_summary noobs label;
        title5 "Activity Summary";
        var activity_type total_activities successful_activities failed_activities error_activities;
        label activity_type = "Activity Type"
              total_activities = "Total"
              successful_activities = "Successful"
              failed_activities = "Failed"
              error_activities = "Errors";
    run;
    
    /* Program Execution Summary */
    proc print data=work.program_execution_log label;
        title5 "Program Execution Summary";
        var program_name execution_start execution_end execution_status errors_count warnings_count;
        format execution_start execution_end datetime20.;
        label program_name = "Program Name"
              execution_start = "Start Time"
              execution_end = "End Time"
              execution_status = "Status"
              errors_count = "Errors"
              warnings_count = "Warnings";
    run;
    
    /* Data Changes Summary */
    %if %sysfunc(exist(work.data_change_log)) %then %do;
        proc freq data=work.data_change_log;
            tables change_type / nocum;
            title5 "Data Changes Summary";
        run;
    %end;
    
    /* Failed Activities */
    proc print data=work.master_audit_log;
        where status in ("FAILED", "ERROR");
        title5 "Failed Activities Requiring Attention";
        var timestamp activity_type object_name action details;
        format timestamp datetime20.;
    run;
    
    /* Detailed Activity Log */
    %if &include_details = Y %then %do;
        proc print data=work.master_audit_log;
            title5 "Detailed Activity Log";
            var timestamp activity_type object_name action status details;
            format timestamp datetime20.;
        run;
    %end;
    
    ods rtf close;
    
    /* Export audit trail to permanent datasets */
    data audit_trail.master_audit_&audit_study._&audit_session_id;
        set work.master_audit_log;
    run;
    
    data audit_trail.program_execution_&audit_study._&audit_session_id;
        set work.program_execution_log;
    run;
    
    %if %sysfunc(exist(work.data_change_log)) %then %do;
        data audit_trail.data_changes_&audit_study._&audit_session_id;
            set work.data_change_log;
        run;
    %end;
    
    %put NOTE: Audit trail report generated: &output_file..rtf;
    
%mend generate_audit_report;

/******************************************************************************
SECTION 7: EXAMPLE USAGE
******************************************************************************/

/*
Example audit trail workflow:

1. Initialize audit trail:
%initialize_audit_trail(
    study_id=XYZ-123,
    user_name=John Smith,
    project_path=/path/to/project,
    audit_level=COMPREHENSIVE
);

2. Start program audit:
%start_program_audit(
    program_name=create_adsl.sas,
    program_purpose=Create ADSL analysis dataset,
    input_datasets=sdtm.dm sdtm.ds sdtm.ex,
    expected_outputs=adam.adsl
);

3. Log data changes:
%log_data_change(
    dataset_name=adam.adsl,
    change_type=DERIVE,
    record_id=USUBJID001,
    variable_name=AGEGR1,
    old_value=,
    new_value=65+,
    change_reason=Derived age group based on AGE variable
);

4. Audit dataset creation:
%audit_dataset_creation(
    dataset_name=adam.adsl,
    source_datasets=sdtm.dm sdtm.ds sdtm.ex,
    derivation_logic=Standard ADSL creation per CDISC ADaM guidelines,
    record_count=150
);

5. End program audit:
%end_program_audit(
    execution_status=SUCCESS,
    actual_outputs=adam.adsl,
    error_count=0,
    warning_count=2
);

6. Generate audit report:
%generate_audit_report(
    report_title=Study XYZ-123 Audit Trail Report,
    output_file=xyz123_audit_trail,
    include_details=Y
);
*/

%put NOTE: Audit trail examples loaded successfully;
%put NOTE: Available macros: initialize_audit_trail, start_program_audit, end_program_audit,;
%put NOTE:                  log_data_change, audit_dataset_creation, audit_output_generation,;
%put NOTE:                  log_user_activity, generate_audit_report;