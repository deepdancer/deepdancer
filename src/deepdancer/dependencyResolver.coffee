class DependencyResolver

  # coffeelint: disable=no_empty_functions
  constructor: (@definition, @container, @lifespan, @providedDependencies) ->
  # coffeelint: enable=no_empty_functions


  resolve: ->
    dependencyInstance = @_getInstance()
    @_applySetupCalls(dependencyInstance)
    dependencyInstance


  _getInstance: ->
    if @definition.type == 'alias'
      return @container.get(@definition.value, @lifespan, @providedDependencies)
    if @definition.type == 'value'
      return @definition.value
    resolvedDependencies = @_getResolvedDependencies(@definition.dependencies)
    if @definition.type == 'class'
      return new @definition.value(resolvedDependencies...)
    # this is a factory
    @definition.value(resolvedDependencies...)


  _applySetupCalls: (dependencyInstance) =>
    for _, setupCall of @definition.setupCalls
      {method, args} = setupCall
      resolvedDependencies = @_getResolvedDependencies(args)
      dependencyInstance[method](resolvedDependencies...)


  _getResolvedDependencies: (dependencies) =>
    resolvedDependencies = []
    for _, dependency of dependencies
      resolved = @_resolveDependency(dependency)
      resolvedDependencies.push(resolved)
    return resolvedDependencies


  _resolveDependency: (dependency) =>
    dependencyType = typeof dependency
    if dependencyType == 'object'
      # we handle the special case to send a string {type: 'string',
      # value: 'valuetosend' }
      typeIsString = ('type' of dependency) & (dependency.type == 'string')
      valueIsString = ('value' of dependency) & (typeof dependency.value ==
          'string')
      if typeIsString && valueIsString
        return dependency.value

      # otherwise it's just an object that we return
      return dependency

    if dependencyType != 'string'
      # It's not a string, let's not even try to load it
      return dependency

    if dependency of @providedDependencies
      # dependency is provided
      return @providedDependencies[dependency]

    dependencyLifespan = @lifespan
    if @lifespan == 'object' # this lifespan doesn't cascade
      dependencyLifespan = 'container'

    @container.get(dependency, dependencyLifespan, @providedDependencies)



module.exports = (args...) ->
  (new DependencyResolver(args...)).resolve()