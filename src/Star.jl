module Star

using ..EOS
using OrdinaryDiffEq

export StarType

# find better names, file and struct cannot have the same name
struct StarType{T<:Real}
    ρ_c::T
    ϵ_c::T
    P_c::T
    eos::Polytrope{T}
end

@inline function ρ_to_P(star::StarType{T}) where {T<:Real}
    star.eos.K^star.eos.Γ
end

# t is params of DiffEq, for us this will be the radius
# Maybe use MVectors from StaticArrays.jl
@inline function rhs_tov!(du::Vector{T}, u::Vector{T}, params, r::Real) where {T}
    @fastmath @inbounds begin
        miden = zero(T)
        press, mass, nu = u
        if press <= miden
            press = miden
        end
        energy = P_to_ϵ(params, press) # this should not be in the rhs, can we provide that ?
        if mass <= miden && t <= miden # the second condition doesn't make sense
            du[1] = miden
            du[2] = miden
            du[3] = miden
        else
            du[1] = -(energy + press) * (mass + 4π * r * r * r * press) / (r * (r - 2mass))
            du[2] = 2π * r * r * energy
            du[3] = miden
        end
    end
    return nothing
end

function solve2(star::StarType{T}) where {T}
    tmp = EOS.ρ_to_P(star.eos, star.ρ_c) # why doesn't it see it since I export it?
    initial_state = [tmp, zero(T), -one(T)]
    r_span = (zero(T), 100.0) # why 100?

    # Prepare stopping criterion
    condition(u, t, integrator) = u[1]
    affect!(integrator) = terminate!(integrator)
    surface = ContinuousCallback(condition, affect!)
    params = (eos = star.eos)
    # Set up problem
    # define tolerances and solvers, adaptive probably
    tov_problem = ODEProblem(rhs_tov!, initial_state, r_span, star.eos, callback=surface)

    # Solve ODE
    sol = OrdinaryDiffEq.solve(tov_problem, Tsit5(), reltol=1e-8, abstol=1e-8)
    # radius = last(sol.t)
    # @view mass_r = sol[2, :]
    # @view ν_r = sol[3, :]
    return sol
    # Star(ρ_c,
    #     ρ_to_ϵ(e, ρ_c),
    #     ρ_to_P(e, ρ_c),
    #     radius,
    #     mass_r,
    # )
end

end # end of module
