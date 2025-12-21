clc
clear
close all

%% Definir posiciones 

posTx = [0,10,10];
posTg = [0,0,0; 
         0,2,0;
         4,1,0];

% Orientacion del Tx respecto al Tg

[az, el, r] = cart2sph(posTx(1)-posTg(:,1), posTx(2)-posTg(:,2), posTx(3)-posTg(:,3));

% Medidas aleatorias 

R = 15;
N = 100;

posX = rand(1,N)*2*R - R;
posY = rand(1,N)*2*R - R;
posZ = rand(1,N)*R;

figure
hold on 
plot3(posTx(1),posTx(2),posTx(3),'ko')
plot3(posTg(:,1),posTg(:,2),posTg(:,2),'ro')
plot3(posX,posY,posZ,'cx')
% grid minor 
% view(3)
% hold off 

%% Filtering 

[az_tg, el_tg, r_tg] = cart2sph(mean(posTg(:,1))-posX, mean(posTg(:,2))-posY, mean(posTg(:,3))-posZ);

% Verify is az_tg is on the range az + pi -+ pi/2, if true keep. Handle wrapping properly

az_min = max(az + pi/2);
az_max = min(az + 3*pi/2);

% Normalize angles to [0, 2*pi] to handle wrapping
az_tg_norm = mod(az_tg, 2*pi);
az_min_norm = mod(az_min, 2*pi);
az_max_norm = mod(az_max, 2*pi);

% Handle wrapping case where the range crosses 0/2π
if az_min_norm > az_max_norm
    % Range crosses the 0/2π boundary
    idx_valid = (az_tg_norm >= az_min_norm) | (az_tg_norm <= az_max_norm);
else
    % Normal case, no wrapping
    idx_valid = (az_tg_norm >= az_min_norm) & (az_tg_norm <= az_max_norm);
end

idx_valid = not(idx_valid);

posX_f = posX(idx_valid);
posY_f = posY(idx_valid);
posZ_f = posZ(idx_valid);

% figure
% hold on
% plot3(posTx(1),posTx(2),posTx(3),'ko')
% plot3(posTg(1),posTg(2),posTg(3),'ro')
plot3(posX_f,posY_f,posZ_f,'bx')
grid minor
view(3)
hold off
