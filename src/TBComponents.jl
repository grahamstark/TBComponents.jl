"
General Purpose stuff for tax simulation models
"
module TBComponents

using Printf
using DataFrames

export ArrayOrFrame;

# inequality stuff
export OutputDict, OutputDictArray
export DEFAULT_ATKINSON_ES, DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS
export makegini, makepoverty, makeinequality, binify, adddecomposedtheil!

# reweighting
export DistanceFunctionType
export doreweighting, dochisquarereweighting

# general tax routines
export TaxResult
export calctaxdue, calc_indirect, IndirResult

# budget constraint stuff
export Point2DG, Point2D, BudgetConstraint, BCSettings, DEFAULT_SETTINGS
export makebc, pointstoarray

include( "common_types.jl" )
include( "poverty_inequality.jl" )
include( "reweighter.jl" )
include( "taxcalcs.jl" )
include( "piecewise_linear_generator.jl" )

end # module
