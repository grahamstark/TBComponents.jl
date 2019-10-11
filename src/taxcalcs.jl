"
Various Standard Tax calculations. Very incomplete.
"

const RateBands = AbstractArray{<:Number}

const IncomesDict = Dict{Any,Real}

const WEEKS_PER_YEAR = 365.25/7.0

function weeklyise( annual_amount )
   round(annual_amount/WEEKS_PER_YEAR, digits=6) # round( x, digits=2) possibly
end

function annualise( weekly_amount :: Number )
   round( weekly_amount*WEEKS_PER_YEAR, digits=2)
end

## TODO rooker wise style stuff

"""
   Useful for e.g. calculating expenses against a list
   of eligible expenses
"""
function times( m1::IncomesDict, m2::IncomesDict)::Real
   m = 0.0
   ikey = intersect( keys(m1), keys(m2))
   for k in ikey
      m += m1[k]*m2[k]
   end
   m
end

import Base.*

function *(m1::IncomesDict, m2::IncomesDict)
    times(m1, m2)
end

struct TaxResult{T<:Real}
   due :: T
   end_band :: Integer
end

struct IndirResult{T<:Real}
   factor_cost :: T
   vat         :: T
   addvalorem  :: T
   specific    :: T
   total       :: T
end

"""
UK (and maybe other) systems have uprating rules for rates and bands
in legislation. For example, next £10 or £100 annually.
"""
function uprate!(
   x         :: Real,
   uprate_by :: Real,
   next      :: Real = 0.0 )
   # TODO
end

"""
UK Tax bands have special rules - annual band *gaps* uprated to *next* £100
"""
function uprate!(
   bands     :: RateBands,
   uprate_by :: Real,
   next      :: Real = 0.0 )
   # TODO
end

"""
e.g. Pre 1996 (?) National Insurance (check!)
"""
function stepped_tax_calculation(
   ;
   taxable :: Real,
   rates   :: RateBands,
   bands   :: RateBands ) :: TaxResult
      # TODO

end

"""
Tax due on `taxable` income, given rates and bands
"""
function calctaxdue(
      ;
   taxable :: Number,
   rates   :: RateBands,
   bands   :: RateBands ) :: TaxResult
   due = 0.0
   mr  = 0.0
   remaining = taxable
   i = 0
   while remaining > 0.0
      i += 1
      if i > 1
         gap = bands[i]-bands[i-1]
      else
         gap = bands[1]
      end
      t = min( remaining, gap )
      due += t*rates[i]
      remaining -= gap
   end
   TaxResult( due, i )
end

#
# Factor cost (tax exclusive cost) given VAT, per unit tax and ad valorem tax).
#
# @param selling_price per unit in some currency
# @param advalorem - tax as % of final selling price as 0.2 for 20%, for instance
# @param vat tax as % of input costs (including advalorem and specific duties) 0.175 for 17.5% e.g.
# @param
#
function calc_factor_cost(
   ;
   selling_price :: Real,
   vat           :: Real,
   advalorem     :: Real,
   specific      :: Real ) :: Real

   p = selling_price
   v = vat
   a = advalorem
   s = specific
   return ( p * ( 1.0 - a - ( v * a ))/( 1.0 + v ) ) - s;
end

function calc_indir_components_per_unit(
   ;
   selling_price :: Real,
   vat           :: Real,
   advalorem     :: Real,
   specific      :: Real ) :: IndirResult
   factor_cost = calc_factor_cost(
      selling_price = selling_price,
      vat           = vat,
      advalorem     = advalorem,
      specific      = specific );

   add     = advalorem * selling_price
   vat_due = vat * (factor_cost+add+specific)
   total   = vat_due + add + specific
   IndirResult( factor_cost, vat_due, add, specific, total )
end

"""
Given total expenditure, an average selling price (£20 per bottle of whisky), and vat (% of inputs, inc. other taxes),
advalorem (e.g. £10 per bottle), and specific (% of final selling price), calculate indirect taxes due, on assumption of unit price elasticity
(e.g. constant spending). Selling price should have same units as advalorem.
"""
function calc_indirect(
   ;
   expenditure   :: Real,
   selling_price :: Real,
   vat           :: Real,
   advalorem     :: Real,
   specific      :: Real ) :: IndirResult
   per_unit = calc_indir_components_per_unit(
      selling_price = selling_price,
      vat           = vat,
      advalorem     = advalorem,
      specific      = specific )
   q = expenditure / selling_price
   IndirResult(
      q*per_unit.factor_cost,
      q*per_unit.vat,
      q*per_unit.addvalorem,
      q*per_unit.specific,
      q*(per_unit.vat + per_unit.specific + per_unit.addvalorem)
   )
end
