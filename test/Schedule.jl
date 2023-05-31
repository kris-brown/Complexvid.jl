module TestSchedule 

using Complexvid
using Complexvid.Schedule: initial_infection_sched, increment, 
      recover, ia_update, im_update, inf_update, inf_infect, overall

using Catlab.CategoricalAlgebra, Catlab.Programs, Catlab.Graphics
using AlgebraicRewriting, Luxor

# Initial infection

sched = initial_infection_sched() |> typecheck
view_sched(sched; names=Name)

X = @acset SIRD begin V=2; S=2; s=[1,2]; group=[:old,:young]; age=[5,6] end
traj, = apply_schedule(sched, X);
traj_res(traj).steps[end].world |> codom

# Incrementing days infected
X = @acset SIRD begin V=2; S=1; s=[1]; Im=1; im=2;
  daysIm=[1]; symptomsIm=[2]; group=[:old,:young]; age=[10,11]
end
traj, = apply_schedule(increment_r(), homomorphism(AIm, X);)
traj_res(traj).steps[end].world |> codom

# Appearance of symptoms

X = @acset_colim yG begin
  (e1,e2,e3)::E; (v1,v2,v3)::V; sus::S; (i1,i2)::Im

  src(e1) == v1; tgt(e1) == v3;
  src(e2) == v1; tgt(e2) == v2;
  src(e3) == v2; tgt(e3) == v3;

  s(sus) == v3; im(i1) == v1; im(i2) == v2

  age(v1) == 5; age(v2) == 6; age(v3) == 7

  daysIm(i1)==2; daysIm(i2) == 4; 
  symptomsIm(i1)==2; symptomsIm(i2) == 0 

  layer(e1) == :Transport; layer(e2) == :Home; layer(e3) == :Work
end

traj, = apply_schedule(isolate(), homomorphisms(AIm, X)[2])
traj_res(traj).steps[end].world |> codom

# Overall 
sched = overall(1);

X = @acset_colim yG begin
  (e1,e2,e3)::E; (v1,v2,v3)::V; sus::S; (i1,i2)::Im

  src(e1) == v1; tgt(e1) == v3;
  src(e2) == v1; tgt(e2) == v2;
  src(e3) == v2; tgt(e3) == v3;

  s(sus) == v3; im(i1) == v1; im(i2) == v2

  age(v1) == 5; age(v2) == 6; age(v3) == 7

  daysIm(i1)==2; daysIm(i2) == 4;
  symptomsIm(i1)==2; symptomsIm(i2) == 0

  layer(e1) == :Transport; layer(e2) == :Home; layer(e3) == :Work
end

traj, = apply_schedule(sched, X);
traj_res(traj).steps[end].world |> codom
traj_view(sched,traj)


end # module
