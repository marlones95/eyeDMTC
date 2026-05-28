%% First Level GLM for Decoding Left vs Right

% Setting up the GLM for the Support vector machine by estimating betas for
% the two conditions of interest
function D1_glm_1stLevel_left_vs_right(Subjects, sj, outputfolder_1st,tr,hpf, runs, duration, hm, currPrefix)

% =========================================================================
%                           Initialization
% =========================================================================

% load the log_file
log_dir = 'D:\eyeDMTC\Logs';
current_sj = Subjects{sj}(end-1:end);
logfile = spm_select('FPList', log_dir, ['^fMRI_', current_sj, '.*\.mat$']);
load(logfile);


% set SPM defaults
spm('defaults','fmri')
spm_jobman('initcfg');

% data directory of the current_sj
data_dir = ['D:\eyeDMTC\data\sub-0', current_sj];

% target directory that will contain the created job.mat file and SPM file
tgt_dir = fullfile(data_dir, outputfolder_1st);

% directory with movement parameters and functional runs
func_dir = [data_dir, '\func'];

if ~exist(tgt_dir, 'dir')
    mkdir(tgt_dir)
end
cd(tgt_dir)

% =========================================================================
%                           Extract timings
% =========================================================================

% Get timing of motor response for all trials
delayperiod = squeeze(mylog.timing(5,:,:))';


% mylog.choice_direction indicates left or right response
left_idx = mylog.choice_direction == 1;
right_idx = mylog.choice_direction == 2;

left = zeros(6,64);
right = zeros(6,64);
left(left_idx) = delayperiod(left_idx);
right(right_idx) = delayperiod(right_idx);

% =========================================================================
%                       Setting up the matlabbatch
% =========================================================================

% event-related analysis
matlabbatch{1, 1}.spm.stats.fmri_spec.dir = cellstr(tgt_dir); % Output Directory
matlabbatch{1, 1}.spm.stats.fmri_spec.timing.units = 'secs';
matlabbatch{1, 1}.spm.stats.fmri_spec.timing.RT = tr;
matlabbatch{1, 1}.spm.stats.fmri_spec.timing.fmri_t = 16; % Temporal resolution
matlabbatch{1, 1}.spm.stats.fmri_spec.timing.fmri_t0 = 8; % reference slice

filter = ['^', currPrefix, 'sub-0', current_sj, '_task-task_run-.*\.nii$'];
f = spm_select('List', func_dir, filter);

for r = 1:size(runs,2)
    V=spm_vol([func_dir filesep f(r,:)]);
    files={};
    for i=1:(size(V,1))
        files{i} = [func_dir filesep strtrim(f(r,:)) ',' int2str(i)];
    end  

    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).scans = cellstr(files');
    matlabbatch{1}.spm.stats.fmri_spec.sess(r).hpf = hpf; % high pass filter

    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).name      = 'decision_left';
    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).onset     = nonzeros(left(r,:))';
    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(1).duration  = duration;

    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).name      = 'decision_right';
    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).onset     = nonzeros(right(r,:))';
    matlabbatch{1, 1}.spm.stats.fmri_spec.sess(r).cond(2).duration  = duration;

    % Motion Parameters and CSF
    filter_move = 'rp_sub-0';

    if hm
        mf = spm_select('FPList', func_dir, [filter_move, current_sj, '_task-task_run-', num2str(r)]);
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