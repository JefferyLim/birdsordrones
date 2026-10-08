%% Passive radar: standalone synthetic drone vs bird experiment
% No App Designer or add-on toolboxes required.
% Simulates two independent scenes using the same OFDM-like illuminator.
% IMPORTANT: illustrative phase-modulation models, NOT validated target physics.
clear; close all; clc;
rng(42);

%% Experiment settings
Fs = 1e6;                 % Complex-baseband IQ sample rate (samples/s)
T = 1.0;                  % Recording duration (s)
N = round(Fs*T);
t = (0:N-1)'/Fs;
blockLen = 1000;          % 1 ms coherent integration
slowFs = Fs/blockLen;     % 1000 Hz; resolves Doppler up to +/-500 Hz
maxDelay = 14;            % Test delays of 0..14 samples
trueDelay = 5;            % Injected echo delay (samples)
bodyDoppler = 35;         % Common body Doppler (Hz)
echoAmp = 0.16;           % Complex echo voltage amplitude
noiseStd = 0.07;          % Complex AWGN RMS voltage
leakageAmp = 0.45;        % Direct-path interference amplitude
clutterAmp = 0.06;        % Stationary clutter echo amplitude
clutterDelay = 11;

%% Create reproducible OFDM-like baseband reference
nFFT = 1024;
nBlocks = ceil(N/nFFT);
qpsk = exp(1j*(pi/4 + (pi/2)*randi([0,3],nFFT,nBlocks)));
blocks = ifft(qpsk,[],1);
ref = blocks(:);
ref = ref(1:N);
ref = ref / sqrt(mean(abs(ref).^2));

% Fixed-delay paths (NOT calibrated geometric distances)
echoCarrier = [zeros(trueDelay,1); ref(1:end-trueDelay)];
clutterCarrier = [zeros(clutterDelay,1); ref(1:end-clutterDelay)];

%% Illustrative micro-Doppler phase models
% Instantaneous Doppler is (1/2pi) * derivative of phase.
% Drone: 75-Hz repetitive rotor-like motion; 220-Hz peak modulation.
rotorRate = 75; droneExcursion = 220;
drPhase = 2*pi*bodyDoppler*t + ...
    (droneExcursion/rotorRate)*sin(2*pi*rotorRate*t);
% Bird: 7-Hz flapping motion; 95-Hz peak modulation, plus harmonic.
flapRate = 7; birdExcursion = 95;
biPhase = 2*pi*bodyDoppler*t + ...
    (birdExcursion/flapRate)*sin(2*pi*flapRate*t) + ...
    0.35*sin(2*pi*2*flapRate*t);

droneEcho = echoAmp*echoCarrier.*exp(1j*drPhase);
birdEcho  = echoAmp*echoCarrier.*exp(1j*biPhase);
noise1 = (noiseStd/sqrt(2))*(randn(N,1)+1j*randn(N,1));
noise2 = (noiseStd/sqrt(2))*(randn(N,1)+1j*randn(N,1));
common = leakageAmp*ref + clutterAmp*clutterCarrier;
survDrone = common + droneEcho + noise1;
survBird  = common + birdEcho  + noise2;

% Save BOTH raw channels and labeled ground truth for repeatable experiments.
params = struct('Fs',Fs,'duration_s',T,'trueDelay_samples',trueDelay, ...
    'bodyDoppler_Hz',bodyDoppler,'echoAmplitude',echoAmp, ...
    'noiseRms',noiseStd,'leakageAmplitude',leakageAmp, ...
    'clutterAmplitude',clutterAmp,'slowFs',slowFs, ...
    'note','Synthetic demonstration; not field-recorded or physically validated');
surv = survDrone; label = 'drone';
save('synthetic_drone.mat','ref','surv','params','label','-v7.3');
surv = survBird; label = 'bird';
save('synthetic_bird.mat','ref','surv','params','label','-v7.3');

%% Process the raw recordings
% Known-leakage subtraction is an IDEALIZATION to isolate radar processing.
% Real passive radar requires direct-path/clutter suppression methods.
cleanDrone = survDrone - leakageAmp*ref;
cleanBird  = survBird  - leakageAmp*ref;

