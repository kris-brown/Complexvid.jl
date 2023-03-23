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
# rewrite(InfectMild, X)

I = HalfEdgeCO()
v = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
r = RuleApp("infectMild", InfectMild, id(v)) # agent map given by A -> I
view_sched(singleton(r))
i = if_cond("closeToAverage", close_to_average, v; argtype=:agent) # schedule 
view_sched(singleton(i))


q = Query("dot", v, I)
view_sched(singleton(q))

sched = mk_sched((init=:I, trace_arg=:V), 1, 
                 (V=v,I=I, avg=i, quer=q, rw=r, w=Weaken("",create(v))), quote 
  q1,q2,q3 = quer(init,trace_arg,)
  avg1, avg2 = avg(q2)
  inf1, inf2 = rw(avg1)
  return ([q1,q3,w(inf1)], [inf2, avg2])
end)

typecheck(sched)

view_sched(sched)

traj = apply_schedule(sched, X; verbose=true)



################################################################################
# Mild Infection (Im) rules
################################################################################

########################################
# Incrementing days infected
########################################

IncrementL = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
# keeping the group variable in the I rule means we don't have to write an expression for it but can - 
# if we didn't have it, we would have to write a rule otherwise we'd introduce a free variables
IncrementI = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
IncrementR = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end

# list after Num = what do with each Num variable in R rule
# expr=(Num=[vs->vs[1]+1, vs->max(0,vs[2]-1)],)

Increment = Rule(homomorphism(IncrementI, IncrementL), 
                  homomorphism(IncrementI, IncrementR); 
                  expr=(Num=[vs->vs[1]+1, vs->vs[2]],))


X = @acset HalfEdgeCO begin V=2; S=1; s=[1]; Im=1; im=2; daysIm=[1]; symptomsIm=[2]; group=[:old,:young]; end
v = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
r = RuleApp("increment", Increment, id(v)) # agent map given by A -> I
view_sched(singleton(r))

traj = apply_schedule(singleton(r), homomorphism(v, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom




########################################
# Appearance of symptoms
########################################

symptomsL = @acset HalfEdgeCO begin 
  E=2; V=2; Im=1; Name=3; 
  Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0];
  layer=[AttrVar(3), AttrVar(3)]; 
  src=[1, 2]; tgt=[2, 1]; inv=[2,1];
end
# keeping the group variable in the I rule means we don't have to write an expression for it but can - 
# if we didn't have it, we would have to write a rule otherwise we'd introduce a free variables
symptomsI = @acset HalfEdgeCO begin 
  V=2; Im=1; Name=2; Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0] 
end
# symptomsR = @acset HalfEdgeCO begin V=2; Im=1; Name=2; Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0] end

symptomsN = @acset HalfEdgeCO begin 
  E=2; V=2; Im=1; Name=2; 
  Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0];
  layer=[:Home, :Home]; 
  src=[1, 2]; tgt=[2, 1]; inv=[2,1];
end

symptoms = Rule(homomorphism(symptomsI, symptomsL; monic=true), 
     id(symptomsI); 
     ac=[AppCond(homomorphism(symptomsL, symptomsN), false)])

A = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=1; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[0] end

r = RuleApp("Symptoms", symptoms, homomorphism(A, symptomsI))
view_sched(singleton(r))
X = @acset HalfEdgeCO begin 
  V=3; Im=2; im=[1,2]; daysIm=[2, 4]; symptomsIm=[2, 0]; 
  S=1; s=3;
  E=6; 
  src=[1,1,2,2,3,3];tgt=[3,2,1,3,1,2];inv=[5,3,2,6,1,4];
  layer=[:Transport,:Home,:Home,:Work,:Transport,:Work];
  group=[:Old,:Old,:Young];
  # layer=[]
end
traj = apply_schedule(singleton(r), homomorphism(A, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom



# get_matches(symptoms, X, verbose = true)
# homomorphisms(symptomsL, X)

# loop_rule


                







InfectMildL = @acset HalfEdgeCO begin V=1; S=1; Name=1; s=1; group=[AttrVar(1)] end
InfectMildI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
InfectMildR = @acset HalfEdgeCO begin V=1; Im=1; Num=1; Name=1; im=1; group=[AttrVar(1)]; daysIm=[0]; symptomsIm=[AttrVar(1)];  end
InfectMild = Rule(homomorphism(InfectMildI, InfectMildL), 
                  homomorphism(InfectMildI, InfectMildR); 
                  expr=(Num=[vs->rand(Int)],))



