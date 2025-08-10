/******************************************************************************
PROGRAM: adaptive-design-examples.sas
PURPOSE: Adaptive clinical trial design examples
AUTHOR: Clinical Biostatistics Handbook
VERSION: 1.0
DATE: 2024

DESCRIPTION:
This program provides practical examples of adaptive clinical trial designs,
including group sequential designs, sample size re-estimation, adaptive
randomization, and seamless phase II/III designs.

SECTIONS INCLUDED:
1. Group Sequential Designs
2. Sample Size Re-estimation
3. Adaptive Randomization
4. Adaptive Dose Finding
5. Seamless Phase II/III Designs
6. Adaptive Enrichment Designs
******************************************************************************/

/******************************************************************************
SECTION 1: GROUP SEQUENTIAL DESIGNS
******************************************************************************/

/******************************************************************************
MACRO: group_sequential_design
PURPOSE: Implement group sequential design with O'Brien-Fleming boundaries
PARAMETERS:
  n_total= : Total planned sample size
  n_stages= : Number of interim analyses
  alpha= : Overall type I error rate
  power= : Desired power
  effect_size= : Standardized effect size
  test_type= : One-sided or two-sided test
******************************************************************************/
%macro group_sequential_design(
    n_total=200,
    n_stages=3,
    alpha=0.025,
    power=0.80,
    effect_size=0.5,
    test_type=one-sided
);
    
    %put NOTE: Setting up group sequential design;
    %put NOTE: Total N=&n_total, Stages=&n_stages, Alpha=&alpha;
    
    /* Calculate information fractions */
    data work.gs_design;
        total_n = &n_total;
        n_stages = &n_stages;
        alpha = &alpha;
        power = &power;
        effect = &effect_size;
        
        /* Information fractions */
        do stage = 1 to n_stages;
            info_frac = stage / n_stages;
            n_stage = round(total_n * info_frac);
            
            /* O'Brien-Fleming boundaries */
            %if &test_type = one-sided %then %do;
                z_alpha = probit(1 - alpha);
                boundary = z_alpha / sqrt(info_frac);
            %end;
            %else %do;
                z_alpha = probit(1 - alpha/2);
                boundary = z_alpha / sqrt(info_frac);
            %end;
            
            /* Nominal p-value for stopping */
            %if &test_type = one-sided %then %do;
                nominal_p = 1 - probnorm(boundary);
            %end;
            %else %do;
                nominal_p = 2 * (1 - probnorm(boundary));
            %end;
            
            /* Expected sample size under null and alternative */
            /* Simplified calculation - would need integration in practice */
            if stage = 1 then do;
                prob_stop_null = nominal_p;
                prob_stop_alt = probnorm(effect * sqrt(n_stage/4) - boundary);
            end;
            
            output;
        end;
        
        format info_frac percent8.1 boundary 8.3 nominal_p pvalue6.4;
    run;
    
    /* Display design */
    proc print data=work.gs_design;
        title1 "Group Sequential Design";
        title2 "O'Brien-Fleming Boundaries";
        var stage n_stage info_frac boundary nominal_p;
    run;
    
    /* Plot boundaries */
    proc sgplot data=work.gs_design;
        series x=info_frac y=boundary / markers markerattrs=(symbol=circlefilled);
        xaxis label="Information Fraction" values=(0 to 1 by 0.2);
        yaxis label="Critical Value (Z-score)" grid;
        refline &z_alpha / axis=y label="Fixed Design Critical Value" 
                          lineattrs=(pattern=dash);
        title "O'Brien-Fleming Stopping Boundaries";
    run;
    
    /* Operating characteristics */
    data work.gs_oc;
        set work.gs_design end=last;
        
        /* Cumulative stopping probabilities */
        retain cum_alpha_spent 0 cum_power 0;
        
        /* Alpha spending */
        alpha_spent = nominal_p;
        cum_alpha_spent + alpha_spent;
        
        /* Power at each stage (simplified) */
        stage_power = probnorm(effect * sqrt(n_stage/4) - boundary);
        cum_power + stage_power * (1 - cum_power);
        
        if last then do;
            total_alpha_spent = cum_alpha_spent;
            total_power = cum_power;
        end;
        
        format cum_alpha_spent cum_power percent8.2;
    run;
    
    proc print data=work.gs_oc;
        title "Operating Characteristics";
        var stage alpha_spent cum_alpha_spent stage_power cum_power;
    run;
    
