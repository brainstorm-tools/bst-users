function varargout = process_sleepspindle_parameters ( varargin )
% PROCESS_SLEEPSPINDLE PARAMETERS: Calculates duration, frequency,
% amplitude and symmetry of the sleep spindles.
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
                                     '4. Spindle symmetry in percentage of the duration.<BR><BR>'...
                                     'Definition of spindle parameters from "Warby et al. (2014)<BR>'...
                                     'Nat Methods . 2014 Apr;11(4):385-92. doi: 10.1038/nmeth.2855."<BR><BR>'...
                                     'Notes<BR>'...
                                     'A) This process assumes that the data was already filtered between 11-16 Hz.<BR>'...
                                     'B) This process will generate 4 matrix files containing duration, frequency, amplitude and symmetry features from all input files.<BR>'...
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
    Nepochs     = length(sInputs); % Numer of inputs or epochs
    EpochN      = 1 : Nepochs; % Changes the x-axis from time (s) to epoch number n. 
    DataMat     = in_bst(sInputs(1).FileName, [], 0); % Read the first file in the list, to obtain channel size. 
    epochSize   = size(DataMat.F);    
    Nchannels   = epochSize(1); % Number of ALL channels (i.e. EEG, EOG, EMG and status)

    % Generate matrices of zeros (Nchannels X Nepochs) to concatenate results
    SS_Dur = zeros (Nchannels,Nepochs); % Spindle duration
    CountP = zeros (Nchannels,Nepochs); % Count the number of peaks
    PeakPo = zeros (Nchannels,Nepochs); % Positive peaks
    PeakNe = zeros (Nchannels,Nepochs); % Negative peaks 
    TimePP = zeros (Nchannels,Nepochs); % Time of max positive peak
    TimeNP = zeros (Nchannels,Nepochs); % Time of max negative peak

    % ===== LOAD THE DATA =====
    for iNepochs = 1 : Nepochs
       DataMat   = in_bst(sInputs(iNepochs).FileName, [], 0);
       epochSize = size(DataMat.F);  
       Ntime     = epochSize(2); % Number of time samples changes depending on sleep spindle
       Data      = DataMat.F; % Actual data containing EEG, EOG and EMG data
       Time      = DataMat.Time(end) - DataMat.Time(1); % Time information of the recording
       Fs        = 1 ./ (DataMat.Time(2) - DataMat.Time(1)); % Calculation of Sampling frequency

    % ===== PROCESS =====
    % This is where the actual process of data manipulation and calculation takes place.
       DataN        = Data*-1; % The negative version of the data
       Data(end,:)  = (randi(100,1,Ntime))*10^-6; % End row which is BDF/status channel is a constant number so replaced this with randi to remove issues during findpeaks 
       DataN(end,:) = (randi(100,1,Ntime))*10^-6;

            for i = 1 : Nchannels
                [PosP, LocP]       = findpeaks(Data(i,:),Fs); % Find all the positive peaks and their locations in seconds
                [NegP, LocN]       = findpeaks(DataN(i,:),Fs); % Find all the negative peaks and their locations in seconds
                [PeakPo(i,iNepochs), IndexP] = max(PosP,[],2); % Find the max positive peak per channel and index its location 
                [PeakNe(i,iNepochs), IndexN] = max(NegP,[],2); % Find the max negative peak per channel and index its location
                TimePP(i,iNepochs) = LocP(IndexP); % Uses the IndexP vector to find the time point of max positive peak
                TimeNP(i,iNepochs) = LocN(IndexN); % Uses the IndexN vector to find the time point of max negative peak (won't be used further from here though)
                CountP(i,iNepochs) = length(PosP); % Count the number of peak 
            end

       SS_Dur(:,iNepochs) = Time; % Calculation of spindle duration
       % Spindle duration = the number of time samples-1 divided by the sampling frequency
       SS_Fre             = 1./(SS_Dur./CountP); % Final calculation of spindle frequency
       % Spinde frequency = the reciprocal of (the number of peaks/duration)
       SS_Amp             = PeakPo + PeakNe; % Final calculation of spindle max peak-peak amplitude
       % Spinde amplitude = the sum of max positive peak and negative peak
       SS_Sym             = (TimePP./SS_Dur)*100; % Final calculation of spindle symmetry
       % Spindle symmetry = the percentage of (the time location of max positive peak/spindle duration) 
    end

    % ===== SAVE THE RESULTS =====
    % Get the output study (Sleep Spindle Duration)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = SS_Dur;
    DataMat.Comment     = sprintf('SS_Dur (%d)', Nepochs); % Names the output file as 'SS_Dur' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochN; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed. 
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename 
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_SS_Dur');
    % Save on disk
    save(OutputFiles{1}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, DataMat);

    % Get the output study (Sleep Spindle Frequency)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = SS_Fre;
    DataMat.Comment     = sprintf('SS_Fre (%d)', Nepochs); % Names the output file as 'SS_Fre' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochN; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed. 
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename 
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_SS_Fre');
    % Save on disk
    save(OutputFiles{1}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, DataMat);

    % Get the output study (Sleep Spindle Amplitude)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = SS_Amp;
    DataMat.Comment     = sprintf('SS_Amp (%d)', Nepochs); % Names the output file as 'SS_Amp' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochN; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed. 
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename 
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_SS_Amp');
    % Save on disk
    save(OutputFiles{1}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, DataMat);
    
    % Get the output study (Sleep Spindle Symmetry)
    iStudy = sInputs(1).iStudy;
    % Create a new data file structure
    DataMat             = db_template('datamat');
    DataMat.F           = SS_Sym;
    DataMat.Comment     = sprintf('SS_Sym (%d)', Nepochs); % Names the output file as 'SS_Sym' with the number of epochs used to generate the file.
    DataMat.ChannelFlag = ones(epochSize(1), 1);   % List of good/bad channels (1=good, -1=bad)
    DataMat.Time        = EpochN; % In this case this will show the number of epochs. But the units will still be "Time (s)" which cannot be changed. 
    DataMat.DataType    = 'recordings';
    DataMat.nAvg        = Nepochs;         % Number of epochs that were used to get this file
    % Create a default output filename 
    OutputFiles{1} = bst_process('GetNewFilename', fileparts(sInputs(1).FileName), 'data_SS_Sym');
    % Save on disk
    save(OutputFiles{1}, '-struct', 'DataMat');
    % Register in database
    db_add_data(iStudy, OutputFiles{1}, DataMat);
end