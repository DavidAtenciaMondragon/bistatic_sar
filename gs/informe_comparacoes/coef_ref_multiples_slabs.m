% =========================================================================
% ===                CONFIGURACIÓN DEL ESCENARIO                      ===
% =========================================================================
clear all; close all; clc;

% --- Parámetros de la simulación ---
f = 15e6; % Frecuencia = 15 GHz
theta1_deg_ejemplo = 45; % Ángulo de ejemplo para el diagrama esquemático

% --- Propiedades de los medios ---
% Medio 1: Vacío (entrada)
eps1 = 8.854e-12; mu1 = 4*pi*1e-7; eta1 = sqrt(mu1/eps1); n1 = 1;

% --- DEFINICIÓN DE N SLABS (ejemplo con 5 slabs) ---
% Puedes cambiar N_slabs y agregar/quitar slabs según necesites
N_slabs = 5; % Número de slabs intermedios

% Propiedades de cada slab [eps_r, espesor_m]
slab_props = [
    4.0, 0.5;  % Slab 1: Cuarzo
    2.1, 0.2;  % Slab 2: Teflón
    4.2, 0.3;  % Slab 3: ejemplo adicional
    1.5, 0.4;  % Slab 4: ejemplo adicional  
    2.8, 0.2;  % Slab 5: ejemplo adicional
];

% Calcular propiedades electromagnéticas para cada slab
eps_r = slab_props(:,1);
d_slab = slab_props(:,2);
eps_slab = eps_r * eps1;
mu_slab = repmat(mu1, N_slabs, 1);
eta_slab = sqrt(mu_slab ./ eps_slab);
n_slab = sqrt(eps_r);

% Medio final: Vacío (salida)  
n_final = 1; eta_final = eta1;

% =========================================================================
% ===     FIGURA 1: DIAGRAMA ESQUEMÁTICO (PROPAGACIÓN HORIZONTAL)     ===
% =========================================================================
figure(1);
subplot(121)
hold on;

% --- Dibujar las slabs verticales (genérico para N slabs) ---
z_interfaces = [0]; % Posición de las interfaces
colors = [0.8 0.8 1; 0.8 1 0.8; 1 0.8 0.8; 0.8 1 1; 1 1 0.8]; % Colores cíclicos

for j = 1:N_slabs
    z_start = z_interfaces(end);
    z_end = z_start - d_slab(j);
    z_interfaces(end+1) = z_end;
    
    color_idx = mod(j-1, size(colors,1)) + 1;
    patch([z_start z_start z_end z_end], [-2 2 2 -2], colors(color_idx,:), 'EdgeColor', 'k');
end

