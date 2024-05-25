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
    sProcess.Category    = 'Filter';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 303;
    sProcess.Description = '';
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Default values for some options
    sProcess.isSourceAbsolute = 0;
    
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
    % Absolute values 
    if isfield(sProcess.options, 'source_abs') && sProcess.options.source_abs.Value
        Comment = [Comment, ', abs'];
    end

end


%% ===== RUN =====
function sInput = Run(sProcess, sInput) %#ok<DEFNU>
      
    options = struct('timewindow',      sProcess.options.timewindow.Value{1}, ...
                     'remove_DC',       sProcess.options.remove_DC.Value,...
                     'baselinewindow',  sProcess.options.baselinewindow.Value{1}, ...
                     'Eventname',       sProcess.options.Eventname.Value);
    
    if strcmp(sInput.FileType, 'data')     % Imported data structure
        sDataIn = in_bst_data(sInput.FileName, 'Events');
        sInput.events = sDataIn.Events;
    elseif strcmp(sInput.FileType, 'results') 
        sDataIn = in_bst_data(sInput.DataFile, 'Events');
        sInput.events = sDataIn.Events;
    elseif strcmp(sInputs.FileType, 'raw')  % Continuous data file
        sDataRaw = in_bst_data(sInputs.FileName, 'F');
        sInput.events = sDataRaw.F.events;
    end

    [time,value] = windows_mean_based_on_event( sInput, options  );
    
    if isempty(time)
        bst_report('Error',   sProcess, sInput, 'Event not found');
    end    
    sInput.A = value;
    sInput.TimeVector = time;
        
end

function [time,value]=  windows_mean_based_on_event( sInput, options )
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
    T       = sInput.TimeVector(2)-sInput.TimeVector(1) ; 
    time    = options.timewindow(1):T:options.timewindow(2);
    Ntime   = length(time);
    Nepochs = size(Event.times,2);
    value = zeros(nChanel,Ntime,Nepochs);
    
    
    for iEpoch=1:Nepochs
        iTime = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.timewindow(1), options.timewindow(2) ]);
        value(:,:,iEpoch) = data(:,iTime);

        if options.remove_DC
            iBaseline = panel_time('GetTimeIndices', sInput.TimeVector, Event.times(1,iEpoch) + [ options.baselinewindow(1), options.baselinewindow(2) ]);
            value(:,:,iEpoch) = value(:,:,iEpoch) - mean(data(:,iBaseline),2);
        end
    end
    
    value = mean(value, 3);
end



