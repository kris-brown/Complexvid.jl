module Complexvid
export HalfEdgeCO, InfectMild

using Catlab.Graphs, Catlab.Graphics
# using Base.Iterators
# using CairoMakie, GeometryBasics
# using CombinatorialSpaces
# import AlgebraicPetri
# using CombinatorialSpaces.SimplicialSets: get_edge!
using Catlab.CategoricalAlgebra, Catlab.Graphs, Catlab.Present, Catlab.Graphics, Catlab.Theories
# using Catlab.CategoricalAlgebra.FinCats: FinCatGraphEq
# import Catlab 
# pres = Catlab.CategoricalAlgebra.CatElements.presentation; # abbreviate long name



#############################################
# schema
#############################################
@present SchHalfEdgeCO(FreeSchema) begin
  V::Ob
  H::Ob
  (S, Ia, Im, Is, Ic, R, D)::Ob

  vertex::Hom(H,V)
  inv::Hom(H,H)
  s::Hom(S,V)
  ia::Hom(Ia,V)
  im::Hom(Im,V)
  is::Hom(Is,V)
  ic::Hom(Ic,V)
  r::Hom(R,V)
  d::Hom(D,V)

  compose(inv, inv) == id(H)

  (Name,Num)::AttrType
  layer::Attr(H,Name)
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


@acset_type AbstractHalfEdgeCO(SchHalfEdgeCO, index=[:vertex])
const HalfEdgeCO = AbstractHalfEdgeCO{Symbol,Int}

h2 = @acset HalfEdgeCO begin
  V = 3
  H = 1
  layer = [:L1]
  group = [:G1]
end

print(h2)



#############################################
# Viz
#############################################

#############################################
# Re-write rules
#############################################


InfectMildL = @acset HalfEdgeCO begin V=1; S=1; Name=1; s=1; group=[AttrVar(1)] end
InfectMildI = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
InfectMildR = @acset HalfEdgeCO begin V=1; Im=1; Num=1; Name=1; im=1; group=[AttrVar(1)]; daysIm=[0]; symptomsIm=[AttrVar(1)];  end
InfectMild = Rule(homomorphism(InfectMildI, InfectMildL), homomorphism(InfectMildI, InfectMildR); expr=(Num=[vs->rand(Int)],))

#############################################
# Schedule
#############################################
# Infection (with state determination)
# Disease progression (showing symptoms, recovery, diagnosis, isolation)
# 

#############################################
# Analysis
#############################################

end # module Complexvid
