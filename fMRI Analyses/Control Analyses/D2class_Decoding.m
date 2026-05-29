function D2class_Decoding(beta_dir, output_dir, labelnames, dec_type, rad)
% This Batch Script first specifies what features should be decoded and
% executes the Decoding analysis.
% The resulting accuracy maps should later be normalized and smoothed

% Create output directory if it does not exist yet
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% =========================================================================
%               Configure input for The Decoding Toolbox
% =========================================================================


clear cfg
cfg = decoding_defaults;
cfg.software = 'SPM12';

% Specify where the results should be saved
cfg.results.overwrite     = 1;
cfg.results.dir           = output_dir;

% DATA SCALING
cfg.scale.method          = 'z';    % standardize the data
cfg.scale.estimation      = 'all';  % only training, only test data, or all

% SEARCHLIGHT SPECIFICATIONS
cfg.analysis              = dec_type;   % = searchlight
cfg.searchlight.unit      = 'voxels';   % Searchlight radius in voxels (not mm) 
cfg.searchlight.radius    = rad;        % 5 voxel radius
cfg.searchlight.spherical = 0;          % only useful for mm
% The amount of information you want to have printed on the screen
% 0: no, 1: normal, output, 2: all):
cfg.verbose               = 0;  

% Method and model parameters 
cfg.decoding.method = 'classification'; % Define classification as the method
cfg.decoding.train.classification.model_parameters = '-s 0 -t 0 -c 1 -b 0 -q'; 

% OUTPUTS SPECIFICATION
cfg.results.output = {'accuracy_minus_chance'}; % 

% DISPLAY:
cfg.plot_selected_voxels  = 0; % 0: no plotting, 1: every step, 2: every second step ...
% 100: every hundredth step ...

cfg.plot_design           = 1; % plots the design every time

if dec_type == 'roi'
    cfg.files.mask = masks;
else
    cfg.files.mask = [beta_dir filesep 'mask.nii']; % The mask created with the GLM
end

% =========================================================================
%                       Specify and run the decoding
% =========================================================================

% Decoding DESIGN
labels = [1 -1]; 
 
% The following function extracts all beta names and corresponding run
% numbers from the SPM.mat
regressor_names = design_from_spm(beta_dir);

% Extract all information for the cfg.files structure
cfg = decoding_describe_data(cfg,labelnames,labels,regressor_names,beta_dir);

% This creates the leave-one-run-out cross validation design:
cfg.design = make_design_cv(cfg);
display_design(cfg);

%% Run decoding
 results = decoding(cfg);