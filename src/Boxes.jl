module Boxes

export if_close_avg, infectmild, query_vertices, increment, 
       isolate, n_days_sick, recoveryFlip, recover, shows_symptoms, 
       is_symptom_day, eweight

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

infectmild() =
  succeed(RuleApp(:infectMild, InfectMild(), id(Av)))


function query_vertices()
  Query(:dot, Av, I)
end

# Increment days infect (for mild infected)
#############################################

function increment(s::Symbol)
  succeed(RuleApp(Symbol("increment_$s"), Increment(s), id(Name["I$s"])))
end

# Check if symptom day (mild infected)
#############################################
function is_symptom_day_fun(itype::Symbol)
  function fun(f::ACSetTransformation)
    X = f.codom
    i = f[Symbol("I$itype")](1)
    return X[i,Symbol("daysI$itype")] == X[i,Symbol("symptomsI$itype")]
  end
end

is_symptom_day(m::Symbol) = 
  if_cond(:is_symptom_day, is_symptom_day_fun(m), Name["I$m"]; argtype=:agent)

function shows_symptoms_fun(itype::Symbol)
  function fun(f::ACSetTransformation)
    X = f.codom
    i = f[Symbol("I$itype")](1)
    return X[i,Symbol("daysI$itype")] > X[i,Symbol("symptomsI$itype")]
  end
end

shows_symptoms(m::Symbol) = if_cond(:show_symptoms, shows_symptoms_fun(m), Name["I$m"])

# Symptoms 
function isolate() 
  rule = Isolate()
  I = dom(left(rule))
  loop_rule(RuleApp(:Isolate, Isolate(), homomorphism(Name["Im"], I)))
end 


# Check if n days infected 
########################################
function days_sick(n::Int)
  function fun(f::ACSetTransformation)
    X = f.codom
    i = f[:Im](1)
    d = X[i,:daysIm]
    return(d >= n)
  end
end

n_days_sick(it::Symbol, n::Int) =
  if_cond(Symbol(">$n days sick"), days_sick(n), Name["I$it"]; argtype=:agent)

# Recovery 
##########
function rf(f::ACSetTransformation) 
  X = f.codom
  i = f[:Im](1)
  s = X[i,:symptomsIm]
  s < 20 || error("Bad s$s (Im#$i) $X")
  p = 1 / (20 - s)
  println("RETURNING  [p, 1 - p] $( [p, 1 - p])")
  error("HERE $p")
  return [p, 1 - p]
end

recoveryFlip() = 
  Conditional(rf, 2, AIm; name=:recoveryFlip, argtype=:agent)

function recover(itype::Symbol)
  RuleApp(Symbol("Recover_$itype"), Recover(itype), 
          id(Name["I$itype"]), id(Name["R"])) |> succeed
end 

# Edge weight
#############
tdict = (Home=3*7,Work=8*5,Transport=1.2*7,School=4*5,Religion=2,Random=1)
kdict = (Work=3,Transport=8,School=5,Religion=6)
const β = 0.3 # TODO formally expose this as a parameter
"""
Given a distinguished edge, compute weight via formula 2 from Complexvid paper
""" 
function eweight(f::ACSetTransformation)
  X = codom(f)
  e = f[:E](1)
  layer = X[e,:layer]
  t = tdict[layer]
  nᵢⱼ = length(filter(e′->X[e′,:layer]==layer, incident(X,X[e,:src],:src)))
  k = get(kdict, layer, nᵢⱼ)
  p = round(t/168 * k/nᵢⱼ * β, digits=2)
  println("layer $layer t $t k $k nᵢⱼ $nᵢⱼ β $β")
  return [p, 1-p]
end 

eweight() = 
  Conditional(eweight, 2, Name["m-s"]; name=:weight, argtype=:agent)



end # module 
