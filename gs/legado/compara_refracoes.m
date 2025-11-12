clc
clear 
close all

m = [];

interp = 5:2:11;

% Primera figura: Errores vs Muestras
figure(1)
hold on
title("Interpolacao variavel")
for i = 1:length(interp)
    load(strcat('refracoes_',num2str(interp(i)),'.mat'))
    % Calcula erros 
    err_eff = sqrt(sum((strRefraccoes_eff.P_refrac_ida - strRefraccoes.P_refrac_ida).^2));
    plot(err_eff,'.-','DisplayName',strcat('Interp = ',num2str(interp(i))))
    m = [m mean(err_eff)];
end

% Agregar la leyenda
legend('show', 'Location', 'best')
grid minor 
hold off

% Guardar primera figura
saveas(gcf, 'comparacion_errores_interpolacion.png')
fprintf('Figura 1 guardada como: comparacion_errores_interpolacion.png\n')

% Segunda figura: Error medio vs Numero de interpolaciones
figure(2)
plot(interp,m,'o-','LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'blue')
xlabel("Numero de interpolacoes")
ylabel("Erro medio")
title("Erro medio vs Numero de interpolaciones")
grid on

% Guardar segunda figura
saveas(gcf, 'error_medio_vs_interpolaciones.png')
fprintf('Figura 2 guardada como: error_medio_vs_interpolaciones.png\n')