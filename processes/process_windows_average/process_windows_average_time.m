function varargout = process_windows_average_time( varargin )
% PROCESS_MOVING_AVERAGE_TIME: For each file in input, compute the moving average with a T time window.

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2018 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
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
% Authors: Edouard Delaire, 2018, 2025

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription()
    % Description the process
    sProcess.Comment     = 'Windows Average';
    sProcess.FileTag     = 'WAvg';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 303;
    sProcess.Description = '';
    
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results'};
    sProcess.OutputTypes = {'data', 'results'};

    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % Definition of the options
    sProcess.options.Eventname.Comment = 'Event name: ';
    sProcess.options.Eventname.Type    = 'text';
    sProcess.options.Eventname.Value   = '';
    
    
    % === TIME WINDOW
    sProcess.options.timewindow.Comment = 'Time window:';
    sProcess.options.timewindow.Type    = 'range';
    sProcess.options.timewindow.Value   =  {[-10,30], 's', 1} ;
    
    % === Remove DC offset
    sProcess.options.remove_DC.Comment    = 'Remove DC offset: select baseline definition';
    sProcess.options.remove_DC.Type       = 'checkbox';
    sProcess.options.remove_DC.Value      = 0;
    sProcess.options.remove_DC.Controller = 'dc_offset';

    sProcess.options.baselinewindow.Comment = 'Time window:';
    sProcess.options.baselinewindow.Type    = 'range';
    sProcess.options.baselinewindow.Value   =  {[-10,0], 's', 1} ;
    sProcess.options.baselinewindow.Class   = 'dc_offset';

    % === Filter bad trials
    sProcess.options.filter_trials.Comment    = 'Filter bad trials';
    sProcess.options.filter_trials.Type       = 'checkbox';
    sProcess.options.filter_trials.Value      = 0;
    sProcess.options.filter_trials.Controller = 'trials_info';

    sProcess.options.trials_info.Comment = 'Trials list  [coma-separated list] (-1 for bad trials, 1 for good trials)';
    sProcess.options.trials_info.Type    = 'text';
    sProcess.options.trials_info.Value   = '';     
    sProcess.options.trials_info.Class   = 'trials_info';

end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess)
    % Get time window
    Comment = [sProcess.Comment, ': [', process_extract_time('GetTimeString', sProcess), ']'];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) 


    % First handle all the case, where we have multiple files, or results
    % files. For Result files, we also do the average on the data file to
    % be able to still have a datafile supervising the results in the
    % database. 

    OutputFiles= {};
    if length(sInputs) > 1

        if strcmp(sInputs(1).FileType, 'data') 

            for iFile = 1:length(sInputs)
                OutputFiles{end+1} =     bst_process('CallProcess', 'process_windows_average_time', {sInputs(iFile).FileName},    [], ...
                                                                                                'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                                'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                                'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                                'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                                                                                                'filter_trials',   sProcess.options.filter_trials.Value, ...
                                                                                                'trials_info',     sProcess.options.trials_info.Value);
            end
            
            return;
        end

        if strcmp(sInputs(1).FileType, 'results') 
            unique_dataFile = unique({sInputs.DataFile});


            if length(unique_dataFile) > 1

                for iDataFile = 1:length(unique_dataFile)
                    iFile  = find( strcmp( {sInputs.DataFile} , unique_dataFile{iDataFile}));
                    OutputFile  =     bst_process('CallProcess', 'process_windows_average_time',   {sInputs(iFile).FileName},    [], ...
                                                                                                    'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                                    'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                                    'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                                    'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                                                                                                    'filter_trials',   sProcess.options.filter_trials.Value, ...
                                                                                                    'trials_info',     sProcess.options.trials_info.Value);
                    for iOutput = 1:length(OutputFile)
                        OutputFiles{end+1} = OutputFile(iOutput).FileName;
                    end
                end

                return;
            end
            
            new_dataFIle =  bst_process('CallProcess', 'process_windows_average_time',   unique_dataFile,    [], ...
                                                                                            'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                            'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                            'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                            'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                                                                                            'filter_trials',   sProcess.options.filter_trials.Value, ...
                                                                                            'trials_info',     sProcess.options.trials_info.Value);

            for iFile = 1:length(sInputs)
                OutputFile  =  bst_process('CallProcess', 'process_windows_average_time', {sInputs(iFile).FileName},    [], ...
                                                                                'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                                                                                'filter_trials',  sProcess.options.filter_trials.Value, ...
                                                                                'trials_info',    sProcess.options.trials_info.Value, ...
                                                                                'new_dataFIle',   new_dataFIle.FileName );

                OutputFiles{end+1} = OutputFile.FileName;
            end
            
            return;
        end

        OutputFiles = {};
        return;
    end


    % We finaly do the average on a specific file here. 
    OutputFiles  = {};


    [sDataIn, sInputIn] = load_input_data(sProcess, sInputs);

    options             = struct('timewindow',      sProcess.options.timewindow.Value{1}, ...
                                 'remove_DC',       sProcess.options.remove_DC.Value,...
                                 'baselinewindow',  sProcess.options.baselinewindow.Value{1}, ...
                                 'Eventname',       sProcess.options.Eventname.Value, ...
                                 'filter_trials',   sProcess.options.filter_trials.Value, ...
                                 'trials_info',     sProcess.options.trials_info.Value);
    


    [time, value, nAvg, includedTrials] = windows_mean_based_on_event( sInputIn,  options  );
    
    if isempty(time)
        bst_report('Error',   sProcess, sInputIn, 'Event not found');
    end    


    sDataOut        = sDataIn; 
    sDataOut.Time   = time; 
    sDataOut.nAvg   = nAvg;
    sDataOut.Comment = [sDataOut.Comment sprintf(' | Avg: %s (%d) [%d,%ds] ',options.Eventname, ...
                                                                             nAvg, ...
                                                                             options.timewindow(1), options.timewindow(2))];
    
    sDataOut = bst_history('add',sDataOut, 'Compute', sprintf('Averaging trials:  %s', num2str(includedTrials)));

    if strcmp(sInputs.FileType, 'data') 
        sDataOut.F      = value;
        sDataOut.Events = [];
    elseif strcmp(sInputs.FileType, 'results') 
        sDataOut.ImageGridAmp = value;
    end

    sStudy = bst_get('Study', sInputs.iStudy);
    [~, filename] = bst_fileparts(sInputs.FileName);
    OutputFile = bst_process('GetNewFilename', bst_fileparts(sStudy.FileName), [filename '_winavg']);
    bst_save(OutputFile, sDataOut);
    db_add_data( sInputs.iStudy, OutputFile, sDataOut);

    OutputFiles{end+1} = OutputFile;
                                                                        
