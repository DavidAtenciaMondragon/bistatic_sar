clc
clear
close all

addpath(genpath(strcat('..',filesep,'gs',filesep,'src')))

% Radar parameters

radarJSON = json2struct(strcat('..',filesep,'parametros',filesep,'radar.json'));
strRadar  = radarJSON.radar; clear radarJSON;

% System parameters

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system.json'));
strSystem   = systemJSON.system; clear systemJSON;

% Load data 

load(strcat('..',filesep,'gs',filesep,'data',filesep,'dados.mat'));
load(strcat('..',filesep,'gs',filesep,'data',filesep,'posRadar.mat'));

% Ideal CHIRP 

chirp   = createCHRIP(strRadar);
pulsoTx = zeros(1,strSystem.IndiceMaximo);

pulsoTx(1:length(chirp)) = chirp;

% Range compression

pulsoTxRep = repmat(conj(fft(pulsoTx)), [strSystem.NumeroPulsos,1]);
pulsoComp  = ifft(fft(dados,strSystem.IndiceMaximo,2).*pulsoTxRep,strSystem.IndiceMaximo,2);

clear pulsoTxRep dados

% Interpolate data 

[numPRT,numRange] = size(pulsoComp);

pulsoComp = interpft(pulsoComp,numRange*strSystem.ratioUp,2);

figure
mesh(abs(pulsoComp))
title('Range compression')
xlabel('Range')
ylabel('Pulses')

% Create image sample grid (x,y)

X = strSystem.xMin:strSystem.discGrid:strSystem.xMax;
Y = strSystem.yMin:strSystem.discGrid:strSystem.yMax;

[XX,YY] = meshgrid(X,Y);

ZZ = zeros(size(XX));

% Calculate wavelength

lambda = strSystem.VelocidadeLuz/strRadar.FreqPortadora;

% Back Projection algorithm

output = zeros(size(XX));

counterProgress = 0; 

for i = 1:size(output,1)
    for j = 1:size(output,2)
        % Show progress percentage
        
        counterProgress = counterProgress + 1;
        if mod(counterProgress,2000) == 0
            disp(['Progress: ',num2str(100*counterProgress/(size(output,1)*size(output,2))),'%'])
        end

        % Calculate slant range for every pixel
        R = sqrt((XX(i,j)-posRadar(1,:)').^2 + (YY(i,j)-posRadar(2,:)').^2 + (ZZ(i,j)-posRadar(3,:)').^2);

        % Phase 
        phi = (4*pi/lambda)*R;
        
        % Calculate index 
        index     = (2*R)/strSystem.VelocidadeLuz*(strRadar.fs*strSystem.ratioUp);
        fracIndex = mod(index,1);
        
        indexPre = sub2ind(size(pulsoComp),(1:size(pulsoComp,1))',min(floor(index),size(pulsoComp,2)));
        indexPos = sub2ind(size(pulsoComp),(1:size(pulsoComp,1))',min(ceil(index),size(pulsoComp,2)));
        info     = (1-fracIndex).*pulsoComp(indexPre) + fracIndex.*pulsoComp(indexPos);

        % Compensate phase
        output(i,j) = sum(exp(1i*phi).*info);
        
    end
end

figure
mesh(abs(output))
title('Back Projection')

