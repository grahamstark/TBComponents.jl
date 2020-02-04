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
    tr = calctaxdue( taxable=inc, rates=rates, thresholds=bands )
    @test tr.due ≈ 30.0
    tr = calctaxdue( taxable=inc, rates=[1.0], thresholds=[999] )
    @test tr.due ≈ 100.0


    # tests of length of bands
    tr = calctaxdue(taxable=10.0,rates=[0.12,0.21], thresholds=[12.0,99999999999999])
    @test tr.due ≈ 1.2

    tr = calctaxdue(taxable=10.0,rates=[0.12,0.21], thresholds=[12.0])
    @test tr.due ≈ 1.2

    tr = calctaxdue(taxable=10.0,rates=[0.12], thresholds=zeros(0))
    @test tr.due ≈ 1.2

end # testset
