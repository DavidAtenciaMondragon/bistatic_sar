clc;
clear;
close all;

% 
addpath(genpath('analise_energia'))
addpath(genpath('src'))
addpath(genpath(strcat('..',filesep,'tools')))

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Transmissor 
[PxT, PyT, PzT] = funcao_espiral(strRadarTx.NumVoltasEsp, strRadarTx.RaioMenorEsp, strRadarTx.RaioMaiorEsp,...
                              strRadarTx.AltMaiorEsp,strRadarTx.AltMenorEsp, strRadarTx.Vt, strRadarTx.PRF);
                          
                          

% --- Parámetros del Grid 3D ---

% 1. Límites de las coordenadas
x_min = -0.25e3;
x_max =  0.25e3;
y_min = -0.25e3;
y_max =  0.25e3;
z_min = -40;
z_max = -20;

% 2. Cantidad de puntos en cada eje
num_puntos_x = 6; % Puntos en la dirección X
num_puntos_y = 6; % Puntos en la dirección Y
num_puntos_z = 5;  % Puntos en la dirección Z

radio_filtro = 200; % Todo lo que esté fuera de este radio será eliminado

% --- Generación de los vectores para cada eje ---
x_vec = linspace(x_min, x_max, num_puntos_x);
y_vec = linspace(y_min, y_max, num_puntos_y);
z_vec = linspace(z_min, z_max, num_puntos_z);


% --- Creación de la malla (Grid) 3D ---
[X, Y, Z] = meshgrid(x_vec, y_vec, z_vec);

% --- APLICACIÓN DEL FILTRO CIRCULAR ---

% Se define el centro del círculo en el plano XY. 
% En tu caso, como los límites son simétricos, el centro es (0,0).
centro_x = 0;
centro_y = 0;

% Calculamos la condición. La ecuación de un círculo es (x-cx)^2 + (y-cy)^2 <= r^2.
% Esto crea una matriz lógica (de 'true' y 'false') del mismo tamaño que X, Y, Z.
% Será 'true' para todos los puntos que están DENTRO del radio y 'false' para los que están fuera.
indices_validos = (X - centro_x).^2 + (Y - centro_y).^2 <= radio_filtro^2;

% Usamos esta matriz lógica para quedarnos solo con los puntos que cumplen la condición.
% Las matrices X, Y, Z se "aplanan" para convertirse en vectores columna con solo los puntos válidos.
X_filtrado = X(indices_validos);
Y_filtrado = Y(indices_validos);
Z_filtrado = Z(indices_validos);

strVolumEmAnalise.X = X_filtrado;
strVolumEmAnalise.Y = Y_filtrado;
strVolumEmAnalise.Z = Z_filtrado;

% Save strVolumEmAnalise (.mat)
save(strcat("data",filesep,"strVolumEmAnalise.mat"),'strVolumEmAnalise');


% Grid solo
[Xg,Yg] = meshgrid([-x_min x_min]);
Zg      = zeros(size(Xg));

% --- Visualización del Grid Filtrado ---

figure; % Crea una nueva figura
hold on 
% Ahora graficamos solo los puntos que pasaron el filtro.
plot3(X_filtrado, Y_filtrado, Z_filtrado, 'b.');
plot3(PxT, PyT, PzT,'k--');
surf(Xg,Yg,Zg,'EdgeColor','none','FaceColor',[1 0 1],'FaceAlpha',0.1)
title('Grid 3D con Filtro Circular');
xlabel('Eje X');
ylabel('Eje Y');
zlabel('Eje Z');
grid on;
view(3);

%% Params

n1 = 1;
n2 = 4;
c = physconst("lightspeed");

%% Run
Rx_inicial_xy = [mean(X_filtrado), mean(Y_filtrado)];
Rx_previo_xy = Rx_inicial_xy; % Para memoria de posición anterior

step = 300;

PxT = PxT(1:step:end);
PyT = PyT(1:step:end);
PzT = PzT(1:step:end);

PxR = zeros(size(PxT));
PyR = zeros(size(PxT));
PzR = zeros(size(PxT));

% Crear archivos de log para registrar energías
log_txt_filename = sprintf('log_energia_%s.txt');
log_csv_filename = sprintf('log_energia_%s.csv');

% Archivo TXT para lectura humana
log_txt_file = fopen(log_txt_filename, 'w');
fprintf(log_txt_file, 'Log de Energías - Optimización de Trayectoria Rx\n');
fprintf(log_txt_file, 'Fecha: %s\n', datestr(now, 'yyyy-mm-dd HH:MM:SS'));
fprintf(log_txt_file, 'Puntos Tx procesados: %d\n', length(PxT));
fprintf(log_txt_file, 'Puntos objetivo: %d\n', length(X_filtrado));
fprintf(log_txt_file, '\n');
fprintf(log_txt_file, 'Formato: Punto_i | Tx[x,y,z] | Rx_optimal[x,y,z] | Rx_inicial[x,y] | Dist_inicial(m) | Energia(nW)\n');
fprintf(log_txt_file, '================================================================================\n');

