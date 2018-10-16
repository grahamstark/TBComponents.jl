"

"
module TBComponents

using Printf

export makegini, makepoverty, makeinequality, binify
export DEFAULT_ATKINSON_ES,DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS

export DistanceFunctionType, doreweighting, dochisquarereweighting

include("poverty_inequality.jl")
include("reweighter.jl")

end # module
