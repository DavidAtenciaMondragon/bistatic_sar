clc  
clear 
close all

%% 

Tx = [10,8,14];
Re = [0,0,0];

% Vector unitario que apunta HACIA el punto R (desde Tx hacia Re)
u1  = Re - Tx;
u1  = u1/norm(u1);

fprintf('========================================================\n');
fprintf('DEFINICIÓN DE VECTOR DESDE DOS PUNTOS:\n');
fprintf('========================================================\n');
fprintf('Transmisor Tx: [%.1f, %.1f, %.1f]\n', Tx);
fprintf('Receptor Re: [%.1f, %.1f, %.1f]\n', Re);
fprintf('Vector u1 (Tx → Re): [%.4f, %.4f, %.4f]\n\n', u1);

azimut    = atan2d(u1(2),u1(1));
elevacion = asind(u1(3));

fprintf('Vector unitario método 1 (esférico):\n');
fprintf('  Azimut: %.1f°, Elevación: %.1f°\n', azimut, elevacion);
fprintf('  u1 = [%.4f, %.4f, %.4f]\n', u1);
fprintf('  |u1| = %.6f\n\n', norm(u1));

%% MÉTODO 4: Vectores unitarios canónicos
% Vectores unitarios básicos en direcciones de ejes

ux = [1, 0, 0];  % Eje X
uy = [0, 1, 0];  % Eje Y  
uz = [0, 0, 1];  % Eje Z

fprintf('Vectores unitarios canónicos:\n');
fprintf('  ux = [%.1f, %.1f, %.1f]\n', ux);
fprintf('  uy = [%.1f, %.1f, %.1f]\n', uy);
fprintf('  uz = [%.1f, %.1f, %.1f]\n\n', uz);

% ========================================================================
% VISUALIZACIÓN DE VECTORES UNITARIOS
% ========================================================================

figure('Name', 'Vectores Unitarios', 'Position', [100, 100, 900, 700]);

% Punto origen para todos los vectores
origen = [0, 0, 0];

% Colores para cada vector (usando nombres válidos)
colores = {'red', 'magenta', 'cyan', 'black'};
etiquetas = {'u1 (esférico)', 'ux', 'uy', 'uz'};
vectores = {u1};

hold on;

% Dibujar cada vector
for i = 1:length(vectores)
    u1 = vectores{i};
    
    % Dibujar vector usando quiver3
    quiver3(origen(1), origen(2), origen(3), u1(1), u1(2), u1(3), ...
            1, 'Color', colores{i}, 'LineWidth', 3, 'MaxHeadSize', 0.2);
    
    % Añadir etiqueta en el extremo del vector
    text(u1(1)*1.1, u1(2)*1.1, u1(3)*1.1, etiquetas{i}, ...
         'FontSize', 10, 'Color', colores{i}, 'FontWeight', 'bold');
end

% Dibujar ejes de referencia (más delgados)
axis_length = 1.2;
quiver3(0, 0, 0, axis_length, 0, 0, 1, 'Color', 'black', 'LineStyle', '--', 'LineWidth', 1, 'MaxHeadSize', 0.1);
quiver3(0, 0, 0, 0, axis_length, 0, 1, 'Color', 'black', 'LineStyle', '--', 'LineWidth', 1, 'MaxHeadSize', 0.1);
quiver3(0, 0, 0, 0, 0, axis_length, 1, 'Color', 'black', 'LineStyle', '--', 'LineWidth', 1, 'MaxHeadSize', 0.1);

% Agregar plano Z = 0 para visualizar la superficie
[x_surf, y_surf] = meshgrid(-1.5:0.3:1.5, -1.5:0.3:1.5);
z_surf = zeros(size(x_surf));
surf(x_surf, y_surf, z_surf, 'FaceAlpha', 0.2, 'EdgeAlpha', 0.3, ...
     'FaceColor', 'yellow', 'EdgeColor', 'black');

