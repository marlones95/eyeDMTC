%---------------------------------------------------------------
% Cross-study analyses comparing vDMTC vs eyeDMTC
%---------------------------------------------------------------

clear
close all

% Set up SPM
spm('Defaults', 'fMRI');
spm_jobman('initcfg');


% Define output directory
output_dir = fullfile('D:\eyeDMTC\Cross-study analysis\RFX\ttest');
mkdir(output_dir);
spmmat_path = fullfile(output_dir, 'SPM.mat');
matlabbatch{1}.spm.stats.factorial_design.dir = {output_dir};

% =========================================================================
%                 Extract first level maps from both studies
% =========================================================================

% Get first level maps from vDMTC (button press version)
exludeSJ = [1,6,11,13,14,19,21,24,25,28];

SJs_vDMTC     = {'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006', 'sub-007','sub-008',...
    'sub-009','sub-010','sub-011', 'sub-012','sub-013','sub-014','sub-015','sub-016',...
    'sub-017','sub-018','sub-019', 'sub-020','sub-021','sub-022','sub-023','sub-024',...
    'sub-025','sub-026','sub-027','sub-028','sub-029','sub-030','sub-031','sub-032','sub-033','sub-034','sub-035',...
    'sub-036','sub-037'};

SJs_vDMTC(exludeSJ) = [];
sjs = length(SJs_vDMTC);

maps_vDMTC = [];

for i = 1:sjs
    current_file = {fullfile('D:\vDMTC\data',SJs_vDMTC{i}, 's3wres_accuracy_minus_chance.nii')};
    maps_vDMTC = [maps_vDMTC;current_file];
end

matlabbatch{1}.spm.stats.factorial_design.des.t2.scans1 = maps_vDMTC;

% Get first level maps from eyeDMTC (saccade version)
exludeSJ = [2,5,7,9,21,22,28,29];

SJs_eyeDMTC     = {'sub-001','sub-002','sub-003','sub-004','sub-005','sub-006','sub-007','sub-008','sub-009',...
    'sub-010','sub-011','sub-012','sub-013','sub-014','sub-015','sub-016','sub-017','sub-018','sub-019'...
    'sub-020','sub-021','sub-022','sub-023','sub-024','sub-025','sub-026','sub-027','sub-028','sub-029',...
    'sub-030','sub-031'};

SJs_eyeDMTC(exludeSJ) = [];
sjs = length(SJs_eyeDMTC);

maps_eyeDMTC = [];

for i = 1:sjs
    current_file = {fullfile('D:\eyeDMTC\data',SJs_eyeDMTC{i}, 's3wres_accuracy_minus_chance.nii')};
    maps_eyeDMTC = [maps_eyeDMTC;current_file];
end

matlabbatch{1}.spm.stats.factorial_design.des.t2.scans2 = maps_eyeDMTC;


% =========================================================================
%                 Defining analysis parameters
% =========================================================================

% General parameters
matlabbatch{1}.spm.stats.factorial_design.des.t2.dept = 0;
matlabbatch{1}.spm.stats.factorial_design.des.t2.variance = 1;
matlabbatch{1}.spm.stats.factorial_design.des.t2.gmsca = 0;
matlabbatch{1}.spm.stats.factorial_design.des.t2.ancova = 0;
matlabbatch{1}.spm.stats.factorial_design.cov = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im = 0;
matlabbatch{1}.spm.stats.factorial_design.masking.em = {'D:\vDMTC\fMRI Analysis\full_brain_mask.nii'};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm = 1;

% Run design specification
spm_jobman('run', matlabbatch); 

clear matlabbatch

% Estimate statistical model
matlabbatch{1}.spm.stats.fmri_est.spmmat = {spmmat_path};
matlabbatch{1}.spm.stats.fmri_est.write_residuals = 0;
matlabbatch{1}.spm.stats.fmri_est.method.Classical = 1;

spm('defaults','FMRI');
spm_jobman('run', matlabbatch);


% Define Contrasts: 1 -1; -1 1; 1 0; 0 1
clear matlabbatch
matlabbatch{1}.spm.stats.con.spmmat = {spmmat_path};

% Contrasts for cross-study t-tests
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'vDMTC > eyeDMTC';
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = [1 -1];
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'eyeDMTC > vDMTC';
matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = [-1 1];
matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

% Contrasts for conjunction analysis
matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'vDMTC';
matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = [1 0];
matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

matlabbatch{1}.spm.stats.con.consess{4}.tcon.name = 'eyeDMTC';
matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = [0 1];
matlabbatch{1}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

matlabbatch{1}.spm.stats.con.delete = 0;  % 1 = delete existing contrasts

% Run the contrast specification
spm_jobman('run', matlabbatch);