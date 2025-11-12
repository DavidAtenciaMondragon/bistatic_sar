function G = encontrar_punto_interfaz(P1, P2, n1, n2)
    % P1 es el punto de inicio, P2 es el punto final
    % n1 es el índice de refracción del medio de P1
    % n2 es el índice de refracción del medio de P2
    
    % La interfaz está en z=0. Proyectamos P1 y P2 sobre el plano xy.
    P1_xy = [P1(1), P1(2)];
    P2_xy = [P2(1), P2(2)];
    
    % Función de camino óptico a minimizar. 'g_xy' son las coords [x,y] del
    % punto G en la interfaz que estamos buscando.
    camino_optico = @(g_xy) n1 * sqrt(sum((P1_xy - g_xy).^2) + P1(3)^2) + ...
                              n2 * sqrt(sum((P2_xy - g_xy).^2) + P2(3)^2);
    
    % Una buena conjetura inicial es la interpolación lineal entre P1 y P2
    % en el plano xy.
    g_inicial_xy = P1_xy + (P2_xy - P1_xy) * abs(P1(3)) / (abs(P1(3)) + abs(P2(3)));
    
    % Opciones para que el optimizador no muestre sus propias iteraciones
    options = optimset('Display','none', 'TolX', 1e-6);
    
    % Minimizar el camino óptico para encontrar g_xy
    g_optimo_xy = fminsearch(camino_optico, g_inicial_xy, options);
    
    % El punto G está en el plano z=0
    G = [g_optimo_xy(1), g_optimo_xy(2), 0];
end