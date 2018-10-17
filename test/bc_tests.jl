 p1 = Point2D( 1.0,2.0)
 p2 = Point2D( 1.0, 2.0 )
 p3 = Point2D( 1.0, 3.0 )
 p4 = Point2D( -1.0, -3.0 )
 p5 = Point2D( 10.0, 13.0 )

 bc = BudgetConstraint( [p1,p2,p3,p4,p5])

 sort!( bc )

 @test count( bc ) == 5

 ps = PointsSet()
 push!( ps, p1 )
 push!( ps, p2 )
 push!( ps, p3 )
 push!( ps, p4 )
 push!( ps, p5 )

 @test count( ps ) == 4
