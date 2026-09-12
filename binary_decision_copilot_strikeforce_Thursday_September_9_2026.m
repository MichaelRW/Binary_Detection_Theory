

%% Synopsis

% Gaussian noise and signal-plus-noise detection using a deterministic
% sinusoidal signal over a range of signal-to-noise ratios.



%% Environment

close all;  clear;  clc;

addpath( 'C:\00 Temporary\95 Strikeforce\Toolset\' );

set( 0, 'DefaultLineLineWidth', 1.0 );

set( 0, 'DefaultFigureWindowStyle', 'normal' );



%% Simulation Parameters

rng(1);

fs = 1000;
duration = 1;
numSamples = round(fs * duration);
numTrials = 10000;

frequency = 50;
time = (0:numSamples-1)' / fs;
baseSignal = sin(2*pi*frequency*time);

noiseVariance = 1;
noiseStandardDeviation = sqrt(noiseVariance);
signalPower = mean(baseSignal.^2);

snrDb = -10:2:10;
numSnrLevels = numel(snrDb);

% Matched-filter template with unit energy
template = baseSignal / norm(baseSignal);

% Decision threshold for the binary decision table
decisionThreshold = 0.5;

% Thresholds used to generate ROC curves
rocThresholds = linspace( 0 , 8, 9 );

probabilityFalseAlarm = zeros(1, numSnrLevels);
probabilityDetection = zeros(1, numSnrLevels);
binaryDecisionTables = zeros(2, 2, numSnrLevels);

% return

%% Detection simulation

figure( 'Name', 'Receiver Operating Characteristics' ); ...

hold on;

    for index = 1:numSnrLevels
    
        currentSnrLinear = 10^(snrDb(index) / 10);
        signalAmplitude = sqrt(currentSnrLinear * noiseVariance / signalPower);
        signal = signalAmplitude * baseSignal;
    
        % Generate noise-only and signal-plus-noise observations
        noiseOnly = noiseStandardDeviation * randn(numSamples, numTrials);
        signalPlusNoise = signal + noiseStandardDeviation * ...
            randn(numSamples, numTrials);
    
        % Matched-filter decision statistics
        statisticUnderH0 = template' * noiseOnly;
        statisticUnderH1 = template' * signalPlusNoise;
    
        % Binary decision table at the selected threshold
        decisionUnderH0 = statisticUnderH0 >= decisionThreshold;
        decisionUnderH1 = statisticUnderH1 >= decisionThreshold;
    
        probabilityFalseAlarm(index) = mean(decisionUnderH0);
        probabilityDetection(index) = mean(decisionUnderH1);
    
        binaryDecisionTables(:, :, index) = [
            mean(~decisionUnderH0), mean(decisionUnderH0);
            mean(~decisionUnderH1), mean(decisionUnderH1)
        ];
    
        % ROC curve for the current SNR
        falseAlarmRate = zeros(size(rocThresholds));
        detectionRate = zeros(size(rocThresholds));
    
        for thresholdIndex = 1:numel(rocThresholds)
            threshold = rocThresholds(thresholdIndex);
            falseAlarmRate(thresholdIndex) = ...
                mean(statisticUnderH0 >= threshold);
            detectionRate(thresholdIndex) = ...
                mean(statisticUnderH1 >= threshold);
        end
    
        plot(falseAlarmRate, detectionRate, 'LineWidth', 1.5, ...
            'DisplayName', sprintf('%+d dB', snrDb(index)));
    
    end
    
    
    plot([0 1], [0 1], 'k--', 'HandleVisibility', 'off');
    xlabel('Probability of False Alarm');
    ylabel('Probability of Detection');
    title('Receiver Operating Characteristic');
    legend( 'Location', 'EastOutside' );
    axis([0 1 0 1]);
    daspect( [ 1 1 1 ] );

% return

%% Display binary decision tables

figure('Name', 'Binary Decision Tables');
tiledlayout(3, 4, 'TileSpacing', 'compact', 'Padding', 'compact');

for index = 1:numSnrLevels
    nexttile;

    imagesc(binaryDecisionTables(:, :, index));
    colormap parula;
    colorbar;
    caxis([0 1]);

    xticks([1 2]);
    xticklabels({'D = 0', 'D = 1'});
    yticks([1 2]);
    yticklabels({'H = 0', 'H = 1'});
    xlabel('Decision');
    ylabel('Actual hypothesis');
    title(sprintf('%+d dB', snrDb(index)));

    for row = 1:2
        for column = 1:2
            text(column, row, ...
                sprintf('%.3f', binaryDecisionTables(row, column, index)), ...
                'HorizontalAlignment', 'center', ...
                'Color', 'white', ...
                'FontWeight', 'bold');
        end
    end
end



%% Plot detection and false-alarm probabilities versus SNR

figure('Name', 'Detection Performance');
plot(snrDb, probabilityDetection, 'o-', 'LineWidth', 1.5);
hold on;
plot(snrDb, probabilityFalseAlarm, 's-', 'LineWidth', 1.5);
grid on;
xlabel('SNR (dB)');
ylabel('Probability');
title('Binary Detection Performance');
legend('Probability of Detection', 'Probability of False Alarm', ...
    'Location', 'southeast');
ylim([0 1]);



%% Clean-up

autoArrangeFigures( 2, 2, 1 );

fprintf( 1, '\n\n\n*** Processing Complete ***\n\n\n' );



%% Reference(s)


