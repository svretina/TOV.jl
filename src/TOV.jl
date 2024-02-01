module TOV

using DifferentialEquations

export Star

include("EOS.jl")

struct Star
    ρ_c::Real
    ϵ_c::Real
    P_c::Real
    # We store the entire solution so that we have access to high-order
    # interpolants
    sol#::ODECompositeSolution
    radius::Real
    mass::Real
    # P_r::Vector{Real}
    # mass_r::Vector{Real}
    # ν_r::Vector{Real}

    # TODO: Normalize ν_c if it is not already
    function Star(ρ_c::Real, ϵ_c::Real, P_c::Real, radius::Real,
                  mass_r::Vector{<:Real},
                  # P_r::Vector{<:Real}, mass_r::Vector{<:Real},
                  # ν_r::Vector{<:Real}
                  )
        mass = last(mass_r)
        new(ρ_c,
            ϵ_c,
            P_c,
            radius,
            mass,
            # P_r,
            # mass_r,
            # ν_r
            )
    end

    function Star(e::EOS, ρ_c::Real)
        # State vector is P, m, nu
        function rhs_tov!(rhs, state, params, r)
            press, mass, nu = state
            if press <=0
                press = 0
            end
            energy = P_to_ϵ(e, press)
            if mass <= 0 && r <= 0
                rhs[1] = 0
                rhs[2] = 0
                rhs[3] = 0
            else
                rhs[1] = -(energy + press) * (mass + 4π * r^3 * press) / (r * (r - 2 * mass))
                rhs[2] = 2π * r^2 * energy
                rhs[3] = 0
            end
        end
        initial_state = [ρ_to_P(e, ρ_c), 0.0, -1.0]
        r_span = (0, 100)

        # Prepare stopping criterion
        condition(u,t,integrator) = u[1]
        affect!(integrator) = terminate!(integrator)
        surface = ContinuousCallback(condition,affect!)

        # Set up problem
        tov_problem = ODEProblem(rhs_tov!, initial_state, r_span, callback=surface)

        # Solve ODE
        sol = solve(tov_problem)

        radius = last(sol.t)
        mass_r = sol[2, :]
        ν_r = sol[3, :]

        Star(ρ_c,
             ρ_to_ϵ(e, ρ_c),
             ρ_to_P(e, ρ_c),
             radius,
             mass_r,
             # ν_r
             )
    end
end

function radius(s::Star)
    last(s.sol.t)
end

end
