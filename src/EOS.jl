module EOS

using DataInterpolations

export AbstractEOS
export Polytrope
export PiecewisePolytrope
export TabulatedEOS
export ConstantDensity
export eos_P_from_ρ, eos_ϵ_from_ρ, eos_ρ_from_P, eos_ϵ_from_P
# Explicit alias for rest-mass density
export eos_ρ0_from_P

"""
    AbstractEOS

Abstract supertype for all Equations of State.
By convention in this library:
- `ρ` refers to **rest-mass density** (ρ₀).
- `ϵ` refers to **total energy density**.
- `P` refers to pressure.
"""
abstract type AbstractEOS end

# Wrapper to explicitly get rest-mass density from Pressure
# Default implementation assumes the standard eos_ρ_from_P returns rest-mass density.
@inline eos_ρ0_from_P(eos::AbstractEOS, P::Real) = eos_ρ_from_P(eos, P)

# ==============================================================================
# Polytrope
# ==============================================================================
"""
    Polytrope{T} <: AbstractEOS

Analytic polytropic equation of state:
    P = K * ρ^Γ
    ϵ = ρ + P / (Γ - 1)
Here `ρ` is the rest-mass density.
"""
struct Polytrope{T<:Real} <: AbstractEOS
    K::T
    Γ::T
    n::T # polytropic index n = 1/(Γ-1)

    function Polytrope(K::T, Γ::T) where {T<:Real}
        n = 1 / (Γ - 1)
        new{T}(K, Γ, n)
    end
end

@inline function eos_P_from_ρ(eos::Polytrope, ρ::Real)
    return eos.K * ρ^eos.Γ
end

@inline function eos_ϵ_from_ρ(eos::Polytrope, ρ::Real)
    P = eos_P_from_ρ(eos, ρ)
    return ρ + P / (eos.Γ - 1)
end

@inline function eos_ρ_from_P(eos::Polytrope, P::Real)
    # P = K ρ^Γ => ρ = (P/K)^(1/Γ)
    # Protection against negative P handled by complex pow if T is complex?
    # Usually we expect P >= 0.
    return (P / eos.K)^(1 / eos.Γ)
end

@inline function eos_ϵ_from_P(eos::Polytrope, P::Real)
    ρ = eos_ρ_from_P(eos, P)
    return ρ + P / (eos.Γ - 1)
end


# ==============================================================================
# TabulatedEOS
# ==============================================================================

"""
    TabulatedEOS{T} <: AbstractEOS

EOS defined by tabulated values of rest-mass density (ρ), pressure (P), and energy density (ϵ).
"""
struct TabulatedEOS{T<:Real} <: AbstractEOS
    # Interpolation objects
    P_of_ρ_interp::LinearInterpolation{Vector{T},Vector{T}}
    ϵ_of_ρ_interp::LinearInterpolation{Vector{T},Vector{T}}
    ρ_of_P_interp::LinearInterpolation{Vector{T},Vector{T}}

    function TabulatedEOS(ρ::Vector{T}, P::Vector{T}, ϵ::Vector{T}) where {T<:Real}
        P_interp = LinearInterpolation(P, ρ)
        ϵ_interp = LinearInterpolation(ϵ, ρ)
        ρ_interp = LinearInterpolation(ρ, P)

        new{T}(P_interp, ϵ_interp, ρ_interp)
    end
end

@inline function eos_P_from_ρ(eos::TabulatedEOS, ρ::Real)
    return eos.P_of_ρ_interp(ρ)
end

@inline function eos_ϵ_from_ρ(eos::TabulatedEOS, ρ::Real)
    return eos.ϵ_of_ρ_interp(ρ)
end

@inline function eos_ρ_from_P(eos::TabulatedEOS, P::Real)
    return eos.ρ_of_P_interp(P)
end

@inline function eos_ϵ_from_P(eos::TabulatedEOS, P::Real)
    ρ = eos_ρ_from_P(eos, P)
    return eos_ϵ_from_ρ(eos, ρ)
end

