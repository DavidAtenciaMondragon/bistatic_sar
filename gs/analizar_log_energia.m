function analizar_log_energia(archivo_csv, archivo_mat)
% ANALIZAR_LOG_ENERGIA - Analiza los datos de energía de la optimización
%
% Uso:
%   analizar_log_energia('log_energia_2025-11-03_14-30-45.csv')
%   analizar_log_energia('log_energia_2025-11-03_14-30-45.csv', 'log_energia_2025-11-03_14-30-45.mat')
%
% Ejemplos de análisis que puedes hacer con los datos

if nargin < 1
    % Si no se proporciona archivo, buscar el más reciente
    archivos = dir('log_energia_*.csv');
    if isempty(archivos)
        error('No se encontraron archivos de log de energía');
    end
    [~, idx] = max([archivos.datenum]);
    archivo_csv = archivos(idx).name;
    fprintf('Usando archivo más reciente: %s\n', archivo_csv);
end

%% 1. LECTURA DE DATOS

% Método 1: Leer CSV (más universal)
fprintf('=== ANÁLISIS DE LOG DE ENERGÍA ===\n');
fprintf('Archivo: %s\n\n', archivo_csv);

% Leer CSV con readtable (más robusto que csvread)
datos = readtable(archivo_csv);

% Extraer columnas
punto = datos.punto;
Tx = [datos.Tx_x, datos.Tx_y, datos.Tx_z];
Rx = [datos.Rx_x, datos.Rx_y, datos.Rx_z];
energia = datos.energia_promedio;

% Método 2: Si existe archivo .mat (más eficiente para MATLAB)
if nargin >= 2 && exist(archivo_mat, 'file')
    fprintf('Cargando también datos desde archivo .mat...\n');
    datos_mat = load(archivo_mat);
    % datos_mat.log_data contiene la misma información en formato matriz
end

%% 2. ESTADÍSTICAS BÁSICAS

fprintf('=== ESTADÍSTICAS BÁSICAS ===\n');
fprintf('Número de puntos procesados: %d\n', length(punto));
fprintf('Energía promedio total: %.6e\n', mean(energia));
fprintf('Energía máxima: %.6e (punto %d)\n', max(energia), punto(energia == max(energia)));
fprintf('Energía mínima: %.6e (punto %d)\n', min(energia), punto(energia == min(energia)));
fprintf('Desviación estándar: %.6e\n', std(energia));
fprintf('\n');

%% 3. ANÁLISIS DE TRAYECTORIAS

fprintf('=== ANÁLISIS DE TRAYECTORIAS ===\n');

% Distancias Tx-Rx
dist_TxRx = sqrt(sum((Tx - Rx).^2, 2));
fprintf('Distancia Tx-Rx promedio: %.2f m\n', mean(dist_TxRx));
fprintf('Distancia Tx-Rx máxima: %.2f m\n', max(dist_TxRx));
fprintf('Distancia Tx-Rx mínima: %.2f m\n', min(dist_TxRx));

% Rangos de coordenadas
fprintf('\nRangos de posiciones Tx:\n');
fprintf('  X: [%.2f, %.2f] m\n', min(Tx(:,1)), max(Tx(:,1)));
fprintf('  Y: [%.2f, %.2f] m\n', min(Tx(:,2)), max(Tx(:,2)));
fprintf('  Z: [%.2f, %.2f] m\n', min(Tx(:,3)), max(Tx(:,3)));

fprintf('Rangos de posiciones Rx óptimas:\n');
fprintf('  X: [%.2f, %.2f] m\n', min(Rx(:,1)), max(Rx(:,1)));
fprintf('  Y: [%.2f, %.2f] m\n', min(Rx(:,2)), max(Rx(:,2)));
fprintf('  Z: [%.2f, %.2f] m\n', min(Rx(:,3)), max(Rx(:,3)));

%% 4. VISUALIZACIONES

figure('Name', 'Análisis de Energía - Trayectorias', 'Position', [100, 100, 1200, 800]);

% Subplot 1: Trayectorias 3D
subplot(2,3,1);
plot3(Tx(:,1), Tx(:,2), Tx(:,3), 'b.-', 'LineWidth', 2, 'MarkerSize', 8);
hold on;
plot3(Rx(:,1), Rx(:,2), Rx(:,3), 'r.-', 'LineWidth', 2, 'MarkerSize', 8);
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
title('Trayectorias Tx y Rx');
legend('Transmisor', 'Receptor', 'Location', 'best');
grid on; axis equal;

% Subplot 2: Energía vs punto
subplot(2,3,2);
plot(punto, energia, 'g.-', 'LineWidth', 2, 'MarkerSize', 6);
xlabel('Punto de trayectoria'); ylabel('Energía promedio');
title('Energía vs Punto de Trayectoria');
grid on;

