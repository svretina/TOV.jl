<p align="center">
  <img src="docs/src/assets/logo.svg" width="300" alt="TOV.jl Logo">
</p>

# TOV.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://svretina.github.io/TOV.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://svretina.github.io/TOV.jl/dev)
[![Build Status](https://github.com/svretina/TOV.jl/workflows/CI/badge.svg)](https://github.com/svretina/TOV.jl/actions)
[![Aqua.jl](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)
[![JET.jl](https://img.shields.io/badge/%F0%9F%9B%A9%EF%B8%8F_tested_with-JET.jl-232f3e)](https://github.com/aviatesk/JET.jl)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

**TOV.jl** is a high-performance Julia library for solving the **Tolman-Oppenheimer-Volkoff (TOV)** equations of relativistic stellar structure. Designed for researchers in **Numerical Relativity** and **Nuclear Astrophysics**, it provides a rigorous, modular framework for constructing and analyzing compact star models.

## Why TOV.jl?

- **Precision & Speed**: Uses `OrdinaryDiffEq.jl` with high-order solvers (Tsit5/Vern7) and callback-based surface detection for numerical precision $\sim 10^{-10}$.
- **Advanced Physics**: 
    - Full support for **Polytropes**, **Piecewise Polytropes**, and **Tabulated EOS** (interpolated).
    - **Baryonic Mass** conservation and **Binding Energy** calculation.
    - **Metric Matching** at the surface for exact Schwarzschild exterior.
- **Diagnostics**: Built-in runtime monitoring for **Causality** ($c_s \le 1$) and **Stability** criteria.
- **Publication Ready**: Integrated plotting with `CairoMakie` producing high-DPI, LaTeX-labeled figures.

## Quick Start

Solve a simple Polytropic star in 3 lines of code:

```julia
using TOV, CairoMakie

# 1. Define EOS (Polytrope K=100, Gamma=2)
eos = Polytrope(100.0, 2.0)

# 2. Solve for a central pressure (dimensionless units G=c=Msun=1)
star = solve_tov(eos, 1.0e-3)

# 3. Visualize
f = plot(star)
save("star.png", f)
```

## Results Gallery

### Stellar Structure Dashboard
Full internal profiles (Pressure, Density, Metric, Sound Speed) are generated automatically.

<p align="center">
  <img src="docs/src/assets/star_dashboard.png" width="800" alt="Star Dashboard">
</p>

### Mass-Radius Relation
Compute sequences to identify stable branches and maximum mass limits.

<p align="center">
  <img src="docs/src/assets/mr_curve.png" width="500" alt="Mass Radius Curve">
</p>

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/svretina/TOV.jl")
```

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines. Use issues to report bugs or request features.

## License

This project is licensed under the [GNU General Public License v3.0](LICENSE).
