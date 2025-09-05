clc
clear
close all

addpath(genpath('src'))
addpath(genpath(strcat('..',filesep,'tools')))
addpath(genpath(strcat('..',filesep,'common')))

% Parametros del transmisor
radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor
radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_espiral.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parametros do sistema
systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_espiral.json'));
strSystem  = systemJSON.system; clear systemJSON;

% Target 
targetJSON = json2struct(strcat('..',filesep,'parametros',filesep,'target_espiral.json'));
strTarget  = targetJSON.target; clear targetJSON;

% Grid
x0  = strTarget.pos(1);
y0  = strTarget.pos(2);

xy0 = strTarget.pos(1); dxy = 0.04;  lxy = 1.2;
z0  = strTarget.pos(3);  dz = 0.08;   lz = 1.2;

%% Calculate params
strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda

%% Load 
load('simulated_raw_david_fermat.mat')

ratio         = 4;
[Nrng,Nazm]   = size(rootData);
strRadarTx.fs = strRadarTx.fs*ratio;

rcompData     = interpft(rootData,Nrng*ratio,1);
rcompData     = rcompData.';
clear rootData

%% Run
strGridToProc.xAxis = strGridToProc.xAxis(1:15:end);
strGridToProc.yAxis = strGridToProc.yAxis(1:15:end);
strGridToProc.zAxis = strGridToProc.zAxis(1:10:end);

outputData = proc_fermat_run(rcompData,strRadarTx,strGridToProc,strEnvironment,strDEM,Tx,Rx);

%% Save outputData
save(strcat('data',filesep,'outputData.mat'), 'outputData');

% %% Plots 
% figure
% s = slice(X,Y,Z,abs(outputData/max(outputData(:))),x0,y0,-5);
% set(s,'EdgeColor','none')
% % title({'Output Data','abs()'})
% xlabel('x (m)')
% ylabel('y (m)')
% zlabel('z (m)')
% axis equal
% colormap parula
% 
% % -------------------------------------------------------------------
% figure
% dataDB = 20*log10(abs(outputData/max(outputData(:))));
% % contourslice(X,Y,Z,dataDB,[],[],-1.1)
% patch(isosurface(X,Y,Z,dataDB,-3),...
%     'EdgeColor','none','CData',-3,'FaceColor','flat');
% % patch(isosurface(X,Y,Z,dataDB,-13),...
% %     'EdgeColor','none','CData',-13,'FaceColor','flat','FaceAlpha',0.15);
% xlabel('x (m)')
% ylabel('y (m)')
% zlabel('z (m)')
% axis equal
% % xlim([-0.15 0.15])
% % ylim([-0.15 0.15])
% % zlim([-2 -0.5])
% 
% xlim([min(X,[],'all') max(X,[],'all')])
% ylim([min(Y,[],'all') max(Y,[],'all')])
% zlim([min(Z,[],'all') max(Z,[],'all')])
% 
% grid on
% grid minor
% view([-45 45])
% camlight right
% % camlight left
% camlight headlight
% lighting gouraud
% colormap jet
% caxis([-40 0])