using Test

@testset "Some tests of our rate band and indirect tax calcs" begin

    # TODO

    calc_indirect(
           expenditure=100.0,
           selling_price=10,
           vat=0.20,
           advalorem = 0.4,
           specific = 2.0 )


    inc = 100.0
    rates = [0.2,0.4]
    bands = [50.0,99999]
    tr = calctaxdue( taxable=inc, rates=rates, bands=bands )
    @test tr.due ≈ 30.0
    tr = calctaxdue( taxable=inc, rates=[1.0], bands=[999] )
    @test tr.due ≈ 100.0


end # testset
