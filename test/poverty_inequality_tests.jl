import TBComponents
using Test

#
# These tests mostly try to replicate examples from
# World Bank 'Handbook on poverty and inequality'
# by Haughton and Khandker
# http://documents.worldbank.org/curated/en/488081468157174849/Handbook-on-poverty-and-inequality
#

# ...
primitive type Amount <: AbstractFloat 64 end

"
This just creates an array which is `times` vcat copies of `a`
"
function vcn( a :: Array{Float64}, times :: Int64 )
    nrows = size( a )[1]
    ncols = size( a )[2]
    newrows = nrows*times
    out = zeros( Float64, newrows, ncols )
    p = 0
    for row in 1:nrows
        for i in 1:times
            p += 1
            out[p,:] .= a[row,:]
        end
    end
    out
end

"
element - by element compare of the type of dicts we use for poverty and inequality output
"
function comparedics( left :: Dict{ Symbol, <:Any}, right :: Dict{ Symbol, <:Any} ) :: Bool
    lk = keys( left )
    if lk != keys( right )
        return false
    end
    for k in lk
        # try catch here in case types are way off
        try
            if !( left[k] ≈ right[k] )
                return false
            end
       catch e
            return false
       end
    end
    return true
end


@testset "WB Chapter 4 - Poverty " begin
    @test 1==1
    @test 1 ≈ 1.0000000000001
    @test comparedics( Dict( :a=>1.0, :b=>1.0 ), Dict( :a=>1.0, :b=>1.0000000001 ))
    country_a = [ 1.0 100; 1.0 100; 1 150; 1 150 ]
    country_b = copy( country_a )
    country_b[1:2,2] .= 124
    country_c = [ 1.0 100; 1.0 110; 1 150; 1 160 ]
    #
    # Ch 4 doesn't discuss weighting issues, so
    # we'll add some simple checks for that.
    # a_2 and b_2 should be the same as country_a and _b,
    # but with 2 obs of weight 2 rather than 4 of weight 1
    #
    country_a_2 = [2.0 100; 2.0 150 ]
    country_b_2 = [2.0 124; 2.0 150 ]
    # d should be a big version of a and also produce same result
    country_d = vcn( country_a, 50 )
    # attempt to blow things up with huge a clone
    country_d = vcn( country_c, 1_000_000 )

    line = 125.0

    country_a_pov = TBComponents.makepoverty( country_a, line )
    print("country A " );println( country_a_pov )
    country_a_2_pov = TBComponents.makepoverty( country_a_2, line )
    country_b_pov = TBComponents.makepoverty( country_b, line )
    country_c_pov = TBComponents.makepoverty( country_c, line )
    print("country C " );println( country_c_pov )
    country_d_pov = TBComponents.makepoverty( country_d, line )
    print("country D " );println( country_d_pov )

    @test comparedics( country_a_pov, country_a_2_pov )
    @test comparedics( country_c_pov, country_d_pov )
end
