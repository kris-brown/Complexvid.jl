module TestRun 
using Complexvid
using AlgebraicRewriting, Catlab
using Luxor
using Random

Random.seed!(1)

X = initialize()

sched = overall(1); # just one day
view_sched(sched;names=Name)

traj, = apply_schedule(sched, X; steps=100);
traj_res(traj).steps[end].world |> codom
traj_view(sched,traj)


end # module 
