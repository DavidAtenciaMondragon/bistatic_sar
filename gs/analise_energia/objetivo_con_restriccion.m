function valor_objetivo = objetivo_con_restriccion(rx_xy, Rx_z, Tx, P_targets, n1, n2, Rx_especular_xy, radio_busqueda)
    % OBJETIVO_CON_RESTRICCION - Función objetivo con restricción geométrica
    %
    % Implementa restricción suave para mantener el receptor cerca de la
    % posición especular geométricamente correcta
    %
    % Inputs:
    %   rx_xy - Posición XY del receptor a evaluar
    %   Rx_z - Altura fija del receptor
    %   Tx - Posición del transmisor
    %   P_targets - Puntos objetivo
    %   n1, n2 - Índices de refracción
    %   Rx_especular_xy - Posición especular ideal
    %   radio_busqueda - Radio de búsqueda permitido
    %
    % Output:
    %   valor_objetivo - Valor a minimizar (energía negativa + penalización)
    
    % 1. CALCULAR ENERGÍA NORMAL
    Rx_3d = [rx_xy, Rx_z];
    energia = calcular_energia_promedio(Rx_3d, Tx, P_targets, n1, n2);
    
    % 2. CALCULAR DISTANCIA A LA POSICIÓN ESPECULAR
    distancia_especular = norm(rx_xy - Rx_especular_xy);
    
    % 3. APLICAR RESTRICCIÓN SUAVE
    if distancia_especular <= radio_busqueda
        % Dentro del radio permitido: solo optimizar energía
        penalizacion = 0;
    else
        % Fuera del radio: penalizar fuertemente
        exceso_distancia = distancia_especular - radio_busqueda;
        
        % Penalización cuadrática que crece rápidamente
        factor_penalizacion = 1e6; % Ajustable según la magnitud de la energía
        penalizacion = factor_penalizacion * exceso_distancia^2;
    end
    
    % 4. VALOR OBJETIVO FINAL
    % Queremos maximizar energía (minimizar -energía) y minimizar penalización
    valor_objetivo = -energia + penalizacion;
    
    % Opcional: Información de debug (comentar para producción)
    % if distancia_especular > radio_busqueda
    %     fprintf('  Fuera de región especular: dist=%.1fm, penalización=%.2e\n', distancia_especular, penalizacion);
    % end
    
end