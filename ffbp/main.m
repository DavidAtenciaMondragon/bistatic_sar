clc
clear 
close all

%% Load data 

load(strcat('..',filesep,'gs',filesep,'data',filesep,'dados.mat'));
load(strcat('..',filesep,'gs',filesep,'data',filesep,'posRadar.mat'));

%% Params FFBP

% Params sistemicos 

c      = 3e8;  % Velocidad de la luz en m/s
fs     = 20e6; % Frecuencia de muestreo en Hz (20 MHz)
numIte = 3;    % Numero de iteracoes  

% Params FFBP 
N_p = size(posRadar,2); % Numero de elementos de apertura en el nodo p_th
L_c = 4;       % Numero de elementos del padre usados para componer una subapertura hijo - longitud de la subapertura 

% M_c = 50;      % Número de muestras en cada subapertura

for i = 1:numIte
    
    if i == 1
       s_p_j = dados; 
       x_p_j = posRadar;
    end
    
    % Paso 1, definir subapertura
    
    N_c   = N_p/L_c; % Numero de elementos de apertura en el nodo hijo c
    
    r     = (0:L_c-1);
    k     = (0:N_c-1).';
    
    J_c_k = k*L_c + r;
    
    % Paso 2, definir centro de fase 
    
    w_p_j_k = ones(1,L_c)/L_c;
    x_c_k   = zeros(size(x_p_j,1),N_c);
    for q = 1:N_c
        x_c_k(:,q) = sum(w_p_j_k.*x_p_j(:,J_c_k(q,:) + 1),2);
    end
    
    % Paso 3, Calcular r_c_k -> Distancia centro de fase, primera muestra
    
    
end

