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

x0  = strTarget.pos(1);
y0  = strTarget.pos(2);

% xy0 = strTarget.pos(1); dxy = 0.04;  lxy = 0.12;
z0  = strTarget.pos(3); %  dz = 0.08;   lz = 0.24;

% Calculate params

strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda


%% Load 

load('simulated_raw_snell.mat')

%% Preproc 

[Nrng,Nazm] = size(rootData);
ratio = 1;

rcompData = interpft(rootData,Nrng*ratio,1);
rcompData = rcompData.';
fs = ratio*strRadarTx.fs;

clear rootData

%% Processamiento 

tic

wb = waitbar(0);
threshold = 1e-11;
c = strSystem.VelocidadeLuz;
outputData = zeros(size(X));

% n2 = n;

%% Inicializar estructuras para análisis de energía
energyAnalysis = struct();
energyAnalysis.gridPoint = [];      % Punto de la grilla [X, Y, Z]
energyAnalysis.rangeIndex = [];     % Índice de rango
energyAnalysis.timeDelay = [];      % Tiempo de retardo t
energyAnalysis.phaseComp = [];      % Compensación de fase phi
energyAnalysis.idxLast = [];        % Índice anterior
energyAnalysis.idxNext = [];        % Índice siguiente 
energyAnalysis.interpWeight = [];   % Peso de interpolación q
energyAnalysis.dataLast = [];       % Dato anterior rcompData(idxRng,idxLast)
energyAnalysis.dataNext = [];       % Dato siguiente rcompData(idxRng,idxNext)
energyAnalysis.powerContrib = [];   % Contribución de potencia individual
energyAnalysis.totalPower = [];     % Potencia total acumulada

% Contador para almacenar datos
dataCounter = 0;

for m = 1:numel(X)

    % Show progress
    if coder.target('MATLAB')
        fprintf('--- PROCESANDO %d de %d ---\n', m, numel(X));
    end
    
    % Slant range calculation
    [R1t,R2t] = slantRange(PxT,PyT,PzT,X(m),Y(m),Z(m),n2,threshold);
    [R1r,R2r] = slantRange(PxR,PyR,PzR,X(m),Y(m),Z(m),n2,threshold);
    
    % Fractional range bin sample
    t = (1/c)*(R1t + n2*R2t + n2*R2r + R1r);
    rngBin = 1 + t*fs;
    
    % Phase compensation term
    phi = (2*pi/strRadarTx.lamb)*(R1t + n2*R2t + n2*R2r + R1r);
    
    % Data accumulation
    allPower = 0;

    for idxRng = 1:length(rngBin)
        idxNext = ceil(rngBin(idxRng));
        idxLast = floor(rngBin(idxRng));

        q = rngBin(idxRng) - idxLast;

        % Calcular datos interpolados y contribución de potencia
        dataLast = rcompData(idxRng,idxLast);
        dataNext = rcompData(idxRng,idxNext);
        interpData = (1-q)*dataLast + q*dataNext;
        powerContrib = interpData * exp(1i*phi(idxRng));
        
        allPower = allPower + powerContrib;
        
        if m == 1
            % Almacenar datos para análisis de energía
            dataCounter = dataCounter + 1;
            energyAnalysis.gridPoint(dataCounter,:) = [X(m), Y(m), Z(m)];
            energyAnalysis.rangeIndex(dataCounter) = idxRng;
            energyAnalysis.timeDelay(dataCounter) = t(idxRng);
            energyAnalysis.phaseComp(dataCounter) = phi(idxRng);
            energyAnalysis.idxLast(dataCounter) = idxLast;
            energyAnalysis.idxNext(dataCounter) = idxNext;
            energyAnalysis.interpWeight(dataCounter) = q;
            energyAnalysis.dataLast(dataCounter) = dataLast;
            energyAnalysis.dataNext(dataCounter) = dataNext;
            energyAnalysis.powerContrib(dataCounter) = powerContrib;
            energyAnalysis.totalPower(dataCounter) = allPower;
        end
    end

    outputData(m) = allPower;
    
    waitbar(m/numel(X),wb,'Ejecutando algoritmo Back-Projection...');
end
close(wb)
toc

%% Exportar datos de análisis de energía a CSV
fprintf('Guardando análisis de energía en CSV...\n');

% Crear tabla con todos los datos de análisis
analysisTable = table(...
    energyAnalysis.gridPoint(:,1), energyAnalysis.gridPoint(:,2), energyAnalysis.gridPoint(:,3), ...
    energyAnalysis.rangeIndex(:), energyAnalysis.timeDelay(:), energyAnalysis.phaseComp(:), ...
    energyAnalysis.idxLast(:), energyAnalysis.idxNext(:), energyAnalysis.interpWeight(:), ...
    real(energyAnalysis.dataLast(:)), imag(energyAnalysis.dataLast(:)), ...
    real(energyAnalysis.dataNext(:)), imag(energyAnalysis.dataNext(:)), ...
    real(energyAnalysis.powerContrib(:)), imag(energyAnalysis.powerContrib(:)), ...
    abs(energyAnalysis.powerContrib(:)), angle(energyAnalysis.powerContrib(:)), ...
    real(energyAnalysis.totalPower(:)), imag(energyAnalysis.totalPower(:)), ...
    abs(energyAnalysis.totalPower(:)), angle(energyAnalysis.totalPower(:)), ...
    'VariableNames', {...
    'Grid_X', 'Grid_Y', 'Grid_Z', 'Range_Index', 'Time_Delay', 'Phase_Compensation', ...
    'Index_Last', 'Index_Next', 'Interp_Weight', ...
    'Data_Last_Real', 'Data_Last_Imag', 'Data_Next_Real', 'Data_Next_Imag', ...
    'Power_Contrib_Real', 'Power_Contrib_Imag', 'Power_Contrib_Magnitude', 'Power_Contrib_Phase', ...
    'Total_Power_Real', 'Total_Power_Imag', 'Total_Power_Magnitude', 'Total_Power_Phase'});

% Guardar en archivo CSV
writetable(analysisTable, 'analisis_energia_matlab.csv');
fprintf('Análisis de energía guardado en: analisis_energia_matlab.csv\n');
fprintf('Total de muestras analizadas: %d\n', dataCounter);

%%

outputData = readBinary("output_3D_matrix.bin");

outputData = permute(outputData,[2 1 3]);

%% Plots 

figure

s = slice(X,Y,Z,abs(outputData/max(outputData(:))),x0,y0,-5);
set(s,'EdgeColor','none')
% title({'Output Data','abs()'})
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
axis equal
colormap parula

% -------------------------------------------------------------------

figure
dataDB = 20*log10(abs(outputData/max(outputData(:))));
% patch(isosurface(X,Y,Z,dataDB,-13),...
%     'EdgeColor','none','CData',-13,'FaceColor','flat','FaceAlpha',0.15);
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
% contourslice(X,Y,Z,dataDB,[],[],-1.1)
patch(isosurface(X,Y,Z,dataDB,-3),...
    'EdgeColor','none','CData',-3,'FaceColor','flat');
axis equal
% xlim([-0.15 0.15])
% ylim([-0.15 0.15])
% zlim([-2 -0.5])

xlim([min(X,[],'all') max(X,[],'all')])
ylim([min(Y,[],'all') max(Y,[],'all')])
zlim([min(Z,[],'all') max(Z,[],'all')])

grid on
grid minor
view([-45 45])
camlight right
% camlight left
camlight headlight
lighting gouraud
colormap jet
caxis([-40 0])