% Marcar los puntos Tx y Re
plot3(Tx(1), Tx(2), Tx(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
plot3(Re(1), Re(2), Re(3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'green');
text(Tx(1)+0.1, Tx(2)+0.1, Tx(3)+0.1, 'Tx', 'FontSize', 10, 'Color', 'red', 'FontWeight', 'bold');
text(Re(1)+0.1, Re(2)+0.1, Re(3)+0.1, 'Re', 'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');

% Dibujar línea de conexión Tx-Re
plot3([Tx(1), Re(1)], [Tx(2), Re(2)], [Tx(3), Re(3)], 'k--', 'LineWidth', 2);

% Etiquetas de ejes
text(axis_length*1.05, 0, 0, 'X', 'FontSize', 12, 'Color', 'black');
text(0, axis_length*1.05, 0, 'Y', 'FontSize', 12, 'Color', 'black');
text(0, 0, axis_length*1.05, 'Z', 'FontSize', 12, 'Color', 'black');

% Configuración del gráfico
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Vector Unitario Tx → Re y Superficie Z=0');
grid on; axis equal;
view(45, 30);
legend({'u1 (Tx→Re)', 'Superficie Z=0', 'Tx', 'Re', 'Conexión Tx-Re'}, 'Location', 'best');

% Establecer límites
axis([-1.5, 1.5, -1.5, 1.5, -1.5, 1.5]);

hold off;

% ========================================================================
% CREAR SISTEMA DE COORDENADAS ROTADO SEGÚN VECTOR UNITARIO
% ========================================================================

%% Definir sistema de coordenadas rotado
% El vector u1 define la dirección principal
% Creamos un plano perpendicular a u1 con su propio sistema de coordenadas

fprintf('========================================================\n');
fprintf('SISTEMA DE COORDENADAS ROTADO:\n');
fprintf('========================================================\n');

% Vector unitario original
vector_principal = u1;
fprintf('Vector principal: u1 = [%.4f, %.4f, %.4f]\n', vector_principal);
fprintf('Azimut original: %.1f°, Elevación: %.1f°\n\n', azimut, elevacion);

%% Crear base ortonormal para el nuevo sistema de coordenadas
% e1: dirección del vector principal (u1)
% e2: dirección perpendicular en el plano (tangente al azimut)
% e3: dirección Z (perfectamente alineada con eje Z)

e1 = vector_principal;  % Dirección principal

% e3: perfectamente alineado con Z
e3 = [0, 0, 1];  % Vector unitario en dirección Z

% e2: perpendicular a e1 y e3 (tangente al azimut)
% Usamos producto cruz: e2 = e3 × e1
e2 = cross(e3, e1);
e2 = e2 / norm(e2);  % Normalizar

% Verificar que e1, e2, e3 forman una base ortonormal derecha
% Si el producto cruz da vector cero, significa que e1 es paralelo a Z
if norm(e2) < 1e-10
    % Caso especial: e1 es paralelo a Z
    % Elegir e2 arbitrario perpendicular a Z (por ejemplo, en dirección X)
    e2 = [1, 0, 0];
    % Asegurar que e2 sea perpendicular a e1
    e2 = e2 - dot(e2, e1) * e1;
    e2 = e2 / norm(e2);
end

fprintf('Base ortonormal del nuevo sistema:\n');
fprintf('  e1 (principal): [%.4f, %.4f, %.4f]\n', e1);
fprintf('  e2 (tangencial): [%.4f, %.4f, %.4f]\n', e2);
fprintf('  e3 (Z alineado): [%.4f, %.4f, %.4f] = [0, 0, 1]\n\n', e3);

% Verificar ortogonalidad
dot_e1_e2 = dot(e1, e2);
dot_e1_e3 = dot(e1, e3);
dot_e2_e3 = dot(e2, e3);

fprintf('Verificación de ortogonalidad:\n');
fprintf('  e1·e2 = %.6f (debe ser ≈ 0)\n', dot_e1_e2);
fprintf('  e1·e3 = %.6f (debe ser ≈ 0)\n', dot_e1_e3);
fprintf('  e2·e3 = %.6f (debe ser ≈ 0)\n\n', dot_e2_e3);

%% Crear matriz de transformación del sistema rotado
% Matriz de rotación: las columnas son los vectores de la nueva base
R = [e1', e2', e3'];  % Transpuesta porque queremos e1,e2,e3 como columnas

fprintf('Matriz de rotación R:\n');
fprintf('  [%.4f  %.4f  %.4f]\n', R(1,:));
fprintf('  [%.4f  %.4f  %.4f]\n', R(2,:));
fprintf('  [%.4f  %.4f  %.4f]\n\n', R(3,:));

%% Definir el plano en el nuevo sistema de coordenadas
% El plano está definido por las direcciones e2 y e3
% (perpendicular a e1, que es la dirección principal)

% Crear malla del plano en el sistema rotado
rango_plano = linspace(-1.2, 1.2, 15);
[u_plano, v_plano] = meshgrid(rango_plano, rango_plano);

% Puntos del plano en el sistema rotado: solo componentes e2 y e3
% (la componente e1 es cero porque el plano es perpendicular a e1)
puntos_plano_rotado = zeros(numel(u_plano), 3);
for i = 1:numel(u_plano)
    % Coordenadas en el sistema rotado: [0, u_plano(i), v_plano(i)]
    coord_rotado = [0, u_plano(i), v_plano(i)];
    % Transformar de vuelta al sistema original
    puntos_plano_rotado(i, :) = R * coord_rotado';
end

% Reorganizar para surf()
x_plano_rot = reshape(puntos_plano_rotado(:,1), size(u_plano));
y_plano_rot = reshape(puntos_plano_rotado(:,2), size(u_plano));
z_plano_rot = reshape(puntos_plano_rotado(:,3), size(u_plano));

%% Crear nueva figura para mostrar el sistema de coordenadas rotado
figure('Name', 'Sistema de Coordenadas Rotado', 'Position', [1050, 100, 900, 700]);
hold on;

% Dibujar el plano rotado (perpendicular al vector principal)
surf(x_plano_rot, y_plano_rot, z_plano_rot, 'FaceAlpha', 0.4, 'EdgeAlpha', 0.2, ...
     'FaceColor', 'cyan', 'EdgeColor', 'blue');

% Agregar plano Z = 0 para referencia
[x_z0, y_z0] = meshgrid(-1.5:0.3:1.5, -1.5:0.3:1.5);
z_z0 = zeros(size(x_z0));
surf(x_z0, y_z0, z_z0, 'FaceAlpha', 0.2, 'EdgeAlpha', 0.3, ...
     'FaceColor', 'yellow', 'EdgeColor', 'black');

% Marcar puntos Tx y Re en el sistema rotado también
plot3(Tx(1), Tx(2), Tx(3), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
plot3(Re(1), Re(2), Re(3), 'go', 'MarkerSize', 8, 'MarkerFaceColor', 'green');
text(Tx(1)+0.1, Tx(2)+0.1, Tx(3)+0.1, 'Tx', 'FontSize', 8, 'Color', 'red');
text(Re(1)+0.1, Re(2)+0.1, Re(3)+0.1, 'Re', 'FontSize', 8, 'Color', 'green');

% Línea Tx-Re
plot3([Tx(1), Re(1)], [Tx(2), Re(2)], [Tx(3), Re(3)], 'k--', 'LineWidth', 1);

% Dibujar la nueva base ortonormal
escala_base = 1.0;

% e1 - dirección principal (rojo, más grueso)
quiver3(0, 0, 0, e1(1)*escala_base, e1(2)*escala_base, e1(3)*escala_base, 1, ...
        'Color', 'red', 'LineWidth', 4, 'MaxHeadSize', 0.15);
text(e1(1)*escala_base*1.1, e1(2)*escala_base*1.1, e1(3)*escala_base*1.1, ...
     'e1 (principal)', 'FontSize', 12, 'Color', 'red', 'FontWeight', 'bold');

% e2 - dirección tangencial (verde)
quiver3(0, 0, 0, e2(1)*escala_base, e2(2)*escala_base, e2(3)*escala_base, 1, ...
        'Color', 'green', 'LineWidth', 3, 'MaxHeadSize', 0.15);
text(e2(1)*escala_base*1.1, e2(2)*escala_base*1.1, e2(3)*escala_base*1.1, ...
     'e2 (tangencial)', 'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');

% e3 - dirección Z (magenta)
quiver3(0, 0, 0, e3(1)*escala_base, e3(2)*escala_base, e3(3)*escala_base, 1, ...
        'Color', 'magenta', 'LineWidth', 3, 'MaxHeadSize', 0.15);
text(e3(1)*escala_base*1.1, e3(2)*escala_base*1.1, e3(3)*escala_base*1.1, ...
     'e3 (Z)', 'FontSize', 10, 'Color', 'magenta', 'FontWeight', 'bold');

% Dibujar ejes originales (más tenues)
axis_length = 1.3;
quiver3(0, 0, 0, axis_length, 0, 0, 1, 'Color', 'black', 'LineStyle', ':', 'LineWidth', 1, 'MaxHeadSize', 0.05);
quiver3(0, 0, 0, 0, axis_length, 0, 1, 'Color', 'black', 'LineStyle', ':', 'LineWidth', 1, 'MaxHeadSize', 0.05);
quiver3(0, 0, 0, 0, 0, axis_length, 1, 'Color', 'black', 'LineStyle', ':', 'LineWidth', 1, 'MaxHeadSize', 0.05);

% Etiquetas de ejes originales
text(axis_length*1.05, 0, 0, 'X', 'FontSize', 8, 'Color', 'black');
text(0, axis_length*1.05, 0, 'Y', 'FontSize', 8, 'Color', 'black');
text(0, 0, axis_length*1.05, 'Z', 'FontSize', 8, 'Color', 'black');

% Configuración del gráfico
xlabel('X (original)'); ylabel('Y (original)'); zlabel('Z (original)');
title(sprintf('Sistema Rotado - Vector Principal: Az=%.1f°, El=%.1f°', azimut, elevacion));
grid on; axis equal;
view(45, 30);
legend({'Plano rotado', 'Superficie Z=0', 'Tx', 'Re', 'Conexión', 'e1 (principal)', 'e2 (tangencial)', 'e3 (Z)'}, ...
       'Location', 'best');
axis([-1.5, 1.5, -1.5, 1.5, -1.5, 1.5]);

hold off;

%% Mostrar cómo el vector principal se descompone en el sistema rotado
coord_principal_rotado = R' * vector_principal';

fprintf('========================================================\n');
fprintf('DESCOMPOSICIÓN DEL VECTOR PRINCIPAL EN SISTEMA ROTADO:\n');
fprintf('========================================================\n');
fprintf('Vector principal u1 en coordenadas originales: [%.4f, %.4f, %.4f]\n', vector_principal);
fprintf('Vector principal u1 en coordenadas rotadas: [%.4f, %.4f, %.4f]\n', coord_principal_rotado);
fprintf('Como era de esperarse:\n');
fprintf('  - Componente e1: %.6f ≈ 1 (dirección principal)\n', coord_principal_rotado(1));
fprintf('  - Componente e2: %.6f ≈ 0 (perpendicular)\n', coord_principal_rotado(2));
fprintf('  - Componente e3: %.6f ≈ 0 (perpendicular)\n\n', coord_principal_rotado(3));

%% Posiciones aleatorias 3D
% Generar posiciones tridimensionales aleatorias con distribución uniforme

n_puntos = 100;
rng(42);  % Reproducibilidad

% Rangos
x_range = [-10, 10];
y_range = [-10, 10]; 
z_range = [-5, 15];

% Generar puntos aleatorios
puntos = [x_range(1) + diff(x_range) * rand(n_puntos, 1), ...
          y_range(1) + diff(y_range) * rand(n_puntos, 1), ...
          z_range(1) + diff(z_range) * rand(n_puntos, 1)];

fprintf('Generados %d puntos aleatorios\n', n_puntos);

%% Filtrar puntos según región de reflexión posible
% Para reflexión especular en Z=0:
% 1. Receptor debe estar en Z > 0 (mismo lado que Tx)
% 2. Desde la perspectiva de Tx, filtrar lo que está "delante" del plano e2-e3
%    y mantener lo que está "detrás" (región de reflexión válida)

% Filtro 1: Z > 0 (superficie)
filtro_superficie = puntos(:,3) > 0;

% Filtro 2: Región "detrás" del plano tangencial desde perspectiva de Tx
% Transformar todos los puntos al sistema rotado
puntos_rotados = (R' * (puntos - Re)')';  % Transponer para operación matricial

% Tx en sistema rotado
Tx_rotado = R' * (Tx - Re)';
fprintf('Tx en sistema rotado: [%.4f, %.4f, %.4f]\n', Tx_rotado);

% El plano tangencial está en e1 = 0 (pasa por Re)
% Desde la perspectiva de Tx:
% - Tx está en e1 < 0 (lado negativo del plano)
% - "Delante" del plano: mismo lado que Tx (e1 < 0) -> FILTRAR
% - "Detrás" del plano: lado opuesto a Tx (e1 > 0) -> MANTENER
filtro_tangencial = puntos_rotados(:,1) > 0;

% Combinar ambos filtros
indices_validos = filtro_superficie & filtro_tangencial;

fprintf('Filtros aplicados:\n');
fprintf('  - Superficie (Z>0): %d/%d puntos\n', sum(filtro_superficie), n_puntos);
fprintf('  - Detrás del plano (e1 > 0): %d/%d puntos\n', sum(filtro_tangencial), n_puntos);
fprintf('  - Ambos filtros: %d/%d puntos válidos\n', sum(indices_validos), n_puntos);

% Categorizar puntos para visualización
puntos_validos = puntos(indices_validos, :);
puntos_solo_superficie = puntos(filtro_superficie & ~filtro_tangencial, :);
puntos_solo_tangencial = puntos(~filtro_superficie & filtro_tangencial, :);
puntos_ninguno = puntos(~filtro_superficie & ~filtro_tangencial, :);

% Visualización
figure('Name', 'Filtrado por Ambos Planos', 'Position', [200, 200, 1000, 800]);
hold on;

% Puntos válidos (verdes, grandes)
if ~isempty(puntos_validos)
    scatter3(puntos_validos(:,1), puntos_validos(:,2), puntos_validos(:,3), ...
             40, 'green', 'filled');
end

% Puntos que cumplen solo filtro de superficie (azules)
if ~isempty(puntos_solo_superficie)
    scatter3(puntos_solo_superficie(:,1), puntos_solo_superficie(:,2), puntos_solo_superficie(:,3), ...
             25, 'blue', 'o');
end

% Puntos que cumplen solo filtro tangencial (amarillos)
if ~isempty(puntos_solo_tangencial)
    scatter3(puntos_solo_tangencial(:,1), puntos_solo_tangencial(:,2), puntos_solo_tangencial(:,3), ...
             25, 'yellow', 's');
end

% Puntos que no cumplen ningún filtro (rojos, pequeños)
if ~isempty(puntos_ninguno)
    scatter3(puntos_ninguno(:,1), puntos_ninguno(:,2), puntos_ninguno(:,3), ...
             15, 'red', 'x');
end

% Plano de reflexión Z=0
[x_plane, y_plane] = meshgrid(-12:2:12, -12:2:12);
z_plane = zeros(size(x_plane));
surf(x_plane, y_plane, z_plane, 'FaceAlpha', 0.2, 'FaceColor', 'yellow', ...
     'EdgeColor', 'black', 'LineWidth', 1);

% Dibujar el plano rotado (el que definimos previamente - formado por e2 y e3)
surf(x_plano_rot, y_plano_rot, z_plano_rot, 'FaceAlpha', 0.3, 'FaceColor', 'cyan', ...
     'EdgeColor', 'blue', 'LineWidth', 1);

% Puntos especiales
plot3(Tx(1), Tx(2), Tx(3), 'ro', 'MarkerSize', 15, 'MarkerFaceColor', 'red', 'LineWidth', 2);
plot3(Re(1), Re(2), Re(3), 'ko', 'MarkerSize', 15, 'MarkerFaceColor', 'black', 'LineWidth', 2);
text(Tx(1)+0.5, Tx(2)+0.5, Tx(3)+0.5, 'Tx', 'FontSize', 12, 'Color', 'red', 'FontWeight', 'bold');
text(Re(1)+0.5, Re(2)+0.5, Re(3)+0.5, 'Re', 'FontSize', 12, 'Color', 'black', 'FontWeight', 'bold');

xlabel('X'); ylabel('Y'); zlabel('Z');
title(sprintf('Filtrado Completo: %d válidos de %d total', sum(indices_validos), n_puntos));
legend({'Válidos (ambos filtros)', 'Solo superficie (Z>0)', 'Solo detrás del plano', 'Ningún filtro', ...
        'Plano superficie (Z=0)', 'Plano tangencial (e2,e3)', 'Tx', 'Re'}, 'Location', 'best');
grid on; view(45, 30);
hold off;



% ========================================================================
% FUNCIONES AUXILIARES
% ========================================================================
% ========================================================================
% FUNCIONES AUXILIARES PARA TRANSFORMACIÓN DE COORDENADAS
% ========================================================================

%% Función para transformar cualquier vector al sistema rotado
function coord_rotado = transformar_a_sistema_rotado(vector, matriz_R)
    % Transforma un vector del sistema original al sistema rotado
    coord_rotado = matriz_R' * vector';
end

%% Función para transformar del sistema rotado al original  
function vector_original = transformar_a_sistema_original(coord_rotado, matriz_R)
    % Transforma coordenadas del sistema rotado al sistema original
    vector_original = matriz_R * coord_rotado';
end 
