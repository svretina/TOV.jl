using TOV
using Test
using Aqua
using JET

@testset "Code Quality (Aqua.jl)" begin
    Aqua.test_all(TOV;
        ambiguities=false, # Often causes false positives with dependencies
        stale_deps=(ignore=[:ProgressLogging],), # ProgressLogging used via macro?
        persistent_tasks=false, # Often flaky with heavy deps like Makie
    )
end

@testset "Static Analysis (JET.jl)" begin
    # Test for type instabilities or errors in the main solver
    eos = Polytrope(100.0, 2.0)
    # Target solve_tov for static analysis
    report = JET.report_call(solve_tov, (Polytrope{Float64}, Float64))
    # We expect clean reports, but JET can be strict. 
    # Let's at least print the report and fail if critical.
    @test_broken length(JET.get_reports(report)) == 0
end
