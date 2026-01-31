using TOV
using CairoMakie

# Define a Polytrope EOS (n=1, gamma=2)
# K = 100 in geometric units roughly corresponds to some nuclear stiffness
# For simple test, let's pick K=100.
eos = Polytrope(100.0, 2.0)

# Solve for a single star
pc = 1.0e-3 # Central pressure
println("Solving for Pc = $pc")
star = solve_tov(eos, pc)
println(star)

# Plot dashboard
f1 = Makie.plot(star)
save("star_dashboard.png", f1, px_per_unit=3)

# Generate Sequence
println("Generating Sequence...")
rho_range = range(1e-4, 5e-3, length=10)
seq = solve_sequence(eos, rho_range)

# Plot M-R
f2 = Makie.plot(seq)
save("mr_curve.png", f2, px_per_unit=3)

println("Verification Complete!")
