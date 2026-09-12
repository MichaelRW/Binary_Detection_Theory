

%% Co-pilot Prompt

% "I want a Matlab script-file that will demonstrate binary decision theory for a 
% signal detection case. It should use a normal distribution for the noise model 
% and a normal distribution for the signal with noise model. The signal model 
% should be a deterministic and be a sinusoidal signal. The signal and noise 
% should be mixed at SNR levels from -10 dB to +10 dB in steps of 2 dB. 
% The script-file should also calculate and plot the binary decision table and also
% plot the receiver operating characterstic for all of the SNR levels considered. 
% Include plots of histograms for both the noise and noise with signal vectors."



%% Environment

close all;  clear;  clc;

addpath( 'C:\00 Temporary\95 Strikeforce\Toolset\' );

set( 0, 'DefaultLineLineWidth', 1.0 );

set( 0, 'DefaultFigureWindowStyle', 'normal' );



%% Binary decision theory: sinusoidal signal detection in Gaussian noise

% H0: x[n] = w[n]
% H1: x[n] = s[n] + w[n]
%
% The detector is a coherent correlator matched to the known sinusoid.
% With Gaussian noise, its decision statistic is Gaussian under both
% hypotheses, which makes the binary decision and ROC calculations direct.


rng(7);



%% Simulation parameters

snrDb = -10:2:10;
nSnr = numel(snrDb);
sigmaNoise = 1;
fs = 1000;
nSamples = 32;
nTrials = 100000;
thresholdCount = 401;

t = (0:nSamples-1) / fs;
f0 = 25;
unitSinusoid = sqrt(2/nSamples) * sin(2*pi*f0*t);

% Raw vectors are retained for the requested histograms.
noiseVectors = cell(1, nSnr);
signalNoiseVectors = cell(1, nSnr);

% Each row contains Monte Carlo decision statistics for one SNR.
noiseDecision = sigmaNoise * randn(nSnr, nTrials);
signalDecision = zeros(nSnr, nTrials);
signalRms = zeros(1, nSnr);
decisionMeans = zeros(1, nSnr);
thresholds = zeros(1, nSnr);

for k = 1:nSnr
    % A sinusoid with this amplitude has the requested RMS SNR.
    amplitude = sqrt(2) * sigmaNoise * 10^(snrDb(k)/20);
    signal = amplitude * sin(2*pi*f0*t);
    signalRms(k) = rms(signal);

    noiseVectors{k} = sigmaNoise * randn(1, nSamples);
    signalNoiseVectors{k} = signal + sigmaNoise * randn(1, nSamples);

    % The unit-energy correlator produces N(mu, sigmaNoise^2).
    decisionMeans(k) = amplitude * sum(sin(2*pi*f0*t) .* unitSinusoid);
    signalDecision(k, :) = decisionMeans(k) + sigmaNoise * randn(1, nTrials);
    thresholds(k) = decisionMeans(k) / 2;  % Equal priors and equal costs.
end



%% Binary decisions at the equal-prior/equal-cost threshold
truePositive = zeros(1, nSnr);
falseNegative = zeros(1, nSnr);
trueNegative = zeros(1, nSnr);
falsePositive = zeros(1, nSnr);

for k = 1:nSnr
    detectedUnderH1 = signalDecision(k, :) >= thresholds(k);
    detectedUnderH0 = noiseDecision(k, :) >= thresholds(k);

    truePositive(k) = sum(detectedUnderH1);
    falseNegative(k) = nTrials - truePositive(k);
    falsePositive(k) = sum(detectedUnderH0);
    trueNegative(k) = nTrials - falsePositive(k);
end

pd = truePositive / nTrials;
pMiss = falseNegative / nTrials;
pfa = falsePositive / nTrials;
pn = trueNegative / nTrials;

binaryDecisionTable = table( ...
    snrDb(:), signalRms(:), thresholds(:), ...
    truePositive(:), falseNegative(:), trueNegative(:), falsePositive(:), ...
    pd(:), pMiss(:), pn(:), pfa(:), ...
    'VariableNames', {'SNR_dB', 'SignalRMS', 'Threshold', ...
    'TruePositive', 'FalseNegative', 'TrueNegative', 'FalsePositive', ...
    'Pd', 'Pmiss', 'Pn', 'Pfa'});

disp('Binary decision table:');
disp(binaryDecisionTable);



%% Plot the binary decision tables as confusion-matrix heatmaps

figure('Name', 'Binary decision tables', 'Color', 'w');
tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:nSnr
    nexttile;
    confusionMatrix = [trueNegative(k), falsePositive(k); ...
                       falseNegative(k), truePositive(k)] / nTrials;
    imagesc(confusionMatrix);
    axis image;
    caxis([0 1]);
    colormap(parula);
    colorbar;
    set(gca, 'XTick', 1:2, 'XTickLabel', {'Decide H0', 'Decide H1'}, ...
        'YTick', 1:2, 'YTickLabel', {'H0 true', 'H1 true'});
    title(sprintf('%+d dB', snrDb(k)));
    for row = 1:2
        for col = 1:2
            text(col, row, sprintf('%.3f', confusionMatrix(row, col)), ...
                'HorizontalAlignment', 'center', 'Color', 'w', ...
                'FontWeight', 'bold');
        end
    end
end
sgtitle('Normalized binary decision tables');



%% Plot raw noise and signal-plus-noise histograms
figure('Name', 'Noise and signal-plus-noise histograms', 'Color', 'w');
tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');
for k = 1:nSnr
    nexttile;
    histogram(noiseVectors{k}, 35, 'Normalization', 'pdf', ...
        'FaceColor', [0.2 0.4 0.8], 'FaceAlpha', 0.55, ...
        'EdgeColor', 'none');
    hold on;
    histogram(signalNoiseVectors{k}, 35, 'Normalization', 'pdf', ...
        'FaceColor', [0.9 0.35 0.2], 'FaceAlpha', 0.55, ...
        'EdgeColor', 'none');
    hold off;
    grid on;
    title(sprintf('%+d dB', snrDb(k)));
    xlabel('Sample value');
    ylabel('PDF');
    if k == 1
        legend('Noise, H0', 'Signal + noise, H1', 'Location', 'best');
    end
end
sgtitle('Raw observation histograms');



%% Plot ROC curves for all SNR levels
figure('Name', 'Receiver operating characteristic', 'Color', 'w');
hold on;
rocColors = lines(nSnr);
auc = zeros(1, nSnr);
for k = 1:nSnr
    rocThresholds = linspace(min(noiseDecision(k, :)), ...
        max(signalDecision(k, :)), thresholdCount);
    rocPd = zeros(size(rocThresholds));
    rocPfa = zeros(size(rocThresholds));
    for m = 1:numel(rocThresholds)
        rocPd(m) = mean(signalDecision(k, :) >= rocThresholds(m));
        rocPfa(m) = mean(noiseDecision(k, :) >= rocThresholds(m));
    end
    [rocPfaSorted, order] = sort(rocPfa);
    rocPdSorted = rocPd(order);
    auc(k) = trapz(rocPfaSorted, rocPdSorted);
    plot(rocPfa, rocPd, 'LineWidth', 1.5, 'Color', rocColors(k, :), ...
        'DisplayName', sprintf('%+d dB (AUC %.3f)', snrDb(k), auc(k)));
end
plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
hold off;
grid on;
xlim([0 1]);
ylim([0 1]);
xlabel('Probability of false alarm, P_{FA}');
ylabel('Probability of detection, P_D');
title('ROC curves for sinusoidal signal detection');
legend('Location', 'southeast');
daspect( [ 1 1 1 ] );



%% Clean-up

autoArrangeFigures( 2, 2, 1 );

fprintf( 1, '\n\n\n*** Processing Complete ***\n\n\n' );



%% Reference(s)


