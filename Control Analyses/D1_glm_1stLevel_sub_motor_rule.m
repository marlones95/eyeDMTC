%% First Level GLM for the subsampling control analyses
% Setting up the GLM for the Support vector machine by estimating betas for
% the two conditions of interest, subsampled for motor response and task rules across runs and
% conditions.
function D1_glm_1stLevel_sub_motor_rule(Subjects, sj, outputfolder_1st, tr, hpf, runs, duration, hm, n_samp)

% =========================================================================
%                           Initialization
% =========================================================================

rng('shuffle')

% load the log_file
log_dir = 'D:\vDMTC\Logs';
current_sj = Subjects{sj}(end-1:end);
logfile = spm_select('FPList', log_dir, ['^fMRI_', current_sj, '.*\.mat$']);
load(logfile);

% set SPM defaults
spm('defaults','fmri')
spm_jobman('initcfg');

% data directory of the current_sj
data_dir = ['D:\vDMTC\data\sub-0', current_sj];

% directory with movement parameters and functional runs
func_dir = [data_dir, '\func'];


% =========================================================================
%                           Prepare Subsampling
% =========================================================================

% Find the minimum number of trials that have to be subsampled across the 8
% conditions and 6 runs
% 8 conditions: Decision x motor response x rule (2x2x2)
% Go through all runs to get the minimum number and then sample that
% minimum number across all trials

% Get the trial number for the 8 conditions for all 6 runs
high_left_rule1 = mylog.perform == 1 & mylog.choice_direction == 1 & (mylog.focus == 1 & mylog.flutter(:,:,1) > mylog.flutter(:,:,2));
high_left_rule2 = mylog.perform == 1 & mylog.choice_direction == 1 & (mylog.focus == 2 & mylog.flutter(:,:,1) < mylog.flutter(:,:,2));
high_right_rule1 = mylog.perform == 1 & mylog.choice_direction == 2 & (mylog.focus == 1 & mylog.flutter(:,:,1) > mylog.flutter(:,:,2));
high_right_rule2 = mylog.perform == 1 & mylog.choice_direction == 2 & (mylog.focus == 2 & mylog.flutter(:,:,1) < mylog.flutter(:,:,2));
low_left_rule1 = mylog.perform == 1 & mylog.choice_direction == 1 & (mylog.focus == 1 & mylog.flutter(:,:,1) < mylog.flutter(:,:,2));
low_left_rule2 = mylog.perform == 1 & mylog.choice_direction == 1 & (mylog.focus == 2 & mylog.flutter(:,:,1) > mylog.flutter(:,:,2));
low_right_rule1 = mylog.perform == 1 & mylog.choice_direction == 2 & (mylog.focus == 1 & mylog.flutter(:,:,1) < mylog.flutter(:,:,2));
low_right_rule2 = mylog.perform == 1 & mylog.choice_direction == 2 & (mylog.focus == 2 & mylog.flutter(:,:,1) > mylog.flutter(:,:,2));

allconditions = [high_left_rule1;high_left_rule2;high_right_rule1;high_right_rule2;...
    low_left_rule1;low_left_rule2;low_right_rule1;low_right_rule2];

allconditions_sum = sum(allconditions,2);

minTrials = min(allconditions_sum);


for i = 1:n_samp
    display(['Step 2, 1st level glm: ' Subjects{sj} '; Sample: ' num2str(i)])

    % target directory that will contain the created job.mat file and SPM file
    tgt_dir = [data_dir, outputfolder_1st, '/', num2str(i)];
    if ~exist(tgt_dir, 'dir')
        mkdir(tgt_dir)
    end
    cd(tgt_dir)

% =========================================================================
%                           Extract timings
% =========================================================================

    % Get timing for all trials
    delayperiod = squeeze(mylog.timing(5,:,:))';

    allconditions_subsampled = false(size(allconditions));

    % Subsample across conditions and runs using the minimum number
    for conds = 1:48
        if allconditions_sum(conds)>minTrials
            onesIndices = find(allconditions(conds, :));
            sampledIndices = randsample(onesIndices, minTrials);
            allconditions_subsampled(conds, sampledIndices) = true;
        else
             allconditions_subsampled(conds,:) = allconditions(conds,:);
        end
    end

    % Now combine the 8 conditions again
    conditions_subsampled = allconditions_subsampled(1:6,:)|allconditions_subsampled(7:12,:)|...
        allconditions_subsampled(13:18,:)|allconditions_subsampled(19:24,:)|allconditions_subsampled(25:30,:)|...
        allconditions_subsampled(31:36,:)|allconditions_subsampled(37:42,:)|allconditions_subsampled(43:48,:);
    
    % Also get the correct trials that were unused as a regressor:
    non_used_idx = mylog.perform & ~conditions_subsampled;
    
    % Extract correct decisions
    decision_idx = mylog.perform == 1;
    decision_correct = zeros(6,64);
    decision_correct(decision_idx) = delayperiod(decision_idx);
    decision_incorrect = zeros(6,64);
    decision_incorrect(decision_idx == 0) = delayperiod(decision_idx == 0);

    % Extract the timings
    high_idx = conditions_subsampled & (high_left_rule1 | high_right_rule1 | high_left_rule2 | high_right_rule2);
    low_idx = conditions_subsampled & (low_left_rule1 | low_right_rule1 | low_left_rule2 | low_right_rule2);
    decision_high_samp = zeros(6,64);
    decision_low_samp = zeros(6,64);
    decision_high_samp(high_idx) = decision_correct(high_idx);
    decision_low_samp(low_idx) = decision_correct(low_idx);

    % And the non-used trials
    non_used = zeros(6,64);
    non_used(non_used_idx) = decision_correct(non_used_idx);
 
