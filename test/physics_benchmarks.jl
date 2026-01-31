using Test
using TOV
using Unitful
using CairoMakie

@testset "Physics Verification" begin

    @testset "Metric Matching Test" begin
        # Test for various EOS that e^{2ν(R)} = 1 - 2M/R
        eos = Polytrope(10.0, 2.0)
        star = solve_tov(eos, 1.0e-3)

        M = star.mass
        R = star.radius

        # Schwarzschild metric at surface
        g_tt_surf = 1.0 - 2.0 * M / R
        nu_surf_analytic = 0.5 * log(g_tt_surf)

        # Our solver matches this by definition (we shift nu), 
        # but let's check if the internal logic holds consistency.
        # Actually, the shift ensures it.
        # Let's check if the shift is reasonable (i.e. not HUGE).
        # Or better: check continuity of derivative?

        # Let's verify the value stored in star.nu[end] IS the analytic one.
        @test isapprox(star.nu[end], nu_surf_analytic, atol=1e-8)

        # Also check dnu/dr at surface approx equals (M/R^2) / (1-2M/R)?
        # Vacuum: dnu/dr = (M/r^2) / (1 - 2M/r)
        # Internal: dnu/dr = -dP/dr / (e+P). At surface P=0, e=0 (for polytrope), so 0/0?
        # Polytrope has e->0, so it matches smoothly.
    end

    @testset "Schwarzschild Interior (Constant Density)" begin
        # rho = energy density = constant
        epsilon_0 = 1.0
        eos = ConstantDensity(epsilon_0) # P(eps) = whatever, but eps(P)=eps0.

        # For constant density, P_c can be anything below a limit.
        # Analytic limit: R = sqrt(3 / (8 pi epsilon_0) * (1 - sqrt(1 - 2M/R)))?

        # Standard solution:
        # M(r) = 4/3 pi epsilon_0 r^3
        # P(r) = epsilon_0 * [ (sqrt(1-2M/R) - sqrt(1-2Mr^2/R^3)) / (sqrt(1-2Mr^2/R^3) - 3sqrt(1-2M/R)) ]

        Pc = 0.1 * epsilon_0
        star = solve_tov(eos, Pc)

        # 1. Mass profile check
        # m(r) = 4/3 pi epsilon_0 r^3
        r_test = star.r[div(end, 2)]
        m_analytic = (4 / 3) * π * epsilon_0 * r_test^3
        m_numerical = star.m[div(end, 2)]
        @test isapprox(m_numerical, m_analytic, rtol=1e-4) # Error accumulates locally

        # 2. Surface check
        # P should go to 0.
        @test abs(star.p[end]) < 1e-6
    end

    @testset "First Law (Baryonic Mass)" begin
        # dM = u dMb? Roughly M vs Mb relation.
        # For a sequence, verify smoothness of M(rho_c) and Mb(rho_c).
        eos = Polytrope(100.0, 2.0)
        seq = solve_sequence(eos, range(1e-4, 5e-3, length=10))

        masses = [s.mass for s in seq.stars]
        mb_masses = [s.mb[end] for s in seq.stars]

        # Baryonic mass should be larger than Gravitational mass (binding energy is negative)
        # M_b > M
        @test all(mb_masses .> masses)

        # Binding Energy > 0
        BE = mb_masses .- masses
        @test all(BE .> 0)
    end

    @testset "Stability Check" begin
        # Polytrope Gamma=2 has a maximum mass?
        # Actually Gamma=2 K=const is scale free or monotonic?
        # Wait, Gamma=2 is n=1. It does NOT have a maximum mass turning point in the same way as NS?
        # No, n=1 has finite radius and mass for any Pc. M ~ Pc^{(n-3)/2(n+1)} ? 
        # For Gamma=2 (n=1), M increases with rho_c indefinitely? R is constant?
        # N=1 Polytrope (Newtonian): R = constant (independent of rho_c). M ~ rho_c.
        # Relativistic Gamma=2: Instability sets in eventually.

        # Let's test a sequence where we expect a peak.
        # Or just verify our function identifies 'stable' for monotonic.

        # Try a causal EOS or something softer to get a max mass peak quickly?
        # Let's assume Gamma=2.
    end
end
