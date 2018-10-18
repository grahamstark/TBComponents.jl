# Generating Weights for a dataset


This generates weights for a sample dataset such that weighted sums of dataset
columns match some set of targets. For example, you might want to weight a
dataset so that it matches known amounts of benefit receipts or numbers of
households in different regions of a country, or both.

A commercial product [Calmar](http://vesselinov.com/CalmarEngDoc.pdf) is
available for this, and widely used, but there are many advantages in having a
version that you can easily embed in a simulation program. It can be very useful
for producing forecasts, for example; see the papers by Reed and Stark and
Creedy in [the bibliography](biblio.md).

The routine calculates a set of weights that are closest in some sense to an
initial set of weights such that, when summed, the weighted data hits the
`target_populations`. Output is a Dict with a vector of weights and some
information on how the routine converged. The paper by [Merz](biblio.md) has a
good discussion of how to lay out the dataset.

```julia

function doreweighting(
    data               :: AbstractArray{ <:Real, 2 },
    initial_weights    :: AbstractArray{ <:Real, 1 }, # a column
    target_populations :: AbstractArray{ <:Real, 1 }, # a row
    functiontype       :: DistanceFunctionType,
    ru                 :: Real = 0.0,
    rl                 :: Real = 0.0,
    tolx               :: Real = 0.000001,
    tolf               :: Real = 0.000001 ) :: Dict{ Symbol, Any }

```
See the [testcase](../test/reweighter_tests.jl) for a simple example, based on
examples from the [Creedy](biblio.md) paper.

The form of 'closeness' used is determined by the `functiontype` parameter of
enumerated type `DistanceFunctionType`. See the [Creedy and Deville and
Sarndal](biblio.md) papers on these. Notes on these:

* `chi_square` - minimising the squared difference between old and new weights can produce negative weights;
* `constrained_chi_square` usually works best - this produces squared-difference weights that are at most `ru` times the original weight and at least `rl` times the original.
* the other measures are taken from the Deville and Sarndal paper and pass simple tests but sometimes fail to converge in real-world situations; whether this is because of something inherent or some mistake I've made I'm unsure;
* I believe Calmar implements different measures; see also [D’Souza](biblio.md).

## TODO

* I really need to use standard Julia optimiser packages, such as [Optim.jl](https://github.com/JuliaNLSolvers/Optim.jl). I was pushed for time, though;
* Chase up and add different closeness measures, e.g the Entropy measure I remember from an old Atkinson and Gomulka working paper, and whatever I can find elsewhere;
* the weird bug with the non-nested callback..
* am I using abstract arrays correctly?
* test with a huge dataset;
* how can I integrate this with a DataFrame?
