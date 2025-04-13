function [strRadarTx, strRadarRx] = calculateCoverageBistatic(strRadarTx,strRadarRx)

% Transmisor
strRadarTx.AperturaElevRad = strRadarTx.AperturaElev*pi/180; % rad
strRadarTx.InclElevRad  = strRadarTx.InclElev*pi/180; % rad

rangeMinTx = tan(strRadarTx.InclElevRad)*strRadarTx.posInicial(3)*cosd(strRadarTx.Yaw);
rangeMaxTx = tan(strRadarTx.AperturaElevRad + strRadarTx.InclElevRad)*strRadarTx.posInicial(3)*cosd(strRadarTx.Yaw);

strRadarTx.AperturaAzimutRad = strRadarTx.AperturaAzimut*pi/180; % rad
pontoMaxTx = tan(strRadarTx.AperturaAzimutRad/2)*rangeMaxTx*cosd(strRadarTx.Yaw);

% Receptor
strRadarRx.AperturaElevRad = strRadarRx.AperturaElev*pi/180; % rad
strRadarRx.InclElevRad     = strRadarRx.InclElev*pi/180; % rad

rangeMinRx = tan(strRadarRx.InclElevRad)*strRadarRx.posInicial(3)*cosd(strRadarRx.Yaw);
rangeMaxRx = tan(strRadarRx.AperturaElevRad + strRadarRx.InclElevRad)*strRadarRx.posInicial(3)*cosd(strRadarRx.Yaw);

strRadarRx.AperturaAzimutRad = strRadarRx.AperturaAzimut*pi/180; % rad
pontoMaxRx = tan(strRadarRx.AperturaAzimutRad/2)*rangeMaxRx*cosd(strRadarRx.Yaw);

% --

figure

subplot(121)
hold on
plot([strRadarTx.posInicial(1), rangeMinTx(1) + strRadarTx.posInicial(1)], [strRadarTx.posInicial(3),0],'--b')
plot([strRadarTx.posInicial(1), rangeMaxTx(1) + strRadarTx.posInicial(1)], [strRadarTx.posInicial(3),0],'--b')
hold off
grid on
xlabel('x')
ylabel('z')
title("Range min e max (front view)")
title('Tx')
grid minor

subplot(122)
hold on
plot([strRadarRx.posInicial(1), rangeMinRx(1) + strRadarRx.posInicial(1)], [strRadarRx.posInicial(3),0],'--b')
plot([strRadarRx.posInicial(1), rangeMaxRx(1) + strRadarRx.posInicial(1)], [strRadarRx.posInicial(3),0],'--b')
hold off
grid on
xlabel('x')
ylabel('z')
title("Range min e max (front view)")
title('Rx')
grid minor


figure

subplot(121)
hold on
plot([0, rangeMaxTx],[0, pontoMaxTx],'--b')
plot([0, rangeMaxTx],[0, -pontoMaxTx],'--b')
xlabel("x")
ylabel("y")
title("Abertura em azimute - Tx")
grid minor
hold off

subplot(122)
hold on
plot([0, rangeMaxRx],[0, pontoMaxRx],'--b')
plot([0, rangeMaxRx],[0, -pontoMaxRx],'--b')
xlabel("x")
ylabel("y")
title("Abertura em azimute - Rx")
grid minor
hold off

figure

hold on
plot([strRadarTx.posInicial(1), rangeMinTx(1) + strRadarTx.posInicial(1)], [strRadarTx.posInicial(3),0],'--b')
plot([strRadarTx.posInicial(1), rangeMaxTx(1) + strRadarTx.posInicial(1)], [strRadarTx.posInicial(3),0],'--b')
plot([strRadarRx.posInicial(1), rangeMinRx(1) + strRadarRx.posInicial(1)], [strRadarRx.posInicial(3),0],'--r')
plot([strRadarRx.posInicial(1), rangeMaxRx(1) + strRadarRx.posInicial(1)], [strRadarRx.posInicial(3),0],'--r')
hold off
grid on
xlabel('x')
ylabel('z')
title("Cobertura (front view)")
grid minor

end