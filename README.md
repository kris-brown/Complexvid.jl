# Complexvid.jl 

This is a work-in-progress demonstration of developing agent-based models 
within the AlgebraicJulia ecosystem, in particular the features of 
[AlgebraicRewriting.jl](https://github.com/AlgebraicJulia/AlgebraicRewriting.jl) 
described here: 1.) [basics of graph rewriting](https://arxiv.org/abs/2111.03784) 
2.) [agent-based modeling](https://arxiv.org/abs/2304.14950). The model is based 
on the [ComplexVID19 model](https://github.com/scabini/COmplexVID-19) explicated 
in "Social interaction layers in complex networks for the dynamical epidemic 
modeling of COVID-19 in Brazil".

## The model

### Setup 

The state of the world at any point in time is an undirected contact graph between a 
collection of individuals who may be susceptible, infected (mildly, severely, etc.), 
recovered, or dead, in addition to having an age. Infected people keep 
track of how many days they've been infected and how many days *until* they begin 
showing symptoms. The edges of this graph are labeled with the kind of 
connection: home, work transport, school, religion, random.

The initial contact graph is created by partitioning all people into fully-connected
subgraphs for each connection type (except for random connections).

The simulation begins with a single mildly infected person.

### Infection

Each contact edge has an associated probability of infection (edge 'weight') 
which can be calculated from its context. 

(To do: finish explanation of model)