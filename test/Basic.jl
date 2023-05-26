module TestBasic 
using Complexvid
using Test
using Catlab.CategoricalAlgebra


@test nparts(Av, :V) == 1 

ob_map(yG, :E)

end # module
