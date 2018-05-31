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
    sProcess.isSourceAbsolute = 1;
    
    % Definition of the options
    
    sProcess.options.channelname.Comment = 'Event name: ';
    sProcess.options.channelname.Type    = 'text';
    sProcess.options.channelname.Value   = '';
    
    
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
      
    DataMat = in_bst(sInput.FileName, [], 0);
    Duration=cell2mat(sProcess.options.timewindow.Value(1));
    disp(sProcess.options.channelname.Value);
    
    [time,value]=windows_mean_based_on_event( DataMat, abs(Duration(1)),Duration(2), sProcess.options.channelname.Value );
    
    if isempty(time)
        bst_report('Error',   sProcess, sInput, 'Event not found');
    end    
    sInput.A=value;
    sInput.TimeVector=time;
        
end


% Calculate the windows average
% Input 
% Output 


function [time,value]=  windows_mean_based_on_event( sFile, duration_before, duration_after, event_name )
%% we calculate the mean so that they are synchronised with events. Each windows begin
% n1 samples before events start and end n2 samples after


f= 1 / ( sFile.Time(2)-sFile.Time(1) ) ; % frequence d'échantillonage

n_before=round(duration_before *f);
n_after= round(duration_after *f);


duration = n_after + n_before ;

[chanel, sample]= size(sFile.F);
value=zeros(chanel,duration);

time=-duration_before:1/f:duration_after;

% First, we extract the event start in the file

event_starts=[];
for i=1:length(  sFile.Events )
    if ( strcmp( sFile.Events(i).label,event_name) == 1)
        event_starts = round(sFile.Events(i).times(1,:)*f); % convert time to sample
    end
end

if( isempty(event_starts) )
    
    value=[];
    time=[];
    return; 
end


for evt=event_starts
    value=value+ sFile.F(:, evt-n_before:evt+n_after-1);
end

value=value/length(event_starts);


end



