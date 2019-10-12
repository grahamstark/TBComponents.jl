using Test
using MiniTB
using TBComponents

# @test size( ps ) == 4
function getnet( data :: Dict, gross :: Float64 ) :: Float64
     person = data[:person]
     person.wage = gross
     person.hours = gross/DEFAULT_WAGE
     rc = calculate( person, data[:params] )
     return rc[:netincome]
end


function locmakebc( person :: Person, params :: Parameters ) :: BudgetConstraint
    data = Dict(
        :person=>person,
        :params=>params )
    bc = makebc( data, getnet )
    return bc
end

p1 = DEFAULT_PERSON
t1 = deepcopy(ZERO_PARAMS)
p1.wage = 100.0
t1.it_rate = [0.2,0.4]
t1.it_band = [50.0,99999]

@testset begin

    tax1 = calculatetax(p1, t1 )
    @test tax1 ≈ 30
    p1.wage += 1
    tax2 = calculatetax(p1, t1 )
    @test tax2-tax1 ≈ 0.4 # mr 0.4

    bc = locmakebc( p1, t1 )

    println( "bc=$bc" )
    @test size( bc )[1] in [3,4] # allow myself a spare...
end
