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
% Authors: Edouard Delaire, 2018

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
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

    sProcess.options.baselinewindow.Comment = 'Time window:';
    sProcess.options.baselinewindow.Type    = 'range';
    sProcess.options.baselinewindow.Value   =  {[-10,0], 's', 1} ;
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Get time window
    Comment = [sProcess.Comment, ': [', process_extract_time('GetTimeString', sProcess), ']'];
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
     OutputFiles= {};
    if length(sInputs) > 1
        if strcmp(sInputs(1).FileType, 'data') 

            for iFile = 1:length(sInputs)
                OutputFiles{end+1} =     bst_process('CallProcess', 'process_windows_average_time', {sInputs(iFile).FileName},    [], ...
                                                                                                'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                                'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                                'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                                'baselinewindow', sProcess.options.baselinewindow.Value{1});
            end

        elseif strcmp(sInputs(1).FileType, 'results') 
            unique_dataFile = unique({sInputs.DataFile});
            if length(unique_dataFile) > 1
                % todo
            else

                new_dataFIle =     bst_process('CallProcess', 'process_windows_average_time',   unique_dataFile,    [], ...
                                                                                                'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                                'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                                'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                                'baselinewindow', sProcess.options.baselinewindow.Value{1} );

                for iFile = 1:length(sInputs)
                    OutputFile  =     bst_process('CallProcess', 'process_windows_average_time', {sInputs(iFile).FileName},    [], ...
                                                                                    'Eventname',      sProcess.options.Eventname.Value, ...
                                                                                    'timewindow',     sProcess.options.timewindow.Value{1} , ...
                                                                                    'remove_DC',      sProcess.options.remove_DC.Value, ...
                                                                                    'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                                                                                    'new_dataFIle', new_dataFIle.FileName );

                    OutputFiles{end+1} = OutputFile.FileName;
                end

            end
        else
            OutputFiles = {};
        end

        return;
    end


    % Apply the average on one specific file. 

    OutputFiles  = {};


    [sDataIn, sInputIn] = load_input_data(sProcess, sInputs);

    options             = struct('timewindow',      sProcess.options.timewindow.Value{1}, ...
                                 'remove_DC',       sProcess.options.remove_DC.Value,...
                                 'baselinewindow',  sProcess.options.baselinewindow.Value{1}, ...
                                 'Eventname',       sProcess.options.Eventname.Value);


    [time, value, nAvg] = windows_mean_based_on_event( sInputIn,  options  );
    
    if isempty(time)
        bst_report('Error',   sProcess, sInputIn, 'Event not found');
    end    


    sDataOut        = sDataIn; 
    sDataOut.Time   = time; 
    sDataOut.nAvg   = nAvg;
    sDataOut.Comment = [sDataOut.Comment sprintf(' | Avg: %s (%d) [%d,%ds] ',options.Eventname, ...
                                                                             nAvg, ...
                                                                             options.timewindow(1), options.timewindow(2))];


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

function [time,value,Nepochs]=  windows_mean_based_on_event( sInput, options )
%% we calculate the mean so that they are synchronised with events. Each windows begin
% n1 samples before events start and end n2 samples after
    [nChanel, ~] = size(sInput.A);

    iEvent = find(strcmp({sInput.events.label},options.Eventname));
    if isempty(iEvent) ||  isempty(sInput.events(iEvent).times )
        value = [];
        time  = [];
        return; 
    end
    
    Event  = sInput.events(iEvent);

    data    = sInput.A;
    
    win     = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,1) + [ options.timewindow(1), options.timewindow(2) ]);
    Ntime   = length(win);
    time    = linspace(options.timewindow(1), options.timewindow(2), Ntime);
    
    
    Nepochs = size(Event.times,2);
    value = zeros(nChanel,Ntime,Nepochs);
    
    
    for iEpoch=1:Nepochs
        iTime = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.timewindow(1), options.timewindow(2) ]);
        
        if length(iTime) < Ntime
            continue
        end
        
        iTime = iTime(1:Ntime);
        value(:,:,iEpoch) = data(:,iTime);

        if options.remove_DC
            iBaseline = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.baselinewindow(1), options.baselinewindow(2) ]);
            value(:,:,iEpoch) = value(:,:,iEpoch) - mean(data(:,iBaseline),2);
        end
    end
    
    value = mean(value, 3);
end



function [sDataIn, sInputIn] = load_input_data(sProcess, sInputs)

    if strcmp(sInputs.FileType, 'data')     
        sDataIn = in_bst_data(sInputs.FileName );
        
        sInputIn = struct('A', sDataIn.F, 'TimeVector', sDataIn.Time,  'events', sDataIn.Events); 
        
    elseif strcmp(sInputs.FileType, 'results') 
        sDataIn = in_bst_results(sInputs.FileName);
        sData = in_bst_data(sInputs.DataFile,'Events');
        
        
        if isfield(sProcess.options, 'new_dataFIle') && ~isempty(sProcess.options.new_dataFIle)
            sDataIn.DataFile = sProcess.options.new_dataFIle.Value;
        else
            
            new_dataFIle =     bst_process('CallProcess', 'process_windows_average_time', {sInputs.DataFile},    [], ...
                'Eventname',      sProcess.options.Eventname.Value, ...
                'timewindow',     sProcess.options.timewindow.Value{1} , ...
                'remove_DC',      sProcess.options.remove_DC.Value, ...
                'baselinewindow', sProcess.options.baselinewindow.Value{1}, ...
                'overwrite',      0);
            sDataIn.DataFile =   new_dataFIle.FileName;
        end
        
        
        sInputIn = struct('A', sDataIn.ImageGridAmp, 'TimeVector', sDataIn.Time,  'events', sData.Events); 
    end
end