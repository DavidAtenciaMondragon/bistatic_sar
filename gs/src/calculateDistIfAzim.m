function dist = calculateDistIfAzim(posRadar,strTarget, strRadar)

dist = [];

% Calcular azimute entre target e radarTx
tmpAz = atan2d(strTarget.pos(2) - posRadar(2), strTarget.pos(1) - posRadar(1));

anguloMinBusca = strRadar.Yaw - strRadar.AperturaAzimut/2;
anguloMaxBusca = strRadar.Yaw + strRadar.AperturaAzimut/2;

if angulo_en_rango(tmpAz,anguloMinBusca,anguloMaxBusca)
    
    % Calcula a distância entre o radar e o alvo
    dist = norm(posRadar(:) - strTarget.pos);
    
end

end