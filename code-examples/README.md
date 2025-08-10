# Code Examples

This directory contains practical SAS code examples, macro libraries, and implementation guides for clinical biostatistics tasks.

## Contents

### 📊 SAS Macro Libraries
- [clinical-macros.sas](clinical-macros.sas) - Essential macros for clinical trial analysis
- [adam-macros.sas](adam-macros.sas) - ADaM dataset creation and validation macros
- [table-macros.sas](table-macros.sas) - Table, listing, and figure generation macros
- [qc-macros.sas](qc-macros.sas) - Quality control and validation macros

### 📈 Statistical Method Implementations
- [survival-analysis-examples.sas](survival-analysis-examples.sas) - Kaplan-Meier, Cox regression examples
- [longitudinal-analysis-examples.sas](longitudinal-analysis-examples.sas) - MMRM, GEE implementations
- [bayesian-examples.sas](bayesian-examples.sas) - Bayesian analysis examples using PROC MCMC
- [adaptive-design-examples.sas](adaptive-design-examples.sas) - Group sequential and adaptive designs

### 🗃️ Data Management Examples
- [sdtm-creation-examples.sas](sdtm-creation-examples.sas) - SDTM domain creation examples
- [adam-creation-examples.sas](adam-creation-examples.sas) - ADaM dataset creation examples
- [data-validation-examples.sas](data-validation-examples.sas) - Comprehensive data validation checks

### 📋 Quality Control Programs
- [double-programming-examples.sas](double-programming-examples.sas) - Independent programming validation
- [cross-validation-examples.sas](cross-validation-examples.sas) - Cross-validation procedures
- [audit-trail-examples.sas](audit-trail-examples.sas) - Audit trail and documentation examples

### 🛠️ Utility Programs
- [environment-setup.sas](environment-setup.sas) - Standard environment setup for clinical projects
- [format-library.sas](format-library.sas) - Clinical trial format definitions
- [validation-framework.sas](validation-framework.sas) - Complete validation framework implementation

## Usage Instructions

### 1. Environment Setup
```sas
/* Run this first to set up your environment */
%include "code-examples/environment-setup.sas";
```

### 2. Load Macro Libraries
```sas
/* Load clinical macros */
%include "code-examples/clinical-macros.sas";
%include "code-examples/adam-macros.sas";
%include "code-examples/table-macros.sas";
```

### 3. Execute Examples
```sas
/* Example: Create ADSL dataset */
%create_adsl(
    source_data=sdtm.dm,
    output_dataset=adam.adsl,
    study_id=PROTO2024
);
```

## Code Organization

### Macro Naming Conventions
- `create_*` - Dataset creation macros
- `validate_*` - Validation and QC macros  
- `analyze_*` - Statistical analysis macros
- `report_*` - Reporting and output macros
- `util_*` - Utility and helper macros

### Documentation Standards
Each macro includes:
- Purpose and description
- Parameter definitions and defaults
- Usage examples
- Dependencies and requirements
- Modification history

### Error Handling
All macros include:
- Parameter validation
- Error checking and messages
- Graceful failure handling
- Debug options for troubleshooting

## Example Usage Scenarios

### Scenario 1: New Study Setup
```sas
/* Set up environment for new study */
%include "environment-setup.sas";
%setup_study_environment(study_id=XYZ123, phase=3);

/* Create folder structure */
%create_study_folders(study_id=XYZ123);

/* Set up format library */
%include "format-library.sas";
```

### Scenario 2: ADaM Dataset Creation
```sas
/* Create subject-level dataset */
%create_adsl(
    dm_data=sdtm.dm,
    sv_data=sdtm.sv,
    ds_data=sdtm.ds,
    output=adam.adsl
);

/* Create lab analysis dataset */
%create_adlb(
    lb_data=sdtm.lb,
    dm_data=sdtm.dm,
    output=adam.adlb
);
```

### Scenario 3: Statistical Analysis
```sas
/* Primary efficacy analysis */
%analyze_primary_endpoint(
    data=adam.adeff,
    treatment_var=trt01p,
    response_var=chg,
    method=ANCOVA
);

/* Generate efficacy tables */
%create_efficacy_table(
    data=adam.adeff,
    table_num=11.1.1,
    output_path=outputs/tables/
);
```

## Quality Control Guidelines

### Code Review Checklist
- [ ] All parameters documented and validated
- [ ] Error handling implemented
- [ ] Test cases included and passing
- [ ] Code follows organization standards
- [ ] Independent review completed

### Testing Requirements
- Unit testing for each macro
- Integration testing for workflows
- Performance testing for large datasets
- User acceptance testing with sample data

### Validation Documentation
- Code specifications document
- Test plan and results
- User requirements traceability
- Change control documentation

## Contributing

### Adding New Examples
1. Follow naming conventions
2. Include comprehensive documentation
3. Add test cases and sample data
4. Update this README file

### Code Standards
- Use consistent indentation (4 spaces)
- Include descriptive comments
- Implement error handling
- Follow macro parameter conventions

## Support

For questions about code examples:
1. Check macro documentation headers
2. Review test cases for usage examples
3. Refer to related handbook sections
4. Submit issues for bugs or enhancements

## Related Resources

- [Templates Directory](../templates/) - Ready-to-use templates
- [Resources Directory](../resources/) - Reference materials and guides
- [Part 5: SAS Programming Excellence](../part-5-sas-programming/) - Comprehensive programming guide

## License

Code examples are provided for educational and professional development. Please ensure compliance with your organization's code sharing policies.