% Subplot 3: Energía vs distancia Tx-Rx
subplot(2,3,3);
scatter(dist_TxRx, energia, 50, punto, 'filled');
xlabel('Distancia Tx-Rx (m)'); ylabel('Energía promedio');
title('Energía vs Distancia Tx-Rx');
colorbar; colormap(jet);
grid on;

% Subplot 4: Distribución de energías
subplot(2,3,4);
histogram(energia, 20, 'FaceColor', [0.7 0.7 1], 'EdgeColor', 'black');
xlabel('Energía promedio'); ylabel('Frecuencia');
title('Distribución de Energías');
grid on;

% Subplot 5: Posiciones Rx en el plano XY coloreadas por energía
subplot(2,3,5);
scatter(Rx(:,1), Rx(:,2), 80, energia, 'filled');
xlabel('X (m)'); ylabel('Y (m)');
title('Posiciones Rx Óptimas (color = energía)');
colorbar; colormap(jet);
axis equal; grid on;

% Subplot 6: Energía vs altura
subplot(2,3,6);
scatter(Rx(:,3), energia, 50, 'filled', 'MarkerFaceColor', [1 0.5 0]);
xlabel('Altura Rx (m)'); ylabel('Energía promedio');
title('Energía vs Altura del Receptor');
grid on;

%% 5. CORRELACIONES

fprintf('\n=== ANÁLISIS DE CORRELACIONES ===\n');

% Correlación energía vs distancia
corr_dist = corrcoef(dist_TxRx, energia);
fprintf('Correlación energía vs distancia Tx-Rx: %.4f\n', corr_dist(1,2));

% Correlación energía vs altura
corr_altura = corrcoef(Rx(:,3), energia);
fprintf('Correlación energía vs altura Rx: %.4f\n', corr_altura(1,2));

%% 6. EXPORTAR RESULTADOS RESUMIDOS

resumen_filename = strrep(archivo_csv, '.csv', '_resumen.txt');
fid = fopen(resumen_filename, 'w');
fprintf(fid, 'RESUMEN DE ANÁLISIS DE ENERGÍA\n');
fprintf(fid, 'Archivo: %s\n', archivo_csv);
fprintf(fid, 'Fecha: %s\n\n', datestr(now));
fprintf(fid, 'Puntos procesados: %d\n', length(punto));
fprintf(fid, 'Energía promedio: %.6e\n', mean(energia));
fprintf(fid, 'Energía máxima: %.6e\n', max(energia));
fprintf(fid, 'Energía mínima: %.6e\n', min(energia));
fprintf(fid, 'Desviación estándar: %.6e\n', std(energia));
fprintf(fid, 'Distancia Tx-Rx promedio: %.2f m\n', mean(dist_TxRx));
fprintf(fid, 'Correlación energía vs distancia: %.4f\n', corr_dist(1,2));
fprintf(fid, 'Correlación energía vs altura: %.4f\n', corr_altura(1,2));
fclose(fid);

fprintf('\nResumen guardado en: %s\n', resumen_filename);
fprintf('Análisis completado.\n');

end

%% FUNCIONES DE EJEMPLO PARA ANÁLISIS ADICIONALES

function encontrar_mejores_puntos(archivo_csv, n_mejores)
% Encuentra los N puntos con mayor energía
if nargin < 2, n_mejores = 5; end

datos = readtable(archivo_csv);
[~, idx] = sort(datos.energia_promedio, 'descend');

fprintf('=== %d MEJORES PUNTOS (mayor energía) ===\n', n_mejores);
for i = 1:min(n_mejores, height(datos))
    j = idx(i);
    fprintf('Punto %d: Energía=%.6e, Tx=[%.1f,%.1f,%.1f], Rx=[%.1f,%.1f,%.1f]\n', ...
        datos.punto(j), datos.energia_promedio(j), ...
        datos.Tx_x(j), datos.Tx_y(j), datos.Tx_z(j), ...
        datos.Rx_x(j), datos.Rx_y(j), datos.Rx_z(j));
end
end

function comparar_logs(archivo1, archivo2)
% Compara dos logs de energía (útil para validar optimizaciones)
fprintf('=== COMPARACIÓN DE LOGS ===\n');

datos1 = readtable(archivo1);
datos2 = readtable(archivo2);

if height(datos1) ~= height(datos2)
    warning('Los archivos tienen diferente número de puntos');
    return;
end

diff_energia = datos2.energia_promedio - datos1.energia_promedio;
diff_relativa = diff_energia ./ datos1.energia_promedio * 100;

fprintf('Archivo 1: %s\n', archivo1);
fprintf('Archivo 2: %s\n', archivo2);
fprintf('Diferencia promedio en energía: %.6e (%.2f%%)\n', mean(diff_energia), mean(diff_relativa));
fprintf('Diferencia máxima: %.6e (%.2f%%)\n', max(abs(diff_energia)), max(abs(diff_relativa)));

figure;
plot(datos1.punto, diff_relativa, 'b.-');
xlabel('Punto'); ylabel('Diferencia relativa (%)');
title('Diferencia de Energía entre Logs');
grid on;
end