# ==============================================================================
# PiecewisePolytrope
# ==============================================================================
"""
    PiecewisePolytrope{T} <: AbstractEOS

Piecewise polytropic EOS where P = K_i * ρ^Γ_i in each region.
Ensures continuity of P and thermodynamic variables.
"""
struct PiecewisePolytrope{T<:Real} <: AbstractEOS
    ρ_boundaries::Vector{T} # Boundaries [ρ_0, ρ_1, ..., ρ_N]
    K_values::Vector{T}     # Polytropic constants for each interval
    Γ_values::Vector{T}     # Polytropic indices for each interval
    a_values::Vector{T}     # Integration constants for energy density (a_i)

    function PiecewisePolytrope(ρ_boundaries::Vector{T}, Γ_values::Vector{T}, K_low::T) where {T<:Real}
        # Validate inputs
        if length(ρ_boundaries) + 1 != length(Γ_values)
            error("Number of Gamma values must be boundaries + 1")
        end
        if !issorted(ρ_boundaries)
            error("Boundaries must be sorted")
        end

        n_regions = length(Γ_values)
        K = Vector{T}(undef, n_regions)
        a = Vector{T}(undef, n_regions)

        # Region 1 (lowest density): specified K_low
        K[1] = K_low
        a[1] = zero(T)

        # Determine subsequent K and a values by matching P and epsilon/mu
        # At boundary i (between region i and i+1), rho = ρ_boundaries[i]
        for i in 1:(n_regions-1)
            ρ_b = ρ_boundaries[i]
            Γ_curr = Γ_values[i]
            Γ_next = Γ_values[i+1]
            K_curr = K[i]
            a_curr = a[i]

            P_b = K_curr * ρ_b^Γ_curr
            K[i+1] = P_b / (ρ_b^Γ_next)

            # Continuity: a_next = a_curr + P_b/ρ_b * (1/(Γ_curr-1) - 1/(Γ_next-1))
            a[i+1] = a_curr + (P_b / ρ_b) * (1 / (Γ_curr - 1) - 1 / (Γ_next - 1))
        end

        new{T}(ρ_boundaries, K, Γ_values, a)
    end
end

function get_region_index(eos::PiecewisePolytrope, ρ::Real)
    searchsortedfirst(eos.ρ_boundaries, ρ)
end

@inline function eos_P_from_ρ(eos::PiecewisePolytrope, ρ::Real)
    i = get_region_index(eos, ρ)
    return eos.K_values[i] * ρ^eos.Γ_values[i]
end

@inline function eos_ϵ_from_ρ(eos::PiecewisePolytrope, ρ::Real)
    i = get_region_index(eos, ρ)
    P = eos.K_values[i] * ρ^eos.Γ_values[i]
    term = P / (eos.Γ_values[i] - 1)
    return ρ * (1 + eos.a_values[i]) + term
end

@inline function eos_ρ_from_P(eos::PiecewisePolytrope, P::Real)
    # Check regions from 1 to N
    for i in 1:length(eos.K_values)
        if i == length(eos.K_values)
            # Last region
            return (P / eos.K_values[i])^(1 / eos.Γ_values[i])
        end

        # P at upper boundary of this region
        ρ_b = eos.ρ_boundaries[i]
        P_b = eos.K_values[i] * ρ_b^eos.Γ_values[i]

        if P <= P_b
            return (P / eos.K_values[i])^(1 / eos.Γ_values[i])
        end
    end
    return (P / eos.K_values[end])^(1 / eos.Γ_values[end])
end

@inline function eos_ϵ_from_P(eos::PiecewisePolytrope, P::Real)
    ρ = eos_ρ_from_P(eos, P)
    return eos_ϵ_from_ρ(eos, ρ)
end

# ==============================================================================
# Constant Density (Schwarzschild Interior)
# ==============================================================================
"""
    ConstantDensity{T} <: AbstractEOS

EOS where energy density is constant: ϵ = ϵ_c.
P is independent variable, but ϵ returns constant.
ρ (rest-mass) is ill-defined for this toy model usually,
but we can define it to be equal to ϵ for simplicity or 0.
However, to satisfy dM_b equation, we might want to just set ρ=ϵ?
Schwarzschild interior usually implies incompressible fluid.
We set ρ = ϵ for simplicity in M_b calculation, or define it formally.
"""
struct ConstantDensity{T<:Real} <: AbstractEOS
    ϵ_0::T
end

@inline function eos_ϵ_from_P(eos::ConstantDensity, P::Real)
    return eos.ϵ_0
end

@inline function eos_ρ_from_P(eos::ConstantDensity, P::Real)
    # For incompressible, ρ is usually constant too.
    return eos.ϵ_0
end

end # module
