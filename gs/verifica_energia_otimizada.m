clc
clear 
close all 

% Add paths 
addpath(genpath('analise_energia'))
addpath(genpath(strcat('..',filesep,'tools')))

% Carregar posicoes do transmissor (Transmissor_traj.csv)
pos_Tx = readmatrix('Transmissor_traj.csv');
pos_Tx = pos_Tx(1:300:end,:);

% Carrega posicoes do receptor (Receptor_traj.csv)
pos_Rx = readmatrix('Receptor_traj.csv');
pos_Rx = pos_Rx(1:300:end,:);

% Carrega posicoes do receptor otimizado (Receptor_traj_otimizado.csv)
pos_Rx_otimizado = readmatrix('Receptor_traj_otimizado.csv');

% Carrega enviroment 
load(strcat("data",filesep,"strEnvironment.mat")); % Carregar environment

% Carrega pontos em analise 
load(strcat("data",filesep,"strVolumEmAnalise.mat")); % Carregar strVolumEmAnalise

% Carrega interface ar-solo
load(strcat("data",filesep,"strDEM.mat")); % Carregar strDEM

% Calcular energia recibida 
P_targets = [strVolumEmAnalise.X, strVolumEmAnalise.Y ,strVolumEmAnalise.Z];
all_Energy_nao_otimizada = zeros(size(pos_Rx,1),1);
all_Energy_otimizada     = zeros(size(pos_Rx,1),1);

fprintf('=== DIAGNÓSTICO DE OPTIMIZACIÓN ===\n');
fprintf('Targets para verificación: %d puntos\n', size(P_targets, 1));
fprintf('Puntos de trayectoria: %d\n', size(pos_Rx, 1));

% Verificar si hay logs disponibles para comparar targets
if exist('log_energia_*.csv', 'file')
    log_files = dir('log_energia_*.csv');
    if ~isempty(log_files)
        % Leer el log más reciente
        [~, idx] = max([log_files.datenum]);
        latest_log = log_files(idx).name;
        fprintf('Log más reciente encontrado: %s\n', latest_log);
        
        % Aquí podríamos comparar targets si es necesario
    else
        fprintf('Warning: No se encontraron logs de optimización\n');
    end
end

% Contadores para diagnóstico
casos_mejor = 0;
casos_peor = 0;
diferencias = zeros(size(pos_Rx,1),1);

for i = 1:size(pos_Rx,1)
    % Show progress in percentage
    if mod(i, round(size(pos_Rx,1)/10)) == 0
        fprintf('Progreso: %.1f%%\n', (i/size(pos_Rx,1))*100);
    end

    energia_nao_otimizada = calcular_energia_promedio(pos_Rx(i,:), pos_Tx(i,:), P_targets, strEnvironment.n1, strEnvironment.n2);
    energia_otimizada     = calcular_energia_promedio(pos_Rx_otimizado(i,:), pos_Tx(i,:), P_targets, strEnvironment.n1, strEnvironment.n2);
    
    all_Energy_nao_otimizada(i) = energia_nao_otimizada;
    all_Energy_otimizada(i)     = energia_otimizada;
    
    % Diagnóstico de cada punto
    diferencia = energia_otimizada - energia_nao_otimizada;
    diferencias(i) = diferencia;
    
    if diferencia > 0
        casos_mejor = casos_mejor + 1;
    else
        casos_peor = casos_peor + 1;
        % Mostrar casos problemáticos con más detalle
        if i <= 5 || diferencia < -1e-12 % Mostrar primeros casos y casos muy negativos
            fprintf('  Punto %d: Opt=%.6e, NoOpt=%.6e, Diff=%.2e (PEOR)\n', ...
                    i, energia_otimizada, energia_nao_otimizada, diferencia);
            
            % DIAGNÓSTICO ADICIONAL: Verificar si el optimizador está restringido
            fprintf('    Tx=[%.1f,%.1f,%.1f], Rx_orig=[%.1f,%.1f,%.1f], Rx_opt=[%.1f,%.1f,%.1f]\n', ...
                    pos_Tx(i,1), pos_Tx(i,2), pos_Tx(i,3), ...
                    pos_Rx(i,1), pos_Rx(i,2), pos_Rx(i,3), ...
                    pos_Rx_otimizado(i,1), pos_Rx_otimizado(i,2), pos_Rx_otimizado(i,3));
            
            % Calcular posición especular teórica para este punto
            Rx_especular_teorica = calcular_posicion_especular(pos_Tx(i,:), P_targets, pos_Rx_otimizado(i,3));
            dist_especular = norm(pos_Rx_otimizado(i,1:2) - Rx_especular_teorica);
            fprintf('    Distancia a pos. especular: %.2f m\n', dist_especular);
        end
    end
