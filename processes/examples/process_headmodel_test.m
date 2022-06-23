function varargout = process_headmodel_test( varargin )
% PROCESS_HEADMODEL_TEST:

% @=============================================================================
% This software is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
%
% Copyright (c)2000-2013 Brainstorm by the University of Southern California
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPL
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
% Authors:

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % Description the process
    sProcess.Comment     = 'Headmodel test #1';
    sProcess.FileTag     = '';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 1000;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw'};
    sProcess.OutputTypes = {'data', 'raw'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Definition of the options
    % Options: Radio button
    sProcess.options.optionname1.Comment = {'Radio button 1', 'Radio button 2', 'Radio button 3'};
    sProcess.options.optionname1.Type    = 'radio';
    sProcess.options.optionname1.Value   = 1;
    % Option: Combo box
    sProcess.options.optionname2.Comment = 'Combobox example:';
    sProcess.options.optionname2.Type    = 'combobox';
    sProcess.options.optionname2.Value   = {3, {'method 1', 'method 2', 'method 3'}};    % {Default index, {list of entries}}
    % Option: Real value
    sProcess.options.optionname3.Comment = 'Real value: ';
    sProcess.options.optionname3.Type    = 'value';
    sProcess.options.optionname3.Value   = {3, 'units', 3};   % {Default value, units, precision}
    % Option: Integer value
    sProcess.options.optionname4.Comment = 'Integer value: ';
    sProcess.options.optionname4.Type    = 'value';
    sProcess.options.optionname4.Value   = {3, 'units', 0};
    % Option: Text field
    sProcess.options.optionname5.Comment = 'Text field: ';
    sProcess.options.optionname5.Type    = 'text';
    sProcess.options.optionname5.Value   = 'default text';
    % Option: Checkbox
    sProcess.options.optionname6.Comment = 'Check box text';
    sProcess.options.optionname6.Type    = 'checkbox';
    sProcess.options.optionname6.Value   = 1;                 % Selected or not by default
    % Option: Atlas
    sProcess.options.optionname7.Comment = 'Select atlas:';
    sProcess.options.optionname7.Type    = 'atlas';
    sProcess.options.optionname7.Value   = [];
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    % Initialize returned list of files
    OutputFiles = {};
    % Get option values
    Option1 = sProcess.options.optionname1.Comment{sProcess.options.optionname1.Value};
    Option2 = sProcess.options.optionname2.Value{2}(sProcess.options.optionname2.Value{1});
    Option3 = sProcess.options.optionname3.Value{1};
    Option4 = sProcess.options.optionname4.Value{1};
    Option5 = sProcess.options.optionname5.Value;
    Option6 = sProcess.options.optionname6.Value;
    AtlasName = sProcess.options.optionname7.Value;

    % ===== GET THE STUDIES TO PROCESS =====
    % Get channel studies
    [sChannels, iChanStudies] = bst_get('ChannelForStudy', unique([sInputs.iStudy]));
    % Check if there are channel files everywhere
    if (length(sChannels) ~= length(iChanStudies))
        bst_report('Error', sProcess, sInputs, ['Some of the input files are not associated with a channel file.' 10 'Please import the channel files first.']);
        return;
    end
    % Keep only once each channel file
    iChanStudies = unique(iChanStudies);
    if isempty(iChanStudies)
        bst_report('Error', sProcess, sInputs, 'Nothing to process');
        return;
    end

    % ===== LOOP ON EACH HEAD MODEL TO CALCULATE =====
    for i = 1:length(iChanStudies)

        % === LOAD CHANNEL FILE ===
        % Get study
        sChanStudy = bst_get('Study', iChanStudies(i));
        % Load channel file
        ChannelMat = in_bst_channel(sInputs(1).ChannelFile);
        % Find the MEG channels
        iMEG = good_channel(ChannelMat.Channel, [], 'MEG');
        iEEG = good_channel(ChannelMat.Channel, [], 'EEG');
        iSEEG = good_channel(ChannelMat.Channel, [], 'SEEG');
        iECOG = good_channel(ChannelMat.Channel, [], 'ECOG');
        % Number of channels
        nChannels = length(ChannelMat.Channel);

        % === LOAD SURFACES ===
        % Get the subject definition
        sSubject = bst_get('Subject', sChanStudy.BrainStormSubject);
        % MRI
        if ~isempty(sSubject.iAnatomy)
            MriFile = sSubject.Anatomy(sSubject.iAnatomy(1)).FileName;
            MriMat = in_mri_bst(MriFile);
        else
            % bst_report('Error', sProcess, sInput, 'Subject's MRI is missing.');
            % return;
        end
        % Cortex
        if ~isempty(sSubject.iCortex)
            CortexFile = sSubject.Surface(sSubject.iCortex(1)).FileName;
            CortexMat = in_tess_bst(CortexFile);
        else
            % bst_report('Error', sProcess, sInput, 'Cortex surface is missing.');
            % return;
        end
        % Scalp
        if ~isempty(sSubject.iScalp)
            ScalpFile = sSubject.Surface(sSubject.iScalp(1)).FileName;
            ScalpMat = in_tess_bst(ScalpFile);
        else
            % bst_report('Error', sProcess, sInput, 'Head surface is missing.');
            % return;
        end
        % Inner skull
        if ~isempty(sSubject.iInnerSkull)
            InnerSkullFile = sSubject.Surface(sSubject.iInnerSkull(1)).FileName;
            InnerSkullMat = in_tess_bst(InnerSkullFile);
        else
            % bst_report('Error', sProcess, sInput, 'Inner skull surface is missing.');
            % return;
        end
        % Outer skull
        if ~isempty(sSubject.iOuterSkull)
            OuterSkullFile = sSubject.Surface(sSubject.iOuterSkull(1)).FileName;
            OuterSkullMat = in_tess_bst(OuterSkullFile);
        else
            % bst_report('Error', sProcess, sInput, 'Outer skull surface is missing.');
            % return;
        end
        % ALL the other surfaces can be loaded in the same way

%         % Get atlas
%         iAtlas = find(strcmpi({CortexMat.Atlas.Name}, AtlasName));
%         if isempty(iAtlas)
%             bst_report('Warning', sProcess, sInput, ['Atlas not found: "' sProcess.options.atlas.Value '"']);
%         end
%         sAtlas = CortexMat.Atlas(iAtlas);



        % ===== PROCESS =====
        %%%% EDIT THIS CODE %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Create source space
        HeadModelType = 'surface';           % Or 'volume'
        nSources      = size(CortexMat.Vertices, 1);
        GridLoc       = rand(nSources, 3);   % Source locations
        GridOrient    = rand(nSources, 3);   % Source orientations  ([] in case of volume source model)
        % Creating gain matrix
        Gain = rand(nChannels, 3 * nSources);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


        % ===== SAVE HEAD MODEL =====
        % Create a new data file structure
        HeadmodelMat = db_template('headmodelmat');
        HeadmodelMat.MEGMethod      = 'test';   % You need to fill at least one of those 4 fields
        HeadmodelMat.EEGMethod      = '';
        HeadmodelMat.ECOGMethod     = '';
        HeadmodelMat.SEEGMethod     = '';
        HeadmodelMat.Gain           = Gain;
        HeadmodelMat.Comment        = 'Test file comment';
        HeadmodelMat.HeadModelType  = HeadModelType;
        HeadmodelMat.GridLoc        = GridLoc;
        HeadmodelMat.GridOrient     = GridOrient;
        HeadmodelMat.SurfaceFile    = CortexFile;    % Leave empty in the case of a volume head model
        HeadmodelMat.InputSurfaces  = [];            % Cell array of the surface file names that were used to calculate this file
        % Generate new filename
        HeadmodelFile = bst_process('GetNewFilename', fileparts(sChanStudy.FileName), 'headmodel_');
        % Save on disk
        save(HeadmodelFile, '-struct', 'HeadmodelMat');

        % ===== REGISTER IN DATABASE =====
        % Database structure
        newHeadModel = db_template('HeadModel');
        newHeadModel.FileName      = file_win2unix(file_short(HeadmodelFile));
        newHeadModel.Comment       = HeadmodelMat.Comment;
        newHeadModel.HeadModelType = HeadmodelMat.HeadModelType;
        newHeadModel.MEGMethod     = HeadmodelMat.MEGMethod;
        newHeadModel.EEGMethod     = HeadmodelMat.EEGMethod;
        newHeadModel.ECOGMethod    = HeadmodelMat.ECOGMethod;
        newHeadModel.SEEGMethod    = HeadmodelMat.SEEGMethod;
        % Register in database
        if isempty(sChanStudy.HeadModel)
            sChanStudy.HeadModel = newHeadModel;
        else
            sChanStudy.HeadModel(end+1) = newHeadModel;
        end
        % Make it the default head model
        sChanStudy.iHeadModel = length(sChanStudy.HeadModel);
        % Update database
        bst_set('Study', iChanStudies(i), sChanStudy);
        % Refresh tree
        panel_protocols('UpdateNode', 'Study', iChanStudies(i));
    end
    % Return the input files
    OutputFiles = {sInputs.FileName};
end
