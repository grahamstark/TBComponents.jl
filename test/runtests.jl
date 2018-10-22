# using TBComponents
using Printf
using Test

include( "../src/taxcalcs.jl" )
include( "../src/reweighter_optim.jl" )
include( "../src/poverty_inequality.jl" )
include( "../src/piecewise_linear_generator.jl" )

include( "reweighter_tests.jl" )
include( "taxcalcs_tests.jl" )
include( "minitb.jl" )
include( "poverty_inequality_tests.jl" )
include( "piecewise_linear_generator_tests.jl" )
