
% Simulating three time-series: signal 1 is considered the reference. The
% envelopes of signals 2 and 3 are correlated with signal 1's envelope at
% r=.7; signals 1 and 3 have a phase difference of 90deg, whereas the phase
% difference between 1 and 2 procedes from 0 to 90deg over the length of
% the signal. Thus the procedure of orthogonalizing decreases correlations
% between 1 and 2, but leaves the correlation between 1 and 3 unaffected.

%% simulation parameters

fs = 600; % sampling frequency
f = 10; % carrier frequency
L = 15; % length of signal
f2 = (L*f+.25)/L; % carrier frequency +x, so there is a progression from 0 to pi/2
f_mod = .5; % frequency of amplitude modulation
c = .7; % correlation of amplitude envelopes
f_band = [8 13]; % filter band for carrier

clear amp_ts s_c y_a y_a_o aecFiles

%% generate amplitude modulated signals

t = 1/fs:1/fs:L;
% amp_ts(:,1) = process_bandpass('Compute', rand(1,L*fs)+.1, fs, fband_mod(1), fband_mod(2));
% amp_ts(:,2) = process_bandpass('Compute', rand(1,L*fs)+.1, fs, fband_mod(1), fband_mod(2));
amp_ts_i = exp(f_mod*2*pi*1i*t);
amp_ts(:,1) = real(amp_ts_i);
amp_ts(:,2) = imag(amp_ts_i);

C = [1 c; c 1];
LL = chol(C);

amp_ts = amp_ts*LL;
amp_ts = amp_ts+1.25; % since modulation signal has to be positive
amp_ts(:,3) = amp_ts(:,2);

s_c(:,1) = real(exp(f*2*pi*1i*t));
s_c(:,2) = real(exp((f2)*2*pi*1i*t));
s_c(:,3) = -imag(exp(f*2*pi*1i*t));

% y = amp_ts.*s_c+randn(size(amp_ts));
y = amp_ts.*s_c;

%% put into brainstorm

sMat = struct();
sMat.Value = y';
sMat.Std = [];
sMat.Time = t;
sMat.Comment = 'Test signals AEC';
for iSig = 1:size(y,2)
    sMat.Description{iSig,1} = sprintf('signal %d', iSig);
end
sMat.nAvg = 1;
sMat.History = {};

subjects = bst_get('ProtocolSubjects');
[studies, iStudy] = bst_get('StudyWithSubject', subjects.Subject(1).FileName);

sFile = bst_process('GetNewFilename', bst_fileparts(studies(end).FileName), 'matrix');
sFile = file_unique(sFile);
bst_save(sFile, sMat, 'v6');

db_reload_studies(iStudy)

%% run AEC process on the matrix files

aecFiles(1) = bst_process('CallProcess', 'process_aec1n', file_short(sFile), [], ...
    'timewindow',  [], ...
    'freqbands',   {'alpha', sprintf('%d, %d', f_band), 'mean'}, ...
    'mirror',      0, ...
    'isorth',      0, ...
    'outputmode',  3);  % Save average connectivity matrix (one file)

aecFiles(2) = bst_process('CallProcess', 'process_aec1n', file_short(sFile), [], ...
    'timewindow',  [], ...
    'freqbands',   {'alpha', sprintf('%d, %d', f_band), 'mean'}, ...
    'mirror',      0, ...
    'isorth',      1, ...
    'outputmode',  3);  % Save average connectivity matrix (one file)

aecFiles(3) = bst_process('CallProcess', 'process_aec1', file_short(sFile), [], ...
    'timewindow',  [], ...
    'src_rowname', '1', ...
    'freqbands',   {'alpha', sprintf('%d, %d', f_band), 'mean'}, ...
    'mirror',      0, ...
    'isorth',      0, ...
    'outputmode',  3);  % Save average connectivity matrix (one file)

aecFiles(3) = bst_process('CallProcess', 'process_aec1', file_short(sFile), [], ...
    'timewindow',  [], ...
    'src_rowname', '1', ...
    'freqbands',   {'alpha', sprintf('%d, %d', f_band), 'mean'}, ...
    'mirror',      0, ...
    'isorth',      1, ...
    'outputmode',  3);  % Save average connectivity matrix (one file)

%% plot the original and orthogonalized time-series

y_f = process_bandpass('Compute', y', fs, f_band(1), f_band(2));
HA = hilbert(y_f')';
HB = HA;

iSeed = 1;
HBo = imag(bsxfun(@times, HB, conj(HA(iSeed,:))./abs(HA(iSeed,:))));
HBos = -imag(HBo .* ((1i*HA)./abs(HA)));

figure(1); clf;

subplot(2,2,1); hold on;
l(1) = plot(t,real(HA(1,:))'+5);
l(2) = plot(t,real(HA(2,:))', '--');
l(3) = plot(t,HBos(2,:)'-5, 'Color', l(2).Color);
l(4) = plot(t,real(HA(3,:))'-10, '--');
l(5) = plot(t,HBos(3,:)'-15, 'Color', l(4).Color);
legend(l, 'signal 1', 'signal 2', 'signal 2 | orth', 'signal 3', 'signal 3 | orth');
ylim([-20 25])
set(gca,'YTick',[])

for ii=2:4
    subplot(2,2,ii); hold on;
    l(1) = plot(t,real(HA(1,:))');
    l(2) = plot(t,real(HA(2,:))', '--');
    l(3) = plot(t,HBos(2,:)', 'Color', l(2).Color);
    ylim([-3.5 3.5])
    set(gca,'YTick',[])
    if ii==1; legend(l, 'signal 1', 'signal 2', 'signal 2 | orth'); end
end
subplot(2,2,2); xlim([0 1.5])
subplot(2,2,3); xlim([7 8.5])
subplot(2,2,4); xlim([13.5 15])

% figure(2); clf;
% subplot(2,2,1); hold on;
% plot(real(HA(1,:)));
% plot(real(HB(2,:)));
% subplot(2,2,3); hold on;
% plot(real(HA(1,:)));
% plot(real(HBos(2,:)));
% 
% subplot(2,2,2); hold on;
% plot(real(HA(1,:)));
% plot(real(HB(3,:)));
% subplot(2,2,4); hold on;
% plot(real(HA(1,:)));
% plot(real(HBos(3,:)));



