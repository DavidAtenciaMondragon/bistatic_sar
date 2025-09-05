import requests
import rasterio
from rasterio.plot import show
import numpy as np
import matplotlib.pyplot as plt
import math

def descargar_dem_region(lat_center, lon_center, width_km=1, height_km=1):
    """
    Descarga y visualiza un Modelo de Elevación Digital (DEM) para una región rectangular.

    Args:
        lat_center (float): Latitud del punto central.
        lon_center (float): Longitud del punto central.
        width_km (float): Ancho del rectángulo en kilómetros (dirección Este-Oeste).
        height_km (float): Alto del rectángulo en kilómetros (dirección Norte-Sur).
    """
    
    # --- 1. Configurar tu clave de API ---
    API_KEY = "200620c6a9992f123a1220c4cf454453"
    
    # --- 2. Calcular los límites geográficos (Bounding Box) ---
    print(f"📍 Coordenadas centrales: Lat={lat_center}, Lon={lon_center}")
    print(f"📐 Dimensiones solicitadas: {width_km} km de ancho x {height_km} km de alto.")
    
    # Conversión aproximada de kilómetros a grados
    km_per_deg_lat = 111.32
    km_per_deg_lon = 111.32 * math.cos(math.radians(lat_center))
    
    lat_offset = (height_km / 2) / km_per_deg_lat
    lon_offset = (width_km / 2) / km_per_deg_lon

    south = lat_center - lat_offset
    north = lat_center + lat_offset
    west = lon_center - lon_offset
    east = lon_center + lon_offset

    print("🗺️  Calculando límites del área...")
    print(f"    Norte: {north:.4f}, Sur: {south:.4f}")
    print(f"    Este: {east:.4f}, Oeste: {west:.4f}")

    # --- 3. Construir y ejecutar la petición a la API ---
    api_url = "https://portal.opentopography.org/API/globaldem"
    dem_type = 'SRTMGL1'
    resolution_m = 30 
    
    params = {
        'demtype': dem_type,
        'south': south,
        'north': north,
        'west': west,
        'east': east,
        'outputFormat': 'GTiff',
        'API_Key': API_KEY
    }
    
    print(f"\n🛰️  Contactando la API de OpenTopography para un DEM '{dem_type}'...")
    
    try:
        response = requests.get(api_url, params=params)
        response.raise_for_status()
        
        # --- 4. Generar nombre de archivo dinámico y guardar ---
        
        # ⭐ CAMBIO CLAVE: Formatear coordenadas para el nombre, reemplazando '.' por '_'
        lat_str = f"{lat_center:.4f}".replace('.', '_')
        lon_str = f"{lon_center:.4f}".replace('.', '_')
        
        output_filename = (
            f"DEM_{width_km}x{height_km}km_"
            f"Res{resolution_m}m_"
            f"Lat{lat_str}_Lon{lon_str}.tif"
        )
        
        with open(output_filename, 'wb') as f:
            f.write(response.content)
            
        print(f"✅ ¡Descarga completada! Archivo guardado como '{output_filename}'")

        # --- 5. Leer y visualizar el archivo GeoTIFF ---
        with rasterio.open(output_filename) as src:
            elevation_data = src.read(1)
            nodata_value = src.nodata
            if nodata_value is not None:
                elevation_data = np.where(elevation_data == nodata_value, np.nan, elevation_data)
            
            fig, ax = plt.subplots(1, 1, figsize=(10, 8))
            img = ax.imshow(elevation_data, cmap='terrain')
            cbar = fig.colorbar(img, ax=ax, shrink=0.7)
            cbar.set_label('Elevación (m)')
            
            ax.set_title(f'Modelo de Elevación Digital ({dem_type}) - {width_km}km x {height_km}km')
            ax.set_xlabel('Píxeles (Longitud)')
            ax.set_ylabel('Píxeles (Latitud)')
            
            plt.show()

    except requests.exceptions.RequestException as e:
        print(f"❌ Error al descargar los datos: {e}")
    except Exception as e:
        print(f"❌ Ocurrió un error inesperado: {e}")


# --- CONFIGURACIÓN PRINCIPAL ---
if __name__ == '__main__':
    latitud_central  = -3.615965 
    longitud_central = -80.455181
    
    ancho_deseado_km = 1
    alto_deseado_km = 1
    
    descargar_dem_region(
        latitud_central, 
        longitud_central, 
        width_km=ancho_deseado_km, 
        height_km=alto_deseado_km
    )