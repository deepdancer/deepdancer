[![Build Status](https://secure.travis-ci.org/deepdancer/deepdancer.png)](http://travis-ci.org/deepdancer/deepdancer)

**Looking for the [documentation](https://deepdancer.github.io/deepdancer-documentation/)**?

Intentions
===

A dependency injections system that:

* Requires only a light configuration
* Fallbacks to loading a module when a key is not declared
* Has its dependencies declared inside the modules (to reduce the probability
to miss an update)
* Support the overriding of the dependencies (for the purpose of testing)
* In my usecase, most if not all of my dependencies are named according to the
path of the module they contain. So far you should be able to name your
dependencies the way you want.

http://xkcd.com/927/

Similar project: https://github.com/nicocube/knit