end

function [time, epochValues, Nepochs, includedTrials]=  windows_mean_based_on_event( sInput, options )
%% we calculate the mean so that they are synchronised with events.  
    
    try
        iEvent = find(strcmp({sInput.events.label}, options.Eventname));
    catch
        error('No event in the file');
    end

    if isempty(iEvent) ||  isempty(sInput.events(iEvent).times )
        epochValues = [];
        time  = []; includedTrials = [];
        Nepochs  = 0;
        return; 
    end
    
    Event  = sInput.events(iEvent);

    data    = sInput.A;
    
    Ntime   = getWindowDuration(sInput.TimeVector, Event, options.timewindow);
    time    = linspace(options.timewindow(1), options.timewindow(2), Ntime);
    
    
    Nepochs     = size(Event.times,2);
    epochValues = zeros(size(sInput.A), Ntime, Nepochs);
    isIncluded  = getTrialsInfo(Nepochs, options);
    
    for iEpoch=1:Nepochs
        iTime = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.timewindow(1), options.timewindow(2) ]);
        
        if ~isIncluded(iEpoch) || length(iTime) < Ntime
            isIncluded(iEpoch) = false;
            continue
        end
        
        iTime = iTime(1:Ntime);
        epochValues(:,:, iEpoch) = data(:,iTime);

        if options.remove_DC
            iBaseline = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.baselinewindow(1), options.baselinewindow(2) ]);
            epochValues(:,:,iEpoch) = epochValues(:,:,iEpoch) - mean(data(:,iBaseline),2);
        end
    end
    
    epochValues     = mean(epochValues(:, :, isIncluded) , 3);
    Nepochs         = sum(isIncluded);
    includedTrials  = find(isIncluded);
end



function [sDataIn, sInputIn] = load_input_data(sProcess, sInputs)

    if strcmp(sInputs.FileType, 'data')     
        sDataIn = in_bst_data(sInputs.FileName );
        
        sInputIn = struct('A', sDataIn.F, 'TimeVector', sDataIn.Time,  'events', sDataIn.Events); 
        
    elseif strcmp(sInputs.FileType, 'results') 
        sDataIn = in_bst_results(sInputs.FileName, 1);
        sData = in_bst_data(sInputs.DataFile,'Events');
        
        
        if isfield(sProcess.options, 'new_dataFIle') && ~isempty(sProcess.options.new_dataFIle)
            sDataIn.DataFile = sProcess.options.new_dataFIle.Value;
        else
            sDataIn.DataFile = [];
            warning('No new data file found')
        end
        
        
        sInputIn = struct('A', sDataIn.ImageGridAmp, 'TimeVector', sDataIn.Time,  'events', sData.Events); 
    end
end

function isIncluded  = getTrialsInfo(Nepochs, options)
    isIncluded = true(1, Nepochs);

    if ~options.filter_trials
        return;
    end
    

    trials_info = strsplit(strrep(options.trials_info,' ',''), ',');
    assert(length(trials_info) == Nepochs, 'You must provide trial information for all the epochs')
    
    for iEvent = 1:length(trials_info)
       if strcmp(trials_info(iEvent), '1')
            isIncluded(iEvent) = true;
       elseif strcmp(trials_info(iEvent), '-1')
            isIncluded(iEvent) = false;
       else
            error('Unknown trial status %s for trial %d', trials_info{iEvent}, iEvent )
       end
    end
end


function out = getWindowDuration(TimeVector, Event, timewindow)
% Return the size of the window in sample.
    
    Nepochs = size(Event.times,2);
    windowSize = zeros(1, Nepochs);

    for iEpoch=1:Nepochs
        iTime = panel_time('GetTimeIndices', TimeVector, Event.times(1,iEpoch) + [ timewindow(1), timewindow(2) ]);
            
        windowSize(iEpoch)  = length(iTime);
    end
    
    out = max(windowSize);

end