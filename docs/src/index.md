# TOV.jl

```@raw html
<img src="assets/logo.svg" width="200" alt="TOV.jl Logo">
```

Welcome to the documentation for **TOV.jl**, a high-performance Julia library for solving the **Tolman-Oppenheimer-Volkoff (TOV)** equations. This library is designed for research in **Equation of State (EOS)** constraints and **Numerical Relativity** initial data.

## Features

- **Modular EOS Architecture**: Support for Polytropes, Piecewise Polytropes, and Tabulated EOS.
- **Rigorous Solver**: Automatic surface detection, metric matching, and thermodynamic consistency.
- **Diagnostics**: Built-in causality checks ($c_s \le 1$) and stability analysis ($dM/d\rho_c$).
- **Visualization**: Integration with `CairoMakie` for publication-quality plots.

## Quick Start

```julia
using TOV

# Define an Equation of State (Polytrope K=100, Gamma=2)
eos = Polytrope(100.0, 2.0)

# Solve for a single star with central pressure P_c = 1.0e-3
star = solve_tov(eos, 1.0e-3)

# Inspect the result
println("Mass: $(star.mass) M⊙")
println("Radius: $(star.radius * 1.4766) km") # 1.4766 is L_geom_km conversion implicit in TOV.Constants if used

# Plot the structure
using CairoMakie
f = plot(star)
```

## Installation

```julia
using Pkg
Pkg.add(url="https://github.com/svretina/TOV.jl")
```
