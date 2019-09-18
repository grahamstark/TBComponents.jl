module MiniTB

using TBComponents
#
# A toy tax-benefit system with outlines of the components
# a real model would need: models of people (and households)
# a parameter system, a holder for results, and some calculations
# using those things.
# Used in test building budget constraints.
# There's also some experiments of mine with constructors
# and copying strucs.
#

export calculate, DEFAULT_PERSON, modifiedcopy, Parameters, Person, getnet
export modifiedcopy, DEFAULT_PARAMS
export Gender, Male, Female
export NetType, NetIncome, TotalTaxes, BenefitsOnly

@enum NetType  NetIncome TotalTaxes BenefitsOnly
@enum Gender Male Female

# experiment with types
const NullableFloat = Union{Missing,Float64}
const NullableInt = Union{Missing,Integer}
const NullableArray = Union{Missing,Array{Float64}}

mutable struct Person
        wage :: Float64
        age  :: Integer
        sex  :: Gender
end

const DEFAULT_PERSON = Person( 1_000.0, 40, Female )

function modifiedcopy(
   copyFrom :: Person;
   wage     :: NullableFloat = missing,
   age      :: NullableInt = missing
   ) :: Person

   Person(
      wage !== missing ? wage : copyFrom.wage,
      age !== missing ? age : copyFrom.age,
      copyFrom.sex
   )
end


mutable struct Parameters
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
# Just a test of an idea
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
        it_rate= [ 0.25, 0.5 ],
        it_band=[ 10000, 9999999999999999999.99 ],
        benefit1 = 150.0,
        benefit2 = 60.0,
        ben2_l_limit = 200.03,
        ben2_u_limit = 300.20 )


const Results = Dict{ Symbol, Any }

## need to include taxcalcs higher up

function calculatetax( pers :: Person, params :: Parameters ) :: Float64
   taxable = max( 0.0, pers.wage - params.it_allow )
   tc :: TaxResult = calctaxdue(
      taxable = taxable,
      rates   = params.it_rate,
      bands   = params.it_band
    )
    return tc.due
end

function calculatebenefit1( pers :: Person, params :: Parameters ) :: Float64
   return ( pers.wage <= params.benefit1 ? params.benefit1-pers.wage : 0.0 );
end

function calculatebenefit2( pers :: Person, params :: Parameters ) :: Float64
   b = pers.wage >= params.ben2_l_limit ? params.benefit2 : 0.0
   if pers.wage > params.ben2_u_limit
      b -= 30.0
   end
   return b
end

function calculate( pers :: Person, params :: Parameters ) :: Results
   res = Results()
   res[:tax] = calculatetax( pers, params )
   res[:benefit1] = calculatebenefit1( pers, params )
   res[:benefit2] = calculatebenefit2( pers, params )
   res[:netincome] = pers.wage + res[:benefit1] + res[:benefit2] - res[:tax]
   return res
end

end
