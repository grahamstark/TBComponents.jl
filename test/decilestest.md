using Printf
using Test
using IterableTables
using TableTraits
using IteratorInterfaceExtensions

include( "../src/poverty_inequality.jl" )

function dodecile()
    data = zeros( 100_000, 2 )
    inc = 0.0
    pop = 0.0
    total = 0.0
    for i in 1:100_000
        pop = 1.0
        inc += 1.0
        total += inc
        data[i,1] = pop
        data[i,2] = inc
    end
    print( "total income $total ; population $pop\n")
    deciles = binify( data, 10, 1, 2 )
    print( "Deciles $deciles \n")   
    quintiles = binify( data, 20, 1, 2 )
    print( "Quintiles $quintiles \n")   
    percentiles = binify( data, 100, 1, 2 )
    print( "Percentiles $percentiles \n")
end

dodecile()
