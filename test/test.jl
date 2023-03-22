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



