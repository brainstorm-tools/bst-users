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
      
    DataMat  = in_bst(sInput.FileName, [], 0);
    Duration = abs(sProcess.options.timewindow.Value{1});
    
    [time,value] = windows_mean_based_on_event( DataMat, Duration(1),Duration(2), sProcess.options.Eventname.Value );
    
    if isempty(time)
        bst_report('Error',   sProcess, sInput, 'Event not found');
    end    
    sInput.A = value;
    sInput.TimeVector = time;
        
end

function [time,value]=  windows_mean_based_on_event( sFile, duration_before, duration_after, event_name )
%% we calculate the mean so that they are synchronised with events. Each windows begin
% n1 samples before events start and end n2 samples after

    if isfield(sFile,'F')
        [nChanel, ~] = size(sFile.F);
    else
        [nChanel, ~] = size(sFile.ImageGridAmp);
        sData = in_bst_data(sFile.DataFile);
        sFile.Events = sData.Events;
    end
    
    iEvent = find(strcmp({sFile.Events.label},event_name));
    if isempty(iEvent) ||  isempty(sFile.Events(iEvent).times )
        value = [];
        time  = [];
        return; 
    end
    
    Event  = sFile.Events(iEvent);
    
    T       =  sFile.Time(2)-sFile.Time(1) ; 
    time    = -duration_before:T:duration_after;
    Ntime   = length(time);
    Nepochs = length(  sFile.Events );
    value = zeros(nChanel,Ntime,Nepochs);
    
    % First, we extract the event start in the file
    
    for iEpoch=1:Nepochs
        iTime = panel_time('GetTimeIndices', sFile.Time, Event.times(1,iEpoch) + [ -duration_before, duration_after ]);
        if isfield(sFile,'F')
            value(:,:,iEpoch) = sFile.F(:,iTime);
        else
            value(:,:,iEpoch) = sFile.ImageGridAmp(:,iTime);
        end
    end
    
    value = mean(value, 3);
end



