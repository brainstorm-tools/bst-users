function varargout = process_average_subsets( varargin )
% PROCESS_AVERAGE_SUBSETS: Average subsets of files from a list.
%
% USAGE:   OutputFiles = process_average_subsets('Run', sProcess, sInputs)

% @=============================================================================
% This function is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2016 University of Southern California & McGill University
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
% Authors: Francois Tadel, Jeremy T. Moreau, 2016

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Average subsets';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Average';
    sProcess.Index       = 1014;
    sProcess.Description = '';
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.OutputTypes = {'data', 'results', 'timefreq', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Definition of the options
    % === TARGET
    sProcess.options.nfiles.Comment = 'Number of files to average per subset: ';
    sProcess.options.nfiles.Type    = 'value';
    sProcess.options.nfiles.Value   = {1, ' files', 0};
    % === FILENAME / COMMENT
    sProcess.options.label1.Comment = 'How to pick the files:';
    sProcess.options.label1.Type    = 'label';
    sProcess.options.method.Comment = {'Sequential', 'Random selection'};
    sProcess.options.method.Type    = 'radio';
    sProcess.options.method.Value   = 1;
    % === FUNCTION
    sProcess.options.label2.Comment = '<U><B>Function</B></U>:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.avg_func.Comment = {'Arithmetic average:  <FONT color="#777777">mean(x)</FONT>', ...
                                         'Average absolute values:  <FONT color="#777777">mean(abs(x))</FONT>', ...
                                         'Root mean square (RMS):  <FONT color="#777777">sqrt(sum(x.^2)/N)</FONT>', ...
                                         'Standard deviation:  <FONT color="#777777">sqrt(var(x))</FONT>', ...
                                         'Standard error:  <FONT color="#777777">sqrt(var(x)/N)</FONT>', ...
                                         'Arithmetic average + Standard deviation', ...
                                         'Arithmetic average + Standard error'};
    sProcess.options.avg_func.Type    = 'radio';
    sProcess.options.avg_func.Value   = 1;
    % === WEIGHTED AVERAGE
    sProcess.options.weighted.Comment    = 'Weighted average:  <FONT color="#777777">mean(x) = sum(nAvg(i) * x(i)) / sum(nAvg(i))</FONT>';
    sProcess.options.weighted.Type       = 'checkbox';
    sProcess.options.weighted.Value      = 0;
    % === KEEP EVENTS
    sProcess.options.keepevents.Comment    = 'Keep all the event markers from the individual epochs';
    sProcess.options.keepevents.Type       = 'checkbox';
    sProcess.options.keepevents.Value      = 0;
    sProcess.options.keepevents.InputTypes = {'data', 'matrix'};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    % Number of files
    nFiles = sProcess.options.nfiles.Value{1};
    Comment = ['Average in subsets of ' num2str(nFiles) ' files '];
    % How to select the files
    switch (sProcess.options.method.Value)
        case 1,  Comment = [Comment, '(sequential)'];
        case 2,  Comment = [Comment, '(random)'];
    end
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    % Number of files
    totalnFiles = length(sInputs);
    nFiles = sProcess.options.nfiles.Value{1};
    if (nFiles < 1)
        bst_report('Error', sProcess, [], 'No files selected.');
        return;
    elseif (nFiles > totalnFiles)
        bst_report('Warning', sProcess, [], 'The number of files to average per subset is larger than the number of input files.');
        OutputFiles = {sInputs.FileName};
        return;
    end
    % Number of subsets
    nSubsets = floor(totalnFiles / nFiles);
    % How to select the files
    switch (sProcess.options.method.Value)
        case 1,  iFiles = sort(randperm(length(sInputs), totalnFiles));
        case 2,  iFiles = (1:totalnFiles);
    end
    % Average subsets
    for i = 1:nSubsets
        filesToAvg = {sInputs(iFiles).FileName};
        sFiles = filesToAvg(((i-1)*nFiles)+1:(i*nFiles));  % stupid 1 indexing...
        sFiles = bst_process('CallProcess', 'process_average', sFiles, [], ...
            'avgtype',    1, ...  % Everything
            'avg_func',   sProcess.options.avg_func.Value, ...
            'weighted',   sProcess.options.weighted.Value, ...
            'keepevents', sProcess.options.keepevents.Value);
        sFiles = bst_process('CallProcess', 'process_add_tag', sFiles, [], ...
            'tag',    ['subset ' num2str(i)], ...
            'output', 1);  % Add to comment
    end
end