% =========================================================================
%                       Setting up the matlabbatch
% =========================================================================

    % event-related analysis
    matlabbatch{1, 1}.spm.stats.fmri_spec.dir = cellstr(tgt_dir); % Output Directory
    matlabbatch{1, 1}.spm.stats.fmri_spec.timing.units = 'secs';
    matlabbatch{1, 1}.spm.stats.fmri_spec.timing.RT = tr;
    matlabbatch{1, 1}.spm.stats.fmri_spec.timing.fmri_t = 16; % Temporal resolution
    matlabbatch{1, 1}.spm.stats.fmri_spec.timing.fmri_t0 = 8; % reference slice

    filter = ['^rsub-0', current_sj, '_task-task_run-.*\.nii$'];
    f = spm_select('List', func_dir, filter);

    for r = 1:size(runs,2)
        V=spm_vol([func_dir filesep f(r,:)]);
        files={};
        for j=1:(size(V,1))
            files{j} = [func_dir filesep strtrim(f(r,:)) ',' int2str(j)];
        end



        % Batch
        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).scans = cellstr(files');
        matlabbatch{1}.spm.stats.fmri_spec.sess(r).hpf = hpf; % high pass filter

        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).name      = 'High';
        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).onset     = nonzeros(decision_high_samp(r,:))';
        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).duration  = duration;

        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).name      = 'Low';
        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).onset     = nonzeros(decision_low_samp(r,:))';
        matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).duration  = duration;

        onsets_non_used = nonzeros(non_used(r,:))';
        if ~isempty(onsets_non_used)
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(3).name      = 'non_used';
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(3).onset     = onsets_non_used;
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(3).duration  = duration;
        end

        onsets_decision_incorrect = nonzeros(decision_incorrect(r,:))';
        if ~isempty(onsets_decision_incorrect)
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(4).name      = 'decision_incorrect';
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(4).onset     = onsets_decision_incorrect;
            matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(4).duration  = duration;
        end

        % Motion Parameters and CSF
        if hm
            mf = spm_select('FPList', func_dir, ['rp_asub-0', current_sj, '_task-task_run-', num2str(r)]);
            matlabbatch{1}.spm.stats.fmri_spec.sess(r).multi_reg = {mf};
        end

    end

    matlabbatch{1, 1}.spm.stats.fmri_spec.fact  	        = struct('name', {}, 'levels', {});
    % model hrf and first temporal derivative
    matlabbatch{1, 1}.spm.stats.fmri_spec.bases.hrf .derivs  = [0 0];
    % model interactions
    matlabbatch{1, 1}.spm.stats.fmri_spec.volt              = 1;
    % global normalization
    matlabbatch{1, 1}.spm.stats.fmri_spec.global            = 'None';
    % masking threshold
    matlabbatch{1, 1}.spm.stats.fmri_spec.mthresh           = 0.8;
    % explicit mask
    matlabbatch{1, 1}.spm.stats.fmri_spec.mask              = {''};
    % autocorrelation modelling (whitening filter)
    matlabbatch{1, 1}.spm.stats.fmri_spec.cvi               = 'AR(1)';

% =========================================================================
%                               Run the GLM
% =========================================================================
   
    %% create the model
    fprintf('Creating GLM\n')
    display(['Univariate First Level: SJ' current_sj])
    spm_jobman('run', matlabbatch);

    % clear job variable
    clear matlabbatch

    %%  Model Estimation:
    load(fullfile(tgt_dir, filesep, 'SPM.mat'));
    fprintf('Estimating GLM \n');
    cd(tgt_dir);
    SPM = spm_spm(SPM);

    clear SPM;
    cd(log_dir);
end