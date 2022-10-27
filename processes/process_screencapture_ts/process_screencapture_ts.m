function varargout = process_screencapture_ts( varargin )
% PROCESS_SCREENCAPTURE_TS Saves screen captures of successive pages of EEG signals.

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c) University of Southern California & McGill University
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
% Authors: Francois Tadel, 2022

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription()
    % Description the process
    sProcess.Comment     = 'Save screen captures of signals';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'File';
    sProcess.Index       = 982;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'raw'};
    sProcess.OutputTypes = {'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    
    % X-axis resolution
    sProcess.options.xres.Comment = 'X-axis resolution:';
    sProcess.options.xres.Type    = 'value';
    sProcess.options.xres.Value   = {400, 'pixels/second', 0};
    % Y-axis resolution
    sProcess.options.yres.Comment = 'Y-axis resolution:';
    sProcess.options.yres.Type    = 'value';
    sProcess.options.yres.Value   = {50, 'microVolts/pixel', 0};    
    % File selection options
    SelectOptions = {...
        '', ...                            % Filename
        '', ...                            % FileFormat
        'open', ...                        % Dialog type: {open,save}
        'Select BIDS dataset output folder...', ...     % Window title
        'ExportData', ...                  % LastUsedDir: {ImportData,ImportChannel,ImportAnat,ExportChannel,ExportData,ExportAnat,ExportProtocol,ExportImage,ExportScript}
        'single', ...                    % Selection mode: {single,multiple}
        'dirs', ...                        % Selection mode: {files,dirs,files_and_dirs}
        {{'.folder'}, 'BIDS dataset folder', 'BIDS'}, ... % Available file formats
        []};                               % DefaultFormats: {ChannelIn,DataIn,DipolesIn,EventsIn,AnatIn,MriIn,NoiseCovIn,ResultsIn,SspIn,SurfaceIn,TimefreqIn}
    % Output folder
    sProcess.options.outdir.Comment = 'Output folder:';
    sProcess.options.outdir.Type    = 'filename';
    sProcess.options.outdir.Value   = SelectOptions;
    % File format
    sProcess.options.format.Comment = 'File format:';
    sProcess.options.format.Type    = 'combobox_label';
    sProcess.options.format.Value   = {'png', {'png', 'jpg', 'tif', 'gif'; 'png', 'jpg', 'tif', 'gif'}};
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    global GlobalData;
    % Initialize returned variable
    OutputFiles = {sInputs.FileName};
    % Get options
    xres = sProcess.options.xres.Value{1};
    yres = sProcess.options.yres.Value{1};
    OutputDir = sProcess.options.outdir.Value{1};
    Format = sProcess.options.format.Value{1};

    % Close everything
    bst_memory('UnloadAll', 'Forced');
    % Loop on input files
    for iFile = 1:length(sInputs)
        % Open viewer
        hFig = view_timeseries(sInputs(iFile).FileName);
        % Get figure references
        [~, iFig, iDS] = bst_figures('GetFigure', hFig);
        % Configure window
        figure_timeseries('SetAutoScale', hFig, 0);
        figure_timeseries('SetDisplayMode', hFig, 'column');
        figure_timeseries('SetResolution', iDS, iFig, xres, yres);  % Note that the time resolution depends on the size of the window        

        % Get window duration
        WinLength = GlobalData.UserTimeWindow.Time(2) - GlobalData.UserTimeWindow.Time(1);
        % Get file duration
        DataMat = in_bst_data(sInputs(iFile).FileName);
        nWin = floor(DataMat.Time(end) / WinLength);
        
        % Get base file name
        [fPath, fBase] = bst_fileparts(sInputs(iFile).FileName);
        % Loop on windows
        for iWin = 1:nWin
            startTime = (iWin - 1) * WinLength;
            panel_record('SetStartTime', startTime);
            out_figure_image(hFig, bst_fullfile(OutputDir, sprintf('%s_%04d.%s', fBase, iWin, Format)));
        end
        
        % Close window
        close(hFig);
    end
end
