# Define-XML Generation Tools and Templates

## Define-XML 2.1 Generation Framework

### SAS-Based Define-XML Generation

```sas
/******************************************************************************
PROGRAM: define_xml_generator.sas
PURPOSE: Generate Define-XML 2.1 files for CDISC submissions
AUTHOR: [Author Name]
DATE: [Date]
******************************************************************************/

%macro generate_define_xml(
    study_name=,
    study_description=,
    protocol_name=,
    data_type=SDTM,  /* SDTM or ADaM */
    input_lib=,
    metadata_lib=work,
    output_path=,
    cdisc_version=SDTM-IG 3.4,
    ct_version=2023-12-29
);

    /* Step 1: Create dataset metadata */
    proc sql;
        create table dataset_metadata as
        select memname as dataset,
               case 
                   when substr(memname,1,2) = 'AD' then 'ANALYSIS'
                   when memname in ('DM','CO','SE') then 'SPECIAL PURPOSE'
                   when memname in ('AE','MH','DV') then 'EVENTS'
                   when memname in ('EX','CM','PR','SU') then 'INTERVENTIONS'
                   when memname in ('LB','VS','EG','PE','SC','QS','MB','PC','PP','FA','MS') then 'FINDINGS'
                   when memname in ('TE','TA','TV','TI','TS','TD') then 'TRIAL DESIGN'
                   else 'OTHER'
               end as class,
               case
                   when substr(memname,1,2) = 'AD' then 'Analysis'
                   else 'Tabulation'
               end as purpose,
               nobs as record_count
        from sashelp.vtable
        where libname = upcase("&input_lib")
        order by memname;
    quit;

    /* Step 2: Extract variable metadata */
    data variable_metadata;
        set sashelp.vcolumn;
        where libname = upcase("&input_lib");
        
        /* Determine origin */
        if index(upcase(name), 'SEQ') then origin = 'Assigned';
        else if name in ('STUDYID','DOMAIN','USUBJID','SUBJID') then origin = 'Assigned';
        else if index(upcase(name), 'DTC') then origin = 'Collected';
        else if index(upcase(name), 'DY') then origin = 'Derived';
        else if substr(name,1,2) = '--' then origin = 'Collected';
        else origin = 'Predecessor';
        
        /* Create basic metadata structure */
        dataset = memname;
        variable = name;
        variable_label = label;
        data_type = case 
            when type = 'char' then 'text'
            when type = 'num' and format in ('DATE9.','YYMMDD10.') then 'date'
            when type = 'num' and index(format,'DATETIME') then 'datetime'
            when type = 'num' then 'integer'
            else 'text'
        end;
        variable_length = length;
        
        keep dataset variable variable_label data_type variable_length origin;
    run;

    /* Step 3: Create controlled terminology references */
    data ct_references;
        length dataset $32 variable $32 codelist $100 codelist_name $200;
        
        /* Standard CDISC CT */
        dataset=''; variable='SEX'; codelist='CL.SEX'; codelist_name='Sex'; output;
        dataset=''; variable='RACE'; codelist='CL.RACE'; codelist_name='Race'; output;
        dataset=''; variable='ETHNIC'; codelist='CL.ETHNIC'; codelist_name='Ethnicity'; output;
        dataset=''; variable='COUNTRY'; codelist='CL.COUNTRY'; codelist_name='Country'; output;
        
        /* Add study-specific controlled terminology as needed */
    run;

    /* Step 4: Generate Define-XML header */
    data _null_;
        file "&output_path/define.xml";
        
        put '<?xml version="1.0" encoding="UTF-8"?>';
        put '<?xml-stylesheet type="text/xsl" href="define2-1-0.xsl"?>';
        put '<ODM xmlns="http://www.cdisc.org/ns/odm/v1.3"';
        put '     xmlns:def="http://www.cdisc.org/ns/def/v2.1"';
        put '     xmlns:xlink="http://www.w3.org/1999/xlink"';
        put '     xmlns:arm="http://www.cdisc.org/ns/arm/v1.0"';
        put '     FileOID="&study_name" FileType="Snapshot"';
        put '     CreationDateTime="' strip(put(datetime(), is8601dt.)) '"';
        put '     ODMVersion="1.3.2" Originator="[Organization]"';
        put '     SourceSystem="SAS" SourceSystemVersion="9.4">';
        put '';
        
        /* Study metadata */
        put '<Study OID="&study_name">';
        put '<GlobalVariables>';
        put '<StudyName>&study_name</StudyName>';
        put '<StudyDescription>&study_description</StudyDescription>';
        put '<ProtocolName>&protocol_name</ProtocolName>';
        put '</GlobalVariables>';
        put '';
        
        /* MetaDataVersion */
        put '<MetaDataVersion OID="CDISC.&data_type.&cdisc_version" Name="&study_name, Data Definitions"';
        put '                 Description="&study_name, Data Definitions"';
        put '                 def:DefineVersion="2.1.0" def:StandardName="&data_type" def:StandardVersion="&cdisc_version">';
        put '';
    run;

    /* Step 5: Generate ItemGroupDefs (Datasets) */
    data _null_;
        set dataset_metadata;
        file "&output_path/define.xml" mod;
        
        put '<ItemGroupDef OID="IG.' dataset +(-1) '" Domain="' dataset +(-1) '" Name="' dataset +(-1) '"';
        put '               Label="' dataset +(-1) '" Repeating="Yes" IsReferenceData="No"';
        put '               SASDatasetName="' dataset +(-1) '" def:Structure="One record per subject per ' dataset +(-1) '"';
        put '               def:Class="' class +(-1) '" Purpose="' purpose +(-1) '">';
        put '<Description><TranslatedText xml:lang="en">' dataset +(-1) '</TranslatedText></Description>';
        
        /* Add ItemRefs - this would need to be generated from variable metadata */
        put '</ItemGroupDef>';
        put '';
    run;

    /* Step 6: Generate ItemDefs (Variables) */
    data _null_;
        set variable_metadata;
        file "&output_path/define.xml" mod;
        
        put '<ItemDef OID="IT.' dataset +(-1) '.' variable +(-1) '" Name="' variable +(-1) '"';
        put '         Label="' strip(variable_label) '"';
        put '         DataType="' data_type +(-1) '" Length="' variable_length +(-1) '">';
        put '<Description><TranslatedText xml:lang="en">' strip(variable_label) '</TranslatedText></Description>';
        put '<def:Origin Type="' origin +(-1) '"/>';
        put '</ItemDef>';
        put '';
    run;

    /* Step 7: Generate CodeLists (Controlled Terminology) */
    data _null_;
        set ct_references end=last;
        file "&output_path/define.xml" mod;
        
        if _n_ = 1 then put '<!-- Controlled Terminology -->';
        
        put '<CodeList OID="' codelist +(-1) '" Name="' codelist_name +(-1) '" DataType="text">';
        put '<Description><TranslatedText xml:lang="en">' codelist_name +(-1) '</TranslatedText></Description>';
        put '<ExternalCodeList Dictionary="' codelist +(-1) '" Version="&ct_version"/>';
        put '</CodeList>';
        put '';
    run;

    /* Step 8: Generate MethodDefs (Computational Methods) */
    data _null_;
        file "&output_path/define.xml" mod;
        
        put '<!-- Computational Methods -->';
        put '<MethodDef OID="MT.AGE" Name="Age Calculation" Type="Computation">';
        put '<Description><TranslatedText xml:lang="en">Age in years at informed consent</TranslatedText></Description>';
        put '<FormalExpression Context="SAS">';
        put 'AGE = FLOOR((RFICDTC - BRTHDTC) / 365.25);';
        put '</FormalExpression>';
        put '</MethodDef>';
        put '';
        
        /* Add more computational methods as needed */
    run;

    /* Step 9: Close Define-XML structure */
    data _null_;
        file "&output_path/define.xml" mod;
        
        put '</MetaDataVersion>';
        put '</Study>';
        put '</ODM>';
    run;

    %put NOTE: Define-XML generated: &output_path/define.xml;

%mend generate_define_xml;

/* Example usage */
%generate_define_xml(
    study_name=ABC-001,
    study_description=A Phase 3 Study of Drug X,
    protocol_name=ABC-001-Protocol,
    data_type=SDTM,
    input_lib=sdtm,
    output_path=/studies/abc001/define
);
```

