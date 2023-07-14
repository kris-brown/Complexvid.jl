module TestRun 
using Complexvid
using AlgebraicRewriting, Catlab, ACSets
using Luxor
using Random

Random.seed!(1)

sched = overall(100); # just one day
view_sched(sched;names=Name)



ssched = sparsify(sched);
sX = sparsify(initialize(100))
Random.seed!(1)
@time interpret!(ssched, sX)

sX

im = InfectMild() |> sparsify
ms = homomorphisms(codom(left(im)), sX)
can_match.(Ref(im), ms)

traj, = apply_schedule(sched, X; steps=100);
traj_res(traj).steps[end].world |> codom
traj_view(sched,traj)


end # module 
