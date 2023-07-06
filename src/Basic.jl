module Basic
export SIRD, yG, Av, AIa, AIm, AIm0, I, Name, traj_view

using Catlab.CategoricalAlgebra, Catlab.Theories, Catlab.Graphics
using Catlab.Graphs, Catlab.Programs
using AlgebraicRewriting: yoneda_cache, view_traj, Names
import Catlab.Graphics: to_graphviz

# Schema
########
"""
Objects: 
  V - generic person
  Each V is mapped to by one of the following 
    s  - Susceptible 
    ia - Asymptomatic infected
    im - Mildly infected
    is - Severely infected
    ic - Critically infected
    r  - recovered
    d  - dead 

Attributes:
  age        - age of the person (ℕ⁺)
  daysIx     - Number of days since infection began  (ℕ⁺)
  symptomsIx - Number of infected days until one shows/showed symptoms (ℕ⁺)
  layer      - What type of connection between two people? One of:
    - Home
    - Work
    - Transport
    - Schools
    - Religion
    - Random
"""
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


@acset_type AbstractSIRD(SchSIRD) <: AbstractSymmetricGraph
const SIRD = AbstractSIRD{Symbol,Int}

# Agent Types
#############
yG = yoneda_cache(SIRD, SchSIRD; clear=false); # compute representables
Av = ob_map(yG,:V)
AIm = ob_map(yG,:Im)
AIa = ob_map(yG,:Ia)
AIm0 = @acset_colim yG begin i::Im; symptomsIm(i) == 0 end
R = ob_map(yG,:R)
Em = @acset_colim yG begin e::E; s_::S; i_::Im; 
  src(e) == s(s_)
  tgt(e) == im(i_)
end
Ea = @acset_colim yG begin e::E; s_::S; i_::Ia; 
  src(e) == s(s_)
  tgt(e) == ia(i_)
end
I = SIRD()
const Name = Names(Dict([
  ""=>I, "•"=>Av, "Im"=>AIm,"Ia"=>AIa, "Im0"=>AIm0, "R"=>R, "m-s"=>Em, "a-s"=>Ea]))

# Visualization
###############

to_graphviz(X::SIRD) = view_SIRD(create(X))

colors = (s="green", ia="pink", im="red", is="purple", ic="grey", r="lightblue", d="black")
function get_label(X::SIRD, v::Int)
  vs = ["($v)", "a:$(X[v,:age])"]
  for s in "amcs"
    i = incident(X, v, Symbol("i$s"))
    if !isempty(i)
      for p in ["days", "symptoms"]
        push!(vs, "$(p[1]):$(X[only(i), Symbol("$(p)I$s")])")
      end
    end
  end
  return join(reverse(vs)," ")
end 
function view_SIRD(f::ACSetTransformation, pth=tempfile())
  X = codom(f)
  pg = PropertyGraph{Any}(; prog = "dot", graph = Dict(),
    node = Dict(:shape => "ellipse", :style=>"filled", :margin => "0"), 
    edge = Dict(:dir=>"none",:minlen=>"1"))

  add_vertices!(pg, nparts(X,:V))
  for v in vertices(X)
    for s in [:s, :ia,:im,:is,:ic,:r,:d]
      if !isempty(incident(X,v,s))
        set_vprop!(pg, v, :label, get_label(X,v))
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
        set_eprop!(pg, new_e, :penwidth, "4.0")
      end
    end
  end
  gv = to_graphviz(pg)
  open(pth, "w") do io 
    show(io,"image/svg+xml",gv) 
  end
  gv
end
traj_view(sched,traj) = view_traj(sched,traj,view_SIRD; agent=true)

end # module 
