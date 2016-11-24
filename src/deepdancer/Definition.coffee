lodash = require 'lodash'

validTypes = ['alias', 'class', 'factory', 'value']

validLifespans = ['container', 'object', 'call']

fieldsDefaults =
  type: undefined
  lifespan: undefined
  dependencies: []
  setupCalls: []
  arityCheck: true

###
  The modules containing the keys will be configured from them if they are
  present in the module
###
extractFieldsFromKeys =
  type: '__type'
  lifespan: '__lifespan'
  dependencies: '__dependencies'
  setupCalls: '__setupCalls'
  arityCheck: '__arityCheck'


class Definition

  constructor: (@key,
              @value,
              options = {}) ->
    @_unwrapOptions(options)
    valueType = typeof @value
    if valueType in ['function', 'object']
      @_extractFromModule()
    if !@type?
      @type = 'value'
    if !@lifespan?
      @lifespan = 'container'
    @_validate()


  _unwrapOptions: (options) =>
    options = lodash.defaults(options, fieldsDefaults)
    for key of fieldsDefaults
      @[key] = options[key]


  _extractFromModule: =>
    for field, potentialModuleKey of extractFieldsFromKeys
      if @_hasFieldBeenOverriden(field)
        continue
      if potentialModuleKey of @value
        @[field] = @value[potentialModuleKey]


  _hasFieldBeenOverriden: (field) =>
    currentValue = @[field]
    defaultIsUndefined = !fieldsDefaults[field]?
    if (defaultIsUndefined) && currentValue?
      # field has been overriden nothing to do
      return true
    defaultCouldBeArray = typeof fieldsDefaults[field] == 'object'
    defaultIsArray = defaultCouldBeArray && ('length' of fieldsDefaults[field])
    if defaultIsArray && currentValue.length > 0
      # field has been overriden nothing to do
      return true
    defaultIsBoolean = typeof(fieldsDefaults[field]) == 'boolean'
    if defaultIsBoolean && currentValue != fieldsDefaults[field]
      # field has been overriden nothing to do
      return true
    return false


  _validate: =>
    if !(@type in validTypes)
      @_fail(@type + ' is not a valid type')
    if !(@lifespan in validLifespans)
      @_fail(@lifespan + ' is not a valid lifespan')
    for _, setupCall of @setupCalls
      if !('method' of setupCall) or !('args' of setupCall)
        @_fail('Incorrect setupCall \'method\' and \'args\' must be set')
    @_validateArity()


  _validateArity: =>
    if !@arityCheck || !(@type in ['factory', 'class'])
      return
    dependenciesLength = @dependencies.length
    arity = @value.length
    if dependenciesLength == arity
      return
    @_fail('Dependency arity is ' + arity + ' while the number of ' +
      'dependencies provides is ' + dependenciesLength + ' maybe you should ' +
      'set the arity check option to false')


  _fail: (message) =>
    throw new Error(@key + ': ' + message)


module.exports = Definition