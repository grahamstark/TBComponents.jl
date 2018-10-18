# General Tax Calculations

This is incomplete and may be UK/Scotland - specific.

Various unfinished things, and two simple tax calculations.



## Direct Tax

This just does a simple calculation of how much is due given some taxable income and a set of tax rates and bands.

```julia
function calctaxdue(
      ;
   taxable :: Real,
   rates   :: RateBands,
   bands   :: RateBands ) :: TaxResult
```

`RateBands` is just an alias for an array of reals `Tax Result` is a struct with
amount due and ending band (for e.g. Marginal Rate calculations). The length of
`rates` and `bands` have to match, and the topmost `band` should be filled with
a number larger than any possible income. Bands should be the top of the band,
not the width.

## Indirect Tax

This function takes some recorded spending on a good, a typical price for that good, and the three types of tax that could be applied to it:

* Value Added Tax (VAT) - a tax on the input costs;
* Ad-Valorem - a tax on the selling price;
* Specific Tax - a per-unit tax.

In the UK/Scotland, only tobacco has all three applied to it. Alcohol has VAT
and specific duties.

The routine produces a record showing how much of each type of tax is paid, the `factor cost` (costs other than tax), and total tax paid.

```julia
function calc_indirect(
   ;
   expenditure   :: Real,
   selling_price :: Real,
   vat           :: Real,
   advalorem     :: Real,
   specific      :: Real ) :: IndirResult
```

I'm unclear if the exact calculation here applies to the UK/Scotland only. For
example, in the UK, VAT is charged on both the non-tax costs and the other
duties.

## Other things

There is also the skeleton of some other code here, for uprating tax bands according to the rules in the UK Finance Act (YEAR), and for the 'stepped' tax calculation formerly used for the UK National Insurance payroll tax. 

## TODO

* finish it;
* check how similar indirect tax regimes work in other countries.
