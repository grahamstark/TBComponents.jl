"
General Purpose stuff for tax simulation models
"
module TBComponents

using Printf
using IterableTables
using IteratorInterfaceExtensions
using TableTraits

# inequality stuff
export OutputDict, OutputDictArray
export DEFAULT_ATKINSON_ES, DEFAULT_ENTROPIES, DEFAULT_FGT_ALPHAS
export makegini, makepoverty, makeinequality, binify, adddecomposedtheil

# reweighting
export DistanceFunctionType
export doreweighting, dochisquarereweighting

# general tax routines
export TaxResult, RateBands, IncomesDict, *
export calctaxdue, calc_indirect, IndirResult

# budget constraint stuff
export Point2DG, Point2D, BudgetConstraint, BCSettings, DEFAULT_SETTINGS
export makebc, pointstoarray

# equivalence scales

export Equivalence_Scale_Type, oxford, modified_oecd, square_root, mcclements
export Equiv_Person_Type, head, spouse_of_head, other_adult, dependent_child
export EQ_Person
export get_equivalence_scale

include( "common_types.jl" )
include( "poverty_inequality.jl" )
include( "reweighter.jl" )
include( "taxcalcs.jl" )
include( "piecewise_linear_generator.jl" )
include( "equivalence_scales.jl" )

end # module