### Enhanced Define-XML Generator with Metadata Tables

```sas
/******************************************************************************
PROGRAM: enhanced_define_generator.sas
PURPOSE: Enhanced Define-XML generation with pre-built metadata tables
******************************************************************************/

/* Create metadata tables structure */
proc sql;
    /* Dataset metadata table */
    create table dataset_meta
    (dataset char(32),
     label char(256),
     class char(50),
     structure char(200),
     purpose char(20),
     keys char(200),
     location char(200),
     documentation char(500));

    /* Variable metadata table */
    create table variable_meta
    (dataset char(32),
     variable char(32),
     label char(256),
     type char(20),
     length num,
     format char(32),
     origin char(20),
     source char(200),
     predecessor char(100),
     comment char(500),
     codelist char(100),
     mandatory char(1),
     order_number num);

    /* Computational methods table */
    create table computation_methods
    (method_oid char(32),
     method_name char(200),
     method_type char(20),
     description char(500),
     formal_expression char(2000),
     context char(20),
     document_ref char(200));

    /* Value level metadata table */
    create table value_level_meta
    (dataset char(32),
     variable char(32),
     where_clause char(500),
     value char(200),
     value_description char(500),
     origin char(20),
     predecessor char(100));
quit;

/* Populate metadata tables - Example for DM domain */
data dataset_meta;
    dataset='DM'; 
    label='Demographics'; 
    class='SPECIAL PURPOSE';
    structure='One record per subject';
    purpose='Tabulation';
    keys='STUDYID, USUBJID';
    location='dm.xpt';
    documentation='Subject demographic and baseline characteristics';
    output;
    
    dataset='AE'; 
    label='Adverse Events'; 
    class='EVENTS';
    structure='One record per adverse event per subject';
    purpose='Tabulation';
    keys='STUDYID, USUBJID, AESEQ';
    location='ae.xpt';
    documentation='Adverse events occurring during the study';
    output;
run;

data variable_meta;
    /* DM Variables */
    dataset='DM'; variable='STUDYID'; label='Study Identifier'; 
    type='text'; length=32; origin='Assigned'; mandatory='Yes'; order_number=1; output;
    
    dataset='DM'; variable='DOMAIN'; label='Domain Abbreviation'; 
    type='text'; length=2; origin='Assigned'; mandatory='Yes'; order_number=2; output;
    
    dataset='DM'; variable='USUBJID'; label='Unique Subject Identifier'; 
    type='text'; length=40; origin='Assigned'; mandatory='Yes'; order_number=3; output;
    
    dataset='DM'; variable='SUBJID'; label='Subject Identifier for the Study'; 
    type='text'; length=20; origin='Assigned'; mandatory='Yes'; order_number=4; output;
    
    dataset='DM'; variable='RFSTDTC'; label='Subject Reference Start Date/Time'; 
    type='datetime'; length=19; origin='Assigned'; order_number=5; output;
    
    dataset='DM'; variable='RFENDTC'; label='Subject Reference End Date/Time'; 
    type='datetime'; length=19; origin='Assigned'; order_number=6; output;
    
    dataset='DM'; variable='SITEID'; label='Study Site Identifier'; 
    type='text'; length=10; origin='Assigned'; mandatory='Yes'; order_number=7; output;
    
    dataset='DM'; variable='AGE'; label='Age'; 
    type='integer'; length=8; origin='Derived'; predecessor='Birth Date'; 
    comment='Age in years at informed consent'; order_number=8; output;
    
    dataset='DM'; variable='AGEU'; label='Age Units'; 
    type='text'; length=10; origin='Assigned'; codelist='CL.AGEU'; order_number=9; output;
    
    dataset='DM'; variable='SEX'; label='Sex'; 
    type='text'; length=1; origin='Collected'; codelist='CL.SEX'; mandatory='Yes'; order_number=10; output;
    
    dataset='DM'; variable='RACE'; label='Race'; 
    type='text'; length=100; origin='Collected'; codelist='CL.RACE'; order_number=11; output;
    
    dataset='DM'; variable='ETHNIC'; label='Ethnicity'; 
    type='text'; length=100; origin='Collected'; codelist='CL.ETHNIC'; order_number=12; output;
    
    dataset='DM'; variable='ARMCD'; label='Planned Arm Code'; 
    type='text'; length=20; origin='Assigned'; order_number=13; output;
    
    dataset='DM'; variable='ARM'; label='Description of Planned Arm'; 
    type='text'; length=200; origin='Assigned'; order_number=14; output;
    
    dataset='DM'; variable='COUNTRY'; label='Country'; 
    type='text'; length=3; origin='Assigned'; codelist='CL.COUNTRY'; order_number=15; output;
    
    /* Add AE variables */
    dataset='AE'; variable='STUDYID'; label='Study Identifier'; 
    type='text'; length=32; origin='Assigned'; mandatory='Yes'; order_number=1; output;
    
    dataset='AE'; variable='DOMAIN'; label='Domain Abbreviation'; 
    type='text'; length=2; origin='Assigned'; mandatory='Yes'; order_number=2; output;
    
    dataset='AE'; variable='USUBJID'; label='Unique Subject Identifier'; 
    type='text'; length=40; origin='Assigned'; mandatory='Yes'; order_number=3; output;
    
    dataset='AE'; variable='AESEQ'; label='Sequence Number'; 
    type='integer'; length=8; origin='Assigned'; mandatory='Yes'; order_number=4; output;
    
    dataset='AE'; variable='AETERM'; label='Reported Term for the Adverse Event'; 
    type='text'; length=200; origin='Collected'; mandatory='Yes'; order_number=5; output;
    
    dataset='AE'; variable='AEDECOD'; label='Dictionary-Derived Term'; 
    type='text'; length=100; origin='Assigned'; mandatory='Yes'; order_number=6; output;
    
    dataset='AE'; variable='AESOC'; label='Primary System Organ Class'; 
    type='text'; length=100; origin='Assigned'; order_number=7; output;
    
    dataset='AE'; variable='AESEV'; label='Severity/Intensity'; 
    type='text'; length=20; origin='Collected'; codelist='CL.AESEV'; order_number=8; output;
    
    dataset='AE'; variable='AESER'; label='Serious Event'; 
    type='text'; length=1; origin='Collected'; codelist='CL.NY'; order_number=9; output;
    
    dataset='AE'; variable='AEREL'; label='Causality'; 
    type='text'; length=20; origin='Collected'; codelist='CL.AEREL'; order_number=10; output;
    
    dataset='AE'; variable='AESTDTC'; label='Start Date/Time of Adverse Event'; 
    type='datetime'; length=19; origin='Collected'; order_number=11; output;
    
    dataset='AE'; variable='AEENDTC'; label='End Date/Time of Adverse Event'; 
    type='datetime'; length=19; origin='Collected'; order_number=12; output;
run;

/* Computational methods examples */
data computation_methods;
    method_oid='MT.AGE'; 
    method_name='Age Calculation'; 
    method_type='Computation';
    description='Calculate age in years based on birth date and informed consent date';
    formal_expression='AGE = FLOOR((RFICDTC - BRTHDTC) / 365.25);';
    context='SAS';
    output;
    
    method_oid='MT.STUDYDAY'; 
    method_name='Study Day Calculation'; 
    method_type='Computation';
    description='Calculate study day relative to reference start date';
    formal_expression='DY = DATE - RFSTDTC + (DATE >= RFSTDTC);';
    context='SAS';
    output;
run;

%macro create_define_xml_v21(
    study_name=,
    study_desc=,
    metadata_version=CDISC-SDTM-3.4,
    output_file=
);

    data _null_;
        file "&output_file";
        
        /* XML Header */
        put '<?xml version="1.0" encoding="UTF-8"?>';
        put '<?xml-stylesheet type="text/xsl" href="define2-1-0.xsl"?>';
        put '<ODM xmlns="http://www.cdisc.org/ns/odm/v1.3"';
        put '     xmlns:def="http://www.cdisc.org/ns/def/v2.1"';
        put '     xmlns:xlink="http://www.w3.org/1999/xlink"';
        put '     xmlns:arm="http://www.cdisc.org/ns/arm/v1.0"';
        put '     FileOID="' "&study_name" +(-1) '.define.xml"';
        put '     FileType="Snapshot"';
        put '     CreationDateTime="' strip(put(datetime(), is8601dt.)) +(-1) '"';
        put '     ODMVersion="1.3.2"';
        put '     Originator="Clinical Data Management System"';
        put '     SourceSystem="SAS" SourceSystemVersion="9.4">';
        put '';
        
        /* Study */
        put '<Study OID="' "&study_name" +(-1) '">';
        put '<GlobalVariables>';
        put '<StudyName>' "&study_name" +(-1) '</StudyName>';
        put '<StudyDescription>' "&study_desc" +(-1) '</StudyDescription>';
        put '<ProtocolName>' "&study_name" +(-1) '</ProtocolName>';
        put '</GlobalVariables>';
        put '';
        
        /* MetaDataVersion */
        put '<MetaDataVersion OID="' "&metadata_version" +(-1) '"';
        put '                 Name="' "&study_name" +(-1) ', Data Definitions"';
        put '                 Description="' "&study_name" +(-1) ', Data Definitions"';
        put '                 def:DefineVersion="2.1.0"';
        put '                 def:StandardName="SDTM"';
        put '                 def:StandardVersion="3.4">';
        put '';
    run;

    /* Generate ItemGroupDefs from dataset metadata */
    proc sort data=dataset_meta;
        by dataset;
    run;

    data _null_;
        set dataset_meta;
        file "&output_file" mod;
        
        put '<ItemGroupDef OID="IG.' dataset +(-1) '"';
        put '               Domain="' dataset +(-1) '"';
        put '               Name="' dataset +(-1) '"';
        put '               Label="' strip(label) +(-1) '"';
        put '               Repeating="Yes"';
        put '               IsReferenceData="No"';
        put '               SASDatasetName="' dataset +(-1) '"';
        put '               def:Structure="' strip(structure) +(-1) '"';
        put '               def:Class="' strip(class) +(-1) '"';
        put '               Purpose="' purpose +(-1) '">';
        put '<Description>';
        put '<TranslatedText xml:lang="en">' strip(documentation) '</TranslatedText>';
        put '</Description>';
        
        /* Add def:leaf for dataset location */
        put '<def:leaf ID="LF.' dataset +(-1) '">';
        put '<def:title>' strip(label) '</def:title>';
        put '</def:leaf>';
    run;

    /* Add ItemRefs for each dataset */
    proc sort data=variable_meta;
        by dataset order_number;
    run;

    data _null_;
        set variable_meta;
        by dataset;
        file "&output_file" mod;
        
        if first.dataset then do;
            put '';
            put '<!-- ItemRefs for ' dataset ' -->';
        end;
        
        put '<ItemRef ItemOID="IT.' dataset +(-1) '.' variable +(-1) '"';
        put '         OrderNumber="' order_number +(-1) '"';
        if mandatory = 'Yes' then put '         Mandatory="Yes"';
        else put '         Mandatory="No"';
        if not missing(codelist) then put '         CodeListRef="' codelist +(-1) '"';
        put '/>';
        
        if last.dataset then do;
            put '</ItemGroupDef>';
            put '';
        end;
    run;

    /* Generate ItemDefs */
    proc sort data=variable_meta;
        by dataset variable;
    run;

    data _null_;
        set variable_meta;
        file "&output_file" mod;
        
        put '<ItemDef OID="IT.' dataset +(-1) '.' variable +(-1) '"';
        put '         Name="' variable +(-1) '"';
        put '         Label="' strip(label) +(-1) '"';
        put '         DataType="' type +(-1) '"';
        if length > 0 then put '         Length="' length +(-1) '"';
        put '>';
        
        put '<Description>';
        put '<TranslatedText xml:lang="en">' strip(label) '</TranslatedText>';
        put '</Description>';
        
        put '<def:Origin Type="' origin +(-1) '"';
        if not missing(source) then put ' Source="' strip(source) +(-1) '"';
        put '>';
        if not missing(predecessor) then do;
            put '<def:Description>';
            put '<TranslatedText xml:lang="en">Derived from ' strip(predecessor) '</TranslatedText>';
            put '</def:Description>';
        end;
        put '</def:Origin>';
        
        if not missing(comment) then do;
            put '<def:Comment>';
            put '<Description>';
            put '<TranslatedText xml:lang="en">' strip(comment) '</TranslatedText>';
            put '</Description>';
            put '</def:Comment>';
        end;
        
        put '</ItemDef>';
        put '';
    run;

    /* Generate CodeLists */
    data _null_;
        file "&output_file" mod;
        
        put '<!-- Code Lists -->';
        put '<CodeList OID="CL.SEX" Name="Sex" DataType="text">';
        put '<Description><TranslatedText xml:lang="en">Sex</TranslatedText></Description>';
        put '<EnumeratedItem CodedValue="F">';
        put '<Decode><TranslatedText xml:lang="en">Female</TranslatedText></Decode>';
        put '</EnumeratedItem>';
        put '<EnumeratedItem CodedValue="M">';
        put '<Decode><TranslatedText xml:lang="en">Male</TranslatedText></Decode>';
        put '</EnumeratedItem>';
        put '<EnumeratedItem CodedValue="U">';
        put '<Decode><TranslatedText xml:lang="en">Unknown</TranslatedText></Decode>';
        put '</EnumeratedItem>';
        put '</CodeList>';
        put '';
        
        put '<CodeList OID="CL.NY" Name="No Yes Response" DataType="text">';
        put '<Description><TranslatedText xml:lang="en">No Yes Response</TranslatedText></Description>';
        put '<EnumeratedItem CodedValue="N">';
        put '<Decode><TranslatedText xml:lang="en">No</TranslatedText></Decode>';
        put '</EnumeratedItem>';
        put '<EnumeratedItem CodedValue="Y">';
        put '<Decode><TranslatedText xml:lang="en">Yes</TranslatedText></Decode>';
        put '</EnumeratedItem>';
        put '</CodeList>';
        put '';
    run;

    /* Generate MethodDefs */
    data _null_;
        set computation_methods;
        file "&output_file" mod;
        
        put '<MethodDef OID="' method_oid +(-1) '"';
        put '           Name="' strip(method_name) +(-1) '"';
        put '           Type="' method_type +(-1) '">';
        put '<Description>';
        put '<TranslatedText xml:lang="en">' strip(description) '</TranslatedText>';
        put '</Description>';
        put '<FormalExpression Context="' context +(-1) '">';
        put strip(formal_expression);
        put '</FormalExpression>';
        put '</MethodDef>';
        put '';
    run;

    /* Close XML structure */
    data _null_;
        file "&output_file" mod;
        
        put '</MetaDataVersion>';
        put '</Study>';
        put '</ODM>';
    run;

    %put NOTE: Define-XML 2.1 file created: &output_file;

%mend create_define_xml_v21;

/* Execute the macro */
%create_define_xml_v21(
    study_name=ABC-001,
    study_desc=Phase 3 Study of Drug X versus Placebo,
    metadata_version=CDISC-SDTM-3.4,
    output_file=/studies/abc001/define/define.xml
);
```

