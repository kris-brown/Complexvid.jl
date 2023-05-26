module Rules 
export InfectMild, Increment, Symptoms, RecoverMild

using Catlab, Catlab.CategoricalAlgebra, Catlab.Programs
using AlgebraicRewriting
using Distributions

using ..Basic


################################################################################
# Rule Definitions
################################################################################

# Initial infection
#############################################
"""
A susceptible person is converted to a mildly infected person.

The rule introduces a variable for days until symptoms show. The value we bind 
this to is chosen via random sampling from lognormal distribution with 
mean=1.621 and sigma=0.418.
"""
function InfectMild()
  InfectMildR = @acset_colim yG begin i::Im; daysIm(i) == 0 end
  Rule(homomorphism(Av, ob_map(yG,:S)), homomorphism(Av, InfectMildR); 
       expr=(Num=[vs->round(Int,rand(LogNormal(1.621, .418)))],))
end


# Increment days infect (for mild infected)
#############################################
function Increment()
  Im = ob_map(yG, :Im)
  Rule(id(Im), id(Im); expr=(Num=[vs->vs[1]+1, vs->vs[2]-1],))
end



# Appearance of symptoms (for mild infected)
#############################################

"""
A remove a non-home connection from an infected person displaying symptoms.
"""
function Symptoms()

  symptomsL = @acset_colim yG begin
    e::E; i::Im; im(i) == src(e); symptomsIm(i)==0
  end
  symptomsI = @acset_colim yG begin
    (v1,v2)::V; i::Im; im(i) == v1; symptomsIm(i)==0
  end
  symptomsN = @acset_colim yG begin
    (v1,v2)::V; i::Im; im(i) == v1; symptomsIm(i)==0
  end
  symptomsN = @acset_colim yG begin 
    e::E; i::Im 
    im(i) == src(e); symptomsIm(i)==0; layer(e)==:Home
  end

  Rule(homomorphism(symptomsI, symptomsL; monic=true), id(symptomsI); 
      ac=[AppCond(homomorphism(symptomsL, symptomsN), false)])
end


# Recovery (of a mild infected)
########################################
function RecoverMild()
  Rule(homomorphism(Av, ob_map(yG, :Im)), homomorphism(Av, ob_map(yG,:R)))
end

end # module