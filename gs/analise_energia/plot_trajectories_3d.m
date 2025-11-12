function plot_trajectories_3d(pos_Tx, pos_Rx, pos_Rx_otimizado, strVolumEmAnalise, strDEM, strEnvironment)
    % PLOT_TRAJECTORIES_3D - Visualización 3D completa del sistema biestático SAR
    %
    % Inputs:
    %   pos_Tx - Matriz Nx3 con posiciones del transmisor
    %   pos_Rx - Matriz Nx3 con posiciones del receptor original
    %   pos_Rx_otimizado - Matriz Nx3 con posiciones del receptor optimizado
    %   strVolumEmAnalise - Estructura con puntos de análisis
    %   strDEM - Estructura con datos del terreno
    %   strEnvironment - Estructura con parámetros del environment
    
    figure('Name', 'Análisis de Trayectorias y Puntos de Irradiación', 'Position', [100, 100, 1400, 900]);
    
    hold on;
    
    % 1. TRAYECTORIAS DEL TRANSMISOR
    plot3(pos_Tx(:,1), pos_Tx(:,2), pos_Tx(:,3), 'k-o');
    
    % 2. TRAYECTORIAS DEL RECEPTOR ORIGINAL
    plot3(pos_Rx(:,1), pos_Rx(:,2), pos_Rx(:,3), 'r-s');
    
    % 3. TRAYECTORIAS DEL RECEPTOR OPTIMIZADO
    plot3(pos_Rx_otimizado(:,1), pos_Rx_otimizado(:,2), pos_Rx_otimizado(:,3), 'b-^');
      
    % 4. PUNTOS DE ANÁLISIS (VOLUMEN DE IRRADIACIÓN)
    if exist('strVolumEmAnalise', 'var') && ~isempty(strVolumEmAnalise)
        plot3(strVolumEmAnalise.X(:), strVolumEmAnalise.Y(:), strVolumEmAnalise.Z(:), 'go');
    end
     
    % 5. SUPERFICIE DEL TERRENO (DEM)
    if exist('strDEM', 'var') && ~isempty(strDEM)
        surf(strDEM.X_vec, strDEM.Y_vec, strDEM.Z_DEM, 'EdgeColor', 'none', 'FaceAlpha', 0.1, 'FaceColor', [0.4 0.6 0.4]);
    end
    
    % 6. CONFIGURACIÓN DE LA VISUALIZACIÓN
    xlabel('X (m)', 'FontSize', 12, 'FontWeight', 'bold');
    ylabel('Y (m)', 'FontSize', 12, 'FontWeight', 'bold');
    zlabel('Z (m)', 'FontSize', 12, 'FontWeight', 'bold');
    title('Análisis Biestático SAR: Trayectorias y Puntos de Irradiación', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Leyenda
    legend_labels = {'Tx', 'Rx', 'Rx Optimizado'};
    if exist('strVolumEmAnalise', 'var') && ~isempty(strVolumEmAnalise)
        legend_labels{end+1} = 'Puntos en análisis';
    end
    if exist('strDEM', 'var') && ~isempty(strDEM)
        legend_labels{end+1} = 'Superficie';
    end
    legend(legend_labels, 'Location', 'best');
    
    % 7. TEXTO CON INFORMACIÓN DEL ENVIRONMENT
    if exist('strEnvironment', 'var') && ~isempty(strEnvironment)
        xlims = xlim; ylims = ylim; zlims = zlim;
        text_x = xlims(1) + 0.02 * (xlims(2) - xlims(1));
        text_y = ylims(2) - 0.02 * (ylims(2) - ylims(1));
        text_z = zlims(2) - 0.1 * (zlims(2) - zlims(1));
        
        env_text = 'ENVIRONMENT:';
        if isfield(strEnvironment, 'n1')
            env_text = [env_text, sprintf('\nn₁: %.3f', strEnvironment.n1)];
        end
        if isfield(strEnvironment, 'n2') 
            env_text = [env_text, sprintf('\nn₂: %.3f', strEnvironment.n2)];
        end
        if isfield(strEnvironment, 'frequencia')
            env_text = [env_text, sprintf('\nf: %.1f MHz', strEnvironment.frequencia/1e6)];
        end
        
        text(text_x, text_y, text_z, env_text, 'FontSize', 9, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'Margin', 3, ...
             'VerticalAlignment', 'top');
    end
    
    % Grid y configuración visual
    grid minor;
    view(45, 30);
    
    hold off;
end