%mend group_sequential_design;

/******************************************************************************
SECTION 2: SAMPLE SIZE RE-ESTIMATION
******************************************************************************/

/******************************************************************************
MACRO: adaptive_sample_size
PURPOSE: Perform sample size re-estimation based on interim results
PARAMETERS:
  interim_n1= : Sample size in group 1 at interim
  interim_n2= : Sample size in group 2 at interim
  interim_mean1= : Observed mean in group 1
  interim_mean2= : Observed mean in group 2
  interim_pooled_sd= : Observed pooled standard deviation
  target_power= : Target power for final analysis
  alpha= : Type I error rate
  min_total_n= : Minimum total sample size
  max_total_n= : Maximum total sample size
******************************************************************************/
%macro adaptive_sample_size(
    interim_n1=,
    interim_n2=,
    interim_mean1=,
    interim_mean2=,
    interim_pooled_sd=,
    target_power=0.80,
    alpha=0.05,
    min_total_n=100,
    max_total_n=500
);
    
    %put NOTE: Performing adaptive sample size re-estimation;
    
    data work.ssr_calculation;
        /* Interim results */
        n1_interim = &interim_n1;
        n2_interim = &interim_n2;
        mean1 = &interim_mean1;
        mean2 = &interim_mean2;
        pooled_sd = &interim_pooled_sd;
        
        /* Calculate observed effect size */
        observed_effect = abs(mean1 - mean2) / pooled_sd;
        
        /* Re-estimate sample size for target power */
        z_alpha = probit(1 - &alpha/2);
        z_beta = probit(&target_power);
        
        /* Sample size per group for remaining patients */
        n_per_group_total = ceil(2 * ((z_alpha + z_beta) / observed_effect)**2);
        
        /* Total sample size needed */
        n_total_needed = 2 * n_per_group_total;
        
        /* Account for patients already enrolled */
        n_already_enrolled = n1_interim + n2_interim;
        n_additional_needed = max(0, n_total_needed - n_already_enrolled);
        
        /* Apply constraints */
        n_total_final = min(max(n_total_needed, &min_total_n), &max_total_n);
        n_additional_final = max(0, n_total_final - n_already_enrolled);
        
        /* Conditional power with original and adapted sample sizes */
        n_original = 200; /* Example original planned sample size */
        
        /* Conditional power calculation */
        if n_already_enrolled < n_original then do;
            remaining_original = n_original - n_already_enrolled;
            z_current = observed_effect * sqrt(n_already_enrolled/2);
            
            cond_power_original = probnorm(
                (z_current + observed_effect * sqrt(remaining_original/2) - 
                 z_alpha * sqrt(n_original/(n_already_enrolled))) / 
                sqrt(remaining_original/n_already_enrolled)
            );
        end;
        
        /* Power with adapted sample size */
        if n_additional_final > 0 then do;
            power_adapted = probnorm(observed_effect * sqrt(n_total_final/2) - z_alpha);
        end;
        else do;
            power_adapted = probnorm(observed_effect * sqrt(n_already_enrolled/2) - z_alpha);
        end;
        
        format observed_effect 8.3 cond_power_original power_adapted percent8.1;
    run;
    
    /* Display results */
    proc print data=work.ssr_calculation noobs;
        title1 "Adaptive Sample Size Re-estimation Results";
        title2 "Interim Analysis: n1=&interim_n1, n2=&interim_n2";
        var observed_effect n_total_needed n_additional_needed 
            n_total_final n_additional_final cond_power_original power_adapted;
    run;
    
    /* Sensitivity analysis */
    data work.ssr_sensitivity;
        do effect_size = 0.1 to 1.0 by 0.1;
            z_alpha = probit(1 - &alpha/2);
            z_beta = probit(&target_power);
            
            n_per_group = ceil(2 * ((z_alpha + z_beta) / effect_size)**2);
            n_total = 2 * n_per_group;
            
            /* Power for different sample sizes */
            do n_scenario = 100 to 500 by 50;
                power = probnorm(effect_size * sqrt(n_scenario/2) - z_alpha);
                output;
            end;
        end;
    run;
    
    /* Plot sensitivity analysis */
    proc sgplot data=work.ssr_sensitivity;
        series x=n_scenario y=power / group=effect_size;
        xaxis label="Total Sample Size" grid;
        yaxis label="Power" values=(0 to 1 by 0.1) grid;
        refline &target_power / axis=y lineattrs=(pattern=dash);
        title "Power Curves for Different Effect Sizes";
    run;
    
