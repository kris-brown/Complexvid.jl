module Run 
export initialize

using Catlab.CategoricalAlgebra
using AlgebraicRewriting: rewrite
using Distributions, Random

using ..Basic
using ..Rules: rand_days_Im

age_dist(ages::Vector{Float64}) = findfirst(Bool.(rand(Multinomial(1, ages))))

function fully_connect!(X,xs::AbstractVector{Int}, l::Symbol)
  for i in 1:length(xs)
    for j in (i+1):length(xs)
      add_edge!(X, i, j; layer=l)
    end
  end
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
        add_edge!(X, members[i],members[j], layer=:Home)
      end
    end
  end
  # add school layers (fully connected groups in age 0-17): 
  #--------------------------------------------------------
  in_school = shuffle(findall(p->X[p,:age] <= 2, vertices(X)))
  while !isempty(in_school)
    n_class = min(length(in_school), rand(16:30))
    class = first(in_school,n_class)
    in_school = in_school[n_class+1:end]
    fully_connect!(X, class, :School)
  end

  # add church layers (fully connected groups in age 0-17): 
  #--------------------------------------------------------
  nodes = shuffle(vertices(X))[1:round(Int,n*0.4)]
  while !isempty(nodes)
    r = rand()
    idx = findfirst(p -> r <= p, [0.552786405,0.845637005,1])
    n_church = rand([10:50,51:80,81:100][idx])
    fully_connect!(X, first(nodes,n_church), :Religion)
    nodes = nodes[n_church+1:end]
  end

  # add transportation layer: 
  #--------------------------
  nodes = shuffle(vertices(X))[1:round(Int,n*0.36)]
  while !isempty(nodes)
    n_metro = rand(10:40)
    fully_connect!(X, first(nodes,n_metro), :Transport)
    nodes = nodes[n+1:end]
  end

  # add random layers
  #------------------
  for _ in 1:5*n
    x,y, _... = shuffle(1:n) # random pair given an edge
    add_edge!(X,x,y; layer=:Random)
  end

  # add work layer (people above 17 below 60): 
  #---------------
  in_work = shuffle(findall(p->2 < X[p,:age] < 6, vertices(X)))
  while !isempty(in_work)
    n_job = min(length(in_work), rand(5:30))
    job = first(in_work,n_job)
    in_work = in_work[n_job+1:end]
    fully_connect!(X, job, :School)
  end

  # Infect random person
  #---------------------
  inf = rand(vertices(X))
  for v in vertices(X)
    if v == inf 
      add_part!(X, :Im, im=v, daysIm=0, symptomsIm=rand_days_Im())
    else 
      add_part!(X, :S, s=v)
    end
  end
  return X
end

end # module 
