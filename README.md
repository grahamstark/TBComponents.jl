# TBComponents.jl

Some microsimulation stuff in Julia. This is a library of some general purpose
code for building tax-benefit models. My intention is to use this as part of a
Tax Benefit model for Scotland. That will be a separate project.

There is code for:

* [generating standard poverty and inequality measures](docs/poverty_inequality.md);
* [generating exact piecewise-linear budget constraints](docs/piecewise_linear_generator.md);
* [reweighting a dataset so the weighted dataset meets a set of targets](docs/reweighter.md); and
* [some general-purpose taxation components](docs/taxcalcs.md).

There's lots to do. I'm new to this language and have based this code
on versions from other languages, so the code is likely not very idiomatic and
I'm sure could be made more efficient.

* fuller docs;
* better test suite;
* more inequality measures: Palma, bits of decomposable indexes;
* understand generics better;
* fix the TODOs

## More

[Further Reading](docs/biblio.md)
