%% MVPA support vector machine classification batch script for the control analyses (motor response and task rules)

% This Batch Script first specifies what features should be decoded and
% executes it.

clc; clear;

% =========================================================================
%                   Specify parameters and analyses
% =========================================================================

% Add vector of subject numbers (e.g. 1,2,3,4,5) if any subject has been
% already analysed to exclude that subjects from the analysis
excludeSJ = [];

% Specify the current prefix (here r because the realigned images are used)
currPrefix = ['r'];


first_level_glm = 1; % First level GLM
dec_anal        = 1; % Support vector regression analysis
normalization   = 1; % Normalization
smoothing       = 1; % Smoothing

% Add necessary paths
addpath('C:\Users\nnu16\Documents\MATLAB\spm12'); % SPM
addpath('C:\Users\nnu16\Documents\MATLAB\decoding_toolbox'); % The Decoding Toolbox
addpath('D:\eyeDMTC\fMRI Analyses\Preprocessing'); % Path containing pre-processing scripts
addpath('D:\eyeDMTC\fMRI Analyses\Control Analyses'); % Path containing decoding scripts
addpath('D:\eyeDMTC\fMRI Analyses\Main Analyses'); % Path containing decoding scripts

% Specify data paths
targetF = 'D:\eyeDMTC\data';    % target directory for all nifti files

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

% Choose what you want to decode: '_left_vs_right' for motor response, '_rule' for rule decoding
version = '_rule'; 
if strcmp('_left_vs_right',version)
    condnames = {'decision_left', 'decision_right'}; 
elseif strcmp('_rule',version) || strcmp('_rule_sub',version)
    condnames = {'FAS', 'SAF'}; % First against second, Second against first
end

duration = 0; % epoch duration, 0 because it is a single event
refslice=slice_order(round(length(slice_order)/2)); % reference slice for slice-time correction
hpf      = 192; % High-pass filter cut-off;
hm = 1;   % include head motion parameters from realignment
rad = 4; % Searchlight radius


% =========================================================================
%                           Step 2: First level GLM
% =========================================================================

if first_level_glm
    outputfolder = append('\decoding_glm',version);
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 2, 1st level glm: ' Subjects{sj} ])
            % D1_glm_1stLevel_left_vs_right: GLM for motor response
            % D1_glm_1stLevel_rule: GLM for rule
            if strcmp('_left_vs_right',version)
                D1_glm_1stLevel_left_vs_right(Subjects, sj, outputfolder, TR, hpf,...
                    runs, duration, hm, currPrefix);
            elseif strcmp('_rule',version)
                D1_glm_1stLevel_rule(Subjects, sj, outputfolder, TR, hpf,...
                    runs, duration, hm, currPrefix);
            end
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
            display(['Step 3, Decoding: ' Subjects{sj} ])
            beta_dir = fullfile(targetF, Subjects{sj}, append('decoding_glm',version));
            output_dir = fullfile(targetF, Subjects{sj}, ['r',num2str(rad)], append('dec',version));
            % Performs decoding for the respective version
            D2_Decoding_SVM(beta_dir, output_dir, labelnames, dec_type, rad);
        end
    end
end


% =========================================================================
%                           Step 4: Normalization
% =========================================================================

% normalization --> prefix: w
if normalization
    vox_size = [2 2 2]; % Normalize to 2x2x2 voxel size
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            if exist(fullfile(targetF, Subjects{sj},['r',num2str(rad)], append('dec',version)))
                display(['Step 4, normalization: ' Subjects{sj}])
                funcPath = [targetF filesep Subjects{sj}];
                struct_dir = fullfile(funcPath, 'anat');
                data_dir = fullfile(funcPath, ['r',num2str(rad)], append('dec',version));
                % D3_normalization performs normalization of functional
                % image to MNI space using the spm_jobman with pre-defined parameters.
                D3_normalization(data_dir, struct_dir, vox_size);
            else
                display('###########################################################')
                display(['############### ' Subjects{sj} ', ' runs{sj, r} ' does not exist ###########'])
            end
        end
    end
end

% =========================================================================
%                           Step 5: Smoothing
% =========================================================================

% smoothing --> prefix: s
if smoothing
    kernel_size = [3 3 3]; % smoothing kernel of 3mm

    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 5, Smoothing: ' Subjects{sj}])
            sj_dir = [targetF filesep Subjects{sj}];
            data_dir = fullfile(sj_dir,['r',num2str(rad)], append('dec',version));
            % D4_smoothing performs smoothing of functional image with
            % a pre-defined kernel using the spm_jobman with pre-defined parameters.
            D4_smoothing(data_dir, Subjects{sj}, ['^wres_accuracy_minus_chance.nii'], kernel_size);
        end
    end
end