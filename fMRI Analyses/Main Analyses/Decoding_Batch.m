%% MVPA support vector machine analysis batch script

% This Batch Script specifies preprocessing and decoding analyses and
% executes the respective scripts

clc; close all; clear;

% =========================================================================
%                   Specify parameters and analyses
% =========================================================================

% Add vector of subject numbers (e.g. 1,2,3,4,5) if any subject has been
% already analysed to exclude that subjects from the analysis
excludeSJ = [];


% Specify the current prefix (e.g. ra if the slice-time corrected and
% realigned images should be used)
currPrefix = ['r'];



dicom_import    = 1; % Import dicom to nifti
realignment     = 1; % realigment
coregister      = 1; % Coregister T1 to functional images
segmentation    = 1; % Segmentation of T1
delete_glms     = 1; % Delete existing GLMs
first_level_glm = 1; % First level GLM
dec_anal        = 1; % Support vector machine analysis
normalization   = 1; % Normalization
smoothing       = 1; % Smoothing

% Add necessary paths
addpath('C:\Users\nnu16\Documents\MATLAB\spm12'); % SPM
addpath('C:\Users\nnu16\Documents\MATLAB\decoding_toolbox'); % The Decoding Toolbox
addpath('D:\eyeDMTC\fMRI Analyses\Preprocessing'); % Path containing pre-processing scripts
addpath(genpath('C:\Users\nnu16\Documents\MATLAB\hMRI-toolbox-0.5.0')); % hmri toolbox
addpath(genpath('C:\Users\nnu16\Documents\MATLAB\DPABI_V8.2_240510'))
addpath('D:\eyeDMTC\fMRI Analyses\Main Analyses'); % Path containing decoding scripts

% Specify data paths
sourceF = 'D:\eyeDMTC\rawdata'; % source directory containing raw dicom files
targetF = 'D:\eyeDMTC\data';    % target directory for all nifti files


% =========================================================================
%       Step 1: Import dicom files to BIDS formatted nifti files
% =========================================================================

if dicom_import
    sess = [0 1]; % First entry: Do wou want an extra instance for session folders?
    % (yes = 1, no = 0)
    % Second entry: How many sessions are there per subject? (eg. 1 or 4) Not runs!
    if ~exist(targetF, 'dir')
        mkdir(targetF);
    end

    cd(sourceF);
    pb = dir('*ccnb_*'); % List of all directories with the relevant raw data
    task = 'task';

    for subj = 1:length(pb)
        if ismember(subj, excludeSJ)
            continue;
        else
            if subj < 10
                sub = ['00' num2str(subj)];
            elseif subj < 100
                sub = ['0' num2str(subj)];
            else
                sub = num2str(subj);
            end
            fSubj = [targetF '/sub-' sub '/']; % Name subject directory
            if ~exist(fSubj, 'dir'), mkdir(fSubj); end
            dcmDir = [pb(subj).folder filesep pb(subj).name]; % Corresponding dicom directory
            % Call dicm2bids function that uses Xiangrui Li's dicm2nii.m
            A1_dicm2bids(dcmDir, targetF, subj, task, sess);
        end
    end
end

% =========================================================================
%           Step 2: Data organization and analysis configuration
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

