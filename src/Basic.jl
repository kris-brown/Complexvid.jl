module Basic
export SIRD, yG, Av, AIm, AIm0, I, Names, traj_view

using Catlab.CategoricalAlgebra, Catlab.Present, Catlab.Theories, Catlab.Graphics
using Catlab.Graphs, Catlab.Programs
using AlgebraicRewriting: yoneda_cache, view_traj
import Catlab.Graphics: to_graphviz

# Schema
########
@present SchSIRD <: SchSymmetricGraph begin
  (S, Ia, Im, Is, Ic, R, D)::Ob

  s  :: Hom(S,V)
  ia :: Hom(Ia,V)
  im :: Hom(Im,V)
  is :: Hom(Is,V)
  ic :: Hom(Ic,V)
  r  :: Hom(R,V)
  d  :: Hom(D,V)

  (Name,Num) :: AttrType
  layer      :: Attr(E,Name)
  age        :: Attr(V,Num)
  daysIa     :: Attr(Ia, Num)
  daysIm     :: Attr(Im, Num)
  daysIc     :: Attr(Ic, Num)
  daysIs     :: Attr(Is, Num)
  symptomsIa :: Attr(Ia, Num)
  symptomsIm :: Attr(Im, Num)
  symptomsIc :: Attr(Ic, Num)
  symptomsIs :: Attr(Is, Num)

  compose(inv, layer) == layer
end


@acset_type AbstractSIRD(SchSIRD) <: AbstractGraph
const SIRD = AbstractSIRD{Symbol,Int}

# Agent Types
#############
yG = yoneda_cache(SIRD, SchSIRD); # compute representables
Av = ob_map(yG,:V)
AIm = ob_map(yG,:Im)
AIm0 = @acset_colim yG begin i::Im; symptomsIm(i) == 0 end
I = SIRD()
Names = Dict([I=>"", Av=>"•", AIm=>"Im", AIm0=>"Im0"]) # acsets to strings dict

# Visualization
###############

to_graphviz(X::SIRD) = view_SIRD(create(X))

colors = (s="green", ia="pink", im="red", is="purple", ic="grey", r="lightblue", d="black")

function view_SIRD(f::ACSetTransformation)
  X = codom(f)
  pg = PropertyGraph{Any}(; prog = "neato", graph = Dict(), # graph level attrs
    node = Dict(:shape => "ellipse", :style=>"filled", :margin => "0"), 
    edge = Dict(:dir=>"none"))

  add_vertices!(pg, nparts(X,:V))
  for (v,a) in enumerate(X[:age])
    for s in [:s, :ia,:im,:is,:ic,:r,:d]
      if !isempty(incident(X,v,s))
        set_vprop!(pg, v, :label, "$s$v($a)")
        set_vprop!(pg, v, :fillcolor, colors[s])
      end
      if v ∈ collect(f[:V])
        set_vprop!(pg, v, :penwidth, "4.0")
      end
    end
  end
  for (e,l) in enumerate(X[:layer])
    if X[e,:inv] > e
      new_e = add_edge!(pg, X[e,:src], X[e,:tgt])
      set_eprop!(pg, new_e, :label, string(l)[1:1])
      if e ∈ collect(f[:E])
        set_eprop!(pg, e, :penwidth, "4.0")
      end
    end
  end
  to_graphviz(pg)
end
traj_view(sched,traj) = view_traj(sched,traj,view_SIRD; agent=true)

end # module 
