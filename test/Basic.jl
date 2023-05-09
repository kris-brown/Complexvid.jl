module TestBasic 
using Complexvid
using Test
using Catlab.CategoricalAlgebra


yG, Av, AIm, AIm0, I, Names = agent_types()
@test nparts(Av, :V) == 1 

ob_map(yG, :E)

end # module
