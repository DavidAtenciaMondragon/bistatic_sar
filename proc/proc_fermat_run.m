function outputData = proc_fermat_run(rcompData,strRadarTx,strGridToProc,strEnvironment,strDEM,Tx,Rx)

f_interp     = uint8(5);
c            = physconst('LightSpeed');
% threshold    = 1e-11;
% bPlotVerbose = false;

%% Preproc 

[Nazm,~] = size(rcompData);
fs       = strRadarTx.fs;

%% Processamiento 

[X,Y,Z] = meshgrid(strGridToProc.xAxis,strGridToProc.yAxis,strGridToProc.zAxis);

outputData = complex(zeros(size(X)));

for m = 1:numel(X)
    
    if coder.target('MATLAB')
        fprintf('--- PROCESANDO %d de %d ---\n', m, numel(X));
    end
    
    P  = [X(m),Y(m),Z(m)];
    n1 = strEnvironment.n1;
    n2 = strEnvironment.n2;
    
    % Slant range calculation
%     [strReflexao, strRefraccoes] = calculaSlantRangeFermat_eff(strDEM,Tx,Rx,P,n1,n2,bPlotVerbose);
    [strReflexao, strRefraccoes] = calculaSlantRangeFermat_eff(strDEM,Tx,Rx,P,n1,n2,f_interp); 
    
    R1t = sqrt(sum((Tx - [strRefraccoes.P_refrac_ida].').^2,2));
    R2t = sqrt(sum((P - [strRefraccoes.P_refrac_ida].').^2,2));
    
    R1r = sqrt(sum((Rx - [strRefraccoes.P_refrac_volta].').^2,2));
    R2r = sqrt(sum((P - [strRefraccoes.P_refrac_volta].').^2,2));
    
    R1t = R1t.';
    R2t = R2t.';
    R1r = R1r.';
    R2r = R2r.';
    
    % Fractional range bin sample
    t = (1/c)*(n1*R1t + n2*R2t + n2*R2r + n1*R1r);
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
    
%     waitbar(m/numel(X),wb,'Ejecutando algoritmo Back-Projection...');
end

end