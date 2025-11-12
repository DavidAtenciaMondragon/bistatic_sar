function Rx_brewster = calcular_posicion_brewster(Tx, P_targets, Rx_z, n1, n2)
    % CALCULAR_POSICION_BREWSTER - Calcula posición del receptor para ángulo de Brewster
    %
    % Para cada punto objetivo, calcula la posición del receptor que produciría
    % el ángulo de Brewster en la reflexión, maximizando la transmisión de energía
    %
    % Ángulo de Brewster: tan(θ_B) = n2/n1
    % En este ángulo, la reflexión de la polarización paralela es cero
    %
    % Inputs:
    %   Tx - Vector [x, y, z] posición del transmisor
    %   P_targets - Matriz Nx3 con posiciones [x, y, z] de los objetivos
    %   Rx_z - Altura fija del receptor
    %   n1, n2 - Índices de refracción (aire, suelo)
    %
    % Output:
    %   Rx_brewster - Vector [x, y] posición promedio para ángulo de Brewster
    
    % 1. CALCULAR ÁNGULO DE BREWSTER
    angulo_brewster = atan(n2/n1);
    
    fprintf('  Ángulo de Brewster: %.2f° (%.4f rad)\n', rad2deg(angulo_brewster), angulo_brewster);
    
    num_targets = size(P_targets, 1);
    posiciones_brewster = zeros(num_targets, 2);
    
    for i = 1:num_targets
        Pi = P_targets(i, :); % Punto objetivo actual
        
        % 2. ENCONTRAR PUNTO DE REFLEXIÓN PARA ÁNGULO DE BREWSTER
        % Para ángulo de Brewster, necesitamos que el ángulo de incidencia sea θ_B
        
        % Altura del transmisor sobre la superficie
        h_tx = abs(Tx(3) - 0); % Distancia de Tx a superficie (z=0)
        
        % Distancia horizontal desde Tx al punto de reflexión para ángulo de Brewster
        % tan(θ_B) = distancia_horizontal / altura_vertical
        d_horizontal_tx = h_tx * tan(angulo_brewster);
        
        % Vector unitario desde Tx hacia Pi en el plano XY
        direccion_tx_pi = [Pi(1) - Tx(1), Pi(2) - Tx(2)];
        distancia_tx_pi_xy = norm(direccion_tx_pi);
        
        if distancia_tx_pi_xy > 1e-10
            dir_unitario = direccion_tx_pi / distancia_tx_pi_xy;
        else
            % Si Tx y Pi están en la misma XY, usar dirección arbitraria
            dir_unitario = [1, 0];
        end
        
        % Punto de reflexión con ángulo de Brewster
        G_brewster = Tx(1:2) + d_horizontal_tx * dir_unitario;
        G_brewster_3d = [G_brewster, 0]; % En la superficie z=0
        
        % 3. CALCULAR POSICIÓN DEL RECEPTOR PARA REFLEXIÓN ESPECULAR
        % Con ángulo de Brewster en la incidencia, la reflexión sigue ley especular
        
        % Vector incidente (normalizado)
        v_incident = G_brewster_3d - Tx;
        v_incident_norm = v_incident / norm(v_incident);
        
        % Vector normal a la superficie (apunta hacia arriba)
        normal = [0, 0, 1];
        
        % Vector reflejado usando ley de reflexión: r = i - 2(i·n)n
        dot_in = dot(v_incident_norm, normal);
        v_reflected = v_incident_norm - 2 * dot_in * normal;
        v_reflected_norm = v_reflected / norm(v_reflected);
        
        % 4. CALCULAR POSICIÓN DEL RECEPTOR
        % El receptor debe estar en la línea del rayo reflejado
        % A la altura especificada Rx_z
        
        altura_reflexion_to_rx = abs(Rx_z - 0);
        
        % Distancia horizontal desde punto de reflexión al receptor
        % tan(ángulo_reflexión) = distancia_horizontal / altura_vertical
        % Por ley de reflexión, ángulo_reflexión = ángulo_incidencia = ángulo_brewster
        d_horizontal_rx = altura_reflexion_to_rx * tan(angulo_brewster);
        
        % Dirección horizontal del rayo reflejado
        dir_reflejado_xy = v_reflected_norm(1:2);
        if norm(dir_reflejado_xy) > 1e-10
            dir_reflejado_xy = dir_reflejado_xy / norm(dir_reflejado_xy);
        else
            % Fallback si el rayo es vertical
            dir_reflejado_xy = dir_unitario;
        end
        
        % Posición del receptor para ángulo de Brewster
        Rx_brewster_i = G_brewster + d_horizontal_rx * dir_reflejado_xy;
        
        posiciones_brewster(i, :) = Rx_brewster_i;
        
        % Debug opcional para el primer target
        if i == 1
            fprintf('  Target 1: G_brewster=[%.1f,%.1f], Rx_brewster=[%.1f,%.1f]\n', ...
                    G_brewster(1), G_brewster(2), Rx_brewster_i(1), Rx_brewster_i(2));
        end
    end
    
    % 5. CALCULAR POSICIÓN PROMEDIO
    Rx_brewster = mean(posiciones_brewster, 1);
    
    fprintf('  Posición Brewster promedio: [%.2f, %.2f]\n', Rx_brewster(1), Rx_brewster(2));
    
    % 6. ANÁLISIS ESTADÍSTICO (opcional)
    distancias_promedio = sqrt(sum((posiciones_brewster - repmat(Rx_brewster, num_targets, 1)).^2, 2));
    fprintf('  Dispersión posiciones Brewster: %.2f ± %.2f m\n', mean(distancias_promedio), std(distancias_promedio));
    
end