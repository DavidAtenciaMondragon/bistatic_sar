% Script de ejemplo para probar crearPadraoRadiacao
clc; clear; close all;

% Crear patrón con especificaciones requeridas
padrao = crearPadraoRadiacao(70, 20);

% Visualizar el patrón
figure('Name', 'Patrón de Radiación', 'Position', [100, 100, 1200, 400]);

% Subplot 1: Patrón 2D
subplot(1, 3, 1);
angulos = -90:1:90;
imagesc(angulos, angulos, padrao);
colorbar;
xlabel('Azimut (°)');
ylabel('Elevación (°)');
title('Patrón 2D');
axis equal tight;

% Subplot 2: Corte en elevación (azimut = 0°)
subplot(1, 3, 2);
indice_az_0 = 91;  % Índice para azimut = 0°
plot(angulos, padrao(:, indice_az_0), 'b-', 'LineWidth', 2);
grid on;
xlabel('Elevación (°)');
ylabel('Ganancia normalizada');
title('Corte en Elevación (Az=0°)');
ylim([0, 1.1]);

% Marcar puntos -3dB
nivel_3db = 1/sqrt(2);  % -3dB = 0.707
hold on;
plot([-35, 35], [nivel_3db, nivel_3db], 'r--', 'LineWidth', 1.5);
plot([35, 35], [0, nivel_3db], 'r--', 'LineWidth', 1.5);
plot([-35, -35], [0, nivel_3db], 'r--', 'LineWidth', 1.5);
legend('Patrón', '-3dB', 'Location', 'best');

% Subplot 3: Corte en azimut (elevación = 0°)
subplot(1, 3, 3);
indice_el_0 = 91;  % Índice para elevación = 0°
plot(angulos, padrao(indice_el_0, :), 'r-', 'LineWidth', 2);
grid on;
xlabel('Azimut (°)');
ylabel('Ganancia normalizada');
title('Corte en Azimut (El=0°)');
ylim([0, 1.1]);

% Marcar puntos -3dB
hold on;
plot([-10, 10], [nivel_3db, nivel_3db], 'b--', 'LineWidth', 1.5);
plot([10, 10], [0, nivel_3db], 'b--', 'LineWidth', 1.5);
plot([-10, -10], [0, nivel_3db], 'b--', 'LineWidth', 1.5);
legend('Patrón', '-3dB', 'Location', 'best');

% Mostrar algunas verificaciones
fprintf('\nVerificaciones:\n');
fprintf('Ganancia en (0°,0°): %.3f\n', padrao(91, 91));
fprintf('Ganancia en (35°,0°): %.3f (debería ser ~0.707)\n', padrao(91+35, 91));
fprintf('Ganancia en (0°,10°): %.3f (debería ser ~0.707)\n', padrao(91, 91+10));
fprintf('Ganancia en (70°,0°): %.3f (debería ser ~0.25)\n', padrao(91+70, 91));
fprintf('Ganancia en (0°,20°): %.3f (debería ser ~0.25)\n', padrao(91, 91+20));