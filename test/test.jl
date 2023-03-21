using Revise
using Complexvid
using Catlab, Catlab.CategoricalAlgebra, Catlab.Graphs, Catlab.Present, Catlab.Graphics, Catlab.Theories
using AlgebraicRewriting

Complexvid.SchHalfEdgeCO |> to_graphviz


# Tests 
########
X = @acset HalfEdgeCO begin V=2; S=2; s=[1,2]; group=[:old,:young] end
rewrite(InfectMild, X)
