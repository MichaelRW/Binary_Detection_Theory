

%% Synopsis

% ph



%% To Do

% ph



%% Definition

% Signal Present Trial - A trial in which the signal of interest is present.
% Signal Absent Trial - A trial i which the signa of interest is not present.

% Hit - The observer says the signal is present when it is present.
% Correct Reject - The observer says the signal is absent when the signal is absent.
% False Alarm - The observer says the signal is present but the signal is absent (Type 1 Error or Alpha Error).
% Miss - The observer says the signal is not present but the signal is present (Type 2 Error of Beta Error).



%% Environment

close all; clear; clc;
% restoredefaultpath;

set( 0, 'DefaultFigureWindowStyle', 'normal', 'DefaultFigureRendererMode', 'auto' );

addpath( 'C:\00 Temporary\Toolset', '-begin' );

set( 0, 'DefaultFigurePosition', [  400  400  900  400  ] );  % [ left bottom width height ]
set( 0, 'DefaultFigureWindowStyle', 'normal' );
set( 0, 'DefaultLineLineWidth', 0.5 );
set( 0, 'DefaultTextInterpreter', 'Latex' );

format ShortG;

warning( 'on' );

pause( 1 );



%% Gaussian DistributionsParameters

rng( 0 );

n = 1e4;
    signalPresentAbsent = round( rand( n, 1 ) );
%
% figure;  histogram( signalPresentAbsent );  grid on;


% set all signal trials by finding where they are and then making them draw
% from the gaussian distribution with mean 1 and std 1 and make that the right size
% signal(find(signalPresentAbsent==1)) = random('norm',1,1,1,sum(signalPresentAbsent));
signal( signalPresentAbsent == 1 ) = random('norm',1,1,1,sum(signalPresentAbsent));
    the_signal = random('norm',1,1,1,sum(signalPresentAbsent));

% same goes for noise trials, but now from gaussian with mean 0 and std 1
signal( ( signalPresentAbsent == 0 ) ) = random('norm',0,1,1,sum(signalPresentAbsent==0));
    noise = signal( ( signalPresentAbsent == 0 ) );


EDGES = -4:0.1:4;

figure; ...
    h_signal_present = histogram(signal(signalPresentAbsent==1), EDGES );  % show signal present distribution
    hold on;
    h_signal_absent = histogram(signal(signalPresentAbsent==0), EDGES );  % show signal absent distribution
    grid on;


response = ( 0.5 < signal );


fprintf( 1, '\n\nTotal number of trials:  %d\n', n );



% Get the total number of signal-present trials.
%
nPresent = sum( signalPresentAbsent == 1 );

% Compute the ratio of hits as all of the responses to trials in which the signal was present (i.e., signalPresentAbsent == 1 )
% in which the response was present (i.e., == 1).
%
hits = sum( response( signalPresentAbsent == 1 ) == 1 ) / nPresent;

% Compute the ratio of misses as all of the responses to trials in which the signal was present (i.e., signalPresentAbsent == 1 )
% in which the response was absent (i.e., == 0).
misses = sum( response( signalPresentAbsent == 1 ) ==0 ) / nPresent;

fprintf( 1, '\n' );
fprintf( 1, 'Number of present signals:  %d\n', nPresent );
fprintf( 1, '\tRatio of hits:  %3.2f\n', hits );
fprintf( 1, '\tRatio of misses:  %3.2f\n', misses );



% Get the total number of signal-abset trials.
nAbsent = sum( signalPresentAbsent == 0 );

% Compute the ratio of hits as all of the responses to trails in which the signal was absent (i.e., signalPresentAbsent == 0)
% in which the response was absent (i.e., == 0).
correctRejects = sum( response( signalPresentAbsent == 0 ) == 0 ) / nAbsent;

% Compute the ratio of hits as all of the responses to trails in which the signal was absent (i.e., signalPresentAbsent == 0)
% in which the response was present (i.e., == 1).
falseAlarms = sum( response( signalPresentAbsent == 0 ) == 1 ) / nAbsent;

