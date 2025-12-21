import numpy as np
import matplotlib.pyplot as plt 
from mpl_toolkits.mplot3d import Axes3D

def crear_padrao_radiacao(abertura_el=70, abertura_az=20):
    """
    Crea un patrón de radiación con aberturas específicas
    
    Parámetros:
    abertura_el - Abertura en elevación (grados) [por defecto: 70°]
    abertura_az - Abertura en azimut (grados) [por defecto: 20°]
    
    Retorna:
    padrao - Matriz 181x181 con patrón de radiación normalizado
             Filas: elevación de -90° a +90°
             Columnas: azimut de -90° a +90°
    """
    
    # Crear vectores de ángulos de -90° a +90°
    angulos = np.arange(-90, 91, 1)  # 181 puntos
    
    # Crear matrices de coordenadas
    az_grid, el_grid = np.meshgrid(angulos, angulos)
    
    # Calcular el ancho del haz a -3dB (half-power beamwidth)
    ancho_el_3db = abertura_el / 2  # ±35° desde el centro
    ancho_az_3db = abertura_az / 2  # ±10° desde el centro
    
    # Parámetro de forma para gaussiana (ajustado para -3dB en los límites)
    sigma_el = ancho_el_3db / np.sqrt(2 * np.log(2))
    sigma_az = ancho_az_3db / np.sqrt(2 * np.log(2))
    
    # Patrón de radiación gaussiano separable
    patron_el = np.exp(-(el_grid**2) / (2 * sigma_el**2))
    patron_az = np.exp(-(az_grid**2) / (2 * sigma_az**2))
    
    # Combinar patrones (producto de funciones separables)
    padrao = patron_el * patron_az
    
    # Normalizar a 1 (0 dB en el máximo)
    padrao = padrao / np.max(padrao)
    
    # Información de salida
    print(f'Patrón de radiación creado:')
    print(f'  Abertura elevación: {abertura_el:.1f}°')
    print(f'  Abertura azimut: {abertura_az:.1f}°')
    print(f'  Ancho de haz -3dB elevación: ±{ancho_el_3db:.1f}°')
    print(f'  Ancho de haz -3dB azimut: ±{ancho_az_3db:.1f}°')
    print(f'  Matriz de salida: {padrao.shape[0]}x{padrao.shape[1]}')
    print(f'  Rango angular: -90° a +90° (1° por muestra)')
    
    return padrao

# Parámetros de la trayectoria
radio = 100  # metros
altura = 120  # metros
num_puntos = 100

# Generar ángulos de 0 a 2π
angulos = np.linspace(0, 2*np.pi, num_puntos)

# Calcular coordenadas cartesianas
x = radio * np.cos(angulos)
y = radio * np.sin(angulos)
z = np.full_like(x, altura)

# Visualizar en 3D
fig = plt.figure(figsize=(10, 8))
ax = fig.add_subplot(111, projection='3d')

ax.plot(x, y, z, 'b-', linewidth=2, label='Trayectoria')
ax.scatter(x[0], y[0], z[0], color='green', s=100, label='Inicio')
ax.set_xlabel('X (metros)')
ax.set_ylabel('Y (metros)')
ax.set_zlabel('Z (metros)')
ax.set_title(f'Trayectoria Circular (R={radio}m, H={altura}m)')
ax.legend()
ax.grid(True)

plt.show()

print(f"Trayectoria generada: {len(x)} puntos")
print(f"Radio: {radio}m, Altura: {altura}m")

# Llamar la función del patrón de radiación
print("\n" + "="*50)
padrao = crear_padrao_radiacao(70, 20)