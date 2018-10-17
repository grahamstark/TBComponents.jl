using Test

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

 # @test size( ps ) == 4
