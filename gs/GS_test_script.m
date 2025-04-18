clc
clear
close all

addpath(genpath('src'))
addpath(genpath(strcat('..',filesep,'tools')))

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_circular.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_circular.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parametros del target

targetJSON = json2struct(strcat('..',filesep,'parametros',filesep,'target_circular.json'));
strTarget  = targetJSON.target; clear targetJSON;

% Parametros do sistema

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_circular.json'));
strSystem  = systemJSON.system; clear systemJSON;

% Pre procesamiento parametros 

strRadarTx = converterPosGrados2Rad(strRadarTx);
strRadarRx = converterPosGrados2Rad(strRadarRx);

% Parametros derivados

% Tx
strRadarTx.PRT  = 1/strRadarTx.PRF;
strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda
strRadarTx.B    = strRadarTx.FreqMayor - strRadarTx.FreqMenor; % Banda do radar

% Rx
strRadarRx.PRT  = 1/strRadarRx.PRF;
strRadarRx.lamb = strSystem.VelocidadeLuz/strRadarRx.FreqPortadora; % Comprimento de onda

% Matriz de transição de estados

[F_tx,H_tx] = calculaMatrizTransicaoObservacao(strRadarTx);
[F_rx,H_rx] = calculaMatrizTransicaoObservacao(strRadarRx);

% --

[strRadarTx, strRadarRx] = calculateCoverageBistatic(strRadarTx, strRadarRx);

% --

chirp   = createCHRIP(strRadarTx);
pulsoTx = zeros(1,strSystem.IndiceMaximo);

pulsoTx(1:length(chirp)) = chirp;
% pulsoTx(1) = 1;

figure
hold on
plot(real(pulsoTx))
plot(imag(pulsoTx))
grid minor
xlabel("amostra")
ylabel("Amplitude")
legend("Real","Imag")
hold off

% --

posRadarTx = zeros(3, strSystem.NumeroPulsos);
posRadarRx = zeros(3, strSystem.NumeroPulsos);

dados      = zeros(strSystem.NumeroPulsos, strSystem.IndiceMaximo);

for i = 1:strSystem.NumeroPulsos
    
    % Mostrar barra de progresso em porcentagem
    if mod(i, 100) == 0
        fprintf('Progresso: %.2f%%\n', i/strSystem.NumeroPulsos*100);
    end
    
    allTargetsSinal = zeros(1, strSystem.IndiceMaximo);

    for j = 1:length(strTarget)
        
        % Inicializar estado do radar
        if i == 1
            estadosTx = strRadarTx.posInicial;
            estadosRx = strRadarRx.posInicial;
        else
            estadosTx = F_tx * estadosTx;
            estadosRx = F_tx * estadosRx;
        end
        
        posRadarTx(:, i) = H_tx*estadosTx;
        posRadarRx(:, i) = H_tx*estadosRx;
        
        posRadarTx(:, i) = convertCordinatesToCartesian(posRadarTx(:,i),strRadarTx.tipoTrajetoria);
        posRadarRx(:, i) = convertCordinatesToCartesian(posRadarRx(:,i),strRadarRx.tipoTrajetoria);
        
        distTx = calculateDistIfAzim(posRadarTx(:, i),strTarget(j), strRadarTx);
        distRx = calculateDistIfAzim(posRadarRx(:, i),strTarget(j), strRadarRx);
        
        if ~isempty(distTx) & ~isempty(distRx)
            
            % Distancia total 
            dist = distTx + distRx;
            
            % Calcula amostra de deslocamento
            idx = (dist/strSystem.VelocidadeLuz)*strRadarTx.fs;
            
            % Calcular fase do sinal deslocado
            fase = -2*pi*dist/strRadarTx.lamb;
            
            % Deslocar o sinal
            pulsoRx = circshift(pulsoTx, round(idx));
            
            % Adicionar a fase
            pulsoRx = pulsoRx .* exp(1j*fase);
            
            % Eq radar
            pulsoRx = pulsoRx*(EqRadar(strRadarTx,strRadarRx,strTarget(j),distTx,distRx));
            
            % Adicionar sinal ao vetor de sinais
            allTargetsSinal = allTargetsSinal + pulsoRx;
        end
        
        % Salvar pulso
        dados(i, :) = allTargetsSinal;
        
    end
end

% Adicionar ruído
dados = dados + randn(size(dados))*potRuido(strRadarRx.Temperatura,strRadarRx.B);

figure
mesh(abs(dados))
xlabel('RangeBins')
ylabel('Pulsos')
title('Pulsos recebidos')
grid minor

figure
hold on
for i = 1:length(strTarget)
    plot3(strTarget(i).pos(1), strTarget(i).pos(2), strTarget(i).pos(3), 'ob')
end
plot3(posRadarTx(1, :), posRadarTx(2, :), posRadarTx(3, :), 'xr')
plot3(posRadarRx(1, :), posRadarRx(2, :), posRadarRx(3, :), 'og')
grid on
xlabel('x')
ylabel('y')
zlabel('z')
title('Radar trajectory')
grid minor
view(3)
hold off

% Gravar dados 

save(strcat('data',filesep,'dados.mat'),'dados')
save(strcat('data',filesep,'posRadarTx.mat'),'posRadarTx')
save(strcat('data',filesep,'posRadarRx.mat'),'posRadarRx')