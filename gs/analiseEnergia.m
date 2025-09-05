clc
clear
close all

addpath(genpath('src'))
addpath(genpath(strcat('..',filesep,'tools')))

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_espiral.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parametros do sistema

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_espiral.json'));
strSystem  = systemJSON.system; clear systemJSON;

% % Calculate params
% 
% strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda

%% Create trajectory

% Transmissor 
[PxT, PyT, PzT] = funcao_espiral(strRadarTx.NumVoltasEsp, strRadarTx.RaioMenorEsp, strRadarTx.RaioMaiorEsp,...
                              strRadarTx.AltMaiorEsp,strRadarTx.AltMenorEsp, strRadarTx.Vt, strRadarTx.PRF);

% Receptor
[PxR, PyR, PzR] = funcao_espiral(strRadarRx.NumVoltasEsp, strRadarRx.RaioMenorEsp, strRadarRx.RaioMaiorEsp,...
                              strRadarRx.AltMaiorEsp,strRadarRx.AltMenorEsp, strRadarRx.Vt, strRadarRx.PRF);
PxR             = -PxR;
PyR             = -PyR;

% Save trajectories on csv files
writematrix([PxT', PyT', PzT'], 'Transmissor_traj.csv');
writematrix([PxR', PyR', PzR'], 'Receptor_traj.csv');

%% Generar video

% generarVideoPlot('DronesBistaticos', numel(PxR), 400,PxT,PyT,PzT,PxR,PyR,PzR)

%% Criar grid 

xGrid         = 1000;
yGrid         = 1000;
zGrid         = 400;
numPontosGrid = 20; 

Xg = linspace(-xGrid,xGrid,numPontosGrid);
Yg = linspace(-yGrid,yGrid,numPontosGrid); 
Zg = linspace(-zGrid,0,numPontosGrid);

[X,Y,Z] = meshgrid(Xg,Yg,Zg);


figure
hold on 
plot3(PxT, PyT, PzT,'k')
plot3(PxR, PyR, PzR,'r')
plot3(X(:),Y(:),Z(:),'.g')
% surf(Xg,Yg,Zg,'EdgeColor','none','FaceColor',[1 0 1],'FaceAlpha',0.1)
xlabel('X')
ylabel('Y')
zlabel('Z')
grid minor 
hold off
legend("Tx","Rx")


%% Proc

n1 = 1;
n2 = 4;
c = strSystem.VelocidadeLuz;
threshold = 1e-10;

Energy = zeros(size(X));

for i = 1:numel(X)
    [r1Tx,r2Tx,angTxTg] = calculateSlantRange(PxT,PyT,PzT,X(i),Y(i),Z(i),c,n2,threshold);
    energiaTxFloor      = 1 - abs(calculateCoefReflex(angTxTg,n1,n2));
    [r1Rx,r2Rx,angTgRx] = calculateSlantRange(PxR,PyR,PzR,X(i),Y(i),Z(i),c,n2,threshold);
    angIncTgRx          = asin((n1/n2) .* sin(angTgRx));
    energiaFloorRx      = 1 - abs(calculateCoefReflex(angIncTgRx,n2,n1));
    Energy(i)           = sum(energiaTxFloor.*energiaFloorRx)/length(PxR);
end

% Visualización con slice
figure
slice(X, Y, Z, Energy, ...
       mean(Xg), ...  % planos en X
       mean(Yg), ...  % planos en Y
       mean(Zg));     % planos en Z

shading interp;          % interpolación suave
colormap jet;            % mapa de colores
colorbar;
xlabel('X'); ylabel('Y'); zlabel('Z');
title('Distribución de Energía con Slice');
axis tight;
view(3);      
