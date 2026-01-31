module Solver

using OrdinaryDiffEq
using ..EOS
using DataInterpolations

export Star
export solve_tov

"""
    Star{T}

Structuring containing the definition and solution of a relativistic star.
"""
struct Star{T<:Real,E<:AbstractEOS}
    eos::E
    central_pressure::T
    mass::T
    radius::T

    # Profiles
    r::Vector{T}
    p::Vector{T}
    epsilon::Vector{T}
    m::Vector{T}
    mb::Vector{T} # Baryonic mass profile
    nu::Vector{T} # Metric potential (g_tt = -e^{2nu})
end

function Base.show(io::IO, star::Star)
    print(io, "Star(M=$(star.mass), R=$(star.radius), P_c=$(star.central_pressure))")
end

#=
State vector u:
u[1] = Pressure P
u[2] = Mass m
u[3] = Metric potential nu (relative)
u[4] = Baryonic Mass mb
=#

function tov_rhs!(du, u, p, r)
    P, m, nu, mb = u
    eos = p.eos

    # 1. Get epsilon from EOS
    # We need to protect against negative P which can happen during search
    if P <= 0
        du[1] = 0
        du[2] = 0
        du[3] = 0
        du[4] = 0
        return
    end

    ϵ = eos_ϵ_from_P(eos, P)
    ρ0 = eos_ρ0_from_P(eos, P)

    # 2. TOV equations
    # dP/dr = - (ϵ + P) * (m + 4πr^3 P) / (r(r - 2m))
    # dm/dr = 4πr^2 ϵ
    # dν/dr = - (dP/dr) / (ϵ + P)

    coeff = -(ϵ + P)
    num = m + 4 * π * r^3 * P
    den = r * (r - 2 * m)

    dP_dr = coeff * num / den

    du[1] = dP_dr
    du[2] = 4 * π * r^2 * ϵ
    du[3] = -dP_dr / (ϵ + P)

    # Baryonic mass evolution
    # dmb/dr = 4πr^2 ρ0 / sqrt(1 - 2m/r)
    # Protected sqrt if 2m/r > 1 (black hole / error)
    metric_factor = sqrt(max(0.0, 1.0 - 2.0 * m / r))
    if metric_factor > 0
        du[4] = 4 * π * r^2 * ρ0 / metric_factor
    else
        du[4] = 0.0 # Should not happen in stable star
    end
end

function tov_rhs_taylor(eos, Pc, r)
    # Approximate derivatives near r=0
    # m ~ 4/3 π ϵ_c r^3  => dm/dr = 4π r^2 ϵ_c
    # P ~ Pc - 2/3 π (ϵ_c + Pc)(ϵ_c + 3Pc) r^2 => dP/dr = -4/3 π (ϵ_c+Pc)(ϵ_c+3Pc) r
    ϵ_c = eos_ϵ_from_P(eos, Pc)

    dP_dr = -(4 / 3) * π * (ϵ_c + Pc) * (ϵ_c + 3 * Pc) * r
    dm_dr = 4 * π * r^2 * ϵ_c
    dnu_dr = -dP_dr / (ϵ_c + Pc)

    # Baryonic mass approx
    # Metric factor 1 - m/r ~ 1.
    ρ0_c = eos_ρ0_from_P(eos, Pc)
    dmb_dr = 4 * π * r^2 * ρ0_c

    return [dP_dr, dm_dr, dnu_dr, dmb_dr]
end

"""
    solve_tov(eos::AbstractEOS, P_c::Real; r_init=1e-8, r_max=100.0)

Solve the TOV equations for a given EOS and central pressure.
"""
function solve_tov(eos::AbstractEOS, P_c::Real; r_init=1.0e-8, r_max=1000.0)
    T = typeof(P_c)

    # Verify P_c is physical
    if P_c <= 0
        error("Central pressure must be positive")
    end

    # Initial conditions at r_init using Taylor expansion
    ϵ_c = eos_ϵ_from_P(eos, P_c)
    ρ0_c = eos_ρ0_from_P(eos, P_c)

    # P(r) approx P_c - ...
    # m(r) approx 4/3 pi e_c r^3
    # nu(r) = 0 (we will shift later)

    P_init = P_c - (2 / 3) * π * (ϵ_c + P_c) * (ϵ_c + 3 * P_c) * r_init^2
    m_init = (4 / 3) * π * ϵ_c * r_init^3
    nu_init = 0.0 # arbitrary start
    mb_init = (4 / 3) * π * ρ0_c * r_init^3

    u0 = [P_init, m_init, nu_init, mb_init]
    tspan = (r_init, r_max)

    # Parameters provided to RHS
    p = (eos=eos,)

    # Callbacks for surface detection (P = 0)
    # We trigger when P (u[1]) crosses 0
    condition(u, t, integrator) = u[1]
    affect!(integrator) = terminate!(integrator)
    cb = ContinuousCallback(condition, affect!)

    prob = ODEProblem(tov_rhs!, u0, tspan, p)

    # Solve with high precision
    sol = solve(prob, Tsit5(), callback=cb, reltol=1e-8, abstol=1e-8)

    # Extract results
    r = sol.t
    P = sol[1, :]
    m = sol[2, :]
    nu_raw = sol[3, :]
    mb = sol[4, :]

    # Final values (Surface)
    R_surf = r[end]
    M_surf = m[end]

    # Shift metric potential to match Schwarzschild at surface
    # e^{2ν(R)} = 1 - 2M/R
    # 2ν(R) = ln(1 - 2M/R)
    # ν(R) = 0.5 * ln(1 - 2M/R)
    # correction = ν_true(R) - ν_raw(R)

    if R_surf > 2 * M_surf
        ν_surf_true = 0.5 * log(1 - 2 * M_surf / R_surf)
        correction = ν_surf_true - nu_raw[end]
        nu = nu_raw .+ correction
    else
        # Blacked hole? or error.
        # Just return raw if failed
        nu = nu_raw
        @warn "Surface radius is less than Schwarzschild radius! (R=$R_surf, 2M=$(2M_surf))"
    end

    # Calculate epsilon profile
    # We can re-evaluate EOS or store it. Re-eval involves loop.
    epsilon = [eos_ϵ_from_P(eos, press) for press in P]

    return Star(eos, P_c, M_surf, R_surf, r, P, epsilon, m, mb, nu)
end

end # module