## R-Based Define-XML Generation

### Using {defineXML} R Package

```r
# Define-XML Generation in R
library(defineXML)
library(dplyr)
library(readr)

# Create dataset metadata
dataset_metadata <- tibble(
  dataset = c("DM", "AE", "LB", "EX"),
  label = c("Demographics", "Adverse Events", "Laboratory Test Results", "Exposure"),
  class = c("SPECIAL PURPOSE", "EVENTS", "FINDINGS", "INTERVENTIONS"),
  structure = c(
    "One record per subject",
    "One record per adverse event per subject", 
    "One record per subject per laboratory test per time point",
    "One record per subject per exposure"
  ),
  purpose = rep("Tabulation", 4),
  comment = c(
    "Demographics and baseline characteristics",
    "Adverse events from first dose through safety follow-up",
    "Laboratory test results from scheduled and unscheduled visits",
    "Study drug exposure records"
  )
)

# Create variable metadata
variable_metadata <- tibble(
  dataset = c(rep("DM", 8), rep("AE", 6), rep("LB", 8)),
  variable = c(
    "STUDYID", "DOMAIN", "USUBJID", "SUBJID", "RFSTDTC", "SITEID", "AGE", "SEX",
    "STUDYID", "DOMAIN", "USUBJID", "AESEQ", "AETERM", "AEDECOD", 
    "STUDYID", "DOMAIN", "USUBJID", "LBSEQ", "LBTESTCD", "LBTEST", "LBSTRESN", "LBSTRESU"
  ),
  label = c(
    "Study Identifier", "Domain Abbreviation", "Unique Subject Identifier", 
    "Subject Identifier for the Study", "Subject Reference Start Date/Time", 
    "Study Site Identifier", "Age", "Sex",
    "Study Identifier", "Domain Abbreviation", "Unique Subject Identifier",
    "Sequence Number", "Reported Term for the Adverse Event", "Dictionary-Derived Term",
    "Study Identifier", "Domain Abbreviation", "Unique Subject Identifier",
    "Sequence Number", "Lab Test Short Name", "Lab Test Name", 
    "Numeric Result/Finding in Standard Units", "Standard Units"
  ),
  type = c(
    rep("text", 4), "datetime", "text", "integer", "text",
    rep("text", 6),
    rep("text", 4), "text", "text", "float", "text"
  ),
  length = c(32, 2, 40, 20, 19, 10, 8, 1, 
            32, 2, 40, 8, 200, 100,
            32, 2, 40, 8, 8, 200, 8, 20),
  origin = c(
    rep("Assigned", 4), "Assigned", "Assigned", "Derived", "Collected",
    rep("Assigned", 4), "Collected", "Assigned",
    rep("Assigned", 4), rep("Collected", 2), "Collected", "Collected"
  ),
  mandatory = c(
    rep("Yes", 4), rep("No", 4),
    rep("Yes", 4), rep("Yes", 2),
    rep("Yes", 6), rep("No", 2)
  )
)

# Create controlled terminology
codelist_metadata <- tibble(
  codelist_oid = c("CL.SEX", "CL.RACE", "CL.ETHNIC", "CL.NY"),
  codelist_name = c("Sex", "Race", "Ethnicity", "No Yes Response"),
  data_type = rep("text", 4),
  items = list(
    tibble(coded_value = c("F", "M", "U"), decode = c("Female", "Male", "Unknown")),
    tibble(coded_value = c("WHITE", "BLACK OR AFRICAN AMERICAN", "ASIAN", "OTHER"), 
           decode = c("White", "Black or African American", "Asian", "Other")),
    tibble(coded_value = c("HISPANIC OR LATINO", "NOT HISPANIC OR LATINO", "NOT REPORTED"), 
           decode = c("Hispanic or Latino", "Not Hispanic or Latino", "Not Reported")),
    tibble(coded_value = c("N", "Y"), decode = c("No", "Yes"))
  )
)

# Generate Define-XML
define_xml_content <- create_define_xml(
  study_name = "ABC-001",
  study_description = "A Phase 3, Randomized Study of Drug X",
  protocol_name = "ABC-001",
  standard_name = "SDTM",
  standard_version = "3.4",
  dataset_metadata = dataset_metadata,
  variable_metadata = variable_metadata,
  codelist_metadata = codelist_metadata
)

# Write to file
write_lines(define_xml_content, "/studies/abc001/define/define.xml")
```

