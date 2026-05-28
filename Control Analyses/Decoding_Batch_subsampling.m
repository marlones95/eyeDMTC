%% MVPA support vector machine classification batch script for the subsampling control analysis 

% This Batch Script first specifies what features should be decoded and
% executes it. It subsamples motor response and task rules across runs and
% conditions.

clc; clear;

% =========================================================================
%                   Specify parameters and analyses
% =========================================================================

% Add vector of subject numbers (e.g. 1,2,3,4,5) if any subject has been
% already analysed to exclude that subjects from the analysis
excludeSJ = [];

% Specify the current prefix (here r because the realigned images are used)
currPrefix = ['r'];


first_level_glm = 1;
dec_anal        = 1;
averaging       = 1;
normalization   = 1;
smoothing       = 1;
 
% Add necessary paths
addpath('C:\Users\nnu16\Documents\MATLAB\spm12'); % SPM
addpath('C:\Users\nnu16\Documents\MATLAB\decoding_toolbox'); % The Decoding Toolbox
addpath('D:\vDMTC\fMRI Analysis\Preprocessing'); % Path containing pre-processing scripts
addpath('D:\vDMTC\fMRI Analysis\Decoding'); % Path containing decoding scripts


% Specify data paths
targetF = 'D:\vDMTC\data';    % target directory for all nifti files

% Number of Subsamples
n_samp = 100; 

% =========================================================================
%           Step 1: Data organization and analysis configuration
% =========================================================================

%%% Data organization %%%
A2_data_org
% A2_data_org does the following:
% - create a cell array Subjects with Subject names
% - unzip all nii.gz files
% - create a cell array containing filenames for all runs per subject
% - compares info from json-file to niftimetadata and gives warning if they do not match
% - gets the TR and the number of slices from the json file


%%% Analysis configuration %%%
dec_type = "searchlight"; % specifies to perform searchlight decoding
condnames = {'High', 'Low'}; 

duration = 0; % epoch duration, 0 because it is a single event
refslice=slice_order(round(length(slice_order)/2)); % reference slice for slice-time correction
hpf      = 192; % High-pass filter cut-off;
hm = 1;   % include head motion parameters from realignment
rad = 4; % Searchlight radius


% =========================================================================
%                           Step 2: First level GLM
% =========================================================================

if first_level_glm
    outputfolder = ['\decoding_glm_subsampling_motor_rule'];
    % folder that will contain the created job.mat file and SPM file
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 2, 1st level glm: ' Subjects{sj} ])
            % The function "D2_glm_1stLevel_sub_motor_rule calculates nsamp
            % GLMs that balance motor response and task rule across
            % conditions and runs
            D1_glm_1stLevel_sub_motor_rule(Subjects, sj, outputfolder, TR, hpf, runs, duration, hm, n_samp);
        end
    end
end

% =========================================================================
%                           Step 3: Decoding
% =========================================================================

if dec_anal
    labelnames = condnames;
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            for i = 1:n_samp
                display(['Step 3, Decoding: ' Subjects{sj} '; Sample: ' num2str(i)  ])
                beta_dir = fullfile(targetF, Subjects{sj}, ['decoding_glm_subsampling_motor_rule'],...
                    '\', num2str(i));
                output_dir = fullfile(targetF, Subjects{sj}, ['dec_subsampling_motor_rule'], '\', num2str(i));
                D2class_Decoding(beta_dir, output_dir, labelnames, dec_type, rad);
            end
        end
    end
end

% =========================================================================
%                           Step 4: Averaging
% =========================================================================

if averaging
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 4, Averaging: ' Subjects{sj}])
            sj_dir = [targetF filesep Subjects{sj} filesep ['dec_subsampling_motor_rule']];
            % Create a 4-dimensional matrix including the nifti-files of
            % all 100 subsamples in a single file
            niftis = zeros(64,64,37,n_samp);
            % Loop through the decoding files 
            for i = 1:n_samp
                data_dir = [sj_dir filesep num2str(i)];
                cd(data_dir)
                header = niftiinfo('res_accuracy_minus_chance.nii');
                niftis(:,:,:,i) = niftiread('res_accuracy_minus_chance.nii');
            end
            % Average across decoding niftis
            cd(sj_dir)
            niftis_mean = single(mean(niftis,4));
            niftiwrite(niftis_mean,'res_accuracy_minus_chance.nii',header);
        end
    end
end

% =========================================================================
%                           Step 5: Normalization
% =========================================================================

% normalization --> prefix: w
if normalization
    vox_size = [2 2 2]; % Normalize to 2x2x2 voxel size
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            if exist([targetF filesep Subjects{sj} filesep ['dec_subsampling_motor_rule']])
                display(['Step 5, normalization: ' Subjects{sj}])
                funcPath = [targetF filesep Subjects{sj}];
                struct_dir = fullfile(funcPath, 'anat');
                data_dir = fullfile(funcPath, ['dec_subsampling_motor_rule']);
                % D3_normalization performs normalization of functional
                % image to MNI space using the spm_jobman with pre-defined parameters.
                D3_normalization(data_dir, struct_dir, vox_size);
            else
                display('###########################################################')
                display(['############### ' SJs{sj} ', ' runs{sj, r} ' does not exist ###########'])
            end
        end
    end
end

% =========================================================================
%                           Step 6: Smoothing
% =========================================================================

% smoothing --> prefix: s
if smoothing
    kernel_size = [3 3 3]; % smoothing kernel of 3mm

    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 6, Smoothing: ' Subjects{sj}])
            sj_dir = [targetF filesep Subjects{sj}];
            data_dir = [sj_dir filesep ['dec_subsampling',version]];
            % D4_smoothing performs smoothing of functional image with
            % a pre-defined kernel using the spm_jobman with pre-defined parameters.
            D4_smoothing(data_dir, Subjects{sj}, ['^wres_accuracy_minus_chance.nii'], kernel_size);
        end
    end
end