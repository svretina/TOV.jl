module Analysis

using CairoMakie
using ..EOS
using ..Solver
using ..Solver: solve_tov
using ..Constants
using Unitful
using LaTeXStrings
using ProgressLogging

export Sequence
export solve_sequence
export plot_dashboard

"""
    Sequence{E<:AbstractEOS}

A sequence of stellar models (equilibrium configurations) for a given EOS.
"""
struct Sequence{E<:AbstractEOS}
    eos::E
    stars::Vector{Star}
end

"""
    solve_sequence(eos::AbstractEOS, ρ_range)

Generate a sequence of stars for central densities in `ρ_range`.
"""
function solve_sequence(eos::AbstractEOS, ρ_range)
    stars = Star[]
    n_steps = length(ρ_range)
    @withprogress name = "Solving Sequence" begin
        for (i, ρ_c) in enumerate(ρ_range)
            # Calculate P_c from ρ_c
            P_c = eos_P_from_ρ(eos, ρ_c)
            try
                star = solve_tov(eos, P_c)
                push!(stars, star)
            catch e
                @warn "Failed to solve for ρ_c = $ρ_c: $e"
            end
            @logprogress i / n_steps
        end
    end
    return Sequence(eos, stars)
end

"""
    check_causality(star::Star)

Check if the speed of sound exceeds the speed of light (c=1) anywhere in the star.
Returns (is_causal, max_cs).
"""
function check_causality(star::Star)
    # Numerical derivative
    dp = diff(star.p)
    de = diff(star.epsilon)
    # Avoid division by zero at surface where both are 0
    # Filter small changes
    mask = abs.(de) .> 1e-16
    cs2 = dp[mask] ./ de[mask]

    if isempty(cs2)
        return (true, 0.0)
    end

    max_cs2 = maximum(cs2)
    min_cs2 = minimum(cs2)

    max_cs = sqrt(max(0.0, max_cs2))

    is_causal = (max_cs <= 1.0) && (min_cs2 >= 0.0)
    return (is_causal, max_cs)
end

"""
    find_stability_branch(seq::Sequence)

Identify the stable and unstable branches of the sequence.
Returns a vector of symbols :stable or :unstable for each star.
Criterion: dM/dρ_c > 0 is stable (usually).
"""
function find_stability_branch(seq::Sequence)
    # We assume sequence is ordered by rho_c (increasing)
    # M should increase until max mass, then decrease.
    masses = [s.mass for s in seq.stars]

    # Find index of maximum mass
    max_m, max_idx = findmax(masses)

    status = Vector{Symbol}(undef, length(seq.stars))
    # Before max mass -> stable
    status[1:max_idx] .= :stable
    # After max mass -> unstable
    if max_idx < length(seq.stars)
        status[max_idx+1:end] .= :unstable
    end

    return status, max_idx
end

# ==============================================================================
# Visualization Recipes (CairoMakie)
# ==============================================================================

