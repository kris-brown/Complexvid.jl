module Schedule

using ..Basic, ..Rules, ..Boxes
using Catlab.CategoricalAlgebra, Catlab.Graphs
using AlgebraicRewriting



#############
# Schedules #
#############

function initial_infection_sched() 
  mk_sched((trace_arg=:V,), (init=:I,), 
           (V=Av,I=I, avg=if_close_avg(), quer=query_vertices(), 
           rw=initial_infect_r(), w=Weaken(create(Av)), fail=Fail(I)), quote 
    q1,q2,q3 = quer(init,trace_arg,)
    fail([q1,q3])
    avg1, avg2 = avg(q2)
    inf1, inf2 = rw(avg1)
    trace = [inf2, avg2]
    return (trace, w(inf1))
  end)
end


# Flip Coin
function sched_rec() 
  mk_sched((trace_arg=:G,), (init=:I,), (A=AIm, I=I, G=Av, A0=AIm0, 
           recFlip=recoveryFlip(), q=q_im(), recoverMildApp=recoverMildApp(), 
           itw=i20(), f=Fail(I), ir=increment_r(), cio=checkI0(), 
           sr=symptoms_r(), w=Weaken(homomorphism(Av,AIm))), quote 
    final_output, loop_start, ignore = q(init, trace_arg)
    f(ignore)
    incremented = ir(loop_start)
    symptomDay, notSymptomDay = cio(incremented)
    quarantined = sr(symptomDay)
    afterTwenty, beforeTwenty = itw([quarantined, notSymptomDay]) 
    wonFlip, lostFlip = recFlip(beforeTwenty) 
    recovered1 = recoverMildApp(w([afterTwenty, wonFlip]))
    trace = [w(lostFlip), recovered1]
    return (trace, final_output)
  end)
end


end # module
