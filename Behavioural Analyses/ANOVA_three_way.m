%% Three way ANOVA (factors: rule, stimulus order, f1 frequency)


clear
close all
clc

%%% Script adapted from Yuan Hao Wu %%%

% Required script: RMAOV33.m 
% https://de.mathworks.com/matlabcentral/fileexchange/9638-rmaov33

% =========================================================================
%                       Get subject's performances
% =========================================================================

% Initialize subject cell array
SJs = {'01', '02', '03', '04', '05','06', '07','08','09','10','11','12','13','14','15','16','17','18','19',...
    '20','21','22','23','24','25','26','27','28','29','30','31'};

% Exclude subjects with performance <0.5 in at least one condition:
exludeSJ = [2,5,7,9,21,22,28,29];
SJs(exludeSJ) = [];

sjs = size(SJs,2); % number of subjects

% Directory containing log files
data_dir = 'D:\eyeDMTC\Logs';
% Initialize performance vector 
perf_FAS_SAF = [];

% Loop over all subjects to get performance per condition (Dependent
% Variable)
for i = 1:sjs
    sj = SJs{i};
    logfile = spm_select('FPList', data_dir, ['^fMRI_', sj, '.*\.mat$']);
    load(logfile);

    FAS_16_12 = mylog.perform(mylog.flutter(:,:,1) == 16 & mylog.flutter(:,:,2) == 12 & mylog.focus == 1);
    FAS_16_20 = mylog.perform(mylog.flutter(:,:,1) == 16 & mylog.flutter(:,:,2) == 20 & mylog.focus == 1);
    FAS_20_16 = mylog.perform(mylog.flutter(:,:,1) == 20 & mylog.flutter(:,:,2) == 16 & mylog.focus == 1);
    FAS_20_24 = mylog.perform(mylog.flutter(:,:,1) == 20 & mylog.flutter(:,:,2) == 24 & mylog.focus == 1);
    FAS_24_20 = mylog.perform(mylog.flutter(:,:,1) == 24 & mylog.flutter(:,:,2) == 20 & mylog.focus == 1);
    FAS_24_28 = mylog.perform(mylog.flutter(:,:,1) == 24 & mylog.flutter(:,:,2) == 28 & mylog.focus == 1);
    FAS_28_24 = mylog.perform(mylog.flutter(:,:,1) == 28 & mylog.flutter(:,:,2) == 24 & mylog.focus == 1);
    FAS_28_32 = mylog.perform(mylog.flutter(:,:,1) == 28 & mylog.flutter(:,:,2) == 32 & mylog.focus == 1);

    perf_FAS_16_12 = sum(FAS_16_12)/length(FAS_16_12);
    perf_FAS_16_20 = sum(FAS_16_20)/length(FAS_16_20);
    perf_FAS_20_16 = sum(FAS_20_16)/length(FAS_20_16);
    perf_FAS_20_24 = sum(FAS_20_24)/length(FAS_20_24);
    perf_FAS_24_20 = sum(FAS_24_20)/length(FAS_24_20);
    perf_FAS_24_28 = sum(FAS_24_28)/length(FAS_24_28);
    perf_FAS_28_24 = sum(FAS_28_24)/length(FAS_28_24);
    perf_FAS_28_32 = sum(FAS_28_32)/length(FAS_28_32);

    SAF_16_12 = mylog.perform(mylog.flutter(:,:,1) == 16 & mylog.flutter(:,:,2) == 12 & mylog.focus == 2);
    SAF_16_20 = mylog.perform(mylog.flutter(:,:,1) == 16 & mylog.flutter(:,:,2) == 20 & mylog.focus == 2);
    SAF_20_16 = mylog.perform(mylog.flutter(:,:,1) == 20 & mylog.flutter(:,:,2) == 16 & mylog.focus == 2);
    SAF_20_24 = mylog.perform(mylog.flutter(:,:,1) == 20 & mylog.flutter(:,:,2) == 24 & mylog.focus == 2);
    SAF_24_20 = mylog.perform(mylog.flutter(:,:,1) == 24 & mylog.flutter(:,:,2) == 20 & mylog.focus == 2);
    SAF_24_28 = mylog.perform(mylog.flutter(:,:,1) == 24 & mylog.flutter(:,:,2) == 28 & mylog.focus == 2);
    SAF_28_24 = mylog.perform(mylog.flutter(:,:,1) == 28 & mylog.flutter(:,:,2) == 24 & mylog.focus == 2);
    SAF_28_32 = mylog.perform(mylog.flutter(:,:,1) == 28 & mylog.flutter(:,:,2) == 32 & mylog.focus == 2);

    perf_SAF_16_12 = sum(SAF_16_12)/length(SAF_16_12);
    perf_SAF_16_20 = sum(SAF_16_20)/length(SAF_16_20);
    perf_SAF_20_16 = sum(SAF_20_16)/length(SAF_20_16);
    perf_SAF_20_24 = sum(SAF_20_24)/length(SAF_20_24);
    perf_SAF_24_20 = sum(SAF_24_20)/length(SAF_24_20);
    perf_SAF_24_28 = sum(SAF_24_28)/length(SAF_24_28);
    perf_SAF_28_24 = sum(SAF_28_24)/length(SAF_28_24);
    perf_SAF_28_32 = sum(SAF_28_32)/length(SAF_28_32);

    perf_FAS_SAF =  [perf_FAS_SAF;[perf_FAS_16_12, perf_FAS_16_20, perf_FAS_20_16, perf_FAS_20_24, ...
        perf_FAS_24_20, perf_FAS_24_28, perf_FAS_28_24, perf_FAS_28_32, perf_SAF_16_12,...
        perf_SAF_16_20, perf_SAF_20_16, perf_SAF_20_24, perf_SAF_24_20, perf_SAF_24_28,...
        perf_SAF_28_24, perf_SAF_28_32]'];
end

% =========================================================================
%                   Initialize and run the ANOVA
% =========================================================================

% Dependent Variable: Performance per condition
% Apply arcsine square root transformation to the performance data
DV = asin(sqrt(perf_FAS_SAF));

% Subjects:
S = kron(1:sjs, ones(1,16))';

%% within-subject factors:
% Factor 1: task rule (compare f1 against f2 (FAS) vs. f2 against f1 (SAF))
rule = repmat(kron(1:2, ones(1,8))', sjs, 1);

%Factor 2: stimulus order (f1 > f2 vs. f1 < f2)
stim_order = repmat(repmat([1:2]', 8,1), sjs, 1); 

% Factor 3: f1 frequency (16 Hz, 20 Hz, 24 Hz, and 28 Hz)
f1_freq  = repmat(repmat(kron(1:4, ones(1,2))', 2,1), sjs, 1);



% X - n*5 data matrix (Column 1 = dependent variable (performance; column 2 = rule;
% column 3 = stimulus order; column 4 = f1 frequency; column 5 = subject;
X = [DV, rule, stim_order, f1_freq, S];
clearvars -except X

% Run the ANOVA with alpha = 0.05
RMAOV33(X, 0.05)