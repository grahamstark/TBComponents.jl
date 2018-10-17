
@enum NetType  NetIncome TotalTaxes BenefitsOnly

struct Person
        wage :: Float64
        age  :: Integer
end

struct Parameters
   it_allow :: Float64
   it_rate  :: Array{Float64}
   it_band  :: Array{Float64}

   benefit1 :: Float64
   benefit2 :: Float64
   ben2_l_limit :: Float64
   ben2_u_limit :: Float64

   function Parameters(
      ;
      it_allow :: Float64,
      it_rate  :: Array{Float64},
      it_band  :: Array{Float64},

      benefit1 :: Float64,
      benefit2 :: Float64,
      ben2_l_limit :: Float64,
      ben2_u_limit :: Float64
      )
      new( it_allow, it_rate, it_band, benefit1, benefit2, ben2_l_limit, ben2_u_limit )
   end

end

const DEFAULT_PARAMS = Parameters(
        it_allow=500.0,
        it_rate= [2500, 4000, 5000, 8000, 9000, 10000, 12000, 9999999999999999999.99],
        it_band=[ 2500, 4000, 5000, 8000, 9000, 10000, 12000, 9999999999999999999.99 ],
        benefit1 = 150.0,
        benefit2 = 60.0,
        ben2_l_limit = 200.03,
        ben2_u_limit = 300.20 )

public struct Results{

        public double Tax {get;set;}
        public double[] Benefit {get;set;}
        public double NetIncome {get;set;}
        public double MR {get;set;}
}