"""
    Makie.plot(star::Star)

Create a 4-panel dashboard for a single star.
"""
function Makie.plot(star::Star)
    theme = mytheme_aps()
    with_theme(theme) do
        # Dashboard fits better in default theme size (roughly single column or slightly wider)
        # APS Double Column is ~510pt. Single is ~246pt.
        # Dashboard has 4 panels, so 2 columns. 
        # Ideally (500, 400) or similar.
        # Let's set it to double column width.
        f = Figure(size=(510, 400))

        # 1. Pressure and Density profiles
        ax1 = Axis(f[1, 1], xlabel=L"Radius $R$ (km)", ylabel=L"Pressure $P$ / Density $\epsilon$", title="Structure")
        r_km = star.r .* L_geom_km
        lines!(ax1, r_km, star.p, label=L"Pressure $P$", color=:blue)
        lines!(ax1, r_km, star.epsilon, label=L"Energy Density $\epsilon$", color=:red)
        axislegend(ax1)

        # 2. Enclosed Mass
        ax2 = Axis(f[1, 2], xlabel=L"Radius $R$ (km)", ylabel=L"Mass $M$ ($M_\odot$)", title="Enclosed Mass")
        r_km = star.r .* L_geom_km
        lines!(ax2, r_km, star.m, color=:green)

        # 3. Metric Potentials
        # 3. Metric Potentials
        ax3 = Axis(f[2, 1], xlabel=L"Radius $R$ (km)", ylabel=L"Metric Potential $\nu, \lambda$", title="Metric Potentials")
        r_km = star.r .* L_geom_km
        lines!(ax3, r_km, star.nu, color=:purple, label=L"$\nu$ ($g_{tt}$)")
        # We could calculate e^λ = (1 - 2m/r)^-1/2
        exp_lambda = [1.0 / sqrt(1.0 - 2.0 * star.m[i] / star.r[i]) for i in 2:length(star.r)]
        # Handle r=0? Limit is 1.
        pushfirst!(exp_lambda, 1.0)
        lines!(ax3, r_km, exp_lambda, color=:orange, label=L"$e^\lambda$ ($g_{rr}$)")
        axislegend(ax3)

        # 4. Speed of Sound
        ax4 = Axis(f[2, 2], xlabel=L"Radius $R$ (km)", ylabel=L"Speed of Sound $c_s$", title="Sound Speed")
        # c_s^2 = dP / dϵ
        # We can approximate numerically or use EOS if available analytically.
        # Numerical derivative from arrays:
        dp = diff(star.p)
        de = diff(star.epsilon)
        cs2 = dp ./ de
        # Valid at midpoints
        r_mid = (star.r[1:end-1] .+ star.r[2:end]) ./ 2
        r_mid_km = r_mid .* L_geom_km
        lines!(ax4, r_mid_km, sqrt.(abs.(cs2)), color=:black) # sqrt of abs used for safety, though cs2 should be positive

        # Add causality warning if needed
        is_causal, max_cs = check_causality(star)
        if !is_causal
            text!(ax4, 0.5, 0.9, text="Violates Causality!\nmax(cs) = $(round(max_cs, digits=3))", color=:red, space=:relative)
        end

        return f
    end

end

"""
    Makie.plot(seq::Sequence)

Plot the Mass-Radius curve for a sequence.
"""
function Makie.plot(seq::Sequence)
    theme = mytheme_aps()
    with_theme(theme) do
        # Single column figure
        f = Figure(size=(246, 200))
        ax = Axis(f[1, 1], xlabel=L"Radius $R$ (km)", ylabel=L"Mass $M$ ($M_\odot$)", title="Mass-Radius Relation")

        radii_km = [s.radius * L_geom_km for s in seq.stars]
        masses = [s.mass for s in seq.stars]

        # Stability analysis
        status, max_idx = find_stability_branch(seq)

        # Split into stable and unstable for plotting
        stable_mask = status .== :stable
        unstable_mask = status .== :unstable

        if any(stable_mask)
            lines!(ax, radii_km[stable_mask], masses[stable_mask], color=:blue, linewidth=2, label="Stable")
            scatter!(ax, radii_km[stable_mask], masses[stable_mask], color=:blue, markersize=5)
        end

        if any(unstable_mask)
            lines!(ax, radii_km[unstable_mask], masses[unstable_mask], color=:red, linewidth=2, linestyle=:dash, label="Unstable")
            scatter!(ax, radii_km[unstable_mask], masses[unstable_mask], color=:red, markersize=5)
        end

        # Mark Max Mass
        if max_idx > 0
            max_m = masses[max_idx]
            max_r = radii_km[max_idx]
            scatter!(ax, [max_r], [max_m], color=:green, marker=:star5, markersize=15, label="Max Mass")
        end

        # Horizontal line at 2.0 Solar Masses
        hlines!(ax, [2.0], color=:grey, linestyle=:dot, label=L"2.0 $M_\odot$ Limit")
        axislegend(ax)
        return f
    end
end

