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
r = RuleApp(:infectMild, InfectMild, id(v)) # agent map given by A -> I
N = Dict([I=>"", v=>"•"]) # acsets to strings dict
view_sched(singleton(r); names=N)
i = if_cond(:closeToAverage, close_to_average, v; argtype=:agent) # schedule 
view_sched(singleton(i); names=N)


q = Query(:dot, v, I)
view_sched(singleton(q), names=N)

sched = mk_sched((trace_arg=:V,), (init=:I,), 
                 (V=v,I=I, avg=i, quer=q, rw=r, w=Weaken(create(v))), quote 
  q1,q2,q3 = quer(init,trace_arg,)
  avg1, avg2 = avg(q2)
  inf1, inf2 = rw(avg1)
  return ([inf2, avg2], [q1,q3,w(inf1)])
end)

typecheck(sched)

view_sched(sched; names=N)

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
r = RuleApp(:increment, Increment, id(v)) # agent map given by A -> I
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

symptoms_r = RuleApp(:Symptoms, symptoms, homomorphism(A, symptomsI))
view_sched(singleton(symptoms_r))
X = @acset HalfEdgeCO begin 
  V=3; Im=2; im=[1,2]; daysIm=[2, 4]; symptomsIm=[2, 0]; 
  S=1; s=3;
  E=6; 
  src=[1,1,2,2,3,3];tgt=[3,2,1,3,1,2];inv=[5,3,2,6,1,4];
  layer=[:Transport,:Home,:Home,:Work,:Transport,:Work];
  group=[:Old,:Old,:Young];
  # layer=[]
end
traj = apply_schedule(singleton(symptoms_r), homomorphism(A, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom



# get_matches(symptoms, X, verbose = true)
# homomorphisms(symptomsL, X)

# loop_rule


                
########################################
# Recovery
########################################
RecoverL = @acset HalfEdgeCO begin 
  V=1; Im=1; im=1; Name=1; Num=2; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] 
end
RecoverI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
RecoverR = @acset HalfEdgeCO begin V=1; R=1; r=1; Name=1; group=[AttrVar(1)];  end
# homomorphism(RecoverI, RecoverL)
# homomorphism(RecoverI, RecoverR)

RecoverMild = Rule(homomorphism(RecoverI, RecoverL), homomorphism(RecoverI, RecoverR))

# A = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
A = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)]; end

recoverMildApp = tryrule(RuleApp(:RecoverMild, RecoverMild, homomorphism(A, RecoverI)))
# r = RuleApp(:RecoverMild, RecoverMild, homomorphism(A, RecoverL), ) # explicitly giving transformations A -> L (first) and A -> R?
# homomorphisms(A, RecoverL)
# homomorphisms(A, RecoverR)
# homomorphisms(A, RecoverI)
# homomorphism(A, I)
# id(A)
# N = Dict([I=>"", v=>"•"]) # acsets to strings dict

view_sched(recoverMildApp)
X = @acset HalfEdgeCO begin 
  V=2; Im=1; im=[1]; daysIm=[18]; symptomsIm=[0]; 
  S=1; s=2;
  E=2; 
  src=[1,2];tgt=[2,1];inv=[2,1];
  layer=[:Home,:Home];
  group=[:Old,:Young];
end
traj = apply_schedule(recoverMildApp, homomorphism(A, X); verbose=true)
traj.initial.codom
traj.steps[1].world.codom

########################################
# Flip Coin
########################################


A = @acset HalfEdgeCO begin 
  V=1; Im=1; im=1; Name=1; Num=2; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] 
end

X = @acset HalfEdgeCO begin 
  V=2; Im=1; im=[1]; daysIm=[21]; symptomsIm=[-10]; 
  S=1; s=2;
  E=2; 
  src=[1,2];tgt=[2,1];inv=[2,1];
  layer=[:Home,:Home];
  group=[:Old,:Young];
end

function rf(f::ACSetTransformation) 
  X = f.codom
  i = f[:Im](1)
  s = X[i,:symptomsIm]
  d = X[i,:daysIm]
  p = 1 / (20 - (s + d))
  return([p, 1 - p])
end

# I = HalfEdgeCO()
v = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
N = Dict([HalfEdgeCO()=>"", v=>"•", A=>"Im"])
recoveryFlip = Conditional(rf, 2, A; name=:recoveryFlip, argtype=:agent)
view_sched(singleton(recoveryFlip), names=N)





average_degree(g::HalfEdgeCO) = sum([degree(g,v) for v in vertices(g)])/nparts(g,:V)
close_to_average(g::HalfEdgeCO, v::Int) = abs(degree(g,v) - average_degree(g)) <= 1
# Convert a homomorphism (V -> world state) into a pair, worldstate + vertex id
close_to_average(f::ACSetTransformation) = close_to_average(codom(f), f[:V](1))


function twenty_days_sick(f::ACSetTransformation)
  X = f.codom
  i = f[:Im](1)
  d = X[i,:daysIm]
  return(d >= 20)
end

i20 = if_cond(:twentyDaysSick, twenty_days_sick, A; argtype=:agent) # schedule 
view_sched(singleton(i20), names = N)

AGeneric = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)]; end
AIm = @acset HalfEdgeCO begin 
  V=1; Im=1; im=1; Name=1; Num=2; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] 
end

q_im = Query(:InfectedPeople, AIm, I, AGeneric) 
sched_rec = mk_sched((trace_arg=:G,), (init=:I,), 
                 (A=AIm, I=I, G=AGeneric, recFlip=recoveryFlip, q=q_im,
                  recoverMildApp=recoverMildApp, itw=i20, f=Fail(I),
                  w=Weaken(homomorphism(AGeneric,AIm))), quote 
  final_output, loop_start, ignore = q(init, trace_arg)
  f(ignore)
  afterTwenty, beforeTwenty = itw(loop_start) 
  wonFlip, lostFlip = recFlip(beforeTwenty) 
  recovered1 = recoverMildApp(w([afterTwenty, wonFlip]))
  return ([w(lostFlip), recovered1], final_output)
end)
view_sched(sched;names=N)