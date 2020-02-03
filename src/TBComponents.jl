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

export WEEKS_PER_YEAR, weeklyise, annualise
export TaxResult, RateBands, IncomesDict
export calctaxdue, calc_indirect, IndirResult,*,times

# budget constraint stuff
export Point2DG, Point2D, BudgetConstraint, BCSettings, DEFAULT_SETTINGS
export makebc, pointstoarray, annotate_bc

# equivalence scales

export Equivalence_Scale_Type, oxford, modified_oecd, eq_square_root, mcclements, eq_per_capita
export Equiv_Person_Type, eq_head, eq_spouse_of_head, eq_other_adult, eq_dependent_child
export EQ_Person
export get_equivalence_scale

include( "common_types.jl" )
include( "poverty_inequality.jl" )
include( "reweighter.jl" )
include( "taxcalcs.jl" )
include( "piecewise_linear_generator.jl" )
include( "equivalence_scales.jl" )

end # module
