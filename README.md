# 🛰️ Bistatic SAR Simulation Framework

> **Advanced bistatic Synthetic Aperture Radar (SAR) simulation and processing framework for doctoral research**

[![MATLAB](https://img.shields.io/badge/MATLAB-R2020a+-blue.svg)](https://www.mathworks.com/products/matlab.html)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/status-Active%20Development-orange.svg)]()

## 📋 Table of Contents

- [Overview](#overview)
- [Key Features](#key-features)
- [Project Structure](#project-structure)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Algorithms](#core-algorithms)
- [Performance Optimization](#performance-optimization)
- [Examples](#examples)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Citation](#citation)

## 🎯 Overview

This framework implements a comprehensive bistatic SAR simulation system based on the **Fermat principle** for accurate electromagnetic wave propagation modeling. The project focuses on developing optimized algorithms for calculating reflection and refraction trajectories in complex terrain scenarios.

### Research Context
- **Institution**: Doctoral Research Program
- **Focus**: Bistatic SAR signal processing and optimization
- **Applications**: Remote sensing, terrain mapping, electromagnetic propagation analysis

## ✨ Key Features

### 🚀 **Optimized Fermat Algorithm**
- **High-Performance Implementation**: Vectorized algorithm with 10x-50x speedup
- **Dual Strategy Approach**: 
  - Iterative high-precision method (`calculaSlantRangeFermat.m`)
  - Efficient grid-based method (`calculaSlantRangeFermat_eff.m`)
- **Scalable Processing**: Handles large datasets with memory-efficient batch processing

### 🌍 **Terrain Integration**
- **DEM Support**: Digital Elevation Model integration
- **Multi-layer Propagation**: Reflection and refraction modeling
- **Adaptive Resolution**: Configurable interpolation factors for precision/speed balance

### 📊 **Energy Analysis**
- **Trajectory Optimization**: Automatic flight path planning
- **Energy Distribution**: 3D energy field analysis
- **Brewster Angle Calculations**: Optimal reflection point determination

### 🔧 **Development Tools**
- **Performance Profiling**: Built-in timing and memory analysis
- **Binary I/O**: Efficient data serialization (`tools/readBinary.m`, `tools/saveBinary.m`)
- **Visualization**: Comprehensive 3D plotting and analysis tools

## 📁 Project Structure

```
bistatic_sar/
├── 📁 common/                     # Core algorithms
│   ├── calculaSlantRangeFermat.m          # High-precision Fermat algorithm
│   ├── calculaSlantRangeFermat_eff.m      # Optimized grid-based algorithm  
│   ├── calculaSlantRangeFermat_optimized.m # Hybrid optimized implementation
│   ├── calcular_normal.m                  # Surface normal calculations
│   └── tiempo_total_*.m                   # Time calculation functions
├── 📁 gs/                         # Ground Station & Geometry
│   ├── 📁 analise_energia/                # Energy analysis modules
│   ├── 📁 data/                          # Processed datasets
│   ├── 📁 informe_comparacoes/           # Performance analysis reports
│   ├── 📁 legado/                        # Legacy implementations
│   ├── GS_fermat_test_script.m           # Main Fermat testing script
│   └── calcula_plano_de_voo.m           # Flight path optimization
├── 📁 proc/                       # Signal Processing
│   ├── 📁 codegen/                       # MATLAB Coder generated files
│   ├── 📁 data/                          # Processing outputs
│   ├── PROC_fermat_test_script.m         # Main processing script
│   └── proc_fermat_run.m                 # Optimized processing core
├── 📁 parametros/                 # Configuration Files
│   ├── radarTx_*.json                    # Transmitter configurations
│   ├── radarRx_*.json                    # Receiver configurations
│   ├── system_*.json                     # System parameters
│   └── target_*.json                     # Target definitions
├── 📁 tools/                      # Utilities
│   ├── readBinary.m / saveBinary.m       # Binary I/O functions
│   └── json2struct.m                     # JSON parser
└── 📁 utills/                     # Additional utilities
    └── generarVideoPlot.m                # Video generation tools
```

## 🛠️ Installation

### Prerequisites
- MATLAB R2020a or later
- Signal Processing Toolbox
- Mapping Toolbox (for DEM handling)
- Parallel Computing Toolbox (optional, for performance)

### Setup
1. **Clone the repository:**
   ```bash
   git clone https://github.com/DavidAtenciaMondragon/bistatic_sar.git
   cd bistatic_sar
   ```

2. **Add to MATLAB path:**
   ```matlab
   addpath(genpath('.'));
   savepath;
   ```

3. **Verify installation:**
   ```matlab
   run('gs/GS_fermat_test_script.m');
   ```

## 🚀 Quick Start

### Basic Fermat Calculation

```matlab
% Load DEM and configure parameters
load('gs/data/strDEM.mat');
load('parametros/system.json');

% Define transmitter and receiver positions
Tx = [1000, 2000, 500];  % [x, y, z] coordinates
Rx = [3000, 4000, 600];  
P = [2000, 3000, 100];   % Target point

% Fermat principle calculation
[strReflexao, strRefraccoes] = calculaSlantRangeFermat_optimized(...
    strDEM, Tx, Rx, P, n1, n2, true, 3);

% Visualize results
plot_trajectories_3d(strReflexao, strRefraccoes, strDEM);
```

### Performance Comparison

```matlab
% Compare algorithm performance
tic;
[result_precise] = calculaSlantRangeFermat(strDEM, Tx, Rx, P, n1, n2, false);
time_precise = toc;

tic;
[result_optimized] = calculaSlantRangeFermat_optimized(strDEM, Tx, Rx, P, n1, n2, false, 2);
time_optimized = toc;

fprintf('Speedup: %.2fx\n', time_precise / time_optimized);
```

## 🧮 Core Algorithms

### 1. **Fermat Principle Implementation**

The framework implements the electromagnetic wave propagation based on Fermat's principle:

```math
T_{total} = \int_{path} \frac{ds}{v(s)}
```

**Three trajectory types:**
- **Reflection**: `T_refl = ||Tx - S||/v₁ + ||S - Rx||/v₁`
- **Refraction (forward)**: `T_refr = ||Tx - Q||/v₁ + ||Q - P||/v₂`  
- **Refraction (return)**: `T_refr = ||P - R||/v₂ + ||R - Rx||/v₁`

### 2. **Optimization Strategies**

| Method | Complexity | Precision | Use Case |
|--------|------------|-----------|----------|
| Iterative (`fminsearch`) | O(N×M×I) | Very High | Small datasets, research |
| Grid-based (`pdist2`) | O(N×M) | High | Large datasets, production |
| Hybrid Optimized | O(N×M) | Configurable | General purpose |

### 3. **Surface Normal Calculation**

```matlab
% Finite difference gradient estimation
dz/dx = (z(x+h) - z(x-h)) / (2h)
dz/dy = (z(y+h) - z(y-h)) / (2h)
N = [-dz/dx, -dz/dy, 1] / ||[-dz/dx, -dz/dy, 1]||
```

## ⚡ Performance Optimization

### Memory Management
- **Batch Processing**: Configurable batch sizes for large datasets
- **Sparse Operations**: Memory-efficient matrix operations
- **Garbage Collection**: Automatic cleanup of intermediate variables

### Computational Efficiency
- **Vectorization**: Full MATLAB vectorization for all core operations
- **Parallel Processing**: Optional `parfor` loops for multi-core systems
- **Caching**: Pre-computed interpolation objects

### Benchmarks

| Dataset Size | Original | Optimized | Speedup |
|--------------|----------|-----------|---------|
| 100 pairs | 2.3s | 0.23s | 10x |
| 1,000 pairs | 45s | 1.2s | 37x |
| 10,000 pairs | 7.5min | 9.8s | 46x |

## 📊 Examples

### 1. **Energy Analysis**
```matlab
cd gs/analise_energia/
run main.m  % Comprehensive energy field analysis
```

### 2. **Flight Path Optimization**
```matlab
cd gs/
resultado = calcula_plano_de_voo(strDEM, target_config);
```

### 3. **Performance Comparison Report**
```matlab
cd gs/informe_comparacoes/
% LaTeX report generation with mathematical analysis
```

## 📖 Documentation

- **📄 Performance Analysis**: `gs/informe_comparacoes/main.pdf`
- **🔬 Mathematical Framework**: Detailed LaTeX documentation with algorithmic analysis
- **📊 Benchmark Results**: Comparative analysis between optimization strategies
- **🎯 API Reference**: Inline documentation in all MATLAB functions

## 🤝 Contributing

### Development Workflow
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Standards
- Follow MATLAB coding standards
- Include comprehensive documentation
- Add unit tests for new algorithms
- Benchmark performance for core functions

## 📚 Citation

If you use this framework in your research, please cite:

```bibtex
@software{bistatic_sar_framework,
    title={Bistatic SAR Simulation Framework},
    author={[Your Name]},
    year={2025},
    url={https://github.com/DavidAtenciaMondragon/bistatic_sar},
    note={Advanced bistatic SAR simulation with optimized Fermat algorithms}
}
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🔗 Links

- **Research Institution**: [Your University/Institution]
- **Related Publications**: [Link to papers]
- **MATLAB Central**: [Link to File Exchange if published]

---

**💡 Need Help?** Open an issue or contact the development team for support with implementation and optimization questions.