## Define-XML Validation Tools

### XML Schema Validation

```python
# Python script for Define-XML validation
import xml.etree.ElementTree as ET
from lxml import etree
import requests

def validate_define_xml(xml_file, schema_url=None):
    """
    Validate Define-XML against schema
    """
    if schema_url is None:
        schema_url = "https://www.cdisc.org/sites/default/files/2021-03/define2-1-0.xsd"
    
    try:
        # Load XML document
        xml_doc = etree.parse(xml_file)
        
        # Load XSD schema
        schema_response = requests.get(schema_url)
        schema_doc = etree.fromstring(schema_response.content)
        schema = etree.XMLSchema(schema_doc)
        
        # Validate
        if schema.validate(xml_doc):
            print(f"✓ {xml_file} is valid according to Define-XML 2.1 schema")
            return True
        else:
            print(f"✗ {xml_file} validation errors:")
            for error in schema.error_log:
                print(f"  Line {error.line}: {error.message}")
            return False
            
    except Exception as e:
        print(f"Error validating {xml_file}: {str(e)}")
        return False

# Usage
validate_define_xml("/studies/abc001/define/define.xml")
```

### SAS Define-XML Validation

```sas
/******************************************************************************
PROGRAM: validate_define_xml.sas
PURPOSE: Validate Define-XML content against datasets
******************************************************************************/

%macro validate_define_xml(
    define_file=,
    dataset_lib=,
    output_file=
);

    /* Read Define-XML using SAS XML engine */
    libname definexml xmlv2 "&define_file" xmlmap=define21map;
    
    /* Extract dataset information from Define-XML */
    data define_datasets;
        set definexml.itemgroupdefs;
        dataset = name;
        define_label = label;
        keep dataset define_label;
    run;
    
    /* Extract variable information from Define-XML */
    data define_variables;
        set definexml.itemdefs;
        variable = name;
        define_label = label;
        define_type = datatype;
        define_length = length;
        keep variable define_label define_type define_length;
    run;
    
    /* Get actual dataset information */
    proc contents data=&dataset_lib.._all_ out=actual_datasets noprint;
    run;
    
    data actual_summary;
        set actual_datasets;
        dataset = memname;
        variable = name;
        actual_label = label;
        actual_type = case when type = 1 then 'integer' else 'text' end;
        actual_length = length;
        keep dataset variable actual_label actual_type actual_length;
    run;
    
    /* Compare Define-XML vs actual datasets */
    proc sql;
        create table validation_results as
        select a.dataset,
               a.variable,
               a.define_label,
               b.actual_label,
               a.define_type,
               b.actual_type,
               a.define_length,
               b.actual_length,
               case 
                   when missing(b.variable) then 'Variable in Define-XML but not in dataset'
                   when missing(a.variable) then 'Variable in dataset but not in Define-XML'
                   when a.define_type ne b.actual_type then 'Data type mismatch'
                   when a.define_length ne b.actual_length then 'Length mismatch'
                   when a.define_label ne b.actual_label then 'Label mismatch'
                   else 'Match'
               end as validation_status
        from define_variables a
        full join actual_summary b
        on a.variable = b.variable;
    quit;
    
    /* Output validation results */
    proc freq data=validation_results;
        tables validation_status / missing;
        title "Define-XML Validation Summary";
    run;
    
    proc print data=validation_results(where=(validation_status ne 'Match'));
        title "Define-XML Validation Issues";
    run;
    
    /* Export results if output file specified */
    %if %length(&output_file) > 0 %then %do;
        proc export data=validation_results
                    outfile="&output_file"
                    dbms=xlsx replace;
        run;
    %end;

%mend validate_define_xml;

/* Execute validation */
%validate_define_xml(
    define_file=/studies/abc001/define/define.xml,
    dataset_lib=sdtm,
    output_file=/studies/abc001/define/validation_results.xlsx
);
```

