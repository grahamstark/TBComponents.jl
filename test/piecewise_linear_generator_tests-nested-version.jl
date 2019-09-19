using Test
using MiniTB

include( "../src/piecewise_linear_generator.jl" )

# @testset begin
 p1 = Point2D( 1.011,2.011)
 p2 = Point2D( 1.011, 2.011 )
 p3 = Point2D( 1.011, 3.011 )
 p4 = Point2D( -1.011, -3.011 )
 p5 = Point2D( 10.011, 13.011 )

 bc = BudgetConstraint( [p1,p2,p3,p4,p5])

sort!( bc )

@test size( bc )[1] == 5

ps = PointsSet([p1,p2,p3,p4,p5] )
push!( ps, p1 )
push!( ps, p2 )
push!( ps, p3 )
push!( ps, p4 )
push!( ps, p5 )
println( "ps = $ps ")
push!( ps, Point2D( 1.0011, 1.999999 ))

bc2 = censor( ps )

println( "bc2 = $bc2 ")
@test size( bc2 )[1] == 5
pers = DEFAULT_PERSON
pars = DEFAULT_PARAMS
res = calculate( pers, pars )
println( "res=$res" )

 # @test size( ps ) == 4

function makebc( pers :: Person, params :: Parameters ) :: BudgetConstraint

    function getnet( gross :: Float64 ) :: Float64
        persedit = modifiedcopy( pers, wage=gross )
        # println( "getnet; made person $persedit")
        rc = calculate( persedit, params )
        return rc[:netincome]
    end

    bc = makebc( getnet )

    return bc
end

bc = makebc( DEFAULT_PERSON, DEFAULT_PARAMS )
println(pointstoarray( bc))
bc = makebc( DEFAULT_PERSON, ZERO_PARAMS )
println( pointstoarray( bc))
pars = DEFAULT_PARAMS
pars.it_allow = 999.0
person = DEFAULT_PERSON
#person.wage -= 1
rc = calculate( DEFAULT_PERSON, pars )
println(rc)
bc = makebc( person, pars )
println( pointstoarray( bc ))