% --- Calcular ángulos para el rayo de ejemplo (genérico) ---
theta_ej = zeros(1, N_slabs+2);
theta_ej(1) = deg2rad(theta1_deg_ejemplo);
n_vec_ej = [n1, n_slab', n_final];

for j = 1:N_slabs+1
    theta_ej(j+1) = asin(n_vec_ej(j)/n_vec_ej(j+1) * sin(theta_ej(j)));
end

% --- Dibujar el rayo (propagación en -z, genérico para N slabs) ---
L = 0.5; % Longitud para visualización del rayo
points = zeros(N_slabs+3, 2); % [x, y] para cada punto del rayo

% Punto inicial (incidente)
points(1,:) = [L*cos(theta_ej(1)), L*sin(theta_ej(1))];

% Puntos en las interfaces y dentro de los slabs
y_cumulative = 0;
for j = 1:N_slabs+1
    z_interface = z_interfaces(j);
    points(j+1,:) = [z_interface, y_cumulative];
    
    if j <= N_slabs
        % Calcular desplazamiento y dentro del slab j
        y_cumulative = y_cumulative - d_slab(j)*tan(theta_ej(j+1));
    end
end

% Punto final (transmitido)
points(end,:) = [z_interfaces(end) - L*cos(theta_ej(end)), y_cumulative - L*sin(theta_ej(end))];

% Dibujar segmentos del rayo
for j = 1:size(points,1)-1
    plot([points(j,1) points(j+1,1)], [points(j,2) points(j+1,2)], 'r', 'LineWidth', 2);
end

% Rayo reflejado
p_ref = [L*cos(theta_ej(1)), -L*sin(theta_ej(1))];
plot([points(2,1) p_ref(1)], [points(2,2) p_ref(2)], 'b--', 'LineWidth', 1.5);

% --- Anotaciones y estilo (genérico para N slabs) ---
for j = 1:N_slabs
    z_center = (z_interfaces(j) + z_interfaces(j+1))/2;
    text(z_center, 0.009, ['slab ' num2str(j) ' (n=' num2str(n_slab(j),'%.2f') ')'], ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'Rotation', 90);
end
title('Diagrama del Escenario (TM)', 'FontSize', 10);
xlabel('Eje de Propagación z (m)');
ylabel('Eje Transversal y (m)');
axis equal;
grid on;
set(gca, 'XDir', 'reverse'); % Invierte el eje Z para que -z apunte a la izquierda
hold off;

% =========================================================================
% ===     FIGURA 2: GRÁFICO DE REFLECTIVIDAD VS ÁNGULO                ===
% ===          (Esta parte no necesita cambios)                       ===
% =========================================================================
% --- Vector de ángulos de incidencia ---
theta1_vec_deg = 0:0.01:89.9;
theta1_vec_rad = deg2rad(theta1_vec_deg);
N = length(theta1_vec_rad);

% --- Inicializar vectores de resultados ---
Gamma_TE = zeros(1, N);
Gamma_TM = zeros(1, N);

% --- Bucle para calcular la reflexión en cada ángulo ---
for i = 1:N
    th1 = theta1_vec_rad(i);
    
    % --- Calcular ángulos de refracción para todos los slabs ---
    theta_vec = zeros(1, N_slabs+2); % [th1, th_slab1, th_slab2, ..., th_final]
    theta_vec(1) = th1; % Ángulo inicial
    
    n_vec = [n1, n_slab', n_final]; % Vector de índices de refracción
    
    % Verificar TIR y calcular ángulos
    TIR_flag = false;
    for j = 1:N_slabs+1
        arg_th = n_vec(j)/n_vec(j+1) * sin(theta_vec(j));
        if abs(arg_th) > 1
            TIR_flag = true;
            break;
        end
        theta_vec(j+1) = asin(arg_th);
    end
    
    if TIR_flag
        Gamma_TE(i) = 1; 
        Gamma_TM(i) = 1; 
        continue; 
    end

    % --- Cálculo iterativo de matrices de transferencia ---
    % Inicializar matrices totales
    M_tot_TE = eye(2); % Matriz identidad 2x2
    M_tot_TM = eye(2);
    
    % --- Polarización TE ---
    Z_input_TE = eta1 / cos(theta_vec(1)); % Impedancia del medio de entrada
    
    for j = 1:N_slabs
        theta_j = theta_vec(j+1); % Ángulo en el slab j
        k_zj = (2*pi*f*n_slab(j)/3e8) * cos(theta_j);
        Z_j_TE = eta_slab(j) / cos(theta_j);
        
        M_j_TE = [cos(k_zj*d_slab(j)),  1j*Z_j_TE*sin(k_zj*d_slab(j)); 
                  1j/Z_j_TE*sin(k_zj*d_slab(j)), cos(k_zj*d_slab(j))];
        
        M_tot_TE = M_tot_TE * M_j_TE; % Multiplicación iterativa
    end
    % Calcular coeficiente de reflexión TE
    A=M_tot_TE(1,1); B=M_tot_TE(1,2); C=M_tot_TE(2,1); D=M_tot_TE(2,2);
    num = A*Z_input_TE + B - C*Z_input_TE^2 - D*Z_input_TE; 
    den = A*Z_input_TE + B + C*Z_input_TE^2 + D*Z_input_TE;
    Gamma_TE(i) = abs(num / den);

    % --- Polarización TM ---
    Z_input_TM = eta1 * cos(theta_vec(1)); % Impedancia del medio de entrada
    
    for j = 1:N_slabs
        theta_j = theta_vec(j+1); % Ángulo en el slab j
        k_zj = (2*pi*f*n_slab(j)/3e8) * cos(theta_j);
        Z_j_TM = eta_slab(j) * cos(theta_j);
        
        M_j_TM = [cos(k_zj*d_slab(j)),  1j*Z_j_TM*sin(k_zj*d_slab(j)); 
                  1j/Z_j_TM*sin(k_zj*d_slab(j)), cos(k_zj*d_slab(j))];
        
        M_tot_TM = M_tot_TM * M_j_TM; % Multiplicación iterativa
    end
    
    % Calcular coeficiente de reflexión TM
    A=M_tot_TM(1,1); B=M_tot_TM(1,2); C=M_tot_TM(2,1); D=M_tot_TM(2,2);
    num = A*Z_input_TM + B - C*Z_input_TM^2 - D*Z_input_TM; 
    den = A*Z_input_TM + B + C*Z_input_TM^2 + D*Z_input_TM;
    Gamma_TM(i) = abs(num / den);
end

% --- Generar la gráfica de resultados ---
subplot(122)
plot(theta1_vec_deg, Gamma_TE, 'LineWidth', 2); hold on;
plot(theta1_vec_deg, Gamma_TM, '--', 'LineWidth', 2);

% --- Encontrar y marcar el ángulo de Brewster ---
[min_val, min_idx] = min(Gamma_TM);
brewster_angle = theta1_vec_deg(min_idx);

% Dibujar línea vertical en el ángulo de Brewster
line([brewster_angle brewster_angle], [0 1], 'Color', 'k', 'LineStyle', ':', 'LineWidth', 2);

% Agregar texto para identificar el ángulo de Brewster
text(brewster_angle + 2, 0.8, ['\theta_B = ' num2str(brewster_angle, '%.1f') '°'], ...
     'FontSize', 10, 'Color', 'k', 'FontWeight', 'bold');

hold off;
grid on;
xlabel('Ángulo de Incidencia \theta_1 (grados)', 'FontSize', 10);
ylabel('Magnitud del Coeficiente de Reflexión | \Gamma |', 'FontSize', 10);
title('Reflectividad Total vs. Ángulo de Incidencia', 'FontSize', 10);
legend('Polarización TE', 'Polarización TM', 'Ángulo de Brewster', 'Location', 'best');
axis([0 90 0 1]);