## Stylesheet and Display Tools

### Custom Define-XML Stylesheet

```xsl
<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" 
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:def="http://www.cdisc.org/ns/def/v2.1"
    xmlns:odm="http://www.cdisc.org/ns/odm/v1.3">
    
<xsl:template match="/">
<html>
<head>
    <title>Define-XML 2.1 Documentation</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #003366; border-bottom: 2px solid #003366; }
        h2 { color: #0066CC; border-bottom: 1px solid #0066CC; }
        table { border-collapse: collapse; width: 100%; margin: 10px 0; }
        th { background-color: #E6F3FF; padding: 8px; border: 1px solid #ccc; }
        td { padding: 8px; border: 1px solid #ccc; }
        .dataset-header { background-color: #F0F8FF; }
        .method { background-color: #FFFACD; margin: 10px 0; padding: 10px; }
    </style>
</head>
<body>
    <h1>Study Data Definition Document</h1>
    
    <h2>Study Information</h2>
    <table>
        <tr><th>Study Name</th><td><xsl:value-of select="//odm:StudyName"/></td></tr>
        <tr><th>Study Description</th><td><xsl:value-of select="//odm:StudyDescription"/></td></tr>
        <tr><th>Protocol Name</th><td><xsl:value-of select="//odm:ProtocolName"/></td></tr>
        <tr><th>Standard</th><td><xsl:value-of select="//@def:StandardName"/> <xsl:value-of select="//@def:StandardVersion"/></td></tr>
        <tr><th>Creation Date</th><td><xsl:value-of select="//@CreationDateTime"/></td></tr>
    </table>
    
    <h2>Datasets</h2>
    <xsl:for-each select="//odm:ItemGroupDef">
        <div class="dataset-header">
            <h3><xsl:value-of select="@Name"/> - <xsl:value-of select="@Label"/></h3>
            <p><strong>Class:</strong> <xsl:value-of select="@def:Class"/></p>
            <p><strong>Structure:</strong> <xsl:value-of select="@def:Structure"/></p>
            <p><strong>Purpose:</strong> <xsl:value-of select="@Purpose"/></p>
        </div>
        
        <table>
            <tr>
                <th>Order</th><th>Variable</th><th>Label</th><th>Type</th>
                <th>Length</th><th>Origin</th><th>Mandatory</th>
            </tr>
            <xsl:for-each select="odm:ItemRef">
                <xsl:variable name="itemoid" select="@ItemOID"/>
                <xsl:for-each select="//odm:ItemDef[@OID=$itemoid]">
                <tr>
                    <td><xsl:value-of select="../@OrderNumber"/></td>
                    <td><xsl:value-of select="@Name"/></td>
                    <td><xsl:value-of select="@Label"/></td>
                    <td><xsl:value-of select="@DataType"/></td>
                    <td><xsl:value-of select="@Length"/></td>
                    <td><xsl:value-of select="def:Origin/@Type"/></td>
                    <td><xsl:value-of select="../@Mandatory"/></td>
                </tr>
                </xsl:for-each>
            </xsl:for-each>
        </table>
    </xsl:for-each>
    
    <h2>Computational Methods</h2>
    <xsl:for-each select="//odm:MethodDef">
        <div class="method">
            <h4><xsl:value-of select="@Name"/></h4>
            <p><xsl:value-of select="odm:Description/odm:TranslatedText"/></p>
            <pre><xsl:value-of select="odm:FormalExpression"/></pre>
        </div>
    </xsl:for-each>
    
</body>
</html>
</xsl:template>
</xsl:stylesheet>
```

