function varargout = process_headmodel_from_atlas( varargin )
% PROCESS_HEADMODEL_FROM_ATLAS: Compute a head model from an atlas (scouts).

% @=============================================================================
% This function is part of the Brainstorm software:
% http://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2017 University of Southern California & McGill University
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
% Authors: Martin Cousineau, 2017

eval(macro_method);
end


%% ===== GET DESCRIPTION =====
function sProcess = GetDescription() %#ok<DEFNU>
    % ===== PROCESS =====
    % Description the process
    sProcess.Comment     = 'Compute head model from atlas';
    sProcess.Category    = 'Custom';
    sProcess.SubGroup    = 'Sources';
    sProcess.Index       = 321;
    % Definition of the input accepted by this process
    sProcess.InputTypes  = {'data', 'raw', 'matrix'};
    sProcess.OutputTypes = {'data', 'raw', 'matrix'};
    sProcess.nInputs     = 1;
    sProcess.nMinFiles   = 1;
    % Options: Comment
    sProcess.options.Comment.Comment = 'Comment: ';
    sProcess.options.Comment.Type    = 'text';
    sProcess.options.Comment.Value   = 'Overlapping spheres (volume)';
    % Option: MEG headmodel
    sProcess.options.label2.Comment = '<BR><B>Forward modeling methods</B>:';
    sProcess.options.label2.Type    = 'label';
    sProcess.options.meg.Comment = '   - MEG method:';
    sProcess.options.meg.Type    = 'combobox';
    sProcess.options.meg.Value   = {3, {'<none>', 'Single sphere', 'Overlapping spheres', 'OpenMEEG BEM'}};
    % Option: EEG headmodel
    sProcess.options.eeg.Comment = '   - EEG method:';
    sProcess.options.eeg.Type    = 'combobox';
    sProcess.options.eeg.Value   = {3, {'<none>', '3-shell sphere', 'OpenMEEG BEM'}};
    % Option: ECOG headmodel
    sProcess.options.ecog.Comment = '   - ECOG method:';
    sProcess.options.ecog.Type    = 'combobox';
    sProcess.options.ecog.Value   = {2, {'<none>', 'OpenMEEG BEM'}};
    % Option: SEEG headmodel
    sProcess.options.seeg.Comment = '   - SEEG method:';
    sProcess.options.seeg.Type    = 'combobox';
    sProcess.options.seeg.Value   = {2, {'<none>', 'OpenMEEG BEM'}};
end


%% ===== FORMAT COMMENT =====
function Comment = FormatComment(sProcess) %#ok<DEFNU>
    Comment = sProcess.Comment;
end


