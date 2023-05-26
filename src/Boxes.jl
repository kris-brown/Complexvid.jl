module Boxes

export if_close_avg, initial_infect_r, query_vertices, increment_r, checkI0, 
       q_im, symptoms_r, twenty_days_sick, i20, recoveryFlip, recoverMildApp

using ..Basic, ..Rules
using Catlab.CategoricalAlgebra, Catlab.Graphs
using AlgebraicRewriting


# Initial infection
#############################################
average_degree(g::SIRD) = sum([degree(g,v) for v in vertices(g)])/nparts(g,:V)
close_to_average(g::SIRD, v::Int) = abs(degree(g,v) - average_degree(g)) <= 1
close_to_average(f::ACSetTransformation) = close_to_average(codom(f), f[:V](1)) 

function if_close_avg()
  if_cond(:closeToAverage, close_to_average, Av; argtype=:agent)
end 

function initial_infect_r() 
  RuleApp(:infectMild, InfectMild(), id(Av)) # agent map given by A -> I
end 

function query_vertices()
  Query(:dot, Av, I)
end

# Increment days infect (for mild infected)
#############################################

function increment_r()
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
  if_cond(:symptomDay, is_symptom_day, AIm; argtype=:agent)
end
function q_im()
  Query(:InfectedPeople, AIm, I, Av) 
end

# Symptoms 
function symptoms_r() 
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
  Conditional(rf, 2, AIm; name=:recoveryFlip, argtype=:agent)
end 

function recoverMildApp()
  rm = RecoverMild()
  tryrule(RuleApp(:RecoverMild, rm, homomorphism(Av, dom(left(rm)))))
end 

# Edge weight
#############
tdict = (Home=3*7,Work=8*5,Transport=1.2*7,School=4*5,Religion=2,Random=1)
kdict = (Work=3,Transport=8,School=5,Religion=6)
const β = 0.3 # TODO formally expose this as a parameter
"""
Given a distinguished edge, compute weight via formula 2 from Complexvid paper
""" 
function weight(f::ACSetTransformation)
  X = codom(f)
  e = only(collect(f[:E]))
  layer = X[e,:layer]
  t = tdict[layer]
  nᵢⱼ = length(filter(e′->X[e′,:layer]==layer, incident(X,e,:src)))
  k = get(kdict, layer, nᵢⱼ)
  return t/168 * k/n * β
end 


end # module 
