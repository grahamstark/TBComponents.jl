# Poverty and Inequality

This generates various measures poverty and inequality from a sample dataset.

The measures are mostly taken from chs. 4-6 of the World Banks' [Handbook on Poverty and Inequality](biblio.md).

See the [test case for worked examples](../test/poverty_inequality_tests.jl)

## Poverty:


```julia

function makepoverty(
    rawdata                       :: AbstractArray{<:Real, 2},
    line                          :: Real,
    growth                        :: Real = 0.0,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS,
    weightpos                     :: Integer = 1,
    incomepos                     :: Integer = 2 ) :: Dict{ Symbol, Any }


```
notes:
* `rawdata` - each row is an observation; one col should be a weight, another is income;
positions assumed to be 1 and 2 unless weight and incomepos are supplied
* `line` - a poverty line. This is the same for for all observations, the income measure needs to be equivalised if the line differs by family size, etc.;
* `foster_greer_thorndyke_alphas` - coefficients for Foster-Greer Thorndyke poverty measures (see World Bank, ch. 4); note that FGT(0)
corresponds to the headcount measure and FGT(1) to poverty gap; count and gap are computed directly anyway but it's worth checking one against the other;
* `growth` is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.

Output is  dictionary with an entry for each measure.

## Inequality

Usage is similar to `makepoverty` above. See chs 5 and 6 of the World Bank book, and the [test case](../test/poverty_inequality_tests.jl) for more detail.

```julia

function makeinequality(
    rawdata                    :: AbstractArray{<:Real, 2},
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES,
    weightpos                  :: Integer = 1,
    incomepos :: Integer = 2 ) :: Dict{ Symbol, Any }

```
Notes:
* `rawdata` a matrix with cols with weights and incomes;
* `atkinson_es` inequality aversion values for the Atkinson indexes;
* `generalised_entropy_alphas` vaues for Theil entropy measure;
* `weightpos` - column with weights
* `incomepos` - column with incomes

Return is a also a Dict of inequality measures.

There's also a small `binify` routine which chops a dataset up
into chunks of cumulative income and population suitable for drawing [Lorenz Curves](https://en.wikipedia.org/wiki/Lorenz_curve).

## TODO

* more inequality measures: [Palma](https://www.cgdev.org/blog/palma-vs-gini-measuring-post-2015-inequality) - though that's easy from binify(a,10)
* sub-components of decomposable indexes;
* better understand how Julia does generics
* ..
