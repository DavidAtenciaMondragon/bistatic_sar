function E_promedio = calcular_energia_promedio(Rx, Tx, P_targets, n1, n2)
    % CALCULAR_ENERGIA_PROMEDIO - Versión optimizada con SOLO polarización TM
    % 
    % Esta función calcula la energía promedio considerando únicamente 
    % polarización TM (Transverse Magnetic), donde existe el ángulo de Brewster.
    % Para polarización TM: θ_Brewster = arctan(n2/n1)
    %
    % VERSION CON INTERFAZ CONSISTENTE Y VECTORIZACIÓN
    % Rx: vector [x, y, z] posición del receptor
    % Tx: vector [x, y, z] posición del transmisor  
    % P_targets: matriz Nx3 con posiciones [x, y, z] de los objetivos
    % n1, n2: índices de refracción
    
    % Validar entrada
    if length(Rx) ~= 3 || length(Tx) ~= 3
        error('Rx y Tx deben ser vectores de 3 elementos [x, y, z]');
    end
    
    if size(P_targets, 2) ~= 3
        error('P_targets debe ser una matriz Nx3 con coordenadas [x, y, z]');
    end
    
    num_targets = size(P_targets, 1);
    
    % VECTORIZACIÓN: Procesar todos los puntos objetivo simultáneamente
    
    % 1. ENCONTRAR TODOS LOS PUNTOS DE REFRACCIÓN
    Gt_all = zeros(num_targets, 3); % Puntos de refracción Tx->Pi
    Gr_all = zeros(num_targets, 3); % Puntos de refracción Pi->Rx
    
    for i = 1:num_targets
        Pi = P_targets(i, :);
        Gt_all(i, :) = encontrar_punto_interfaz(Tx, Pi, n1, n2);
        Gr_all(i, :) = encontrar_punto_interfaz(Pi, Rx, n2, n1);
    end
    
    % 2. CÁLCULOS DE DISTANCIAS VECTORIZADOS
    % Usar broadcasting para calcular todas las distancias de una vez
    diff_Tx_Gt = Gt_all - repmat(Tx, num_targets, 1);
    d_Tx_Gt = sqrt(sum(diff_Tx_Gt.^2, 2));
    
    diff_Gt_Pi = P_targets - Gt_all;
    d_Gt_Pi = sqrt(sum(diff_Gt_Pi.^2, 2));
    
    diff_Pi_Gr = Gr_all - P_targets;
    d_Pi_Gr = sqrt(sum(diff_Pi_Gr.^2, 2));
    
    diff_Gr_Rx = repmat(Rx, num_targets, 1) - Gr_all;
    d_Gr_Rx = sqrt(sum(diff_Gr_Rx.^2, 2));
    
    R_ida = d_Tx_Gt + d_Gt_Pi;
    R_vuelta = d_Pi_Gr + d_Gr_Rx;
    
    % 3. CÁLCULOS DE ÁNGULOS VECTORIZADOS
    % Ángulos de incidencia para ida (Tx -> Gt)
    v_incidente_ida = Gt_all - repmat(Tx, num_targets, 1);
    v_inc_ida_norm = sqrt(sum(v_incidente_ida.^2, 2));
    dot_products_ida = -v_incidente_ida(:, 3) ./ v_inc_ida_norm;
    dot_products_ida = max(-1, min(1, dot_products_ida)); % Clamp para evitar errores numéricos
    theta_t_inc = acos(dot_products_ida);
    
    % Ángulos de incidencia para vuelta (Pi -> Gr)
    v_incidente_vuelta = Gr_all - P_targets;
    v_inc_vuelta_norm = sqrt(sum(v_incidente_vuelta.^2, 2));
    dot_products_vuelta = v_incidente_vuelta(:, 3) ./ v_inc_vuelta_norm;
    dot_products_vuelta = max(-1, min(1, dot_products_vuelta));
    theta_r_inc = acos(dot_products_vuelta);
    
    % 4. COEFICIENTES DE FRESNEL VECTORIZADOS - SOLO POLARIZACIÓN TM
    eta1 = 377 / n1; % Impedancia del medio 1 (aire)
    eta2 = 377 / n2; % Impedancia del medio 2 (suelo)
    
    % Ida (aire -> suelo) - Solo TM
    theta_t_trans = asin((n1/n2) * sin(theta_t_inc));
    cos_theta_t_inc = cos(theta_t_inc);
    cos_theta_t_trans = cos(theta_t_trans);
    
    % Coeficiente de reflexión TM para ida
    R_TM_ida = ((eta2*cos_theta_t_trans - eta1*cos_theta_t_inc) ./ ...
                (eta2*cos_theta_t_trans + eta1*cos_theta_t_inc)).^2;
    
    % Coeficiente de transmisión TM para ida
    T12_TM = 1 - R_TM_ida;
    
    % Vuelta (suelo -> aire) - Solo TM, con verificación de reflexión total
    sin_theta_r_trans = (n2/n1) * sin(theta_r_inc);
    reflection_total = sin_theta_r_trans >= 1;
    
    T21_TM = zeros(num_targets, 1);
    valid_idx = ~reflection_total;
    
    if sum(valid_idx) > 0
        theta_r_trans_valid = asin(sin_theta_r_trans(valid_idx));
        cos_theta_r_inc_valid = cos(theta_r_inc(valid_idx));
        cos_theta_r_trans_valid = cos(theta_r_trans_valid);
        
        % Solo coeficiente TM para vuelta
        R_TM_vuelta_valid = ((eta1*cos_theta_r_trans_valid - eta2*cos_theta_r_inc_valid) ./ ...
                            (eta1*cos_theta_r_trans_valid + eta2*cos_theta_r_inc_valid)).^2;
        
        T21_TM(valid_idx) = 1 - R_TM_vuelta_valid;
    end
    
    % 5. CÁLCULO FINAL DE ENERGÍA VECTORIZADO - SOLO TM
    valid_ranges = (R_ida > 1e-6) & (R_vuelta > 1e-6);
    energia_i = zeros(num_targets, 1);
    energia_i(valid_ranges) = (T12_TM(valid_ranges) .* T21_TM(valid_ranges)) ./ ...
                              (R_ida(valid_ranges).^2 .* R_vuelta(valid_ranges).^2);
    
    E_promedio = sum(energia_i) / num_targets;
end