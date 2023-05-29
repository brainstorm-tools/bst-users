function varargout = process_wavg_rnoise_nepoch_fsp( varargin )
% PROCESS_WAVG_RNOISE_NEPOCH_FSP: Calculates weighted average, classic and weighted residual noise,
% noise per epoch and classic and weighted Fsp of all epochs as inspired from
% "Evaluating residual background noise in human auditory brain-stem responses by
% Manuel Don, and Claus Elberling, 1994" AND
% Elberling and Don (1984) Quality estimation of averaged auditory brainstem responses
% Scandinavian Audiology 13: 187-197
%
% Author MINCHUL PARK (June 2022)
% University of Canterbury | Te Whare Wānanga o Waitaha
% Christchurch | Ōtautahi
% New Zealand | Aotearoa
%
% Contributors: François Tadel and Raymundo Cassani

eval(macro_method);
end

%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'WAvg RNoise NEpoch Fsp';
    sProcess.FileTag     = 'WAvg RNoise NEpoch Fsp';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Custom Processes';
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 2;

    % Description of the process
    sProcess.options.info.Comment = ['1. Calculates epoch specific weightings then evaluates weighted averaging.<BR>'...
                                     '2. Calculates classic and weighted residual noise from all epochs.<BR>' ...
                                     '3. Calculates noise per epoch for X number of epochs.<BR>' ...
                                     '4. Calculates Fsp values (classic and weighted) from the given ABR epochs.<BR><BR>'...
                                     'Methods were inspired from "Evaluating residual background noise in human ABR<BR>'...
                                     'by Manuel Don, and Claus Elberling, (1994)."<BR><BR>' ...
                                     'The seminal article on ABR Fsp is from Elberling and Don (1984)<BR>'...
                                     'Quality estimation of averaged auditory brainstem responses.<BR>'...
                                     'Scandinavian Audiology 13: 187-197.<BR><BR>'...
                                     'Notes<BR>' ...
                                     '1. In residual noise and noise per epoch calculations, the x-axis = epoch number<BR>'...
                                     'but the units will = "Time (s)". Unfortunately this cannot be changed.<BR><BR>' ...
                                     '2. This process will generate four files - weighted average, classic residual noise,<BR>'...
                                     'weighted residual noise and noise per epoch.<BR><BR>'...
                                     '3. The noise value is essentially the standard deviation of each epoch.<BR><BR>'...
                                     '4. ABR Fsp degrees of freedom = 15<BR><BR>'...
                                     '5. Time = 1 in Fsp to be able to open the figures.<BR><BR>'];
    sProcess.options.info.Type    = 'label';
    sProcess.options.info.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
     Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Initialize returned list of files
    OutputFiles = {};

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
    % Calculation of Weighted Average
    Nchannels = epochSize(1); % Number of channels.
    Nepochs   = length(sInputs); % Number of epochs.
    EpochW    = ones(Nchannels,1,Nepochs)./var((AllMat),0,2); % Calculation of epoch specific weighting.
    WEpoch    = EpochW.*(AllMat); % Application of epoch specific weighting to all epochs.
    WAvg      = sum(WEpoch,3)./sum(EpochW,3); % Calculation of weighted averaging through the weighted epochs.

    % Calculation of Classic Residual Noise, Weighted Residual Noise and Noise per Epoch.
    ESqrt     = sqrt(linspace (1,(Nepochs),(Nepochs))); % Sqrt of 1 to epoch number n.
    EpochW2D  = reshape(EpochW, [Nchannels Nepochs]); % Changes EpochW 3D matrix into 2D matrix for easier manipulation.
    EpochNum  = linspace (1,(Nepochs),(Nepochs)); % Changes the x-axis from time (s) to epoch number n.

    % Calculation of ABR_Fsp
    AllMatFsp = AllMat;
    EpochWFsp = ones(Nchannels,1,Nepochs)./var((AllMatFsp),0,2); % Calculation of epoch specific weighting (Fsp use).
    WEpochFsp = EpochWFsp.*(AllMatFsp); % Application of epoch specific weighting to all epochs (Fsp use).

    CRN       = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros.
    WRNN      = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros
    WRND      = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros
    NEpoch    = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros.
    SpWEpoch  = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros.
    SpEpoch   = zeros(Nchannels, Nepochs); % Creates Nchannels X Nepochs matrix of zeros.

    % The for loops down below were originally separated but upon testing,
    % combining them together proved slightly faster, thus they are in this
    % current form.

        for j = 1 : Nepochs
            CRN(:,j) = std(AllMat(:, :, 1:j), 0, [2 3]); % for loop to calculate std of data in rows and over pages of epochs.

            WRNN(:,j) = std(WEpoch(:, :, 1:j), 0, [2 3]); % for loop to calculate std of weighted data in [2 3] dimension the mean of epoch weighting in rows.
            WRND(:,j) = mean(EpochW2D(:, 1:j), 2);

            NEpoch(:,j) = std(AllMat(:, :, j), 0, 2); % for loop to calculate std of data in rows of epochs.

            % for loop selects the single time point (column) of every epoch and adds it to the zeros matrix.
            SpWEpoch (:,j) = WEpochFsp (:,263,j); % [Nchannels X Nepochs]
            SpEpoch  (:,j) = AllMatFsp (:,263,j); % [Nchannels X Nepochs]
        end

    CRN       = CRN./ESqrt; % Final calculation of classic residual noise. Generates 6 X 6000 double matrix.

    WRNN      = WRNN./ESqrt;
    WRN       = WRNN./WRND; % Final calculation of weighted residual noise. Generates 6 X 6000 double matrix.

    AvgWEpoch = mean(WEpochFsp,3); % Weighted epoch averaging over epochs (i.e. averaging in time points).
    % Changes [Nchannels x Ntime x Nepochs] into [Nchannels X Ntime].
    AvgWEpoch = AvgWEpoch(:,[183 194 206 217 229 240 252 263 275 286 298 309 321 332 344]); % Selects 15 time points (degrees of freedom). [Nchannels X Ntime points]
    AvgEpoch  = mean(AllMatFsp,3); % Unweighted epoch averaging over epochs.
    AvgEpoch  = AvgEpoch(:,[183 194 206 217 229 240 252 263 275 286 298 309 321 332 344]); % Selects 15 time points (degrees of freedom). [Nchannels X Ntime points]
    TimeFsp   = 1; % Fsp_C and Fsp_W both produce a single value therefore need time = 1 to open the file.

    Numerator_W   = var(AvgWEpoch,0,2); % [Nchannels X 1]
    Denominator_W = var(SpWEpoch,0,2)./(Nepochs); % [Nchannels X 1]

    Numerator_C   = var(AvgEpoch,0,2); % [Nchannels X 1]
    Denominator_C = var(SpEpoch,0,2)./(Nepochs); % [Nchannels X 1]

    Fsp_W = Numerator_W./Denominator_W; % Weighted Fsp final calculation
    Fsp_C = Numerator_C./Denominator_C; % Classic Fsp final calculation

    % ===== SAVE THE RESULTS =====
    % Get the output study (Weighted Average)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = WAvg;
    DataMat.Comment     = sprintf('WAvg (%d)', length(sInputs)); % Names the output file as 'WAvg' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = Time;
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = length(sInputs);         % Number of epochs that were averaged to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_WAvg');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);

    % Get the output study (Classic Residual Noise)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = CRN;
    DataMat.Comment     = sprintf('RNoise_C (%d)', length(sInputs)); % Names the output file as 'RNoise' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochNum; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed.
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = length(sInputs);         % Number of epochs that were averaged to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_RNoise_C');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);

    % Get the output study (Weighted Residual Noise)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = WRN;
    DataMat.Comment     = sprintf('RNoise_W (%d)', length(sInputs)); % Names the output file as 'RNoise' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochNum; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed.
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = length(sInputs);         % Number of epochs that were averaged to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_RNoise_W');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);

    % Get the output study (Noise per epoch)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = NEpoch;
    DataMat.Comment     = sprintf('NEpoch (%d)', length(sInputs)); % Names the output file as 'NEpoch' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochNum; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed.
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = length(sInputs);         % Number of epochs that were averaged to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_NEpoch');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);

    % Get the output study (pick the one from the first file)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = Fsp_C;
    DataMat.Time        = TimeFsp;
    DataMat.Comment     = sprintf('ABR_Fsp_C (%d)', Nepochs); % Names the output file as 'ABR_Fsp_C' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_ABR_Fsp_C');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);

    % ===== SAVE THE RESULTS =====
    % Get the output study (pick the one from the first file)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = Fsp_W;
    DataMat.Time        = TimeFsp;
    DataMat.Comment     = sprintf('ABR_Fsp_W (%d)', Nepochs); % Names the output file as 'ABR_Fsp_W' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_ABR_Fsp_W');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, DataMat);
end
