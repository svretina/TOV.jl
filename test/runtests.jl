using TOV
using Test

@testset "TOV.jl" begin
    include("test_eos.jl")
    include("test_solver.jl")
    include("physics_benchmarks.jl")
    include("qa.jl")
end
