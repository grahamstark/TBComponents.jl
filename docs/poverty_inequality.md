# Poverty and Inequality

This generates various measures poverty and inequality from a sample dataset.

The measures are mostly taken from chs. 4-6 of the World Banks' [Handbook on Poverty and Inequality](biblio.md).

See the [test case for worked examples](../test/poverty_inequality_tests.jl)

## Poverty:

These routines can use both 2d arrays and dataframes as inputs For the arrays, supply with integers
giving the columns holding weights and incomes; for the frames, the names of the columns (as symbols).

```julia

function makepoverty(
    rawdata                       :: Array{<:Real, 2},
    line                          :: Real,
    growth                        :: Real,
    weightpos                     :: Integer = 1,
    incomepos                     :: Integer = 2,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS ) :: OutputDict

function makepoverty(
    rawdata,
    line                          :: Real,
    growth                        :: Real,
    weightcol                     :: Symbol,
    incomecol                     :: Symbol,
    foster_greer_thorndyke_alphas :: AbstractArray{<:Real, 1} = DEFAULT_FGT_ALPHAS,
     ) :: OutputDict    

```
notes:
* `rawdata` - each row is an observation; one col should be a weight, another is income;
positions assumed to be 1 and 2 unless weight and incomepos are supplied (or names as symbols for the frame version)
* the dataframe version can use anything that supports the [Queryverse iterable table interface](https://github.com/queryverse/IterableTables.jl);
* `line` - a poverty line. This is the same for for all observations, the income measure needs to be equivalised if the line differs by family size, etc.;
* `foster_greer_thorndyke_alphas` - coefficients for Foster-Greer Thorndyke poverty measures (see World Bank, ch. 4); note that FGT(0)
corresponds to the headcount measure and FGT(1) to poverty gap; count and gap are computed directly anyway but it's worth checking one against the other;
* `growth` is (e.g.) 0.01 for 1% per period, and is used for 'time to exit' measure.

Output is  dictionary with an entry for each measure.

## Inequality

Usage is similar to `makepoverty` above. See chs 5 and 6 of the World Bank book, and the [test case](../test/poverty_inequality_tests.jl) for more detail.

Version1:

```julia

function makeinequality(
    rawdata                    :: Array{<:Real, 2 },
    weightpos                  :: Integer = 1,
    incomepos                  :: Integer = 2,
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict

function makeinequality(
    rawdata,
    weightcol                  :: Symbol,
    incomecol                  :: Symbol,
    atkinson_es                :: AbstractArray{<:Real, 1} = DEFAULT_ATKINSON_ES,
    generalised_entropy_alphas :: AbstractArray{<:Real, 1} = DEFAULT_ENTROPIES ) :: OutputDict


```
Notes:
* `rawdata` a matrix with cols with weights and incomes;
* `atkinson_es` inequality aversion values for the Atkinson indexes;
* `generalised_entropy_alphas` vaues for Theil entropy measure;
* `weightpos` - column with weights
* `incomepos` - column with incomes

Return is a also a Dict of inequality measures.

There's also a method:

```Julia
function adddecomposedtheil( popindic :: OutputDict, subindices :: OutputDictArray ) :: OutputDict
```

which takes an array of output dicts, broken down by (e.g.) Regions, Genders, etc. and produces a Theil
index decomposition from them.


There's also a small `binify` routine which chops a dataset up
into chunks of cumulative income and population suitable for drawing [Lorenz Curves](https://en.wikipedia.org/wiki/Lorenz_curve).
