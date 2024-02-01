module TOV

using Reexport

include("EOS.jl")
include("Star.jl")

@reexport using .EOS
@reexport using .Star

end