% Archivo CSV para análisis en MATLAB
log_csv_file = fopen(log_csv_filename, 'w');
fprintf(log_csv_file, 'punto,Tx_x,Tx_y,Tx_z,Rx_x,Rx_y,Rx_z,Rx_inicial_x,Rx_inicial_y,dist_inicial,energia_promedio\n');

% Preallocar matriz para datos CSV (más eficiente)
log_data = zeros(length(PxT), 8);

fprintf('Iniciando optimización. Logs guardados en:\n');
fprintf('  - Formato legible: %s\n', log_txt_filename);
fprintf('  - Formato CSV: %s\n', log_csv_filename);

tic
for i = 1:length(PxT)
    
    fprintf('Procesando punto %d/%d\n', i, length(PxT));
    
    % Altura fija para el receptor Rx (igual a la del Tx en este punto)
    Rx_z = PzT(i);
    Tx   = [PxT(i), PyT(i), PzT(i)];
    P_targets = [X_filtrado, Y_filtrado, Z_filtrado];
    
    % Calcular posición especular ideal
    Rx_especular_xy = calcular_posicion_especular(Tx, P_targets, Rx_z);
    
    % Punto inicial inteligente
    if i > 1
        % Para puntos posteriores, usar la posición anterior como inicial 
        Rx_inicial_restringido = Rx_previo_xy;
    else
        % Para el primer punto, usar posición especular o centro del grid
        Rx_inicial_restringido = [mean(X_filtrado), mean(Y_filtrado)];
    end
    
    % Usar optimización libre (RECOMENDADO tras diagnóstico)
    objective_function = @(rx_xy) -calcular_energia_promedio([rx_xy, Rx_z], Tx, P_targets, n1, n2);
    
    % Configurar opciones del optimizador para mayor precisión
    options = optimset('TolX', 1e-8, 'TolFun', 1e-12, 'MaxIter', 1000, 'MaxFunEvals', 2000, 'Display', 'off');
    
    % Llamada al optimizador con punto inicial geométricamente inteligente
    [optimal_Rx_xy, max_energia_neg] = fminsearch(objective_function, Rx_inicial_restringido, options);
    
    % Reconstruir la posición 3D óptima del receptor
    optimal_Rx = [optimal_Rx_xy, Rx_z];
    
    % Calcular la energía promedio final con la posición óptima
    energia_promedio = calcular_energia_promedio(optimal_Rx, Tx, P_targets, n1, n2);
    
    % Calcular distancia a la posición inicial para el log  
    distancia_inicial = norm(optimal_Rx_xy - Rx_inicial_restringido);
    
    % Registrar en el log TXT (legible con energía en nanowatts)
    energia_nW = energia_promedio * 1e9; % Convertir de watts a nanowatts
    fprintf(log_txt_file, '%3d | [%8.2f,%8.2f,%6.2f] | [%8.2f,%8.2f,%6.2f] | [%8.2f,%8.2f] | %8.2f | %12.6f\n', ...
            i, Tx(1), Tx(2), Tx(3), optimal_Rx(1), optimal_Rx(2), optimal_Rx(3), ...
            Rx_inicial_restringido(1), Rx_inicial_restringido(2), distancia_inicial, energia_nW);
    
    % Registrar en el log CSV 
    fprintf(log_csv_file, '%d,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.12e\n', ...
            i, Tx(1), Tx(2), Tx(3), optimal_Rx(1), optimal_Rx(2), optimal_Rx(3), ...
            Rx_inicial_restringido(1), Rx_inicial_restringido(2), distancia_inicial, energia_promedio);
    
    % Guardar en matriz para análisis posterior (expandida)
    log_data(i, :) = [i, Tx(1), Tx(2), Tx(3), optimal_Rx(1), optimal_Rx(2), optimal_Rx(3), energia_promedio];
    
    PxR(i) = optimal_Rx(1);
    PyR(i) = optimal_Rx(2);
    PzR(i) = optimal_Rx(3);
    
    % Actualizar posición anterior para próxima iteración
    Rx_previo_xy = optimal_Rx_xy;

end
tiempo_total = toc;

% Cerrar los archivos de log
fprintf(log_txt_file, '\n================================================================================\n');
fprintf(log_txt_file, 'Optimización completada en %.2f segundos\n', tiempo_total);
fprintf(log_txt_file, 'Archivo de trayectoria guardado: Receptor_traj_otimizado.csv\n');
fclose(log_txt_file);
fclose(log_csv_file);

fprintf('Logs de energías completados:\n');
fprintf('  - Formato legible: %s\n', log_txt_filename);
fprintf('  - Formato CSV: %s\n', log_csv_filename);

% Guardar también los datos en formato .mat para MATLAB
mat_filename = sprintf('log_energia_%s.mat');
save(mat_filename, 'log_data', 'tiempo_total', 'PxT', 'PyT', 'PzT', 'PxR', 'PyR', 'PzR');
fprintf('  - Formato MAT: %s\n', mat_filename);

plot3(PxR, PyR, PzR,'r--');
hold off

% Grabar trajetoria do Rx em formato csv (Receptor_traj_otimizado.csv)
Rx_trajectory = [PxR.', PyR.', PzR.'];
csvwrite('Receptor_traj_otimizado.csv', Rx_trajectory);