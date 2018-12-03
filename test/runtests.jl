# using TBComponents
using Printf
using Test
using IterableTables
using IteratorInterfaceExtensions


include( "../src/common_types.jl" )
include( "../src/taxcalcs.jl" )
include( "../src/reweighter.jl" )
include( "../src/poverty_inequality.jl" )
include( "../src/piecewise_linear_generator.jl" )

#
# comment this one out if you don't have HBAI from the UKDS
#
include( "test_hbai.jl")

include( "poverty_inequality_tests.jl" )
include( "reweighter_tests.jl" )
include( "taxcalcs_tests.jl" )
include( "minitb.jl" )
include( "piecewise_linear_generator_tests.jl" )
