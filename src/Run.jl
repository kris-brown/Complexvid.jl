module Run 
export initialize

using Catlab.CategoricalAlgebra
using Distributions, Random

using ..Basic

age_dist(ages::Vector{Float64}) = findfirst(Bool.(rand(Multinomial(1, ages))))

"""Add a reflexive edge in a particular layer"""
function add_refl_edge!(X, x::Int, y::Int, l::Symbol) 
  es = add_edges!(X, [x,y],[y,x]; layer=l)
  X[es,:inv] = reverse(es)
end 

"""
Age brackets for age dist: <13, 14-17, 19-24, 25-39, 40-59, 60+
"""
function initialize(n::Int=10, ages=[.18,.06,.11,.23,.26,.16])
  X = SIRD()
  add_parts!(X, :V, n; age=[age_dist(ages) for _ in 1:n])

  # add home layers: fully connected groups which have an adult
  #------------------------------------------------------------
  n_fam = round(Int, n*0.3) # total number of families
  adults = findall(a -> a >  2, X[:age])
  heads  = shuffle(adults)[1:n_fam] # every family has a random adult
  # randomly pick a family for everyone else
  fams = [i ∈ heads ? findfirst(==(i), heads) : rand(1:n_fam) for i in 1:n]
  # Add edges
  for fam in 1:n_fam
    members = findall(==(fam), fams)
    for i in 1:length(members)-1
      for j in i+1:length(members)
        add_refl_edge!(X, members[i],members[j], :Home)
      end
    end
  end

    # add ? layers: 
  #------------------------------------------------------------


  # add random layers
  #------------------
  for _ in 1:5*n
    x,y, _... = shuffle(1:n) # random pair given an edge
    add_refl_edge!(X,x,y,:Random)
  end
  return X
end

end # module 