%mend adaptive_sample_size;

/******************************************************************************
SECTION 3: RESPONSE-ADAPTIVE RANDOMIZATION
******************************************************************************/

/******************************************************************************
MACRO: response_adaptive_randomization
PURPOSE: Implement response-adaptive randomization
PARAMETERS:
  current_data= : Dataset with current trial data
  response_var= : Binary response variable
  treatment_var= : Treatment assignment variable
  method= : Adaptation method (OPTIMAL, NEYMAN, RSIHR)
  target_allocation= : Target allocation ratio (for some methods)
******************************************************************************/
%macro response_adaptive_randomization(
    current_data=,
    response_var=,
    treatment_var=,
    method=OPTIMAL,
    target_allocation=
);
    
    %put NOTE: Implementing response-adaptive randomization;
    %put NOTE: Method: &method;
    
    /* Calculate current response rates */
    proc means data=&current_data noprint;
        class &treatment_var;
        var &response_var;
        output out=work.current_rates mean=response_rate n=n_patients;
    run;
    
    /* Calculate adaptive randomization probabilities */
    data work.adaptive_prob;
        set work.current_rates;
        where not missing(&treatment_var);
        
        /* Get response rates and sample sizes */
        if &treatment_var = 0 then do;
            p0 = response_rate;
            n0 = n_patients;
        end;
        else if &treatment_var = 1 then do;
            p1 = response_rate;
            n1 = n_patients;
        end;
        
        retain p0 p1 n0 n1;
        
        /* Calculate allocation probabilities based on method */
        if _n_ = 2 then do; /* After both groups processed */
            
            %if &method = OPTIMAL %then %do;
                /* Optimal allocation for maximizing power */
                if p0 > 0 and p0 < 1 and p1 > 0 and p1 < 1 then do;
                    ratio = sqrt(p1*(1-p1)) / sqrt(p0*(1-p0));
                    prob_trt1 = ratio / (1 + ratio);
                end;
                else do;
                    prob_trt1 = 0.5; /* Default to equal allocation */
                end;
            %end;
            
            %else %if &method = NEYMAN %then %do;
                /* Neyman allocation - minimize variance */
                sd0 = sqrt(p0 * (1 - p0));
                sd1 = sqrt(p1 * (1 - p1));
                ratio = sd1 / sd0;
                prob_trt1 = ratio / (1 + ratio);
            %end;
            
            %else %if &method = RSIHR %then %do;
                /* Randomized play-the-winner */
                /* Add one success/failure to avoid zeros */
                success0 = p0 * n0 + 1;
                failure0 = (1 - p0) * n0 + 1;
                success1 = p1 * n1 + 1;
                failure1 = (1 - p1) * n1 + 1;
                
                prob_trt1 = (success1 / (success1 + failure1)) / 
                           ((success0 / (success0 + failure0)) + 
                            (success1 / (success1 + failure1)));
            %end;
            
            /* Apply constraints */
            prob_trt1 = max(0.1, min(0.9, prob_trt1)); /* Keep between 10% and 90% */
            prob_trt0 = 1 - prob_trt1;
            
            /* Output results */
            treatment = 0; 
            allocation_prob = prob_trt0;
            current_response_rate = p0;
            current_n = n0;
            output;
            
            treatment = 1;
            allocation_prob = prob_trt1;
            current_response_rate = p1;
            current_n = n1;
            output;
        end;
        
        format current_response_rate allocation_prob percent10.1;
        keep treatment current_response_rate current_n allocation_prob;
    run;
    
    /* Display results */
    proc print data=work.adaptive_prob noobs;
        title1 "Response-Adaptive Randomization";
        title2 "Method: &method";
    run;
    
    /* Simulate next assignments */
    data work.next_assignments;
        set work.adaptive_prob;
        where treatment = 1;
        
        /* Simulate next 20 patients */
        do patient = 1 to 20;
            if rand('uniform') < allocation_prob then
                assigned_treatment = 1;
            else
                assigned_treatment = 0;
            output;
        end;
        
        keep patient assigned_treatment;
    run;
    
    proc freq data=work.next_assignments;
        tables assigned_treatment;
        title "Next 20 Patient Assignments (Simulated)";
    run;
    