fprintf( 1, '\n' );
fprintf( 1, 'Number of absent signals:  %d\n', nAbsent );
fprintf( 1, '\tRatio of correct rejections:  %3.2f\n', correctRejects );
fprintf( 1, '\tRatio of false alarms:  %3.2f\n', falseAlarms );



%% Calculate d'

% zHits = icdf('norm',hits,0,1)
% zFalseAlarms = icdf('norm',falseAlarms,0,1)
% dPrime = zHits-zFalseAlarms



%% Secondary Observer


% simulate observer
response = signal>0.5;
% get hits and falseAlarms
hits = sum(response(signalPresentAbsent==1)==1)/nPresent
falseAlarms = sum(response(signalPresentAbsent==0)==1)/nAbsent
% compute z-scores
zHits = icdf('norm',hits,0,1)
zFalseAlarms = icdf('norm',falseAlarms,0,1)
% compute d-prime
dPrime = zHits-zFalseAlarms


hits = [];falseAlarms=[];
nSignal = length(signal);nNoise = length(noise);
for criterion = 10:-0.1:-10
  hits(end+1) = sum(signal>criterion)/nSignal;
  falseAlarms(end+1) = sum(noise>criterion)/nNoise;
end


figure;  ...
    plot( falseAlarms, hits);  grid on;
    daspect( [ 1 1 1 ] );
    xlabel( 'False Alarm Ratio' );  ylabel( 'Hit Ratio' );

areaUnderROC = sum(hits(2:end).*diff(falseAlarms))
% 
% n = length( the_signal );
%     sum( noise < the_signal ) ./ n



%% Test

% make a new experiment with n=1000 trials
n = 1000;
% choose which trials have signal and which do not
signalPresentAbsent = round(rand(1,1000));
% reset your signal
signal = [];
% and put signal or noise appropriately into the signal
signal(find(signalPresentAbsent==1)) = random('norm',1,1,1,sum(signalPresentAbsent));
% same goes for noise trials, but now from gaussian with mean 0 and std 1
signal(find(signalPresentAbsent==0)) = random('norm',0,1,1,sum(signalPresentAbsent==0));
% now compute the response at different thresholds
response = 1+(signal>0)+(signal>0.333)+(signal>0.666)+(signal>1)


% compute number of present and absent trials
nPresent = sum(signalPresentAbsent==1);
nAbsent = sum(signalPresentAbsent==0);
% now compute hits and false alarms for rating 5 
hits(1) = sum(response(signalPresentAbsent==1)==5)/nPresent;
falseAlarms(1) = sum(response(signalPresentAbsent==0)==5)/nAbsent;
% now compute hits and false alarms for rating 4 
hits(2) = sum(response(signalPresentAbsent==1)>=4)/nPresent;
falseAlarms(2) = sum(response(signalPresentAbsent==0)>=4)/nAbsent;
% and so on...
hits(3) = sum(response(signalPresentAbsent==1)>=3)/nPresent;
falseAlarms(3) = sum(response(signalPresentAbsent==0)>=3)/nAbsent;
hits(4) = sum(response(signalPresentAbsent==1)>=2)/nPresent;
falseAlarms(4) = sum(response(signalPresentAbsent==0)>=2)/nAbsent;


figure; ...
    plot( [ 0  falseAlarms  1 ], [ 0  hits  1 ], 'ko-' );   grid on;
    daspect( [ 1 1 1 ] );
    xlabel( 'False Alarm Ratio' );  ylabel( 'Hit Ratio' );



%% Clean-up

monitors = get( 0, 'MonitorPositions' );
    if ( 1 < size( monitors, 1 ) )
        autoArrangeFigures( 2, 2, 2 );
    end

fprintf( 1, '\n\n\n*** Processing Complete ***\n\n\n' );



%% Reference(s)

% https://gru.stanford.edu/doku.php/tutorials/sdt
    % https://www.cns.nyu.edu/~david/handouts/sdt/sdt.html


