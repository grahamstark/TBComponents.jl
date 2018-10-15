using Test

#
#
#

target_populations = [ 50.0, 20.0, 230.0, 35.0 ]

data = [
 1.0 1.0 0.0 0.0 ;
 0.0 1.0 0.0 0.0 ;
 1.0 0.0 2.0 0.0 ;
 0.0 0.0 6.0 1.0 ;
 1.0 0.0 4.0 1.0 ;
 1.0 1.0 0.0 0.0 ;
 1.0 0.0 5.0 0.0 ;
 0.0 0.0 6.0 1.0 ;
 0.0 1.0 0.0 0.0 ;
 0.0 0.0 3.0 1.0 ;
 1.0 0.0 2.0 0.0 ;
 1.0 1.0 0.0 1.0 ;
 1.0 0.0 3.0 1.0 ;
 1.0 0.0 4.0 0.0 ;
 0.0 0.0 5.0 0.0 ;
 0.0 1.0 0.0 1.0 ;
 1.0 0.0 2.0 1.0 ;
 0.0 0.0 6.0 0.0 ;
 1.0 0.0 4.0 1.0 ;
 0.0 1.0 0.0 0.0  ]

initial_weights = [
   3.0,
   3.0,
   5.0,
   4.0,
   2.0,
   5.0,
   5.0,
   4.0,
   3.0,
   3.0,
   5.0,
   4.0,
   4.0,
   3.0,
   5.0,
   3.0,
   4.0,
   5.0,
   4.0,
   3.0 ]

actual_final_weights = [
   2.753,
   2.109,
   5.945,
   4.005,
   2.484,
   4.589,
   5.752,
   4.005,
   2.109,
   3.120,
   5.945,
   3.985,
   5.019,
   3.490,
   4.678,
   2.345,
   5.070,
   4.614,
   4.967,
   2.109 ]

nrows = size( data )[1]
ncols = size( data )[2]


@testset "Reproduce the basic test case in Creedy NEW ZEALAND TREASURY WORKING PAPER 03/17" begin

   @test ncols == size( target_populations )[1]
   @test nrows == size( initial_weights )[1]

   print( target_populations )

   # a = target_populations - (data'*initial_weights)
   # print( a )

   wchi = dochisquarereweighting( data, initial_weights, target_populations )

   tp = wchi' * data

   print( tp )

   @test tp' ≈ target_populations

   rw = doreweighting( data, initial_weights, target_populations, chi_square, 0.0, 0.0 )

   print( rw )

end # creedy testset