function mytheme_aps()
    return Theme(
        # Axis attributes
        ;
        Axis=Attributes(; spinewidth=1.1,
            xgridvisible=true,
            xlabelpadding=-0,
            xlabelsize=12,
            xminortickalign=1,
            xminorticks=IntervalsBetween(5, true),
            xminorticksize=3,
            xminorticksvisible=true,
            xminortickwidth=0.75,
            xtickalign=1,
            xticklabelsize=8,
            xticksize=5,
            xticksmirrored=true,
            xtickwidth=0.8,
            ygridvisible=true,
            ylabelpadding=2,
            ylabelsize=12,
            yminortickalign=1,
            yminorticks=IntervalsBetween(5, true),
            yminorticksize=3,
            yminorticksvisible=true,
            yminortickwidth=0.75,
            ytickalign=1,
            yticklabelsize=10,
            yticksize=5,
            yticksmirrored=true,
            ytickwidth=0.8,
            xticklabelfont="cmr10",  # Upright Computer Modern
            yticklabelfont="cmr10",  # Upright Computer Modern
            xticklabelstyle=Attributes(; italic=false),
            yticklabelstyle=Attributes(; italic=false)),
        # General figure settings
        colgap=10,
        figure_padding=2,
        rowgap=10,
        size=(246, 165), # Standard single column default
        # Colorbar attributes
        Colorbar=Attributes(; labelpadding=2,
            labelsize=10,
            minortickalign=1,
            minorticksize=3,
            minorticksvisible=true,
            minortickwidth=0.75,
            size=8,
            spinewidth=1.1,
            tickalign=1,
            ticklabelpad=2,
            ticklabelsize=8,
            ticksize=5,
            tickwidth=0.8),
        fonts=Attributes(; bold="NewComputerModern10 Bold",
            bold_italic="NewComputerModern10 Bold Italic",
            italic="NewComputerModern10 Italic",
            regular="NewComputerModern Math Regular"),
        # fonts=Attributes(; bold="ComputerModern Bold",
        #                  bold_italic="ComputerModern Bold Italic",
        #                  italic="ComputerModern Italic",
        #                  regular="ComputerModern Math Regular"),
        # Legend attributes
        Legend=Attributes(; colgap=4,
            framecolor=(:grey, 0.5),
            framevisible=false,
            labelsize=7.5,
            margin=(0, 0, 0, 0),
            nbanks=1,
            padding=(2, 2, 2, 2),
            rowgap=-10,
            #labelfont="cmr10"
        ),
        # Lines attributes
        Lines=Attributes(;
            cycle=Cycle([[:color] => :color],
                true)),
        # Scatter attributes
        Scatter=Attributes(;
            cycle=Cycle([[:color] => :color, [:marker] => :marker],
                true),
            markersize=7,
            strokewidth=0),
        markersize=7,
        # Palette attributes
        palette=Attributes(;
            color=[RGBAf(0.298039, 0.447059, 0.690196, 1.0),
                RGBAf(0.866667, 0.517647, 0.321569, 1.0),
                RGBAf(0.333333, 0.658824, 0.407843, 1.0),
                RGBAf(0.768627, 0.305882, 0.321569, 1.0),
                RGBAf(0.505882, 0.447059, 0.701961, 1.0),
                RGBAf(0.576471, 0.470588, 0.376471, 1.0),
                RGBAf(0.854902, 0.545098, 0.764706, 1.0),
                RGBAf(0.54902, 0.54902, 0.54902, 1.0),
                RGBAf(0.8, 0.72549, 0.454902, 1.0),
                RGBAf(0.392157, 0.709804, 0.803922, 1.0)],
            linestyle=[nothing, :dash, :dot, :dashdot, :dashdotdot],
            marker=[:circle, :rect, :dtriangle, :utriangle, :cross,
                :diamond, :ltriangle, :rtriangle, :pentagon,
                :xcross, :hexagon],
            markercolor=[RGBAf(0.298039, 0.447059, 0.690196, 1.0),
                RGBAf(0.866667, 0.517647, 0.321569, 1.0),
                RGBAf(0.333333, 0.658824, 0.407843, 1.0),
                RGBAf(0.768627, 0.305882, 0.321569, 1.0),
                RGBAf(0.505882, 0.447059, 0.701961, 1.0),
                RGBAf(0.576471, 0.470588, 0.376471, 1.0),
                RGBAf(0.854902, 0.545098, 0.764706, 1.0),
                RGBAf(0.54902, 0.54902, 0.54902, 1.0),
                RGBAf(0.8, 0.72549, 0.454902, 1.0),
                RGBAf(0.392157, 0.709804, 0.803922, 1.0)],
            patchcolor=[RGBAf(0.298039, 0.447059, 0.690196, 1.0),
                RGBAf(0.866667, 0.517647, 0.321569, 1.0),
                RGBAf(0.333333, 0.658824, 0.407843, 1.0),
                RGBAf(0.768627, 0.305882, 0.321569, 1.0),
                RGBAf(0.505882, 0.447059, 0.701961, 1.0),
                RGBAf(0.576471, 0.470588, 0.376471, 1.0),
                RGBAf(0.854902, 0.545098, 0.764706, 1.0),
                RGBAf(0.54902, 0.54902, 0.54902, 1.0),
                RGBAf(0.8, 0.72549, 0.454902, 1.0),
                RGBAf(0.392157, 0.709804, 0.803922, 1.0)]),
        # PolarAxis attributes
        PolarAxis=Attributes(; spinewidth=1.1))
end

end # module