end

% Resumen del diagnóstico
fprintf('\n=== RESUMEN DEL DIAGNÓSTICO ===\n');
fprintf('Casos donde optimizada es MEJOR: %d (%.1f%%)\n', casos_mejor, (casos_mejor/size(pos_Rx,1))*100);
fprintf('Casos donde optimizada es PEOR: %d (%.1f%%)\n', casos_peor, (casos_peor/size(pos_Rx,1))*100);
fprintf('Mejora promedio: %.2e\n', mean(diferencias));
fprintf('Mejora mínima: %.2e\n', min(diferencias));
fprintf('Mejora máxima: %.2e\n', max(diferencias));

% Análisis de tendencia
fprintf('\n=== ANÁLISIS DE TENDENCIA ===\n');
primera_mitad = diferencias(1:round(end/2));
segunda_mitad = diferencias(round(end/2)+1:end);
fprintf('Mejora promedio primera mitad: %.2e\n', mean(primera_mitad));
fprintf('Mejora promedio segunda mitad: %.2e\n', mean(segunda_mitad));

% Correlación con índice (tendencia temporal)
indices = (1:length(diferencias))';
corr_coef = corrcoef(indices, diferencias);
fprintf('Correlación diferencias vs índice: %.4f\n', corr_coef(1,2));
if corr_coef(1,2) < -0.3
    fprintf('⚠️  ALERTA: Tendencia decreciente significativa detectada!\n');
end

%% VISUALIZACIÓN 3D COMPLETA
plot_trajectories_3d(pos_Tx, pos_Rx, pos_Rx_otimizado, strVolumEmAnalise, strDEM, strEnvironment);

%% GRÁFICO DE ENERGÍA COMPARATIVA
figure('Position', [100, 100, 1200, 800]);

% Subplot 1: Energías absolutas
subplot(2,2,1);
hold on 
plot(all_Energy_nao_otimizada,'r-o','DisplayName','Energia No Optimizada', 'LineWidth', 1.5);
plot(all_Energy_otimizada,'b-o','DisplayName','Energia Optimizada', 'LineWidth', 1.5);
xlabel('Índice de Punto');
ylabel('Energía Promedio');
title('Comparación de Energía: Optimizada vs No Optimizada');
legend('show');
grid on;
hold off;

% Subplot 2: Diferencias (Optimizada - No Optimizada)
subplot(2,2,2);
plot(diferencias, 'g-o', 'LineWidth', 1.5, 'MarkerSize', 4);
xlabel('Índice de Punto');
ylabel('Diferencia de Energía');
title('Diferencia: Energía Optimizada - No Optimizada');
grid on;
% Línea horizontal en cero para referencia
hold on;
plot(xlim, [0 0], 'k--', 'LineWidth', 1);
hold off;

% Subplot 3: Ratio de mejora
subplot(2,2,3);
ratio_mejora = all_Energy_otimizada ./ all_Energy_nao_otimizada;
plot(ratio_mejora, 'm-o', 'LineWidth', 1.5, 'MarkerSize', 4);
xlabel('Índice de Punto');
ylabel('Ratio (Optimizada/No Optimizada)');
title('Ratio de Mejora');
grid on;
% Línea horizontal en 1 para referencia
hold on;
plot(xlim, [1 1], 'k--', 'LineWidth', 1);
hold off;

% Subplot 4: Histograma de diferencias
subplot(2,2,4);
histogram(diferencias, 20, 'FaceColor', [0.7 0.7 1], 'EdgeColor', 'black');
xlabel('Diferencia de Energía');
ylabel('Frecuencia');
title('Distribución de Diferencias');
grid on;
% Línea vertical en cero
hold on;
ylims = ylim;
hold off;
