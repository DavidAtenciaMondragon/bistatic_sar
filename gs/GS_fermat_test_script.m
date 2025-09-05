clc
clear
close all

addpath(genpath('src'))
addpath(genpath(strcat('..',filesep,'tools')))
addpath(genpath(strcat('..',filesep,'common')))

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_espiral.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parametros del target

targetJSON = json2struct(strcat('..',filesep,'parametros',filesep,'target_espiral.json'));
strTarget  = targetJSON.target; clear targetJSON;

% Parametros do sistema

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_espiral.json'));
strSystem  = systemJSON.system; clear systemJSON;

% Calculate params

strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda

%% Create trajectory

% Transmissor 
[PxT, PyT, PzT] = funcao_espiral(strRadarTx.NumVoltasEsp, strRadarTx.RaioMenorEsp, strRadarTx.RaioMaiorEsp,...
                              strRadarTx.AltMaiorEsp,strRadarTx.AltMenorEsp, strRadarTx.Vt, strRadarTx.PRF);

% Receptor
[PxR, PyR, PzR] = funcao_espiral(strRadarRx.NumVoltasEsp, strRadarRx.RaioMenorEsp, strRadarRx.RaioMaiorEsp,...
                              strRadarRx.AltMaiorEsp,strRadarRx.AltMenorEsp, strRadarRx.Vt, strRadarRx.PRF);
PxR             = -PxR;
PyR             = -PyR;

%% Load .tif file 

name_DEM = 'assets\DEM_1x1km_Res30m_Lat-3_6160_Lon-80_4552.tif';

[X_DEM, Y_DEM, Z_DEM] = loadDEM(name_DEM);

Z_DEM = Z_DEM * 0;


%% Plot del escenario 
figure
hold on 
plot3(PxT, PyT, PzT,'k')
plot3(PxR, PyR, PzR,'r')
plot3(strTarget.pos(1),strTarget.pos(2),strTarget.pos(3),'o','MarkerFaceColor','k');
surf(X_DEM,Y_DEM,Z_DEM,'EdgeColor','none','FaceAlpha',0.1)
xlabel('X')
ylabel('Y')
zlabel('Z')
grid minor 
hold off
legend("Tx","Rx","Target")

%% Create grid 
x0 = strTarget.pos(1);
y0 = strTarget.pos(2);  dxy = 0.04;  lxy = 1.0;
z0 = strTarget.pos(3);   dz = 0.08;   lz = 1.0;

xAxis = x0-lxy:dxy:x0+lxy;
yAxis = y0-lxy:dxy:y0+lxy;
zAxis = z0-lz:dz:z0+lz;

[X,Y,Z] = meshgrid(xAxis,yAxis,zAxis);

strGridToProc.xAxis = xAxis;
strGridToProc.yAxis = yAxis;
strGridToProc.zAxis = zAxis;

%% Create raw data

n = 3;
c = strSystem.VelocidadeLuz;
threshold = 1e-10;

x0 = strTarget.pos(1);
y0 = strTarget.pos(2);
z0 = strTarget.pos(3);

%% Build data

n1 = 1;
n2 = 4;

strEnvironment.n1 = n1;
strEnvironment.n2 = n2;

%Preproc 
strDEM.X_vec = X_DEM(1,:);
strDEM.Y_vec = Y_DEM(:,1).';
strDEM.Z_DEM = double(Z_DEM);

Tx = [PxT.', PyT.', PzT.'];
Rx = [PxR.', PyR.', PzR.'];

P  = strTarget.pos.'; 

bPlotVerbose = false;
f_interp     = 5;

% [strReflexao, strRefraccoes] = calculaSlantRangeFermat(strDEM,Tx,Rx,P,n1,n2,bPlotVerbose);
tic
[strReflexao, strRefraccoes] = calculaSlantRangeFermat_eff(strDEM,Tx,Rx,P,n1,n2,f_interp);
toc

%% Create ranges 

r1Tx = sqrt(sum((Tx - [strRefraccoes.P_refrac_ida].').^2,2));
r2Tx = sqrt(sum((P - [strRefraccoes.P_refrac_ida].').^2,2));

r1Rx = sqrt(sum((Rx - [strRefraccoes.P_refrac_volta].').^2,2));
r2Rx = sqrt(sum((P - [strRefraccoes.P_refrac_volta].').^2,2));

r1Tx = r1Tx.';
r2Tx = r2Tx.';
r1Rx = r1Rx.';
r2Rx = r2Rx.'; 

%% Create raw matrix 

t       = (1/c)*(r1Tx + n*r2Tx + r1Rx + n*r2Rx);
rngBin  = 1 + round(t*strRadarRx.fs);

phi     = -(2*pi/strRadarTx.lamb)*(r1Tx + n*r2Tx + r1Rx + n*r2Rx);

auxData = zeros(strSystem.IndiceMaximo,length(PxT));
IND     = sub2ind(size(auxData),rngBin,1:length(PxT));

auxData(IND) = strTarget.rcs.*exp(1i*phi);

chirp   = createCHRIP(strRadarTx);
pulsoTx = zeros(1,strSystem.IndiceMaximo);

pulsoTx(1:length(chirp)) = chirp;

K = fix(length(chirp)/2);

reference    = circshift([pulsoTx],K).';
rawData      = ifft(fft(auxData).*fft(reference));

% Compression

rootData = ifft(fft(rawData).*conj(fft(reference)));

% Save at proc folder 

dir = strcat("..",filesep,"proc",filesep,"simulated_raw_david_fermat.mat");

save(dir, 'rootData', 'strDEM', 'strEnvironment', 'Tx', 'Rx', 'strGridToProc');

dir = strcat("..",filesep,"proc",filesep,"simulated_raw_david.mat");

save(dir, 'rootData', 'x0', 'y0', 'z0', 'n', 'PxT', 'PyT', 'PzT', 'PxR', 'PyR', 'PzR', 'X', 'Y', 'Z');

