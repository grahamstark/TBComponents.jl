# Piecewise Linear Budget Constraints

This generates a complete two-dimensional budget constraints for some unit
(person, benefit-unit, household, etc.) for some tax-benefit system. That is, a
list points describing the combinations of net income that the unit would get for different values of gross income (or hours worked, wages, etc.).

See Duncan and Stark in [the bibliography](biblio.md) for more on the idea.

## Usage

Define a function that returns the net income for some gross value - this could be (e.g.) hours worked, wage, or gross income
```julia
   function getnet( gross :: Real ) :: Real
```
I've found the simplest way to do this in Julia is to use nested functions, as in:

```julia


function makebc( pers :: Person, params :: Parameters ) :: BudgetConstraint

    function getnet( gross :: Float64 ) :: Float64
        # edit the person to change wage, see the tests/minitb.jl
        persedit = modifiedcopy( pers, wage=gross )
        rc = calculate( persedit, params )
        return rc[:netincome]
    end

    bc = TBComponents.makebc( getnet )

    return bc
end

```

where `calculate` is a call to some function that does a full set of
calculations for this person and returns a record which includes a new net income. The call to `makebc` then generates the budget constraint using `getnet`. If successful this returns a BudgetConstraint array, which is a collection of `x,y` points describing all the points where the budget constraint has a change of slope, where `x` is the gross value and `y` the net.

The routine is controlled by a `BCSettings` struct; there is a `DEFAULT_SETTINGS` constant version of this which I suggest you don't change, apart from perhaps the upper and lower x-bounds of the graph.


## Problems/TODO

* the tolerance isn't used consistently (see `nearlysameline`);
* I may be misunderstanding abstract types in the declarations;
* possibly use some definition of point, line, etc. from some standard package.
