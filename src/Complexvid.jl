module Complexvid
export HalfEdgeCO, InfectMild, close_to_average, initial_infect_r, if_close_avg, query_vertices, names_dict
export Av, AIm, AIm0, I
export increment_r, checkI0, q_im
export symptoms_r
export i20
export recoveryFlip
export recoverMildApp
using Catlab, Catlab.Graphs, Catlab.Graphics
using Catlab.CategoricalAlgebra, Catlab.Present, Catlab.Graphics, Catlab.Theories
using AlgebraicRewriting

################################################################################
# schema
################################################################################
@present SchHalfEdgeCO <: SchSymmetricGraph begin
  (S, Ia, Im, Is, Ic, R, D)::Ob

  s::Hom(S,V)
  ia::Hom(Ia,V)
  im::Hom(Im,V)
  is::Hom(Is,V)
  ic::Hom(Ic,V)
  r::Hom(R,V)
  d::Hom(D,V)

  (Name,Num)::AttrType
  layer::Attr(E,Name)
  group::Attr(V,Name)
  daysIa::Attr(Ia, Num)
  daysIm::Attr(Im, Num)
  daysIc::Attr(Ic, Num)
  daysIs::Attr(Is, Num)
  symptomsIa::Attr(Ia, Num)
  symptomsIm::Attr(Im, Num)
  symptomsIc::Attr(Ic, Num)
  symptomsIs::Attr(Is, Num)

end


@acset_type AbstractHalfEdgeCO(SchHalfEdgeCO) <: AbstractGraph
const HalfEdgeCO = AbstractHalfEdgeCO{Symbol,Int}

################################################################################
# Agent Types
################################################################################
Av = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)]; end
AIm = @acset HalfEdgeCO begin 
  V=1; Im=1; im=1; Name=1; Num=2; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] 
end
AIm0 = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=1; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[0] end
I = HalfEdgeCO()

names_dict = Dict([I=>"", Av=>"•", AIm=>"Im", AIm0=>"Im0"]) # acsets to strings dict

################################################################################
# Rule Definitions
################################################################################

# Initial infection
#############################################
InfectMildL = @acset HalfEdgeCO begin V=1; S=1; Name=1; s=1; group=[AttrVar(1)] end
InfectMildI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
InfectMildR = @acset HalfEdgeCO begin V=1; Im=1; Num=1; Name=1; im=1; group=[AttrVar(1)]; daysIm=[0]; symptomsIm=[AttrVar(1)];  end
InfectMild = Rule(homomorphism(InfectMildI, InfectMildL), 
                  homomorphism(InfectMildI, InfectMildR); 
                  expr=(Num=[vs->rand(Int)],))


average_degree(g::HalfEdgeCO) = sum([degree(g,v) for v in vertices(g)])/nparts(g,:V)
close_to_average(g::HalfEdgeCO, v::Int) = abs(degree(g,v) - average_degree(g)) <= 1
# Convert a homomorphism (V -> world state) into a pair, worldstate + vertex id
close_to_average(f::ACSetTransformation) = close_to_average(codom(f), f[:V](1)) 

initial_infect_r = RuleApp(:infectMild, InfectMild, id(Av)) # agent map given by A -> I

if_close_avg = if_cond(:closeToAverage, close_to_average, Av; argtype=:agent) # schedule 
query_vertices = Query(:dot, Av, I)


# Increment days infect (for mild infected)
#############################################
IncrementL = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
IncrementI = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end
IncrementR = @acset HalfEdgeCO begin V=1; Im=1; Name=1; Num=2; im=1; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] end

Increment = Rule(homomorphism(IncrementI, IncrementL), 
                  homomorphism(IncrementI, IncrementR); 
                  expr=(Num=[vs->vs[1]+1, vs->vs[2]-1],))

increment_r = tryrule(RuleApp(:increment, Increment, id(AIm))) # agent map given by A -> I



# Check if symptom day (mild infected)
#############################################
function is_symptom_day(f::ACSetTransformation)
  X = f.codom
  i = f[:Im](1)
  d = X[i,:daysIm]
  return(d == 0)
end

checkI0 = if_cond(:symptomDay, is_symptom_day, AIm; argtype=:agent)

q_im = Query(:InfectedPeople, AIm, I, Av) 


# Appearance of symptoms (for mild infected)
#############################################
symptomsL = @acset HalfEdgeCO begin 
  E=2; V=2; Im=1; Name=3; 
  Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0];
  layer=[AttrVar(3), AttrVar(3)]; 
  src=[1, 2]; tgt=[2, 1]; inv=[2,1];
end

symptomsI = @acset HalfEdgeCO begin 
  V=2; Im=1; Name=2; Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0] 
end

symptomsN = @acset HalfEdgeCO begin 
  E=2; V=2; Im=1; Name=2; 
  Num=1; im=1; group=[AttrVar(1), AttrVar(2)]; daysIm=[AttrVar(1)]; symptomsIm=[0];
  layer=[:Home, :Home]; 
  src=[1, 2]; tgt=[2, 1]; inv=[2,1];
end

symptoms = Rule(homomorphism(symptomsI, symptomsL; monic=true), 
     id(symptomsI); 
     ac=[AppCond(homomorphism(symptomsL, symptomsN), false)])

symptoms_r = tryrule(RuleApp(:Symptoms, symptoms, homomorphism(AIm, symptomsI)))


# Check if 20 days infected (mild infected)
########################################
function twenty_days_sick(f::ACSetTransformation)
  X = f.codom
  i = f[:Im](1)
  d = X[i,:daysIm]
  return(d >= 20)
end

i20 = if_cond(:twentyDaysSick, twenty_days_sick, AIm; argtype=:agent) # schedule 

# Flip for recovery (mild infected)
########################################
function rf(f::ACSetTransformation) 
  X = f.codom
  i = f[:Im](1)
  s = X[i,:symptomsIm]
  d = X[i,:daysIm]
  p = 1 / (20 - (s + d))
  return([p, 1 - p])
end

recoveryFlip = Conditional(rf, 2, AIm; name=:recoveryFlip, argtype=:agent)

# Recovery (mild infected)
########################################
RecoverL = @acset HalfEdgeCO begin 
  V=1; Im=1; im=1; Name=1; Num=2; group=[AttrVar(1)]; daysIm=[AttrVar(1)]; symptomsIm=[AttrVar(2)] 
end
RecoverI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
RecoverR = @acset HalfEdgeCO begin V=1; R=1; r=1; Name=1; group=[AttrVar(1)];  end
RecoverMild = Rule(homomorphism(RecoverI, RecoverL), homomorphism(RecoverI, RecoverR))
recoverMildApp = tryrule(RuleApp(:RecoverMild, RecoverMild, homomorphism(Av, RecoverI)))



end # module Complexvid