## Best Practices and Tips

### Define-XML Quality Checklist

```
□ XML Structure and Validation
  □ Valid XML syntax
  □ Schema validation passes
  □ Required elements present
  □ Proper namespace declarations

□ Study Metadata
  □ Study name and description accurate
  □ Protocol name matches submission
  □ Standard name and version correct
  □ Creation date current

□ Dataset Documentation
  □ All datasets documented
  □ Dataset classes assigned correctly
  □ Structure descriptions accurate
  □ Purpose values appropriate

□ Variable Documentation  
  □ All variables documented
  □ Labels match dataset contents
  □ Data types correct
  □ Lengths match actual data
  □ Origins assigned appropriately

□ Computational Methods
  □ All derivations documented
  □ SAS code syntax correct
  □ Method descriptions clear
  □ References to external documents

□ Controlled Terminology
  □ Code lists complete
  □ External dictionaries referenced
  □ Version information current
  □ Custom terminology documented

□ Cross-References
  □ ItemRefs match ItemDefs
  □ CodeListRefs valid
  □ MethodRefs valid
  □ WhereClause references correct
```

### Common Define-XML Issues and Solutions

| Issue | Solution |
|-------|----------|
| Invalid XML characters | Use CDATA sections or encode special characters |
| Missing mandatory elements | Check schema requirements for each element type |
| Incorrect data types | Verify mapping between SAS and XML data types |
| Missing computational methods | Document all derived variables with MethodDefs |
| Inconsistent variable names | Ensure Define-XML matches actual dataset variables |
| Missing controlled terminology | Include all code lists referenced by variables |

---

*These Define-XML tools and templates should be customized based on specific study requirements, organizational standards, and current CDISC Define-XML specifications.*