%% ===== RUN =====
function OutputFiles = Run(sProcess, sInputs) %#ok<DEFNU>
    OutputFiles = {};
    isOpenMEEG = 0;
    % == MEG options ==
    if isfield(sProcess.options, 'meg') && isfield(sProcess.options.meg, 'Value') && iscell(sProcess.options.meg.Value)
        switch (sProcess.options.meg.Value{1})
            case 1,  sMethod.MEGMethod = '';
            case 2,  sMethod.MEGMethod = 'meg_sphere';
            case 3,  sMethod.MEGMethod = 'os_meg';
            case 4,  sMethod.MEGMethod = 'openmeeg';   isOpenMEEG = 1;
        end
    else
        sMethod.MEGMethod = '';
    end
    % == EEG options ==
    if isfield(sProcess.options, 'eeg') && isfield(sProcess.options.eeg, 'Value') && iscell(sProcess.options.eeg.Value)
        switch (sProcess.options.eeg.Value{1})
            case 1,  sMethod.EEGMethod = '';
            case 2,  sMethod.EEGMethod = 'eeg_3sphereberg';
            case 3,  sMethod.EEGMethod = 'openmeeg';   isOpenMEEG = 1;
        end
    else
        sMethod.EEGMethod = '';
    end
    % == ECOG options ==
    if isfield(sProcess.options, 'ecog') && isfield(sProcess.options.ecog, 'Value') && iscell(sProcess.options.ecog.Value)
        switch (sProcess.options.ecog.Value{1})
            case 1,  sMethod.ECOGMethod = '';
            case 2,  sMethod.ECOGMethod = 'openmeeg';   isOpenMEEG = 1;
        end
    else
        sMethod.ECOGMethod = '';
    end
    % == SEEG options ==
    if isfield(sProcess.options, 'seeg') && isfield(sProcess.options.seeg, 'Value') && iscell(sProcess.options.seeg.Value)
        switch (sProcess.options.seeg.Value{1})
            case 1,  sMethod.SEEGMethod = '';
            case 2,  sMethod.SEEGMethod = 'openmeeg';   isOpenMEEG = 1;
        end
    else
        sMethod.SEEGMethod = '';
    end
    % Source space options
    sMethod.HeadModelType = 'volume';
    % Comment
    if isfield(sProcess.options, 'Comment') && isfield(sProcess.options.Comment, 'Value') && ~isempty(sProcess.options.Comment.Value)
        sMethod.Comment = sProcess.options.Comment.Value;
    end
    % Set the source space (grid of source points, and constrained orientation at those source points)
    if isfield(sProcess.options, 'gridloc') && isfield(sProcess.options.gridloc, 'Value') && ~isempty(sProcess.options.gridloc.Value)
        sMethod.GridLoc = sProcess.options.gridloc.Value;
    end
    if isfield(sProcess.options, 'gridorient') && isfield(sProcess.options.gridorient, 'Value') && ~isempty(sProcess.options.gridorient.Value)
        sMethod.GridOrient = sProcess.options.gridorient.Value;
    end
    if isfield(sProcess.options, 'volumegrid') && isfield(sProcess.options.volumegrid, 'Value') && ~isempty(sProcess.options.volumegrid.Value)
        sMethod.GridOptions = sProcess.options.volumegrid.Value;
    else
        sMethod.GridOptions = bst_get('GridOptions_headmodel');
    end

    % Get channel studies
    [sChannels, iChanStudies] = bst_get('ChannelForStudy', unique([sInputs.iStudy]));
    % Check if there are channel files everywhere
    if (length(sChannels) ~= length(iChanStudies))
        bst_report('Error', sProcess, sInputs, ['Some of the input files are not associated with a channel file.' 10 'Please import the channel files first.']);
        return;
    end
    % Keep only once each channel file
    iChanStudies = unique(iChanStudies);
    
    % Copy OpenMEEG options to OPTIONS structure
    if isOpenMEEG
        if ~isfield(sProcess.options, 'openmeeg') || ~isfield(sProcess.options.openmeeg, 'Value') || isempty(sProcess.options.openmeeg.Value)
            sProcess.options.openmeeg.Value = bst_get('OpenMEEGOptions');
        end
        sMethod = struct_copy_fields(sMethod, sProcess.options.openmeeg.Value, 1);
        bst_set('OpenMEEGOptions', sProcess.options.openmeeg.Value);
    end
    % Non-interactive process
    sMethod.Interactive = 0;
    sMethod.SaveFile = 1;
    
    % Loop through each subject
    for iStudy = 1:length(iChanStudies)
        % Find scouts info
        sStudy = bst_get('Study', iChanStudies(iStudy));
        [sSubject, iSubject] = bst_get('Subject', sStudy.BrainStormSubject);
        CortexFile = sSubject.Surface(sSubject.iCortex).FileName;
        [~, sSurf, ~] = panel_scout('GetScouts', CortexFile);
        atlases = {sSurf.Atlas.Name};
        
        % Ask for atlas to use
        [iAtlas, answered] = listdlg('PromptString', ['Select an atlas for subject ', sSubject.Name, ':'], ...
                'SelectionMode', 'single', ...
                'ListSize', [350, 350], ...
                'ListString', atlases);
        if ~answered
            bst_report('Error', sProcess, sInputs, ['No atlas chosen for subject "', sSubject.Name, '".']);
            return;
        end
        
        % Compute centroids
        scouts = sSurf.Atlas(iAtlas).Scouts;
        numScouts = length(scouts);
        centroids = zeros(numScouts, 3);
        for i = 1:numScouts
            centroids(i, :) = mean(sSurf.Vertices(scouts(i).Vertices, :));
        end
        
        % Compute grid
        [sEnvelope, sCortex] = tess_envelope(CortexFile, 'convhull', 4000, .001, []);
        sEnvelope.Vertices = centroids;
        sMethod.GridOptions.Method = 'adaptive';
        sMethod.GridOptions.nLayers = 1;
        sMethod.GridLoc = bst_sourcegrid(sMethod.GridOptions, CortexFile, sCortex, sEnvelope);

        % Call head modeler
        [HeadModelFiles, errMessage] = panel_headmodel('ComputeHeadModel', iChanStudies(iStudy), sMethod);
    end

    % Report errors
    if isempty(HeadModelFiles) && ~isempty(errMessage)
        bst_report('Error', sProcess, sInputs, errMessage);
        return;
    elseif ~isempty(errMessage)
        bst_report('Warning', sProcess, sInputs, errMessage);
    end
    % Return the data files in input
    OutputFiles = {sInputs.FileName};
end



