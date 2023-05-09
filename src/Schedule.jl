module Schedule

using ..Basic, ..Rules
using Catlab.CategoricalAlgebra, Catlab.Graphs
using AlgebraicRewriting


# Initial infection
#############################################
average_degree(g::SIRD) = sum([degree(g,v) for v in vertices(g)])/nparts(g,:V)
close_to_average(g::SIRD, v::Int) = abs(degree(g,v) - average_degree(g)) <= 1
close_to_average(f::ACSetTransformation) = close_to_average(codom(f), f[:V](1)) 

function if_close_avg()
  _, Av, _... = agent_types()
  if_cond(:closeToAverage, close_to_average, Av; argtype=:agent)
end 

function initial_infect_r() 
  _, Av, _... = agent_types()
  RuleApp(:infectMild, InfectMild(), id(Av)) # agent map given by A -> I
end 

function query_vertices()
  _, Av, _, _, I, _... = agent_types()
  Query(:dot, Av, I)
end

# Increment days infect (for mild infected)
#############################################

function increment_r()
  _, _, AIm, _... = agent_types()
  tryrule(RuleApp(:increment, Increment(), id(AIm)))
end

# Check if symptom day (mild infected)
#############################################
function is_symptom_day(f::ACSetTransformation)
  X = f.codom
  i = f[:Im](1)
  d = X[i,:daysIm]
  return(d == 0)
end

function checkI0()
  _, _, AIm, _... = agent_types()
  if_cond(:symptomDay, is_symptom_day, AIm; argtype=:agent)
end
function q_im()
  yG, Av, AIm, _, I, _ = agent_types()
  Query(:InfectedPeople, AIm, I, Av) 
end


# Symptoms 
function symptoms_r() 
  _, _, AIm, _... = agent_types()
  sym = Symptoms()
  I = dom(left(sym))
  tryrule(RuleApp(:Symptoms, sym, homomorphism(AIm, I)))
end 

# Check if 20 days infected (mild infected)
########################################
function twenty_days_sick(f::ACSetTransformation)
  X = f.codom
  i = f[:Im](1)
  d = X[i,:daysIm]
  return(d >= 20)
end

function i20() 
  _, _, AIm, _... = agent_types()
  if_cond(:twentyDaysSick, twenty_days_sick, AIm; argtype=:agent) # schedule 
end 

# Recovery 
##########
function rf(f::ACSetTransformation) 
  X = f.codom
  i = f[:Im](1)
  s = X[i,:symptomsIm]
  d = X[i,:daysIm]
  p = 1 / (20 - (s + d))
  return([p, 1 - p])
end

function recoveryFlip()
  _, _, AIm, _... = agent_types()
  Conditional(rf, 2, AIm; name=:recoveryFlip, argtype=:agent)
end 

function recoverMildApp()
  _, Av, _... = agent_types()
  rm = RecoverMild()
  tryrule(RuleApp(:RecoverMild, rm, homomorphism(Av, dom(left(rm)))))
end 

#############
# Schedules #
#############

function initial_infection_sched() 
  _, Av, _, _, I, _ = agent_types()
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
  _, Av, AIm, AIm0, I, _ = agent_types()
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
