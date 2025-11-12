function outputData = proc_fermat_run(rcompData,strRadarTx,strGridToProc,strEnvironment,strDEM,Tx,Rx)

f_interp     = uint8(5);
c            = physconst('LightSpeed');
threshold    = 1e-11;
bPlotVerbose = false;

%% Preproc 

[Nazm,~] = size(rcompData);
fs       = strRadarTx.fs;

%% Processamiento 

[X,Y,Z] = meshgrid(strGridToProc.xAxis,strGridToProc.yAxis,strGridToProc.zAxis);

X = X(1:5);
Y = Y(1:5);
Z = Z(1:5);

outputData = complex(zeros(size(X)));

for m = 1:numel(X)
    
    if coder.target('MATLAB')
        fprintf('--- PROCESANDO %d de %d ---\n', m, numel(X));
    end
    
    P  = [X(m),Y(m),Z(m)];
    n1 = strEnvironment.n1;
    n2 = strEnvironment.n2;
    
    strRefraccoes.P_refrac_ida   = randn(3,size(Tx,1))+5 + 10;
    strRefraccoes.P_refrac_ida(3,:) = 0;
    strRefraccoes.P_refrac_volta = randn(3,size(Tx,1))+5 + 10;
    strRefraccoes.P_refrac_volta(3,:) = 0;
        
    % Slant range calculation
%     tic
%     [strReflexao, strRefraccoes] = calculaSlantRangeFermat(strDEM,Tx,Rx,P,n1,n2,bPlotVerbose);
%     toc 
    
    % Matrix-based distance calculation - fixed for current azimuth processing
    % For current azimuth index (assuming azimuth loop), take current Tx/Rx positions
    % If processing all azimuths at once, need to adapt accordingly
    
    % Convert refraction points to [Mx3] format 
    P_refrac_ida_T = strRefraccoes.P_refrac_ida.';      % [Mx3]
    P_refrac_volta_T = strRefraccoes.P_refrac_volta.';  % [Mx3]
    
    % Calculate distances efficiently using pdist2
    % For current point P [1x3] to all refraction points
    R2t = pdist2(P, P_refrac_ida_T);                    % [1xM]
    R2r = pdist2(P, P_refrac_volta_T);                  % [1xM]
    
    % For Tx/Rx processing - sum over all azimuth positions or use specific ones
    % Method 1: Use mean distances (if processing target from all perspectives)
    R1t = mean(pdist2(Tx, P_refrac_ida_T), 1);         % [1xM] - mean over all Tx
    R1r = mean(pdist2(Rx, P_refrac_volta_T), 1);       % [1xM] - mean over all Rx
    
    % Alternative Method 2: Use closest distances (uncomment if preferred)
    % R1t = min(pdist2(Tx, P_refrac_ida_T), [], 1);    % [1xM] - min distance
    % R1r = min(pdist2(Rx, P_refrac_volta_T), [], 1);  % [1xM] - min distance
    
    % Note: R1t, R2t, R1r, R2r are now [1xM] vectors, no need to transpose
    
    % Fractional range bin sample
    t      = (1/c)*(n1*R1t + n2*R2t + n2*R2r + n1*R1r);
    rngBin = 1 + round(t*fs);
    
    % Phase compensation term
    phi = (2*pi/strRadarTx.lamb)*(n1*R1t + n2*R2t + n2*R2r + n1*R1r);

    % Linear interpolation
    lastIND = sub2ind(size(rcompData),(1:Nazm),floor(rngBin));
    nextIND = sub2ind(size(rcompData),(1:Nazm),ceil(rngBin));
    
    q       = rngBin - lastIND;
    interp  = (1-q).*rcompData(lastIND) + q.*rcompData(nextIND);
    
    % Data accumulation
    outputData(m) = sum(interp.*exp(1i*phi));

    % Mostrar log com fprintf - Mostrar posicao do Tx, Rx, Pm 
    if coder.target('MATLAB')
        fprintf('Tx: [%f, %f, %f], Rx: [%f, %f, %f], Pm: [%f, %f, %f]\n', ...
            Tx(1), Tx(2), Tx(3), Rx(1), Rx(2), Rx(3), P(1), P(2), P(3));
    end

    % strRefracoes tanto ida como volta para posicoes 
    if coder.target('MATLAB')
        idxToShow = [1,50,100,150,200,250];
        for idx = 1:numel(idxToShow)
            fprintf('Refracoes %d: P_refrac_ida: [%f, %f, %f], P_refrac_volta: [%f, %f, %f]\n', ...
                idx, strRefraccoes.P_refrac_ida(1,idx), strRefraccoes.P_refrac_ida(2,idx), strRefraccoes.P_refrac_ida(3,idx), ...
                strRefraccoes.P_refrac_volta(1,idx), strRefraccoes.P_refrac_volta(2,idx), strRefraccoes.P_refrac_volta(3,idx));
        end
    end 

    disp("------------------------------------------------------------------------")

    % Mostrar distancias R1t, R2t, R1r, R2r
%     if coder.target('MATLAB')
%         fprintf('R1t: %f, R2t: %f, R1r: %f, R2r: %f\n', R1t, R2t, R1r, R2r);
%     end

%     waitbar(m/numel(X),wb,'Ejecutando algoritmo Back-Projection...');
end

end