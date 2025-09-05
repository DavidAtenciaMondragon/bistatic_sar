clc
clear
% close all

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_espiral.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_espiral.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% Parametros do sistema

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_espiral.json'));
strSystem  = systemJSON.system; clear systemJSON;

% Target 

targetJSON = json2struct(strcat('..',filesep,'parametros',filesep,'target_espiral.json'));
strTarget  = targetJSON.target; clear targetJSON;

x0  = strTarget.pos(1);
y0  = strTarget.pos(2);

xy0 = strTarget.pos(1); dxy = 0.04;  lxy = 1.2;
z0  = strTarget.pos(3);  dz = 0.08;   lz = 1.2;

% Calculate params

strRadarTx.lamb = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora; % Comprimento de onda


%% Load 

load('simulated_raw_david.mat')

%% Preproc 

[Nrng,Nazm] = size(rootData);
ratio = 4;

rcompData = interpft(rootData,Nrng*ratio,1);
rcompData = rcompData.';
fs = ratio*strRadarTx.fs;

clear rootData

%% Processamiento 

tic

wb = waitbar(0);
threshold = 1e-11;
c = strSystem.VelocidadeLuz;
outputData = zeros(size(X));

for m = 1:numel(X)
    
    % Slant range calculation
    [R1t,R2t] = slantRange(PxT,PyT,PzT,X(m),Y(m),Z(m),n,threshold);
    [R1r,R2r] = slantRange(PxR,PyR,PzR,X(m),Y(m),Z(m),n,threshold);
    
    % Fractional range bin sample
    t = (1/c)*(R1t + n*R2t + n*R2r + R1r);
    rngBin = 1 + round(t*fs);
    
    % Phase compensation term
    phi = (2*pi/strRadarTx.lamb)*(R1t + n*R2t + n*R2r + R1r);
    
    % Linear interpolation
    lastIND = sub2ind(size(rcompData),(1:Nazm),floor(rngBin));
    nextIND = sub2ind(size(rcompData),(1:Nazm),ceil(rngBin));
    q = rngBin - lastIND;
    interp = (1-q).*rcompData(lastIND) + q.*rcompData(nextIND);
    
    % Data accumulation
    outputData(m) = sum(interp.*exp(1i*phi));
    
    waitbar(m/numel(X),wb,'Ejecutando algoritmo Back-Projection...');
end
close(wb)
toc

%% Plots 

figure

s = slice(X,Y,Z,abs(outputData/max(outputData(:))),x0,y0,-5);
set(s,'EdgeColor','none')
% title({'Output Data','abs()'})
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
axis equal
colormap parula

% -------------------------------------------------------------------

figure
dataDB = 20*log10(abs(outputData/max(outputData(:))));
% contourslice(X,Y,Z,dataDB,[],[],-1.1)
patch(isosurface(X,Y,Z,dataDB,-3),...
    'EdgeColor','none','CData',-3,'FaceColor','flat');
% patch(isosurface(X,Y,Z,dataDB,-13),...
%     'EdgeColor','none','CData',-13,'FaceColor','flat','FaceAlpha',0.15);
xlabel('x (m)')
ylabel('y (m)')
zlabel('z (m)')
axis equal
% xlim([-0.15 0.15])
% ylim([-0.15 0.15])
% zlim([-2 -0.5])

xlim([min(X,[],'all') max(X,[],'all')])
ylim([min(Y,[],'all') max(Y,[],'all')])
zlim([min(Z,[],'all') max(Z,[],'all')])

grid on
grid minor
view([-45 45])
camlight right
% camlight left
camlight headlight
lighting gouraud
colormap jet
caxis([-40 0])