clc
clear
% close all

% Load analisis energia matlab  en formato csv: analisis_energia_matlab.csv
matlab_data = readtable('analisis_energia_matlab.csv');

amplitud_last_m = abs(complex(matlab_data.Data_Last_Real,matlab_data.Data_Last_Imag));
amplitud_next_m = abs(complex(matlab_data.Data_Next_Real,matlab_data.Data_Next_Imag));

index_last_m    = matlab_data.Index_Last;
index_next_m    = matlab_data.Index_Next;

% Load analisis energia c++ en formarto csv: analisis_energia_c++.csv
cpp_data = readtable('analisis_energia_c++.csv');

amplitud_last_c = cpp_data.Amplitud_Last;
amplitud_next_c = cpp_data.Amplitud_Next;

index_last_c    = cpp_data.Indice_Rango_Last;
index_next_c    = cpp_data.Indice_Rango_Next;

figure;

subplot(2,1,1);
plot(amplitud_last_m,'b-o','DisplayName','Matlab');
hold on;
plot(amplitud_last_c,'r-s','DisplayName','C++');
title('Comparación de Amplitud Last');
xlabel('Muestra');
ylabel('Amplitud Last');
legend;
grid on;

subplot(2,1,2);
plot(amplitud_next_m,'b-o','DisplayName','Matlab');
hold on;
plot(amplitud_next_c,'r-s','DisplayName','C++');
title('Comparación de Amplitud Next');
xlabel('Muestra');
ylabel('Amplitud Next');
legend;
grid on;

% Diferencia entre Matlab y C++

diff_last = amplitud_last_m - amplitud_last_c;
diff_next = amplitud_next_m - amplitud_next_c;
figure; 
subplot(2,1,1);
plot(diff_last,'k-','DisplayName','Diferencia Last (Matlab - C++)');
title('Diferencia de Amplitud Last entre Matlab y C++');
xlabel('Muestra');
ylabel('Diferencia Amplitud Last');
legend;
grid on;
subplot(2,1,2);
plot(diff_next,'k-','DisplayName','Diferencia Next (Matlab - C++)');
title('Diferencia de Amplitud Next entre Matlab y C++');
xlabel('Muestra');
ylabel('Diferencia Amplitud Next');
legend;
grid on;

% Plot indices 
figure;
subplot(2,1,1);
plot(index_last_m,'b-o','DisplayName','Matlab');
hold on;
plot(index_last_c+1,'r-s','DisplayName','C++');
title('Comparación de Índice Last');
xlabel('Muestra');
ylabel('Índice Last');
legend;
grid on;
subplot(2,1,2);
plot(index_next_m,'b-o','DisplayName','Matlab');
hold on;
plot(index_next_c+1,'r-s','DisplayName','C++');
title('Comparación de Índice Next');
xlabel('Muestra');
ylabel('Índice Next');
legend;
grid on;

