clc
clear
close all

% Parámetros del transmisor
radarJSON = json2struct(strcat('..', filesep, 'parametros', filesep, 'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parámetros del receptor
radarJSON = json2struct(strcat('..', filesep, 'parametros', filesep, 'radarRx_espiral.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parámetros del sistema
systemJSON = json2struct(strcat('..', filesep, 'parametros', filesep, 'system_espiral.json'));
strSystem = systemJSON.system; clear systemJSON;

% Target 
targetJSON = json2struct(strcat('..', filesep, 'parametros', filesep, 'target_espiral.json'));
strTarget = targetJSON.target; clear targetJSON;

x0 = strTarget.pos(1);
y0 = strTarget.pos(2);

xy0 = strTarget.pos(1); dxy = 0.04; lxy = 1.2;
z0 = strTarget.pos(3); dz = 0.08; lz = 1.2;

% Calcular parámetros
strRadarTx.lamb = strSystem.VelocidadeLuz / strRadarTx.FreqPortadora; % Longitud de onda

%% Carga 

load('simulated_raw_david_fermat.mat')

%% Preprocesamiento

[Nrng, Nazm] = size(rootData);
ratio = 4;

rcompData = interpft(rootData, Nrng * ratio, 1);
rcompData = rcompData.';
fs = ratio * strRadarTx.fs;

clear rootData

%% Procesamiento 

bPlotVerbose = false;
f_interp = 5;

[X, Y, Z] = meshgrid(strGridToProc.xAxis, strGridToProc.yAxis, strGridToProc.zAxis);

% Se abre el pool de trabajadores para la ejecución paralela
if isempty(gcp('nocreate'))
    parpool;
end

outputData_temp = zeros(size(X)); % Variable temporal para guardar los resultados
wb = waitbar(0);
threshold = 1e-11;
c = strSystem.VelocidadeLuz;

parfor m = 1:numel(X)
    
    fprintf('--- PROCESANDO %d de %d ---\n', m, numel(X));
    
    P = [X(m), Y(m), Z(m)];
    n1 = strEnvironment.n1;
    n2 = strEnvironment.n2;
    
    tic
    % Cálculo de Slant range
    [strReflexao, strRefraccoes] = calculaSlantRangeFermat_eff(strDEM, Tx, Rx, P, n1, n2, f_interp); 
    toc
    
    R1t = sqrt(sum((Tx - [strRefraccoes.P_refrac_ida].').^2, 2));
    R2t = sqrt(sum((P - [strRefraccoes.P_refrac_ida].').^2, 2));
    
    R1r = sqrt(sum((Rx - [strRefraccoes.P_refrac_volta].').^2, 2));
    R2r = sqrt(sum((P - [strRefraccoes.P_refrac_volta].').^2, 2));
    
    R1t = R1t.';
    R2t = R2t.';
    R1r = R1r.';
    R2r = R2r.';
    
    % Muestra de bin de rango fraccional
    t = (1/c) * (n1 * R1t + n2 * R2t + n2 * R2r + n1 * R1r);
    rngBin = 1 + round(t * fs);
    
    % Término de compensación de fase
    phi = (2 * pi / strRadarTx.lamb) * (n1 * R1t + n2 * R2t + n2 * R2r + n1 * R1r);
    
    % Interpolación lineal
    lastIND = sub2ind(size(rcompData), (1:Nazm), floor(rngBin));
    nextIND = sub2ind(size(rcompData), (1:Nazm), ceil(rngBin));
    
    q = rngBin - lastIND;
    interp = (1 - q) .* rcompData(lastIND) + q .* rcompData(nextIND);
    
    % Acumulación de datos
    outputData_temp(m) = sum(interp .* exp(1i * phi));
    
    waitbar(m/numel(X), wb, 'Ejecutando algoritmo Back-Projection...');
end

outputData = outputData_temp; % Asignación final de los resultados
close(wb)