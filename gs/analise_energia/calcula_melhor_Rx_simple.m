% =========================================================================
% SCRIPT PRINCIPAL: Encontrar la Posición Óptima del Receptor
% =========================================================================
clear; clc; close all;

%% 1. DEFINICIÓN DE PARÁMETROS Y CONSTANTES

% Propiedades de los medios
epsilon_r_suelo = 4; % Permitividad relativa del suelo (ej: arena seca)
n1 = 1.0;            % Índice de refracción del aire
n2 = sqrt(epsilon_r_suelo); % Índice de refracción del suelo

% Coordenadas del Transmisor (Tx)
Tx = [0, 50, 10]; % [x, y, z] en metros

% Coordenadas de los 5 Objetivos Subterráneos (P_i)
% Cada fila es un punto [x, y, z]
P_targets = [
    25, 10, -5;
    30, -15, -8;
    10, 5, -12;
    -5, -20, -6;
    -10, 15, -10
];

% Altura fija para el receptor Rx (z > 0)
Rx_z = 10; 

%% 2. OPTIMIZACIÓN NUMÉRICA

% conjetura inicial para la posición (x, y) del receptor.
% Una buena conjetura es el centroide de los objetivos.
Rx_inicial_xy = [mean(P_targets(:,1)), mean(P_targets(:,2))];

% La función a optimizar. Pasamos los parámetros fijos (Tx, P_targets, etc.)
% usando una función anónima.
% fminsearch MINIMIZA, por lo que minimizamos la energía NEGATIVA para maximizarla.
objective_function = @(rx_xy) -calcular_energia_promedio(rx_xy, Rx_z, Tx, P_targets, n1, n2);

% Opciones del optimizador para ver el proceso
% options = optimset('Display','iter');

% Llamada al optimizador
fprintf('Iniciando optimización para encontrar la posición de Rx...\n');
[optimal_Rx_xy, max_energia_neg] = fminsearch(objective_function, Rx_inicial_xy);

% Reconstruir la posición 3D óptima del receptor
optimal_Rx = [optimal_Rx_xy, Rx_z];
max_energia_promedio = -max_energia_neg;

%% 3. MOSTRAR RESULTADOS

fprintf('\n================== RESULTADOS ==================\n');
fprintf('Posición Óptima del Receptor (Rx):\n');
fprintf('  Rx_x: %.2f metros\n', optimal_Rx(1));
fprintf('  Rx_y: %.2f metros\n', optimal_Rx(2));
fprintf('  Rx_z: %.2f metros\n', optimal_Rx(3));
fprintf('Valor de Energía Promedio Máxima (relativo): %.4e\n', max_energia_promedio);
fprintf('================================================\n');

%% 4. VISUALIZACIÓN GRÁFICA

figure;
hold on; grid on; axis equal;
title('Escenario del Radar y Posición Óptima');
xlabel('X (m)'); ylabel('Y (m)'); zlabel('Z (m)');
view(3); % Vista 3D

% Dibujar el plano del suelo
[X, Y] = meshgrid(min([-20; P_targets(:,1); Tx(1)])-10:5:max([60; P_targets(:,1); Tx(1)])+10, ...
                  min([-30; P_targets(:,2); Tx(2)])-10:5:max([60; P_targets(:,2); Tx(2)])+10);
Z = zeros(size(X));
surf(X, Y, Z, 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'FaceColor', [0.8 0.7 0.6]);

% Plotear puntos
plot3(Tx(1), Tx(2), Tx(3), 'b^', 'MarkerSize', 12, 'MarkerFaceColor', 'b');
plot3(P_targets(:,1), P_targets(:,2), P_targets(:,3), 'ko', 'MarkerSize', 8, 'MarkerFaceColor', 'k');
plot3(optimal_Rx(1), optimal_Rx(2), optimal_Rx(3), 'rV', 'MarkerSize', 12, 'MarkerFaceColor', 'r');

legend('Transmisor (Tx)', 'Objetivos (P_i)', 'Receptor Óptimo (Rx)', 'Suelo (z=0)', 'Location', 'best');

% Dibujar los rayos para la solución óptima
for i = 1:size(P_targets, 1)
    Pi = P_targets(i, :);
    % Calcular puntos de refracción para la solución final
    Gt = encontrar_punto_interfaz(Tx, Pi, n1, n2);
    Gr = encontrar_punto_interfaz(Pi, optimal_Rx, n2, n1);

    % Dibujar rayos - no deben tener legendas
    plot3([Tx(1), Gt(1)], [Tx(2), Gt(2)], [Tx(3), Gt(3)], 'b--', 'HandleVisibility', 'off');
    plot3([Gt(1), Pi(1)], [Gt(2), Pi(2)], [Gt(3), Pi(3)], 'b-', 'HandleVisibility', 'off');
    plot3([Pi(1), Gr(1)], [Pi(2), Gr(2)], [Pi(3), Gr(3)], 'r-', 'HandleVisibility', 'off');
    plot3([Gr(1), optimal_Rx(1)], [Gr(2), optimal_Rx(2)], [Gr(3), optimal_Rx(3)], 'r--', 'HandleVisibility', 'off');
end

hold off;

% =========================================================================
%% 5. ANÁLISIS DEL ÁNGULO DE BREWSTER
% =========================================================================

fprintf('\n========= ANÁLISIS DEL ÁNGULO DE BREWSTER =========\n');

% 1. Calcular el Ángulo de Brewster teórico para la interfaz SUELO -> AIRE
% La onda viaja del medio n2 (suelo) al medio n1 (aire)
brewster_angle_rad = atan(n1 / n2);
brewster_angle_deg = rad2deg(brewster_angle_rad);

fprintf('Ángulo de Brewster teórico (Suelo->Aire): %.2f grados\n', brewster_angle_deg);
fprintf('----------------------------------------------------\n');
fprintf('Ángulos de incidencia reales en la solución óptima:\n');

% Pre-alocar un vector para guardar los ángulos
angulos_reales_deg = zeros(size(P_targets, 1), 1);

normal = [0, 0, 1]; % Normal a la superficie apuntando hacia arriba

for i = 1:size(P_targets, 1)
    Pi = P_targets(i, :);
    
    % 2. Encontrar el punto de refracción Gr para el trayecto de vuelta óptimo
    Gr = encontrar_punto_interfaz(Pi, optimal_Rx, n2, n1);
    
    % 3. Calcular el ángulo de incidencia real desde abajo
    % Vector desde el objetivo Pi hasta el punto de refracción Gr
    v_incidente_vuelta = Gr - Pi;
    
    % El ángulo de incidencia es el ángulo entre el vector incidente y la normal
    theta_r_inc_rad = acos(dot(v_incidente_vuelta, normal) / norm(v_incidente_vuelta));
    angulos_reales_deg(i) = rad2deg(theta_r_inc_rad);
    
    fprintf('  Objetivo %d -> Rx: Ángulo de incidencia = %.2f grados\n', i, angulos_reales_deg(i));
end

% Calcular el promedio de los ángulos
angulo_promedio_real = mean(angulos_reales_deg);
fprintf('----------------------------------------------------\n');
fprintf('Ángulo promedio real: %.2f grados\n', angulo_promedio_real);
fprintf('Diferencia con Brewster: %.2f grados\n', abs(angulo_promedio_real - brewster_angle_deg));
fprintf('====================================================\n');