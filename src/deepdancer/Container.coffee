Definition = require 'deepdancer/Definition'
dependencyResolver = require 'deepdancer/dependencyResolver'

class Container

  constructor: ->
    @_definitions = {}
    @_instances = {}
    @_autoregisteredRootModules = []
    @_pendingResolutionModules = []


  register: (args...) =>
    definition = new Definition(args...)
    key = args[0]
    @_definitions[key] = definition


  setModulesAsAutoregistered: (rootModuleName) =>
    @_autoregisteredRootModules.push(rootModuleName)


  registerFromModule: (args...) =>
    moduleName = args[0] #name and future key
    value = require moduleName
    remainingArgs = args[1..]
    remainingArgs.unshift(value)
    remainingArgs.unshift(moduleName)
    @register(remainingArgs...)


  has: (key) =>
    if key of @_instances
      return true
    return (key of @_definitions)


  get: (key, lifespan, providedDependencies = {}) =>
    lookupInInstances = !lifespan? || (lifespan == 'container')
    if lookupInInstances && (key of @_instances)
      return @_instances[key]

    @_markAsPendingResolution(key, lifespan)
    try
      instance = @_getInstance(key, lifespan, providedDependencies)
    catch e
      throw e
    finally
      @_markAsResolved(key, lifespan)
    instance


  ###
  Eagerly loads all the defined components. Use this function for testing your
  container or to see what external modules will end up registered.
  ###
  eagerLoad: =>
    for key, _ of @_definitions
      @get(key)


  _getInstance: (key, lifespan, providedDependencies) =>
    if key of @_definitions
      return @_getFromDefinition(key, lifespan, providedDependencies)
    else if @_isAutoregisteredModule(key)
      @registerFromModule(key)
      return @_getFromDefinition(key, lifespan, providedDependencies)
    else
      return @_getFromModule(key, lifespan)


  _isAutoregisteredModule: (moduleName) =>
    for _, autoregisteredRootModuleName of @_autoregisteredRootModules
      if moduleName.indexOf(autoregisteredRootModuleName) == 0
        return true
    false


  _getFromDefinition: (key, lifespan, providedDependencies) =>
    definition = @_definitions[key]
    if !lifespan?
      lifespan = definition.lifespan
    dependencyInstance = dependencyResolver(definition,
      this, lifespan, providedDependencies)
    if lifespan == 'container'
      @_instances[key] = dependencyInstance
    dependencyInstance


  _getFromModule: (key, lifespan) =>
    dependencyInstance = require key
    @_markAsResolved(key, lifespan)
    if !lifespan?
      lifespan = 'container'
    if lifespan == 'container'
      @_instances[key] = dependencyInstance
    dependencyInstance


  _markAsPendingResolution: (key, lifespan = 'container') =>
    if lifespan != 'container'
      # _ We don't handle circular resolution outside 'container' lifespan
      # _ But why?
      # _ I don't fucking know, we never need them ... Add that if you want!
      return
    if key in @_pendingResolutionModules
      pendingList = '\'' + @_pendingResolutionModules.join('\', ') + '\''
      message = 'deepdancer is detecting a circular error while resolving ' +
        '\'' + key + '\'' + ' modules pending resolution: ' + pendingList
      throw new Error(message)
    @_pendingResolutionModules.push(key)


  _markAsResolved: (key, lifespan = 'container') =>
    if lifespan != 'container'
      # We don't handle circular resolution outside container lifespan
      return
    currentIndex = @_pendingResolutionModules.indexOf(key)
    @_pendingResolutionModules[currentIndex..currentIndex] = []


    
module.exports = Container