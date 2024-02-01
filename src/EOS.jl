export EOS
export Polytrope
export ρ_to_P
export P_to_ρ
export P_to_ei
export P_to_ϵ

abstract type EOS end

struct Polytrope <: EOS
    K::Real
    Γ::Real
end

"""
    Compute pressure from rest-mass density.
"""
ρ_to_P(e::Polytrope, ρ::Real) = e.K^e.Γ

"""
    Compute total energy density from rest-mass density.
"""
ρ_to_ϵ(e::Polytrope, ρ::Real) = ρ * (1 + e.K^e.Γ/(e.Γ - 1.0))

"""
    Compute rest-mass density from pressure.
"""
P_to_ρ(e::Polytrope, P::Real) = (P/e.K)^(1.0/e.Γ)

"""
    Compute internal energy density from pressure.
"""
P_to_ei(e::Polytrope, P::Real) = P/(e.Γ - 1.0)

"""
    Compute total energy density from pressure.
"""
P_to_ϵ(e::Polytrope, P::Real) = P_to_ρ(e, P) + P_to_ei(e, P)
