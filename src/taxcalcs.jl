"
Various Standard Tax calculations. Very incomplete.
"

const RateBands = Array{Real}

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
   FIXME I don't really understand why Dict{T,Number} works here but Dict{Any,Number} doesn't
"""
function times( m1::Dict{T,Real}, m2::Dict{T,Real})::Real where T
   m = 0.0
   ikey = intersect( keys(m1), keys(m2))
   for k in ikey
      m += m1[k]*m2[k]
   end
   m
end

import Base.*

function *(m1::Dict{T,Real}, m2::Dict{T,Real}) :: Real where T
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
Tax due on `taxable` income, given rates and thresholds
rates can be one more than thresholds, in which case the last band is assumed infinite.
Rates should be (e.g.) 0.12 for 12%.
"""
function calctaxdue(
      ;
   taxable    :: Number,
   rates      :: RateBands,
   thresholds :: RateBands ) :: TaxResult
   nbands = length(bands)[1]
   nrates = length(rates)[1]

   @assert (nrates >= 1) && ((nrates - nthresholds) in 0:1 ) # allow thresholds to be 1 less & just fill in the top if we need it
   due = 0.0
   mr  = 0.0
   remaining = taxable
   i = 0
   if nthresholds > 0
      maxv = typemax( typeof( thresholds[1] ))
      gap = thresholds[1]
   else
      maxv = typemax( typeof( taxable ))
      gap = maxv
   end
   while remaining > 0.0
      i += 1
      if i > 1
         if i < nrates
            gap = thresholds[i]-thresholds[i-1]
         else
            gap = maxv
         end
      end
      t = min( remaining, gap )
      # println( "got gap as $gap remaining $remaining")
      due += t*rates[i]
      remaining -= gap
   end
   TaxResult( due, i )
end

"""
Factor cost (tax exclusive cost) given VAT, per unit tax and ad valorem tax).

@param selling_price per unit in some currency
@param vat tax as proportion of input costs (including advalorem and specific duties) 0.175 for 17.5% e.g.
@param advalorem - tax as proportion of final selling price as 0.2 for 20%, for instance
@param specific - amount per (e.g.) bottle, packet, etc. in same units as selling price.

"""
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

"""
@param selling_price per unit in some currency
@param vat tax as proportion of input costs (including advalorem and specific duties) 0.175 for 17.5% e.g.
@param advalorem - tax as proportion of final selling price as 0.2 for 20%, for instance
@param specific - amount per (e.g.) bottle, packet, etc. in same units as selling price.
"""
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
Given:

* total expenditure;
* an average selling price (£20 per bottle of whisky, say),
* vat (proportion of inputs, inc. other taxes - 0.2 for 20%, say),
* advalorem (proportion of final selling price); and
* specific (e.g. £10 per bottle).

Calculate indirect taxes due, on assumption of unit price elasticity
(e.g. constant spending).

Selling price should have same units as advalorem.
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

function thresholds_to_bands( thresh :: RateBands ) :: RateBands
   n = size( thresh )[1]
   bands = RateBands(undef,n)
   bands[1] = thresh[1]
   for i in 2:n
      bands[i]=thresh[i]-thresh[i-1]
   end
   bands
end

function bands_to_thresholds( bands :: RateBands ) :: RateBands
   n = size( bands )[1]
   thresholds = RateBands(undef,n)
   thresholds[1] = bands[1]
   for i in 2:n
      thresholds[i]=thresholds[i-1]+bands[i]
   end
   thresholds;
end


"""
A little thing that comes up in UK income tax where tax on different sources
is applied progressively, with possibly different rates and bands for each source.

If rates are
    0.1,0.2,0.4
and thresholds are:
    100,200
then
    delete_bands_up_to( rates=rates, bands=bands, 101 )
gives
    rates = 0.2,0.4 bands = 99,200
"""
function delete_thresholds_up_to( ; rates :: RateBands, thresholds :: RateBands, upto :: Real )
  total = 0.0
  bands = thresholds_to_bands( thresholds )
  last_total = 0.0
  firstband = 0.0
  num_bands = size( bands )[1]
  deleteband = -1
  n = size( bands )[1]
  for i in 1:n
    total += bands[i]
    if total > upto
      deleteband = i
      firstband = upto - last_total
      break
    elseif i == n
      deleteband = -1
    end
    last_total = total
  end # 1:n
  if deleteband > 0
    rates = rates[deleteband:end]
    bands = bands[deleteband:end]
    bands[1] -= firstband
  elseif deleteband == -1
    rates = rates[end:end]
    bands :: RateBands = [ Inf ]
  end

  rates, bands_to_thresholds(bands)
end
