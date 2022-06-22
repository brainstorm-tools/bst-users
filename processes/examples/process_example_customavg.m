function varargout = process_example_customavg( varargin )
% PROCESS_EXAMPLE_CUSTOMAVG: Example file that reads all the data files in input, and saves the average.

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
% Authors: Francois Tadel, 2013

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Process example: Custom average';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Examples';
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 2;
    % Definition of the options
    % === OPTION EXAMPLE
    sProcess.options.example1.Comment = {'Choice 1', 'Choice 2', 'Choice 3'};
    sProcess.options.example1.Type    = 'radio';
    sProcess.options.example1.Value   = 1;
    % === OPTION EXAMPLE
    sProcess.options.example2.Comment = 'Example option 2';
    sProcess.options.example2.Type    = 'checkbox';
    sProcess.options.example2.Value   = 1;
    % === OPTION EXAMPLE
    sProcess.options.example3.Comment = 'Example option 3: ';
    sProcess.options.example3.Type    = 'value';
    sProcess.options.example3.Value   = {5, 'units', 2};
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
    example1 = sProcess.options.example1.Value;
    example2 = sProcess.options.example2.Value;
    example3 = sProcess.options.example3.Value{1};

    % ===== LOAD THE DATA =====
    % Read the first file in the list, to initialize the loop
    DataMat = in_bst(sInputs(1).FileName, [], 0);
    epochSize = size(DataMat.F);
    Time = DataMat.Time;
    % Initialize the load matrix: [Nchannels x Ntime x Nepochs]
    AllMat = zeros(epochSize(1), epochSize(2), length(sInputs));
    % Reading all the input files in a big matrix
    for i = 1:length(sInputs)
        % Read the file #i
        DataMat = in_bst(sInputs(i).FileName, [], 0);
        % Check the dimensions of the recordings matrix in this file
        if ~isequal(size(DataMat.F), epochSize)
            % Add an error message to the report
            bst_report('Error', sProcess, sInputs, 'One file has a different number of channels or a different number of time samples.');
            % Stop the process
            return;
        end
        % Add the current file in the big load matrix
        AllMat(:,:,i) = DataMat.F;
    end

    % ===== PROCESS =====
    % Just doing a simple average of the trials, can be replaced with anything
    AllMat = mean(AllMat, 3);

    % ===== SAVE THE RESULTS =====
    % Get the output study (pick the one from the first file)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat = db_template('datamat');
    DataMat.F           = AllMat;
    DataMat.Comment     = 'Custom comment';
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = Time;
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = length(sInputs);         % Number of epochs that were averaged to get this file
    % Create a default output filename
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_custom_');
    % Save on disk
    save(OutputFiles{1}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, DataMat);
end
