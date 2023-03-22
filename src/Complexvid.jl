module Complexvid
export HalfEdgeCO, InfectMild, close_to_average

using Catlab, Catlab.Graphs, Catlab.Graphics
using Catlab.CategoricalAlgebra, Catlab.Present, Catlab.Graphics, Catlab.Theories
using AlgebraicRewriting



#############################################
# schema
#############################################
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

h2 = @acset HalfEdgeCO begin
  V = 3
  H = 1
  layer = [:L1]
  group = [:G1]
end



#############################################
# Viz
#############################################

#############################################
# Re-write rules
#############################################


InfectMildL = @acset HalfEdgeCO begin V=1; S=1; Name=1; s=1; group=[AttrVar(1)] end
InfectMildI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
InfectMildR = @acset HalfEdgeCO begin V=1; Im=1; Num=1; Name=1; im=1; group=[AttrVar(1)]; daysIm=[0]; symptomsIm=[AttrVar(1)];  end
InfectMild = Rule(homomorphism(InfectMildI, InfectMildL), 
                  homomorphism(InfectMildI, InfectMildR); 
                  expr=(Num=[vs->rand(Int)],))

#############################################
# Schedule
#############################################
# Infection (with state determination)
# Disease progression (showing symptoms, recovery, diagnosis, isolation)
# 

average_degree(g::HalfEdgeCO) = sum([degree(g,v) for v in vertices(g)])/nparts(g,:V)
close_to_average(g::HalfEdgeCO, v::Int) = abs(degree(g,v) - average_degree(g)) <= 1
# Convert a homomorphism (V -> world state) into a pair, worldstate + vertex id
close_to_average(f::ACSetTransformation) = close_to_average(codom(f), f[:V](1)) 
#############################################
# Analysis
#############################################

end # module Complexvid
