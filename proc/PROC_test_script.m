clc
clear
close all

addpath(genpath(strcat('..',filesep,'gs',filesep,'src')))

% Parametros del transmisor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarTx_circular.json'));
strRadarTx = radarJSON.radar; clear radarJSON;

% Parametros del receptor

radarJSON  = json2struct(strcat('..',filesep,'parametros',filesep,'radarRx_circular.json'));
strRadarRx = radarJSON.radar; clear radarJSON;

% System parameters

systemJSON = json2struct(strcat('..',filesep,'parametros',filesep,'system_circular.json'));
strSystem   = systemJSON.system; clear systemJSON;

% Load data 

load(strcat('..',filesep,'gs',filesep,'data',filesep,'dados.mat'));
load(strcat('..',filesep,'gs',filesep,'data',filesep,'posRadarTx.mat'));
load(strcat('..',filesep,'gs',filesep,'data',filesep,'posRadarRx.mat'));

% Ideal CHIRP 

chirp   = createCHRIP(strRadarTx);
pulsoTx = zeros(1,strSystem.IndiceMaximo);

pulsoTx(1:length(chirp)) = chirp;

% Range compression

pulsoTxRep = repmat(conj(fft(pulsoTx)), [strSystem.NumeroPulsos,1]);
pulsoComp  = ifft(fft(dados,strSystem.IndiceMaximo,2).*pulsoTxRep,strSystem.IndiceMaximo,2);

figure
mesh(abs(pulsoComp))
title('Range compression')
xlabel('Range')
ylabel('Pulses')

clear pulsoTxRep dados

% Interpolate data 

[numPRT,numRange] = size(pulsoComp);

pulsoComp = interpft(pulsoComp,numRange*strSystem.ratioUp,2);

% Create image sample grid (x,y)

X = strSystem.xMin:strSystem.discGrid:strSystem.xMax;
Y = strSystem.yMin:strSystem.discGrid:strSystem.yMax;

[XX,YY] = meshgrid(X,Y);

ZZ = zeros(size(XX));

% Calculate wavelength

lambda = strSystem.VelocidadeLuz/strRadarTx.FreqPortadora;

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
        R_Tx_Tg = sqrt((XX(i,j)-posRadarTx(1,:)').^2 + (YY(i,j)-posRadarTx(2,:)').^2 + (ZZ(i,j)-posRadarTx(3,:)').^2);
        R_Tg_Rx = sqrt((XX(i,j)-posRadarRx(1,:)').^2 + (YY(i,j)-posRadarRx(2,:)').^2 + (ZZ(i,j)-posRadarRx(3,:)').^2);
        R       = R_Tx_Tg + R_Tg_Rx;

        % Phase 
        phi = (2*pi/lambda)*R;
        
        % Calculate index 
        index     = (R)/strSystem.VelocidadeLuz*(strRadarRx.fs*strSystem.ratioUp);
        fracIndex = mod(index,1);
        
        indexPre = sub2ind(size(pulsoComp),(1:size(pulsoComp,1))',min(floor(index),size(pulsoComp,2)));
        indexPos = sub2ind(size(pulsoComp),(1:size(pulsoComp,1))',min(ceil(index),size(pulsoComp,2)));
        info     = (1-fracIndex).*pulsoComp(indexPre) + fracIndex.*pulsoComp(indexPos);

        % Compensate phase
        output(i,j) = sum(exp(1i*phi).*info);
        
    end
end

% Show output with labels (XX,YY)
figure
mesh(XX,YY,abs(output))
title('Back Projection')
xlabel('X')
ylabel('Y')
zlabel('Amplitude')

% --- 8.4 Display Focused Image ---
figure;
imagesc(X, Y, 20*log10(abs(output)/max(abs(output(:))))); % Display in dB scale
colormap('gray');
colorbar;
xlabel('X (m)');
ylabel('Y (m)');
title('Focused SAR Image (Bistatic Backprojection - dB Scale)');
axis xy; % Set origin to bottom-left corner
axis equal; axis tight;
