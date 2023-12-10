function varargout = process_sleepspindle_parameters ( varargin )
% PROCESS_SLEEPSPINDLE PARAMETERS: Calculates duration, frequency,
% amplitude, symmetry, RMS and activity of the sleep spindles.
% Spindle density requires input from stage2 epochs therefore will be calculated separately.
% Author: by MinChul Park (October 2023)
% University of Canterbury | Te Whare Wānanga o Waitaha
% Christchurch | Ōtautahi
% New Zealand | Aotearoa
% Contributor: Raymundo Cassani, Brainstorm software engineer

eval(macro_method);
end

%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Sleep spindle parameters';
    sProcess.FileTag     = 'SS_P';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Custom Processes';
    sProcess.Index       = 1000;
    sProcess.Description = 'https://github.com/park-minchul/Brainstorm-Custom-Processes/blob/main/Sleep%20Spindle%20Parameters/README.md';
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data'};
    sProcess.OutputTypes = {'data'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;

    % Description of the process
    sProcess.options.info.Comment = ['Takes in X number of sleep spindles (each input data file = one spindle) and calculates the following parameters.<BR><BR>'...
                                     '1. Spindle duration in seconds.<BR>'...
                                     '2. Spindle frequency in Hz.<BR>'...
                                     '3. Spindle maximum peak to peak amplitude.<BR>'...
                                     '4. Spindle symmetry in percentage of the duration.<BR>'...
                                     '5. Spindle RMS amplitude.<BR>'...
                                     '6. Spindle activity which is peak to peak amplitude*duration.<BR><BR>'...
                                     'Definition of spindle parameters from "Warby et al. (2014)<BR>'...
                                     'Nat Methods . 2014 Apr;11(4):385-92. doi: 10.1038/nmeth.2855."<BR><BR>'...
                                     'Notes<BR>'...
                                     'A) This process assumes that the data was already filtered between 11-16 Hz.<BR>'...
                                     'B) This process will generate 6 matrix files containing duration, frequency, amplitude, symmetry, RMS and activity features from all input files.<BR>'...
                                     'C) Each file x-axis = spindle number but the units will = Time(s). Cannot be changed.<BR>'...
                                     'D) Follow the online tutorial which will take you to the GitHub README.md written by the<BR>'...
                                     'author of this process to further understand how the process works.<BR><BR>'
                                     ];
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
    % Numer of inputs or epochs
    Nepochs     = length(sInputs);
    % Find EEG channels for each input file
    sChannel   = bst_get('ChannelForStudy', [sInputs(1).iStudy]);
    ChannelMat = in_bst_channel(sChannel.FileName, 'Channel');
    eegIxs     = strcmpi({ChannelMat.Channel.Type}, 'EEG');
    Nchannels  = sum(eegIxs); % Number of EEG channels

    % Generate matrices of zeros (N_EEGchannels X Nepochs) to concatenate results
    SS_Dur = zeros (Nchannels,Nepochs); % Spindle duration
    SS_Rms = zeros (Nchannels,Nepochs); % Spindle RMS 
    CountP = zeros (Nchannels,Nepochs); % Count the number of peaks
    PeakPo = zeros (Nchannels,Nepochs); % Positive peaks
    PeakNe = zeros (Nchannels,Nepochs); % Negative peaks 
    TimePP = zeros (Nchannels,Nepochs); % Time of max positive peak
    TimeNP = zeros (Nchannels,Nepochs); % Time of max negative peak

    % ===== LOAD THE DATA =====
    for iNepochs = 1 : Nepochs
        DataMat = in_bst(sInputs(iNepochs).FileName, [], 0);
        Data    = DataMat.F; % Actual data containing EEG, EOG and EMG data
        Time    = DataMat.Time(end) - DataMat.Time(1);      % Time information of the recording
        Fs      = 1 ./ (DataMat.Time(2) - DataMat.Time(1)); % Calculation of Sampling frequency

        % ===== PROCESS =====
        % This is where the actual process of data manipulation and calculation takes place.
        DataN = Data*-1; % The negative version of the data

        % Find EEG channels for each input file
        sChannel = bst_get('ChannelForStudy', [sInputs(iNepochs).iStudy]);
        ChannelMat = in_bst_channel(sChannel.FileName, 'Channel');
        eegIxs = find(strcmpi({ChannelMat.Channel.Type}, 'EEG'));
        % Loop over EEG channels
        for i = 1 : length(eegIxs)
            Data_Chan = Data(eegIxs(i),:); % Extracts individual channel info from the data matrix
            % Check for flat channel
            if sum((Data_Chan - mean(Data_Chan)).^2) == 0
                continue;
            end
            % Compute spindle parameters
            [PosP, LocP]       = findpeaks(Data(eegIxs(i),:),Fs);  % Find all the positive peaks and their locations in seconds
            [NegP, LocN]       = findpeaks(DataN(eegIxs(i),:),Fs); % Find all the negative peaks and their locations in seconds
            [PeakPo(i,iNepochs), IndexP] = max(PosP,[],2); % Find the max positive peak per channel and index its location
            [PeakNe(i,iNepochs), IndexN] = max(NegP,[],2); % Find the max negative peak per channel and index its location
            TimePP(i,iNepochs) = LocP(IndexP); % Uses the IndexP vector to find the time point of max positive peak
            TimeNP(i,iNepochs) = LocN(IndexN); % Uses the IndexN vector to find the time point of max negative peak (won't be used further from here though)
            CountP(i,iNepochs) = length(PosP); % Count the number of peak
        end
        % Spindle duration = the number of time samples-1 divided by the sampling frequency
        SS_Dur(:,iNepochs) = Time; % Calculation of spindle duration
        % Spinde frequency = the reciprocal of (the number of peaks/duration)
        SS_Fre             = 1./(SS_Dur./CountP); % Final calculation of spindle frequency
        % Spinde amplitude = the sum of max positive peak and negative peak
        SS_Amp             = PeakPo + PeakNe; % Final calculation of spindle max peak-peak amplitude
        % Spindle symmetry = the percentage of (the time location of max positive peak/spindle duration)
        SS_Sym             = (TimePP./SS_Dur)*100; % Final calculation of spindle symmetry
        SS_Rms(:,iNepochs) = rms(Data(eegIxs,:),2); % Calculation of spindle RMS 
        SS_Act             = SS_Amp.*SS_Dur; % Calculation of spindle activity (μVs)
    end

    % ===== SAVE THE RESULTS =====
    % Get the output Study
    iStudy = sInputs(1).iStudy;
    % Create template matrix file structure
    sOutputBaseMat             = db_template('matrixmat');
    sOutputBaseMat.Time        = 1 : Nepochs; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed. 
    sOutputBaseMat.Description = {ChannelMat.Channel(eegIxs).Name}';
    sOutputBaseMat.nAvg        = Nepochs;     % Number of epochs that were used to get this file

    % Matrix file structure for Sleep Spindle Duration
    sOutputMat         = sOutputBaseMat;
    sOutputMat.Value   = SS_Dur;
    sOutputMat.Comment = sprintf('SS_Dur (%d)', Nepochs);
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Dur');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);

    % Matrix file structure for Sleep Spindle Frequency
    sOutputMat = sOutputBaseMat;
    sOutputMat.Value   = SS_Fre;
    sOutputMat.Comment = sprintf('SS_Fre (%d)', Nepochs); % Names the output file as 'SS_Fre' with the number of epochs used to generate the file.
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Fre');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);

    % Matrix file structure for Sleep Spindle Amplitude
    sOutputMat = sOutputBaseMat;
    sOutputMat.Value   = SS_Amp;
    sOutputMat.Comment = sprintf('SS_Amp (%d)', Nepochs); % Names the output file as 'SS_Amp' with the number of epochs used to generate the file.
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Amp');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);

    % Matrix file structure for Sleep Spindle Symmetry
    sOutputMat = sOutputBaseMat;
    sOutputMat.Value   = SS_Sym;
    sOutputMat.Comment = sprintf('SS_Sym (%d)', Nepochs); % Names the output file as 'SS_Sym' with the number of epochs used to generate the file.
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Sym');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);

    % Matrix file structure for Sleep Spindle RMS
    sOutputMat = sOutputBaseMat;
    sOutputMat.Value   = SS_Rms;
    sOutputMat.Comment = sprintf('SS_Rms (%d)', Nepochs); % Names the output file as 'SS_Rms' with the number of epochs used to generate the file.
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Rms');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);

    % Matrix file structure for Sleep Spindle Activity
    sOutputMat = sOutputBaseMat;
    sOutputMat.Value   = SS_Act;
    sOutputMat.Comment = sprintf('SS_Act (%d)', Nepochs); % Names the output file as 'SS_Act' with the number of epochs used to generate the file.
    % Create a default output filename 
    OutputFiles{end+1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'matrix_SS_Act');
    % Save on disk
    save(OutputFiles{end}, '-struct', 'sOutputMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{end}, sOutputMat);
end