% CAF-like delay-Doppler map: integrate reference-conjugate*surveillance
% in each 1-ms block, then FFT along slow-time. This is deliberately
% simplified, not a production wideband CAF processor.
[mapDrone, fd, delayBins, slowDrone] = simpleMap(ref,cleanDrone, ...
    Fs,blockLen,maxDelay,trueDelay);
[mapBird, ~, ~, slowBird] = simpleMap(ref,cleanBird, ...
    Fs,blockLen,maxDelay,trueDelay);

figure('Name','Synthetic passive radar: delay-Doppler','Color','w');
subplot(1,2,1);
imagesc(delayBins,fd,20*log10(abs(mapDrone.')+1e-12));
axis xy; xlabel('Echo delay (samples)'); ylabel('Doppler (Hz)');
title('Drone: delay-Doppler'); colorbar;
subplot(1,2,2);
imagesc(delayBins,fd,20*log10(abs(mapBird.')+1e-12));
axis xy; xlabel('Echo delay (samples)'); ylabel('Doppler (Hz)');
title('Bird: delay-Doppler'); colorbar;

% Time-varying spectrum of the slow-time matched-filter output, showing
% faster drone modulation versus slower bird flaps.
figure('Name','Synthetic micro-Doppler','Color','w');
subplot(2,1,1);
showSTFT(slowDrone,slowFs,'Drone: micro-Doppler');
subplot(2,1,2);
showSTFT(slowBird,slowFs,'Bird: micro-Doppler');

fprintf('Saved synthetic_drone.mat and synthetic_bird.mat\n');
fprintf('Fs = %.1f MHz, T = %.1f s, true delay = %d samples\n', ...
    Fs/1e6,T,trueDelay);
fprintf('Approx. echo/noise SNR before processing = %.1f dB\n', ...
    20*log10(echoAmp/noiseStd));
fprintf(['Note: delay bins are not target distance. Bistatic geometry, ' ...
    'waveform bandwidth and scattering must be modeled for range claims.\n']);

%% Local functions (MATLAB R2016b or newer)
function [map,fd,delays,atTruth] = simpleMap(ref,surv,Fs,L,maxDelay,trueDelay)
    blocks = floor(numel(ref)/L);
    n = blocks*L;
    survBlocks = reshape(surv(1:n),L,blocks);
    delays = 0:maxDelay;
    map = zeros(numel(delays),blocks);
    for k=1:numel(delays)
        d = delays(k);
        delayed = zeros(n,1);
        if d==0
            delayed=ref(1:n);
        else
            delayed(d+1:end)=ref(1:n-d);
        end
        refBlocks = reshape(delayed,L,blocks);
        slow = mean(conj(refBlocks).*survBlocks,1);
        map(k,:) = fftshift(fft(slow));
        if d==trueDelay
            atTruth = slow(:);
        end
    end
    slowFs = Fs/L;
    fd = ((0:blocks-1)-floor(blocks/2))*(slowFs/blocks);
end

function showSTFT(x,Fs,caption)
    % Manual STFT, no Signal Processing Toolbox dependency
    winLen=128; hop=12; nFFT=512;
    nFrames = floor((numel(x)-winLen)/hop)+1;
    win = 0.5-0.5*cos(2*pi*(0:winLen-1)'/(winLen-1));
    S = zeros(nFFT,nFrames);
    for k=1:nFrames
        seg=x((k-1)*hop+(1:winLen)).*win;
        S(:,k) = fftshift(fft(seg,nFFT));
    end
    freq=((0:nFFT-1)-nFFT/2)*Fs/nFFT;
    centers=((0:nFrames-1)*hop + winLen/2)/Fs;
    imagesc(centers,freq,20*log10(abs(S)+1e-10));
    axis xy; ylim([-350 350]);
    xlabel('Time (s)'); ylabel('Doppler (Hz)');
    title(caption); colorbar;
end
