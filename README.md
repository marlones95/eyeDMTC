# eyeDMTC
Effector-Dependent Neural Representations of Perceptual Decisions Independent of Motor Actions and Sensory Modalities
Authors:

    Marlon F. Esmeyer
    Timo T. Schmidt
    Hilal Katirci
    Felix Blankenburg

Abstract
Many primate and human studies support an intentional framework of perceptual decisions, proposing that decisions are encoded in brain regions associated with the required response. By dissociating decisions from stimulus order and motor response, recent neuroimaging studies indicate that categorical decisions are represented in effector-dependent activation patterns, independent of stimulus order, motor response and sensory modality, within brain regions like the frontal eye fields for saccades, the dorsal premotor cortex for button presses and the posterior parietal cortex for both (Esmeyer et al., 2025; Y. Wu et al., 2019, 2021). Whether this generalizes across effectors in different sensory modalities remains unresolved. To address this, the present functional magnetic resonance imaging study employed a visual delayed match-to-comparison task in which participants compared the frequencies of two sequential visual flicker stimuli and indicated their decisions with saccades whose direction was unknown during decision formation. A whole-brain multivariate pattern analysis searchlight approach identified above-chance decoding of binary decisions in bilateral frontal eye fields and inferior parietal lobule. A cross-effector comparison with an identical task using button press responses (Esmeyer et al., 2025) revealed preferential involvement of the right frontal eye field for saccades, while a conjunction analysis identified effector-independent activation patterns in the left intraparietal sulcus. These findings suggest that premotor regions such as the frontal eye fields encode decisions in an effector-dependent, but response-independent manner, whereas the posterior parietal cortex represents decisions more flexibly and partly effector-independent. Notably, both forms of encoding remain independent of stimulus order, motor response and sensory modality.

Scripts

Matlab codes for the analyses performed for the manuscript titled "Effector-Dependent Neural Representations of Perceptual Decisions Independent of Motor Actions and Sensory Modalities".
fMRI Analyses
Main Analyses

    Decoding_Batch: Batch script running all pre-processing and analysis functions (first level)
    D1_glm_1stLevel_SVM: Function running the GLM
    D2_Decoding_SVM: Function running the support vector machine decoding
    Second_Level_Decoding_SVM: Script running the 2nd level one-sample t-test

Conjunction Analysis

    t_test_SVM: Batch script for the conjunction
    t_test_job_SVM: setting up the conjunction
    Estimate_job_SVM: Parameter estimation for the conjunction

Control Analyses

    Decoding_Batch_control: Batch for the Support Vector Machine classification for motor response and rule decoding
    Decoding_Batch_subsampling: Batch for the Support Vector Machine classification for the subsampling of motor response and task rule
    D1_glm_1stLevel_left_vs_right: Function running the GLM for motor response
    D1_glm_1stLevel_rule: Function running the GLM for rule
    D1_glm_1stLevel_sub_motor_rule: Function running the GLM for the subsampling of motor response and task rule
    D2class_Decoding: Function running the support vector machine classification
    Second_Level_Decoding_left_vs_right: Script running the 2nd level one-sample t-test for motor response
    Second_Level_Decoding_rule: Script running the 2nd level one-sample t-test for rule
    Second_Level_Decoding_sub_motor_rule: Script running the 2nd level one-sample t-test for the subsampling

Behavioural Analyses

    ANOVA_three_way: Script running a three-way repeated measures ANOVA (factors: rule, stimulus order, f1 frequency)
    Chi_Squared_tests: Script running the chi-squared testd (comparing motor responses)

Required software packages and toolboxes:

    SPM12: https://www.fil.ion.ucl.ac.uk/spm/software/spm12/
    The Decoding Toolbox (TDT): https://sites.google.com/site/tdtdecodingtoolbox/
