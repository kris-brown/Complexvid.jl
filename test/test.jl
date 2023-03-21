using Revise
using Complexvid
using Catlab, Catlab.CategoricalAlgebra, Catlab.Graphs, Catlab.Present, Catlab.Graphics, Catlab.Theories
using AlgebraicRewriting

# Complexvid.SchHalfEdgeCO |> to_graphviz




# Tests 
########
X = @acset HalfEdgeCO begin V=2; S=2; s=[1,2]; group=[:old,:young] end
# rewrite(InfectMild, X)

I = HalfEdgeCO()
v = @acset HalfEdgeCO begin V=1; Name=1; group=[AttrVar(1)] end
r = RuleApp("infectMild", InfectMild, id(v)) # schedule 
view_sched(singleton(r))
i = if_cond("closeToAverage", close_to_average, v) # schedule 
view_sched(singleton(i))


q = Query("dot", I, v)
view_sched(singleton(q))

mk_sched((trace_arg=:V,init=:I), 1, (V=v,I=I, avg=i, quer=q, rw=r), begin 
  q1,q2,q3 = quer(init,trace_arg)
  avg1, avg2 = avg(q2)
  inf1, inf2 = rw(avg1)
  return ([inf2, avg2],[q1,q3,inf1])
end)
