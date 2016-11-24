[![Build Status](https://secure.travis-ci.org/deepdancer/deepdancer.png)](http://travis-ci.org/deepdancer/deepdancer)

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

Pros
===

* The above **Intentions**.
* High test coverage.
* Tested and improved since more than nine months before release on the backend
of https://konnectr.co/ , a coverage of more than 90% on the core of the
application (we probably have your use cases covered).

Cons
===

* The library being resolving dependency recursively, the callstack may
be quite long when an error occures while loading an object.

Basic usage
===

Declaring dependencies
---

```js
// This example is the most common use case a factory.

// The myModuleFactory will be called once with your depency as an argument.
var myModuleFactory = function(someOfMyProjectDependency, fs) {

    // This is what will be trully exposed to the rest of the components in
    // deepdancer
    var myModule = function(anArgument) {

    };

    return myModule;
};

// This should be processed as a factory
myModuleFactory.__type = 'factory'

// Dependencies of the module
// Please note that using different paths to access the same dependency
// will lead to problems
myModuleFactory.__dependencies = ['myproject/someOfMyProjectDependency', 'fs']

module.exports = myModuleFactory
```

Using dependencies
---

In the example above, `myProject/someOfMyProjectDependency` can be a
module declared somewhere in your code under the path
`myProject/someOfMyProjectDependency`.

Running: calling your first dependencies somewhere
---

```js
// Once in the main file of your application you will need to instantiate the
// container to manage your dependencies.

// You shouldn't do this outside of your main file and your tests.
dependencies = new (require('deepdancer').Container)()

// This is optional but in the nominal case you want to tell that you module is
// composed of modules that are autoloading themselves in deepdancer.
dependencies.setModulesAsAutoregistered('myProject')

dependencies.get('myProject/app').run()
```

Documentation
===

Every example below assumes that you have a container instanciated for your
dependencies.

```js
dependencies = new (require('deepdancer').Container)()
```

Internals that may help your understanding
---

* A `deepdancer` container contains a dictionary of definitions, describing how
to instantiate the items
* A `deepdancer` container contains a dictionary of instances, storing the items
after instantiation.
* `deepdancer` does not contain any singleton or global variable.

Dependency definition options
---

They can all either:

* Be passed upon an explicit call to `register` through the
third, `options` argument.
* Autoregistered (if it belongs to an autoregistered root module) by exposing
fields in the raw module (what you put in
`module.exports`): `__type`, `__lifespan`, `__dependencies`, `__setupCalls` and
`__arityCheck`.

### type

* `alias`: the dependency value is just an alias pointing to another one.
* `class`: the dependency value is a class, upon retrieval an object will be
  instanciated with all dependencies passed to the constructor
* `factory`: the dependency value is a factory upon retrieval it will be
  called with all dependencies passed as arguments.
* `value`: the dependency is a value to be provided as is.

The default is `value`.

### lifespan

* `container`: the dependency will be kept in the container.
* `object`: the dependency won't be retrieved nor stored in the container, but
it's dependencies may be. You will get a new item composed of dependencies from
the registry
* `call`: Neither the dependency or its dependencies will be retrieved nor
stored in the container. You will get a new item composed of other new items.

The default is `container`.

### dependencies

An array containing the dependencies for this item (can be an object or a
factory in that case).

A dependency can be:

* A`string` that will be used as key in the registry.
* An `object` of the form `{type: 'string', value: 'someValue'}`, a way to pass
a string that will not be used as a key in the registry.
* Anything else that will be used as is.

The default is an empty array, meaning no dependency.

### setupCalls

An array of objects of the form:

```js
var setupCalls = [{
    method: 'initializeApplication',
    args: ['router', 'express']
},
...
];
```

For each entry, the method will be called on the item with the provided args as
dependencies. `args` here is just an array of dependencies, following the same
resolution process as any other mentionned dependencies (see above)

The default value is an empty array, meaning no setup call.

### arityCheck

A boolean enabling arity check.

If you use deepdancer without the autoloading features of deepdancer-darkmagic,
you may get easily into strange problem when you change the arguments of your
factory or objects. The arityCheck option will raise an error if the number of
dependencies does not match the number of expected arguments of the factory or
class constructor.

The default value is `true`.

Note about container access and methods
---

There are two usecases where it is ok to interact with the container:

* Initializing it
* Writing tests

If you are doing something else, then you are probably doing something wrong.

register(key, value, options)
---

Arguments:

* key: the key in the registry, how you will name your dependencies
* value: the value to be registered could be anything a class, an object,
a factory, an int.
* options (optional): a dictionary of options that can be used


setModulesAsAutoregistered(rootModuleName)
---

Arguments:

* rootModuleName: the root module name, this also could be not a full module.
For example if you want to autoload thinks like
`myProject/generic/controller` and `myProject/app/router` you can
autoregister `'myProject'` even if no `myProject/index.js' exists.

Mark all submodules as autoregistered.

has(key)
---

Arguments:

* key: the dependency key to check

Tells if the key is in the dependency container.

get(key, lifespan, providedDependencies)
---

Arguments:

* key: the key to get the dependency
* lifespan (optional): the lifespan in which instantiating the dependency
* providedDependencies (optional): a dictionary of provided dependency that will
be looked up before the internal registry of the container

Retrieve an element from the container.

eagerLoad
---

By default, deepdancer only loads your dependencies when they are needed, if
you want to load all of the registered definition `eagerLoad` is the way to go.