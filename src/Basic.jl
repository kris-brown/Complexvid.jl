module Basic
export SIRD, agent_types

using Catlab.CategoricalAlgebra, Catlab.Present, Catlab.Theories
using Catlab.Graphs, Catlab.Programs
using AlgebraicRewriting: yoneda_cache

################################################################################
# schema
################################################################################
@present SchSIRD <: SchSymmetricGraph begin
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

  compose(inv, layer) == layer
end


@acset_type AbstractSIRD(SchSIRD) <: AbstractGraph
const SIRD = AbstractSIRD{Symbol,Int}

################################################################################
# Agent Types
################################################################################
function agent_types()
  yG = yoneda_cache(SIRD, SchSIRD); # compute representables
  Av = ob_map(yG,:V)
  AIm = ob_map(yG,:Im)
  AIm0 = @acset_colim yG begin i::Im; symptomsIm(i) == 0 end
  I = SIRD()
  Names = Dict([I=>"", Av=>"•", AIm=>"Im", AIm0=>"Im0"]) # acsets to strings dict
  return yG, Av, AIm, AIm0, I, Names
end 
end # module 