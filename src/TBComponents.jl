"
General Purpose stuff for tax simulation models
"
module TBComponents

using Printf

# inequality stuff
export makegini, makepoverty, makeinequality, binify
export DEFAULT_ATKINSON_ES,DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS

# reweighting
export DistanceFunctionType, doreweighting, dochisquarereweighting

# general tax routines
export calc_indirect, IndirResult
export calctaxdue, TaxResult

# budget constraint stuff

include("poverty_inequality.jl")
include("reweighter.jl")
include("taxcalcs.jl")

end # module