%mend response_adaptive_randomization;

/******************************************************************************
SECTION 4: ADAPTIVE DOSE FINDING
******************************************************************************/

/******************************************************************************
MACRO: adaptive_dose_finding
PURPOSE: Implement adaptive dose-finding using continual reassessment method (CRM)
PARAMETERS:
  dose_levels= : Space-separated list of dose levels
  prior_skeleton= : Prior estimates of toxicity probability
  target_toxicity= : Target toxicity rate
  current_data= : Current toxicity data
  cohort_size= : Size of each cohort
******************************************************************************/
%macro adaptive_dose_finding(
    dose_levels=1 2 3 4 5,
    prior_skeleton=0.05 0.10 0.20 0.35 0.50,
    target_toxicity=0.25,
    current_data=,
    cohort_size=3
);
    
    %put NOTE: Adaptive dose-finding using CRM;
    %put NOTE: Target toxicity rate: &target_toxicity;
    
    /* Parse dose levels and skeleton */
    data work.dose_toxicity;
        array doses[5] _temporary_ (&dose_levels);
        array skeleton[5] _temporary_ (&prior_skeleton);
        
        do i = 1 to dim(doses);
            dose_level = doses[i];
            prior_tox_prob = skeleton[i];
            output;
        end;
        
        drop i;
    run;
    
    /* If current data exists, update estimates */
    %if %length(&current_data) > 0 %then %do;
        
        /* Calculate observed toxicities by dose */
        proc sql;
            create table work.observed_tox as
            select dose_level,
                   sum(toxicity) as n_tox,
                   count(*) as n_patients,
                   sum(toxicity) / count(*) as obs_tox_rate
            from &current_data
            group by dose_level;
        quit;
        
        /* Bayesian update using beta-binomial model */
        data work.posterior_estimates;
            merge work.dose_toxicity work.observed_tox;
            by dose_level;
            
            /* Prior parameters (using method of moments) */
            a_prior = prior_tox_prob * 2; /* Weak prior with ESS=2 */
            b_prior = (1 - prior_tox_prob) * 2;
            
            /* Posterior parameters */
            if not missing(n_patients) then do;
                a_post = a_prior + n_tox;
                b_post = b_prior + (n_patients - n_tox);
            end;
            else do;
                a_post = a_prior;
                b_post = b_prior;
                n_patients = 0;
                n_tox = 0;
            end;
            
            /* Posterior mean */
            post_tox_prob = a_post / (a_post + b_post);
            
            /* Distance from target */
            distance_from_target = abs(post_tox_prob - &target_toxicity);
            
            format prior_tox_prob post_tox_prob obs_tox_rate percent10.1;
        run;
        
        /* Select next dose */
        proc sort data=work.posterior_estimates;
            by distance_from_target;
        run;
        
        data work.next_dose;
            set work.posterior_estimates;
            if _n_ = 1 then do;
                next_dose = dose_level;
                next_dose_tox_prob = post_tox_prob;
                output;
            end;
        run;
        
    %end;
    %else %do;
        /* No data yet - start with dose closest to target in skeleton */
        data work.next_dose;
            set work.dose_toxicity;
            distance_from_target = abs(prior_tox_prob - &target_toxicity);
        run;
        
        proc sort data=work.next_dose;
            by distance_from_target;
        run;
        
        data work.next_dose;
            set work.next_dose;
            if _n_ = 1;
            next_dose = dose_level;
            next_dose_tox_prob = prior_tox_prob;
        run;
    %end;
    
    /* Display results */
    proc print data=work.posterior_estimates;
        title1 "Adaptive Dose-Finding Results";
        title2 "Target Toxicity Rate: &target_toxicity";
        var dose_level n_patients n_tox prior_tox_prob post_tox_prob distance_from_target;
    run;
    
    proc print data=work.next_dose noobs;
        title3 "Recommended Dose for Next Cohort";
        var next_dose next_dose_tox_prob;
    run;
    
    /* Plot dose-toxicity curve */
    proc sgplot data=work.posterior_estimates;
        series x=dose_level y=prior_tox_prob / markers 
               lineattrs=(pattern=dash) name='prior' legendlabel='Prior';
        series x=dose_level y=post_tox_prob / markers 
               lineattrs=(thickness=2) name='posterior' legendlabel='Posterior';
        scatter x=dose_level y=obs_tox_rate / markerattrs=(symbol=circlefilled size=10)
                name='observed' legendlabel='Observed';
        refline &target_toxicity / axis=y lineattrs=(color=red) label='Target';
        xaxis label="Dose Level" integer;
        yaxis label="Toxicity Probability" values=(0 to 1 by 0.1);
        legend location=inside position=topleft;
        title "Dose-Toxicity Relationship";
    run;
    