% Specify condition names (first number refers to f1 frequency, second to
% f2 frequency, low or high refers to the correct decision. E.g. in
% 16_12_low participants had to compare f2 against f1, such that the
% correct decision was lower, while in 16_12_high participants had to
% compare f1 against f2 so the correct decision was higher
condnames = {'High', 'Low'};
duration = 0; % epoch duration, 0 because it is a single event
refslice=slice_order(round(length(slice_order)/2)); % reference slice for slice-time correction
hpf      = 192; % High-pass filter cut-off;
hm = 1;   % include head motion parameters from realignment
% in the white matter and cerebrospinal fluid signals
rad = 4; % Searchlight radius


% =========================================================================
%                       Step 3: Realignment
% =========================================================================

% Realignment --> prefix: r
if realignment
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            sj_dir = [targetF filesep Subjects{sj}];
            if exist([targetF filesep Subjects{sj} filesep 'func' filesep runs{sj, r}])
                display(['Step 3, realignment: ' Subjects{sj} ', ' runs{sj, r}])
                funcPath = [targetF filesep Subjects{sj} filesep 'func'];
                run_dir = fullfile(funcPath);
                for r = 1:size(runs, 2)
                    run_files{r} = spm_select('List',run_dir,['^' currPrefix runs{sj, r}]);
                end
                % A4_realignment performs Realignment: Estimate & Reslice 
                % using the spm_jobman with the pre-defined parameters
                A3_Realignment([sj_dir filesep 'func'], run_files);
            else
                display('###########################################################')
                display(['############### ' Subjects{sj} ', '...
                    runs{sj, r} ' does not exist ###########'])
            end
        end

    end
    currPrefix=['r' currPrefix]; % add the prefix r
end

% =========================================================================
%                       Step 4: Coregistration
% =========================================================================

if coregister
    Co_er = 0; % default setting: only estimate (no reslice), if 1, then estimate & reslice
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            if exist([targetF filesep Subjects{sj} filesep 'func'])
                funcPath    = [targetF filesep Subjects{sj}];
                func_dir    = fullfile(funcPath, 'func');
                struct_dir  = fullfile(funcPath, 'anat');
                if Co_er ~= 1
                    display(['Step 5, coregistration (estimate): ' Subjects{sj}])
                    % A5a_coregister_est performs coregistration using the 
                    % spm_jobman with the pre-defined parameters. It 
                    % coregisters the structural image to the mean of the 
                    % functional images.
                    A4a_coregister_est(currPrefix, func_dir, struct_dir, '^sub.*\.nii', '^means.*\.nii');
                    %meana if slice time correction is applied
                else
                    display(['Step 5b, coregistration (estimate & reslice): ' Subjects{sj}])
                    A5b_coregister_est_re(currPrefix, func_dir, struct_dir, Subjects{sj}, '^sub.*\.nii', '^means.*\.nii');
                end
            else
                display('###########################################################')
                display(['############### ' Subjects{sj} 's functional data do not exist ###########'])
            end
        end
    end
end

% =========================================================================
%                           Step 5: Segmentation
% =========================================================================

% Segmentation --> prefix y_ (to structural image)
if segmentation
    warning off
    SPM_path  = 'C:\Users\nnu16\Documents\MATLAB\spm12';
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        elseif exist([targetF filesep Subjects{sj} filesep ana])==7
            display(['Step 6, segmentation: ' Subjects{sj}])
            struct_dir = fullfile(targetF, Subjects{sj}, 'anat');
            % A6_segmentation performs segmentation of the structural image
            % using the spm_jobman with pre-defined parameters. 
            A6_segmentation(struct_dir, Subjects{sj}, SPM_path, '^sub.*\.nii');
        else
            display('###########################################################')
            display(['############### ' Subjects{sj} ', ' ana ' does not exist ###########'])
        end
    end
end



% =========================================================================
%                           Step 6: First level GLM
% =========================================================================

if first_level_glm
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            outputfolder = '\decoding_glm';
            display(['Step 8, 1st level glm: ' Subjects{sj}])
            subj_dir = fullfile(targetF, Subjects{sj});
            % D1_glm_1stLevel_SVM sets up a GLM estimating betas for the 2
            % conditions
            D1_glm_1stLevel_SVM(Subjects, sj, outputfolder, TR,...
                hpf, runs, duration, hm, CSFWM_params, currPrefix);
        end
    end
end

% =========================================================================
%                           Step 7: Decoding
% =========================================================================

if dec_anal
    labelnames = condnames;
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 9, Decoding: ' Subjects{sj} ])
            beta_dir = fullfile(targetF, Subjects{sj}, 'decoding_glm');
            output_dir = fullfile(targetF, Subjects{sj}, ['r',num2str(rad)], 'dec');
            % D2_Decoding_SVM runs the SVM classification analysis          
            D2_Decoding_SVM(beta_dir, output_dir, labelnames, dec_type, rad);
        end
    end
end


% =========================================================================
%                           Step 8: Normalization
% =========================================================================

% normalization --> prefix: w
if normalization
    vox_size = [2 2 2]; % Normalize to 2x2x2 voxel size
    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            if exist(fullfile(targetF, Subjects{sj},['r',num2str(rad)], 'dec'))
                display(['Step 10, normalization: ' Subjects{sj}])
                funcPath = [targetF filesep Subjects{sj}];
                struct_dir = fullfile(funcPath, 'anat');
                data_dir = fullfile(funcPath,['r',num2str(rad)],'dec');
                % A8_normalization_SVR performs normalization of functional
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
%                           Step 9: Smoothing
% =========================================================================

% smoothing --> prefix: s
if smoothing
    kernel_size = [3 3 3]; % smoothing kernel of 3mm

    for sj = 1:numel(Subjects)
        if ismember(sj, excludeSJ)
            continue;
        else
            display(['Step 11, Smoothing: ' Subjects{sj}])
            sj_dir = [targetF filesep Subjects{sj}];
            data_dir = fullfile(sj_dir,['r',num2str(rad)],'dec');
            % A8_smoothing_run performs smoothing of functional image with
            % a pre-defined kernel using the spm_jobman with pre-defined parameters.
            D4_smoothing(data_dir, Subjects{sj}, ['^wres_accuracy_minus_chance.nii'], kernel_size);
        end
    end
end