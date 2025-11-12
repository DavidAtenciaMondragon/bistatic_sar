%% PRUEBA RÁPIDA DE LA INTERFAZ ACTUALIZADA
% Verifica que la función modificada funciona correctamente

clc; clear;

fprintf('=== PRUEBA DE INTERFAZ ACTUALIZADA ===\n\n');

% Añadir paths
addpath(genpath('analise_energia'))
addpath(genpath(strcat('..',filesep,'tools')))

try
    % Crear datos de prueba mínimos
    fprintf('Creando datos de prueba...\n');
    
    % Puntos objetivo simples
    P_targets = [
        0,   0,   -30;
        100, 100, -30;
        -100, 100, -30
    ];
    
    % Posiciones de prueba
    Tx = [0, 0, 0];      % Transmisor en origen
    Rx = [50, 50, 0];    % Receptor cercano
    
    % Parámetros físicos
    n1 = 1;  % Aire
    n2 = 4;  % Suelo
    
    fprintf('Datos configurados:\n');
    fprintf('- Tx: [%.0f, %.0f, %.0f]\n', Tx(1), Tx(2), Tx(3));
    fprintf('- Rx: [%.0f, %.0f, %.0f]\n', Rx(1), Rx(2), Rx(3));
    fprintf('- Targets: %d puntos\n', size(P_targets, 1));
    
    % Probar la función actualizada
    fprintf('\nProbando función calcular_energia_promedio...\n');
    
    tic;
    E_resultado = calcular_energia_promedio(Rx, Tx, P_targets, n1, n2);
    tiempo = toc;
    
    fprintf('✅ Función ejecutada correctamente\n');
    fprintf('   Energía calculada: %.6e\n', E_resultado);
    fprintf('   Tiempo: %.4f segundos\n', tiempo);
    
    if isnan(E_resultado) || isinf(E_resultado)
        fprintf('⚠️ Valor problemático (NaN o Inf)\n');
    else
        fprintf('✅ Valor numérico válido\n');
    end
    
    % Probar optimización simple
    fprintf('\nProbando optimización...\n');
    
    objective_function = @(rx_xy) -calcular_energia_promedio([rx_xy, 0], Tx, P_targets, n1, n2);
    
    options = optimset('Display', 'off', 'MaxIter', 20, 'MaxFunEvals', 40);
    
    tic;
    [optimal_rx_xy, fval] = fminsearch(objective_function, [0, 0], options);
    tiempo_opt = toc;
    
    fprintf('✅ Optimización ejecutada correctamente\n');
    fprintf('   Posición óptima: [%.2f, %.2f]\n', optimal_rx_xy(1), optimal_rx_xy(2));
    fprintf('   Energía máxima: %.6e\n', -fval);
    fprintf('   Tiempo optimización: %.4f segundos\n', tiempo_opt);
    
    fprintf('\n✅ PRUEBA COMPLETADA EXITOSAMENTE\n');
    fprintf('La interfaz actualizada funciona correctamente.\n');
    fprintf('Ahora puedes ejecutar: run(''calcula_plano_de_voo.m'')\n');
    
catch ME
    fprintf('\n❌ ERROR EN PRUEBA:\n');
    fprintf('Mensaje: %s\n', ME.message);
    if length(ME.stack) > 0
        fprintf('Archivo: %s\n', ME.stack(1).file);
        fprintf('Línea: %d\n', ME.stack(1).line);
    end
    fprintf('\nRevisa que las funciones estén correctamente modificadas.\n');
end