%mend adaptive_dose_finding;

/******************************************************************************
SECTION 5: SEAMLESS PHASE II/III DESIGN
******************************************************************************/

/******************************************************************************
MACRO: seamless_phase2_3
PURPOSE: Implement seamless phase II/III adaptive design
PARAMETERS:
  phase2_n= : Sample size for phase II portion
  phase3_n= : Additional sample size for phase III
  n_doses= : Number of dose levels in phase II
  selection_criterion= : Criterion for dose selection
  futility_boundary= : Futility boundary for phase II
  efficacy_boundary= : Efficacy boundary for combined analysis
******************************************************************************/
%macro seamless_phase2_3(
    phase2_n=60,
    phase3_n=240,
    n_doses=3,
    selection_criterion=HIGHEST_RESPONSE,
    futility_boundary=0.10,
    efficacy_boundary=0.025
);
    
    %put NOTE: Implementing seamless phase II/III design;
    
    /* Phase II: Dose selection stage */
    data work.phase2_design;
        phase2_n = &phase2_n;
        n_doses = &n_doses;
        n_per_dose = phase2_n / (n_doses + 1); /* Include control */
        
        /* Simulate phase II results */
        do dose = 0 to n_doses;
            if dose = 0 then do;
                true_response = 0.20; /* Control response rate */
                dose_label = "Control";
            end;
            else do;
                /* Dose-response relationship */
                true_response = 0.20 + 0.10 * dose / n_doses;
                dose_label = cats("Dose ", dose);
            end;
            
            /* Simulate responses */
            n_response = rand('binomial', true_response, n_per_dose);
            obs_response = n_response / n_per_dose;
            
            /* Selection criteria */
            %if &selection_criterion = HIGHEST_RESPONSE %then %do;
                selection_score = obs_response;
            %end;
            %else %if &selection_criterion = TREND_TEST %then %do;
                selection_score = dose * obs_response; /* Simplified */
            %end;
            
            output;
        end;
        
        format true_response obs_response percent10.1;
    run;
    
    /* Futility check */
    proc sql noprint;
        select max(obs_response) into :max_response
        from work.phase2_design
        where dose > 0;
        
        select obs_response into :control_response
        from work.phase2_design
        where dose = 0;
    quit;
    
    %if %sysevalf(&max_response < &control_response + &futility_boundary) %then %do;
        %put WARNING: Futility criterion met - stopping trial;
        
        data work.futility_stop;
            decision = "STOP FOR FUTILITY";
            max_dose_response = &max_response;
            control_response = &control_response;
            futility_boundary = &futility_boundary;
        run;
        
        proc print data=work.futility_stop;
            title "Trial Stopped for Futility";
        run;
    %end;
    %else %do;
        /* Select best dose */
        proc sort data=work.phase2_design;
            by descending selection_score;
        run;
        
        data work.selected_dose;
            set work.phase2_design;
            if _n_ = 1 and dose > 0 then do;
                selected_dose = dose;
                selected_response = obs_response;
                output;
            end;
        run;
        
        /* Phase III: Confirmatory stage */
        proc sql noprint;
            select selected_dose, selected_response 
            into :selected_dose, :phase2_selected_response
            from work.selected_dose;
        quit;
        
        data work.phase3_design;
            selected_dose = &selected_dose;
            phase3_n = &phase3_n;
            total_n = &phase2_n + &phase3_n;
            
            /* Patients from each phase */
            n_selected_phase2 = &phase2_n / (&n_doses + 1);
            n_control_phase2 = &phase2_n / (&n_doses + 1);
            n_selected_phase3 = &phase3_n / 2;
            n_control_phase3 = &phase3_n / 2;
            
            /* Combined analysis */
            /* Using normal approximation for illustration */
            p1_hat = 0.35; /* Example combined response rate for selected dose */
            p0_hat = 0.20; /* Example combined response rate for control */
            
            n1_total = n_selected_phase2 + n_selected_phase3;
            n0_total = n_control_phase2 + n_control_phase3;
            
            /* Test statistic */
            p_pooled = (p1_hat * n1_total + p0_hat * n0_total) / (n1_total + n0_total);
            se_diff = sqrt(p_pooled * (1 - p_pooled) * (1/n1_total + 1/n0_total));
            z_stat = (p1_hat - p0_hat) / se_diff;
            p_value = 1 - probnorm(z_stat);
            
            /* Adaptive adjustment for using phase II data */
            /* Simplified - would need proper combination test */
            adjusted_alpha = &efficacy_boundary * 0.8; /* Penalty for adaptation */
            
            if p_value < adjusted_alpha then decision = "REJECT NULL";
            else decision = "FAIL TO REJECT";
            
            format p1_hat p0_hat percent10.1 p_value pvalue6.4;
        run;
        
        /* Display results */
        proc print data=work.phase2_design;
            title1 "Phase II Dose-Finding Results";
        run;
        
        proc print data=work.selected_dose noobs;
            title2 "Selected Dose for Phase III";
        run;
        
        proc print data=work.phase3_design noobs;
            title3 "Combined Phase II/III Analysis";
            var selected_dose n1_total n0_total p1_hat p0_hat z_stat p_value decision;
        run;
    %end;
    
