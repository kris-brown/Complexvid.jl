using Revise
using Complexvid
using Catlab, Catlab.CategoricalAlgebra, Catlab.Graphs, Catlab.Present, Catlab.Graphics, Catlab.Theories
using AlgebraicRewriting

# Complexvid.SchHalfEdgeCO |> to_graphviz


# Tests 
########

########################################
# Initial infection
########################################
X = @acset HalfEdgeCO begin V=2; S=2; s=[1,2]; group=[:old,:young] end
view_sched(singleton(initial_infect_r); names=names_dict)
# i = if_cond(:closeToAverage, close_to_average, Av; argtype=:agent) # schedule 
view_sched(singleton(if_close_avg); names=names_dict)
view_sched(singleton(query_vertices), names=names_dict)
initial_infection_sched = mk_sched((trace_arg=:V,), (init=:I,), 
                 (V=Av,I=I, avg=if_close_avg, quer=query_vertices, rw=initial_infect_r, w=Weaken(create(Av))), quote 
  q1,q2,q3 = quer(init,trace_arg,)
  avg1, avg2 = avg(q2)
  inf1, inf2 = rw(avg1)
  return ([inf2, avg2], [q1,q3,w(inf1)])
end)

typecheck(initial_infection_sched)
view_sched(initial_infection_sched; names=names_dict)
traj = apply_schedule(initial_infection_sched, X; verbose=true)

########################################
# Incrementing days infected
########################################
X = @acset HalfEdgeCO begin V=2; S=1; s=[1]; Im=1; im=2; daysIm=[1]; symptomsIm=[2]; group=[:old,:young]; end
view_sched(increment_r, names = names_dict)

traj = apply_schedule(increment_r, homomorphism(AIm, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom


########################################
# Appearance of symptoms
########################################
view_sched(symptoms_r, names = names_dict)
X = @acset HalfEdgeCO begin 
  V=3; Im=2; im=[1,2]; daysIm=[2, 4]; symptomsIm=[2, 0]; 
  S=1; s=3;
  E=6; 
  src=[1,1,2,2,3,3];tgt=[3,2,1,3,1,2];inv=[5,3,2,6,1,4];
  layer=[:Transport,:Home,:Home,:Work,:Transport,:Work];
  group=[:Old,:Old,:Young];
  # layer=[]
end
traj = apply_schedule(symptoms_r, homomorphisms(AIm, X)[2]; verbose=true)
traj.initial.codom
traj.steps[1].world.codom
                
# ########################################
# # Recovery
# ########################################
view_sched(recoverMildApp, names = names_dict)
X = @acset HalfEdgeCO begin 
  V=2; Im=1; im=[1]; daysIm=[18]; symptomsIm=[0]; 
  S=1; s=2;
  E=2; 
  src=[1,2];tgt=[2,1];inv=[2,1];
  layer=[:Home,:Home];
  group=[:Old,:Young];
end
traj = apply_schedule(recoverMildApp, homomorphism(Av, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom

########################################
# Flip Coin
########################################
X = @acset HalfEdgeCO begin 
  V=2; Im=1; im=[1]; daysIm=[21]; symptomsIm=[-10]; 
  S=1; s=2;
  E=2; 
  src=[1,2];tgt=[2,1];inv=[2,1];
  layer=[:Home,:Home];
  group=[:Old,:Young];
end
view_sched(singleton(recoveryFlip), names=names_dict)
view_sched(singleton(i20), names = names_dict)

sched_rec = mk_sched((trace_arg=:G,), (init=:I,), 
                 (A=AIm, I=I, G=Av, A0=AIm0, recFlip=recoveryFlip, q=q_im,
                  recoverMildApp=recoverMildApp, itw=i20, f=Fail(I), ir=increment_r,
                  cio=checkI0, sr=symptoms_r, w=Weaken(homomorphism(Av,AIm))), quote 
  final_output, loop_start, ignore = q(init, trace_arg)
  f(ignore)
  incremented = ir(loop_start)
  symptomDay, notSymptomDay = cio(incremented)
  quarantined = sr(symptomDay)
  afterTwenty, beforeTwenty = itw([quarantined, notSymptomDay]) 
  wonFlip, lostFlip = recFlip(beforeTwenty) 
  recovered1 = recoverMildApp(w([afterTwenty, wonFlip]))
  return ([w(lostFlip), recovered1], final_output)
end)

view_sched(singleton(q_im), names = names_dict)
view_sched(singleton(checkI0), names = names_dict)
view_sched(symptoms_r, names = names_dict)
view_sched(singleton(i20), names = names_dict)
view_sched(singleton(recoveryFlip), names = names_dict)
view_sched(sched_rec;names=names_dict)


