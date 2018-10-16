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

   println( "target popns $target_populations" )

   # a = target_populations - (data'*initial_weights)
   # print( a )

   wchi = dochisquarereweighting( data, initial_weights, target_populations )
   println( "direct chi-square results $wchi")
   weighted_popn_chi = (wchi' * data)'
   @test weighted_popn_chi ≈ target_populations

   for method in [
      chi_square,
      d_and_s_type_a,
      d_and_s_type_b,
      constrained_chi_square,
      d_and_s_constrained] # CHECK: how to iterate neatly over an Enum
      println( "on method $method")
      ul = 1.4
      ll = 0.3
      rw =
         doreweighting(
            data,
            initial_weights,
            target_populations,
            method,
            ul,
            ll )
      println( "results for method $method = $rw" )
      weights = rw[:weights]
      weighted_popn = (weights' * data)'
      @test weighted_popn ≈ target_populations
      if method != chi_square
         for w in weights # check: what's the 1-liner for this?
            @test w > 0.0
         end
      else
         @test weights ≈ wchi # chisq the direct way should match chisq the iterative way
      end
      if method in [constrained_chi_square, d_and_s_constrained ]
         # check the constrainted methods keep things inside ll and ul
         for r in 1:nrows
            @test weights[r] <= initial_weights[r]*ul
            @test weights[r] >= initial_weights[r]*ll
         end
      end
   end

end # creedy testset