%mend seamless_phase2_3;

/******************************************************************************
SECTION 6: ADAPTIVE ENRICHMENT DESIGNS
******************************************************************************/

/******************************************************************************
MACRO: adaptive_enrichment
PURPOSE: Implement adaptive enrichment design
PARAMETERS:
  interim_data= : Interim analysis dataset
  biomarker_var= : Biomarker variable
  response_var= : Response variable
  treatment_var= : Treatment variable
  interim_fraction= : Fraction of total sample size at interim
  enrichment_threshold= : Threshold for enrichment decision
******************************************************************************/
%macro adaptive_enrichment(
    interim_data=,
    biomarker_var=,
    response_var=,
    treatment_var=,
    interim_fraction=0.5,
    enrichment_threshold=0.10
);
    
    %put NOTE: Performing adaptive enrichment analysis;
    
    /* Analyze interim results by biomarker subgroup */
    proc means data=&interim_data noprint;
        class &biomarker_var &treatment_var;
        var &response_var;
        output out=work.subgroup_results mean=response_rate n=n_patients;
    run;
    
    /* Calculate treatment effects by subgroup */
    proc sql;
        create table work.enrichment_analysis as
        select a.&biomarker_var,
               a.response_rate as rate_trt,
               a.n_patients as n_trt,
               b.response_rate as rate_ctrl,
               b.n_patients as n_ctrl,
               a.response_rate - b.response_rate as treatment_effect,
               calculated treatment_effect / 
                   sqrt(a.response_rate*(1-a.response_rate)/a.n_patients +
                        b.response_rate*(1-b.response_rate)/b.n_patients) as z_score,
               1 - probnorm(calculated z_score) as p_value
        from work.subgroup_results as a
        inner join work.subgroup_results as b
        on a.&biomarker_var = b.&biomarker_var
        where a.&treatment_var = 1 and b.&treatment_var = 0
              and not missing(a.&biomarker_var);
    quit;
    
    /* Make enrichment decision */
    data work.enrichment_decision;
        set work.enrichment_analysis;
        
        /* Decision rules */
        if &biomarker_var = 1 then biomarker_group = "Positive";
        else biomarker_group = "Negative";
        
        /* Check if enrichment criteria met */
        if &biomarker_var = 1 and treatment_effect > &enrichment_threshold and
           p_value < 0.10 then do;
            enrich_positive = "YES";
            decision = "Enrich for biomarker positive";
        end;
        else if &biomarker_var = 0 and treatment_effect < 0 then do;
            enrich_positive = "NO";
            decision = "Continue in all patients";
        end;
        else do;
            enrich_positive = "NO";
            decision = "Continue in all patients";
        end;
        
        format rate_trt rate_ctrl treatment_effect percent10.1 p_value pvalue6.4;
    run;
    
    /* Display results */
    proc print data=work.enrichment_decision;
        title1 "Adaptive Enrichment Analysis";
        title2 "Interim Analysis at %sysevalf(&interim_fraction*100)% Information";
        var biomarker_group n_trt n_ctrl rate_trt rate_ctrl treatment_effect p_value decision;
    run;
    
    /* Calculate sample size implications */
    data work.sample_size_impact;
        set work.enrichment_decision;
        
        /* Original sample size allocation */
        if biomarker_group = "Positive" then original_fraction = 0.3; /* 30% positive */
        else original_fraction = 0.7; /* 70% negative */
        
        /* Adjusted allocation after enrichment */
        if enrich_positive = "YES" and biomarker_group = "Positive" then
            new_fraction = 1.0;
        else if enrich_positive = "YES" and biomarker_group = "Negative" then
            new_fraction = 0.0;
        else new_fraction = original_fraction;
        
        /* Power implications */
        if treatment_effect > 0 then do;
            z_alpha = probit(0.975);
            z_beta = probit(0.80);
            
            /* Required sample size for 80% power */
            if treatment_effect > 0 then
                n_required = 2 * ((z_alpha + z_beta) / (treatment_effect / 0.5))**2;
            else n_required = 999999;
            
            /* Effective sample size after enrichment */
            effective_n = n_required * new_fraction;
        end;
        
        format original_fraction new_fraction percent10.0;
    run;
    
    proc print data=work.sample_size_impact;
        title3 "Sample Size Impact of Enrichment";
        var biomarker_group original_fraction new_fraction n_required effective_n;
    run;
    
