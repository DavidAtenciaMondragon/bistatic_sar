function generarVideoPlot(nombreArchivo, nFrames, frameRate, PxT, PyT, PzT, PxR, PyR, PzR)
% generarVideoPlot(nombreArchivo, nFrames, frameRate, PxT, PyT, PzT, PxR, PyR, PzR)
% Genera un video 3D con la trayectoria de dos puntos (Tx y Rx) a lo largo del tiempo.
%
% PxT, PyT, PzT : posiciones del transmisor (vectores de tamaño nFrames)
% PxR, PyR, PzR : posiciones del receptor (vectores de tamaño nFrames)

    % Crear objeto de video
    v = VideoWriter(nombreArchivo);
    v.FrameRate = frameRate;
    open(v);

    % Crear figura
    fig = figure;

    for i = 1:nFrames
        % Borrar contenido previo
        clf;

        % Activar hold on después del clf
        hold on;

        % Dibujar los puntos Tx y Rx
        plot3(PxT(i), PyT(i), PzT(i), 'xk', 'MarkerSize', 10, 'LineWidth', 2);
        plot3(PxR(i), PyR(i), PzR(i), 'xr', 'MarkerSize', 10, 'LineWidth', 2);

        % Opcional: trayectoria completa hasta ese punto
        plot3(PxT(1:i), PyT(1:i), PzT(1:i), '-k');
        plot3(PxR(1:i), PyR(1:i), PzR(1:i), '-r');

        % Ejes y formato
        axis([-300 300 -300 300 0 300]);
        xlabel('X'); ylabel('Y'); zlabel('Z');
        title('Voo dos Drones Tx-Rx');
        grid minor;
        view(3);

        % Capturar y guardar frame
        frame = getframe(fig);
        writeVideo(v, frame);
    end

    % Cerrar archivo de video
    close(v);
    close(fig);
    fprintf('✅ Video guardado como: %s\n', nombreArchivo);
end
