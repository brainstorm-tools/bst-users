function varargout = process_beamformer_test( varargin )
% PROCESS_BEAMFORMER_TEST:

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
%
% Copyright (c)2000-2013 Brainstorm by the University of Southern California
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
% license can be found at http://www.gnu.org/copyleft/gpl.html.
%
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors:

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Beamformer test #1';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'results'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Definition of the options
    % === ACTIVE STATE
    sProcess.options.active_time.Comment = 'Active state time window: ';
    sProcess.options.active_time.Type    = 'timewindow';
    sProcess.options.active_time.Value   = [];
    % === ACTIVE STATE
    sProcess.options.minvar_time.Comment = 'Minimum variance time window: ';
    sProcess.options.minvar_time.Type    = 'timewindow';
    sProcess.options.minvar_time.Value   = [];
    % === REGULARIZATION
    sProcess.options.reg.Comment = 'Regularization parameter: ';
    sProcess.options.reg.Type    = 'value';
    sProcess.options.reg.Value   = {0.03, ' ', 4};
    % === Sensor types
    sProcess.options.sensortypes.Comment = 'Sensor types or names (empty=all): ';
    sProcess.options.sensortypes.Type    = 'text';
    sProcess.options.sensortypes.Value   = 'MEG, EEG';
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Initialize returned list of files
    OutputFiles = {};
    % Get option values
    ActiveTime  = sProcess.options.active_time.Value{1};
    MinVarTime  = sProcess.options.minvar_time.Value{1};
    Reg         = sProcess.options.reg.Value{1};
    SensorTypes = sProcess.options.sensortypes.Value;

    % ===== LOAD CHANNEL FILE =====
    % Load channel file
    ChannelMat = in_bst_channel(sInputs(1).ChannelFile);
    % Find the MEG channels
%     iMEG = good_channel(ChannelMat.Channel, [], 'MEG');
%     iEEG = good_channel(ChannelMat.Channel, [], 'EEG');
%     iSEEG = good_channel(ChannelMat.Channel, [], 'SEEG');
%     iECOG = good_channel(ChannelMat.Channel, [], 'ECOG');
    iChannels = channel_find(ChannelMat.Channel, SensorTypes);

    % ===== LOAD HEAD MODEL =====
    % Get channel study
    [sChannelStudy, iChannelStudy] = bst_get('ChannelFile', sInputs(1).ChannelFile);
    % Load the default head model
    HeadModelFile = sChannelStudy.HeadModel(sChannelStudy.iHeadModel).FileName;
    sHeadModel = load(file_fullpath(HeadModelFile));
    % Get number of sources
    nSources = length(sHeadModel.GridLoc);

    % ===== LOAD THE DATA =====
    % Read the first file in the list, to initialize the loop
    DataMat = in_bst(sInputs(1).FileName, [], 0);
    nChannels = size(DataMat.F,1);
    nTime     = size(DataMat.F,2);
    Time = DataMat.Time;
    % Find the indices for covariance calculation
    iActiveTime = panel_time('GetTimeIndices', Time, ActiveTime);
    iMinVarTime = panel_time('GetTimeIndices', Time, MinVarTime);
    % Initialize the covariance matrices
    ActiveCov = zeros(nChannels, nChannels);
    MinVarCov = zeros(nChannels, nChannels);
    nTotalActive = zeros(nChannels, nChannels);
    nTotalMinVar = zeros(nChannels, nChannels);
    % Reading all the input files in a big matrix
    for i = 1:length(sInputs)
        % Read the file #i
        DataMat = in_bst(sInputs(i).FileName, [], 0);
        % Check the dimensions of the recordings matrix in this file
        if (size(DataMat.F,1) ~= nChannels) || (size(DataMat.F,2) ~= nTime)
            % Add an error message to the report
            bst_report('Error', sProcess, sInputs, 'One file has a different number of channels or a different number of time samples.');
            % Stop the process
            return;
        end
        % Get good channels
        iGoodChan = find(DataMat.ChannelFlag == 1);
        % Average baseline values
        FavgActive = mean(DataMat.F(iGoodChan,iActiveTime), 2);
        FavgMinVar = mean(DataMat.F(iGoodChan,iMinVarTime), 2);
        % Remove average
        DataActive = bst_bsxfun(@minus, DataMat.F(iGoodChan,iActiveTime), FavgActive);
        DataMinVar = bst_bsxfun(@minus, DataMat.F(iGoodChan,iMinVarTime), FavgMinVar);
        % Compute covariance for this file
        fileActiveCov = DataMat.nAvg .* (DataActive * DataActive');
        fileMinVarCov = DataMat.nAvg .* (DataMinVar * DataMinVar');
        % Add file covariance to accumulator
        ActiveCov(iGoodChan,iGoodChan) = ActiveCov(iGoodChan,iGoodChan) + fileActiveCov;
        MinVarCov(iGoodChan,iGoodChan) = MinVarCov(iGoodChan,iGoodChan) + fileMinVarCov;
        nTotalActive(iGoodChan,iGoodChan) = nTotalActive(iGoodChan,iGoodChan) + length(iActiveTime);
        nTotalMinVar(iGoodChan,iGoodChan) = nTotalMinVar(iGoodChan,iGoodChan) + length(iMinVarTime);
    end
    % Remove zeros from N matrix
    nTotalActive(nTotalActive <= 1) = 2;
    nTotalMinVar(nTotalMinVar <= 1) = 2;
    % Divide final matrix by number of samples
    ActiveCov = ActiveCov ./ (nTotalActive - 1);
    MinVarCov = MinVarCov ./ (nTotalMinVar - 1);


    % ===== PROCESS =====
    % Processing iChannels
    %%%% TO EDIT %%%%%
    ImageGridAmp = rand(nSources, nTime);
    GridLoc = rand(nSources, 3);

    % ===== SAVE THE RESULTS =====
    % Create a new data file structure
    ResultsMat = db_template('resultsmat');
    ResultsMat.ImagingKernel = [];
    ResultsMat.ImageGridAmp  = ImageGridAmp;
    ResultsMat.nComponents   = 1;   % 1 or 3
    ResultsMat.Comment       = 'TEST';
    ResultsMat.Function      = 'NameMethod';
    ResultsMat.Time          = Time;           % Leave it empty if using ImagingKernel
    ResultsMat.DataFile      = [];
    ResultsMat.HeadModelFile = HeadModelFile;
    ResultsMat.HeadModelType = sHeadModel.HeadModelType;
    ResultsMat.ChannelFlag   = [];
    ResultsMat.GoodChannel   = iChannels;
    ResultsMat.SurfaceFile   = sHeadModel.SurfaceFile;
    ResultsMat.GridLoc       = GridLoc;

    % === NOT SHARED ===
    % Get the output study (pick the one from the first file)
    iStudy = sInputs(1).iStudy;
    % Create a default output filename
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'results_');
%     % === SHARED ===
%     % Get the output study (pick the one from the first file)
%     iStudy = iChannelStudy;
%     % Create a default output filename
%     OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).ChannelFile), 'results_KERNEL_');

%     OutputFiles{2} = ...

    % Save on disk
    save(OutputFiles{1}, '-struct', 'ResultsMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, ResultsMat);
end
