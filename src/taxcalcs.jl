"
Various Standard Tax calculations
"

const RateBands = AbstractArray{<:Real}

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

function uprate!(
   x         :: Real,
   uprate_by :: Real,
   next      :: Real = 0.0 )
   # TODO
end

function uprate!(
   bands     :: RateBands,
   uprate_by :: Real,
   next      :: Real = 0.0 )
   # TODO
end

function stepped_tax_calculation(
   ;
   taxable :: Real,
   rates   :: RateBands,
   bands   :: RateBands ) :: TaxResult
      # TODO

end

function calctaxdue(
      ;
   taxable :: Real,
   rates   :: RateBands,
   bands   :: RateBands ) :: TaxResult
   due = 0.0
   mr  = 0.0
   remaining = taxable
   i = 1
   while remaining > 0.0
      if i > 1
         gap = bands[i]-bands[i-1]
      else
         gap = bands[1]
      end
      t = min( remaining, gap )
      due += t*rates[i]
      remaining -= gap
      i += 1
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
