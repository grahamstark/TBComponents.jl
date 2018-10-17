
@enum NetType  NetIncome TotalTaxes BenefitsOnly

# experiment with types
const NullableFloat = Union{Missing,Float64}
const NullableInt = Union{Missing,Integer}
const NullableArray = Union{Missing,Array{Float64}}

struct Person
        wage :: Float64
        age  :: Integer
end

const DEFAULT_PERSON = Person( 1_000.0, 40 )

function modifiedcopy(
   copyFrom :: Person;
   wage     :: NullableFloat = missing,
   age      :: NullableInt = missing
   ) :: Person

   Person(
      wage !== missing ? wage : copyFrom.wage,
      age !== missing ? age : copyFrom.age
   )
end


struct Parameters
   it_allow :: Float64
   it_rate  :: Array{Float64}
   it_band  :: Array{Float64}

   benefit1 :: Float64
   benefit2 :: Float64
   ben2_l_limit :: Float64
   ben2_u_limit :: Float64

   # attempt a constructor with named parameters
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

#
# e.g newpars = modifiedcopy( DEFAULT_PARAMS, it_allow=3_000 )
#
function modifiedcopy(
   copyFrom :: Parameters;
   it_allow :: NullableFloat = missing,
   it_rate  :: NullableArray = missing,
   it_band  :: NullableArray = missing,

   benefit1 :: NullableFloat = missing,
   benefit2 :: NullableFloat = missing,
   ben2_l_limit :: NullableFloat = missing,
   ben2_u_limit :: NullableFloat = missing
   ) :: Parameters

   x = it_allow !== missing ? it_allow : copyFrom.it_allow
   Parameters(
      it_allow = it_allow !== missing ? it_allow : copyFrom.it_allow,
      it_rate  = it_rate  !== missing ? it_rate : copyFrom.it_rate,
      it_band  = it_band  !== missing ? it_band : copyFrom.it_band,

      benefit1 = benefit1 !== missing ? benefit1 : copyFrom.benefit1,
      benefit2 = benefit2 !== missing ? benefit2 : copyFrom.benefit2,
      ben2_l_limit = ben2_l_limit !== missing ? ben2_l_limit : copyFrom.ben2_l_limit,
      ben2_u_limit = ben2_u_limit !== missing ? ben2_u_limit : copyFrom.ben2_u_limit
   )
end

const DEFAULT_PARAMS = Parameters(
        it_allow=500.0,
        it_rate= [2500, 4000, 5000, 8000, 9000, 10000, 12000, 9999999999999999999.99],
        it_band=[ 2500, 4000, 5000, 8000, 9000, 10000, 12000, 9999999999999999999.99 ],
        benefit1 = 150.0,
        benefit2 = 60.0,
        ben2_l_limit = 200.03,
        ben2_u_limit = 300.20 )


const Results = Dict{ Symbol, Any }