%mend adaptive_enrichment;

/******************************************************************************
EXAMPLE USAGE
******************************************************************************/

/*
Example 1: Group Sequential Design
%group_sequential_design(
    n_total=300,
    n_stages=3,
    alpha=0.025,
    power=0.80,
    effect_size=0.4,
    test_type=one-sided
);

Example 2: Sample Size Re-estimation
%adaptive_sample_size(
    interim_n1=50,
    interim_n2=50,
    interim_mean1=2.5,
    interim_mean2=1.8,
    interim_pooled_sd=2.0,
    target_power=0.80,
    alpha=0.05,
    min_total_n=100,
    max_total_n=400
);

Example 3: Response-Adaptive Randomization
%response_adaptive_randomization(
    current_data=trial_data,
    response_var=response,
    treatment_var=treatment,
    method=OPTIMAL
);

Example 4: Adaptive Dose Finding
%adaptive_dose_finding(
    dose_levels=1 2 3 4 5,
    prior_skeleton=0.05 0.10 0.20 0.35 0.50,
    target_toxicity=0.25,
    current_data=toxicity_data,
    cohort_size=3
);

Example 5: Seamless Phase II/III
%seamless_phase2_3(
    phase2_n=80,
    phase3_n=320,
    n_doses=3,
    selection_criterion=HIGHEST_RESPONSE,
    futility_boundary=0.10,
    efficacy_boundary=0.025
);

Example 6: Adaptive Enrichment
%adaptive_enrichment(
    interim_data=interim_results,
    biomarker_var=biomarker_positive,
    response_var=response,
    treatment_var=treatment,
    interim_fraction=0.5,
    enrichment_threshold=0.10
);
*/

%put NOTE: Adaptive design examples loaded successfully;
%put NOTE: Available macros: group_sequential_design, adaptive_sample_size,;
%put NOTE:                  response_adaptive_randomization, adaptive_dose_finding,;
%put NOTE:                  seamless_phase2_3, adaptive_enrichment;