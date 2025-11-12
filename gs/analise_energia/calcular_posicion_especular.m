function Rx_specular = calcular_posicion_especular(Tx, P_targets, Rx_z)
    % CALCULAR_POSICION_ESPECULAR - Calcula la posición especular ideal del receptor
    %
    % Para un sistema biestático SAR, el receptor debe estar posicionado para
    % recibir la reflexión especular desde los puntos objetivo según las leyes
    % de reflexión: ángulo de incidencia = ángulo de reflexión
    %
    % Inputs:
    %   Tx - Vector [x, y, z] posición del transmisor
    %   P_targets - Matriz Nx3 con posiciones [x, y, z] de los objetivos
    %   Rx_z - Altura fija del receptor
    %
    % Output:
    %   Rx_specular - Vector [x, y] posición especular promedio en el plano XY
    
    num_targets = size(P_targets, 1);
    posiciones_especulares = zeros(num_targets, 2);
    
    for i = 1:num_targets
        Pi = P_targets(i, :); % Punto objetivo actual
        
        % 1. ENCONTRAR EL PUNTO DE REFLEXIÓN EN LA SUPERFICIE (z=0)
        % Usando el principio de Fermat: el camino óptico debe ser mínimo
        % Esto es equivalente a encontrar el punto donde el ángulo de incidencia
        % es igual al ángulo de reflexión
        
        % Método: "Imagen especular"
        % Crear una imagen especular del transmisor reflejado en z=0
        Tx_mirror = [Tx(1), Tx(2), -Tx(3)];
        
        % El punto de reflexión óptimo está en la línea que conecta
        % la imagen especular del Tx con el punto objetivo Pi
        % Intersección con el plano z=0
        
        % Vector de Tx_mirror a Pi
        dir_vector = Pi - Tx_mirror;
        
        % Parámetro t donde la línea intersecta z=0
        % Tx_mirror(3) + t * dir_vector(3) = 0
        if abs(dir_vector(3)) > 1e-10 % Evitar división por cero
            t_intersect = -Tx_mirror(3) / dir_vector(3);
            
            % Punto de reflexión en la superficie
            G_reflection = Tx_mirror + t_intersect * dir_vector;
        else
            % Si dir_vector(3) ≈ 0, usar proyección directa
            G_reflection = [Pi(1), Pi(2), 0];
        end
        
        % 2. CALCULAR POSICIÓN ESPECULAR DEL RECEPTOR
        % Para reflexión especular perfecta, el receptor debe estar en la
        % dirección que hace el mismo ángulo con la normal que el rayo incidente
        
        % Vector incidente (Tx -> punto de reflexión)
        v_incident = G_reflection - Tx;
        v_incident_xy = v_incident(1:2); % Solo componentes XY
        
        % Vector reflejado en XY (simétrico respecto a la normal en Z)
        % La componente Z cambia de signo, XY se mantiene
        v_reflected_xy = v_incident_xy; % En el plano XY, la reflexión mantiene dirección
        
        % Normalizar el vector reflejado
        v_reflected_xy_norm = v_reflected_xy / norm(v_reflected_xy);
        
        % Calcular la distancia desde el punto de reflexión al receptor
        % basándose en la altura del receptor y la geometría especular
        altura_reflection_to_rx = abs(Rx_z - 0); % Distancia vertical desde superficie
        
        % Calcular distancia horizontal usando ángulo especular
        % tan(ángulo_reflexión) = dist_horizontal / altura_vertical
        v_incident_3d = [v_incident_xy, v_incident(3)];
        angulo_incident = atan2(norm(v_incident_xy), abs(v_incident(3)));
        
        if angulo_incident > 1e-10 % Evitar ángulo muy pequeño
            dist_horizontal = altura_reflection_to_rx * tan(angulo_incident);
        else
            dist_horizontal = norm(v_incident_xy); % Fallback
        end
        
        % Posición especular del receptor
        Rx_specular_i = G_reflection(1:2) + dist_horizontal * v_reflected_xy_norm;
        
        posiciones_especulares(i, :) = Rx_specular_i;
    end
    
    % 3. CALCULAR POSICIÓN PROMEDIO PONDERADA
    % Promedio simple de todas las posiciones especulares
    Rx_specular = mean(posiciones_especulares, 1);
    
    % Opcional: También se podría ponderar por la intensidad esperada de cada objetivo
    % o usar la mediana para ser más robusto a outliers
    
end