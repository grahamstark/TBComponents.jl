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
export makebc,BCSettings,DEFAULT_SETTINGS
export Point2DG,Point2D,BudgetConstraint

include( "poverty_inequality.jl" )
include( "reweighter.jl" )
include( "taxcalcs.jl" )
include( "piecewise_linear_generator.jl" )

end # module
