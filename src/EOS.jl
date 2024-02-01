module EOS

export Polytrope
export ρ_to_P
export P_to_ρ
export P_to_ei
export P_to_ϵ

abstract type EquationOfState{T} end

struct Polytrope{T<:AbstractFloat} <: EquationOfState{T}
    K::T
    Γ::T
end

## shouldn't this use ρ?
"""
    ρ_to_P(e::Polytrope{T}, ρ::T) where {T<:Real}
    Compute pressure from rest-mass density.
"""
@inline function ρ_to_P(e::Polytrope{T}, ρ::T) where {T<:Real}
    e.K^e.Γ
end
"""
    ρ_to_ϵ(e::Polytrope{T}, ρ::T) where {T<:Real}
    Compute total energy density from rest-mass density.
"""
@inline function ρ_to_ϵ(e::Polytrope{T}, ρ::T) where {T<:Real}
    ρ * (one(T) + e.K^e.Γ / (e.Γ - one(T)))
end

"""
    P_to_ρ(e::Polytrope{T}, P::T) where {T<:Real}
    Compute rest-mass density from pressure.
"""
@inline function P_to_ρ(e::Polytrope{T}, P::T) where {T<:Real}
    (P / e.K)^(one(T) / e.Γ)
end

"""
    P_to_ei(e::Polytrope{T}, P::T) where {T<:Real}
    Compute internal energy density from pressure.
"""
@inline function P_to_ei(e::Polytrope{T}, P::T) where {T<:Real}
    P / (e.Γ - one(T))
end

"""
    P_to_ϵ(e::Polytrope{T}, P::T) where {T<:Real}
    Compute total energy density from pressure.
"""
@inline function P_to_ϵ(e::Polytrope{T}, P::T) where {T<:Real}
    P_to_ρ(e, P) + P_to_ei(e, P)
end

end # end of module
