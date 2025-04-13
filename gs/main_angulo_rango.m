clc
clear 
close all

angulo = -30;
minimo = 300;
maximo = 60;

if angulo_en_rango(angulo, minimo, maximo)
    disp('El ángulo está dentro del rango.')
else
    disp('El ángulo está fuera del rango.')
end