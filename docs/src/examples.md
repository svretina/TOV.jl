# Examples

## Mass-Radius Sequence

Generating a Mass-Radius curve (M-R) allows you to study the stability of a given EOS family.

```julia
using TOV
using CairoMakie

# Define a Piecewise Polytrope (Read et al. 2009 parameterization usually)
# Here we use a simple toy model
rho_b = [1e-4, 5e-4, 1e-3]
Gammas = [2.0, 3.0, 2.8, 2.5]
K_low = 100.0

eos = PiecewisePolytrope(rho_b, Gammas, K_low)

# Define a density range for the core
rho_range =range(1.0e-4, 5.0e-3, length=50)

# Solve the sequence
seq = solve_sequence(eos, rho_range)

# Plot the M-R curve
f = plot(seq)
save("mr_sequence.png", f)
```
