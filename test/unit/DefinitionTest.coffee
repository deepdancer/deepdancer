{expect, config} = require 'chai'

config.includeStack = true

Definition = require 'deepdancer/Definition'

# coffeelint: disable=cyclomatic_complexity
describe 'deepdancer/Definition', ->
  it 'should correctly validate the type', ->
    errorRaised = false
    try
      definition = new Definition('somekey', 'avalue')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false
    expect(definition.type).to.be.equal 'value'

    errorRaised = false
    try
      new Definition('somekey', Error, {
        type: 'class',
        arityCheck: false
      })
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false

    errorRaised = false
    try
      new Definition('somekey', (-> 'hi'), type: 'factory')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false

    errorRaised = false
    try
      new Definition('somekey', 'avalue', type: 'Jean-Paul Sartre')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.true

  it 'should correctly validate the lifespan', ->
    errorRaised = false
    try
      new Definition('somekey', 'avalue', lifespan: 'container')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false

    errorRaised = false
    try
      new Definition('somekey', 'avalue', lifespan: 'call')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false

    errorRaised = false
    try
      new Definition('somekey', 'avalue', lifespan: 'callaaaa')
    catch e
      errorRaised = true
    expect(errorRaised).to.be.true

  it 'should correctly validate the setupCalls', ->
    correctSetupCall1 =
      method: 'someMethod'
      args: []

    correctSetupCall2 =
      method: 'someMethod2'
      args: [1,2,3]

    incorrectSetupCall =
      method: 'someMethod3'
      ar: [1,2,3]

    errorRaised = false
    try
      new Definition('somekey', 'avalue', {
        lifespan: 'container',
        setupCalls: [correctSetupCall1, correctSetupCall2]
      })
    catch e
      errorRaised = true
    expect(errorRaised).to.be.false

    errorRaised = false
    try
      new Definition('somekey', 'avalue', {
        lifespan: 'container'
        setupCalls: [correctSetupCall1, incorrectSetupCall]
      })
    catch e
      errorRaised = true
    expect(errorRaised).to.be.true

  testDescription = 'should properly load setup type, lifespan, calls and ' +
      'dependencies from the values'
  it testDescription, ->
    class TestClass
      @__dependencies: [12]
      @__type = 'class'
      @__lifespan =  'call'

      constructor: (@someValue) ->
        @port = undefined

      setPort: (port) =>
        @port = port

    TestClass.__setupCalls = [{method: 'setPort', args: ['config.port']}]
    definition = new Definition('testObject', TestClass)

    expect(definition.type).to.be.equal 'class'
    expect(definition.lifespan).to.be.equal 'call'
    expect(definition.dependencies).to.have.length 1
    expect(definition.setupCalls).to.have.length 1


  it 'should be able to handle arity problems within factories and classes', ->
    someFactory = (someDependency) -> 'hi'

    errorRaised = false
    try
      new Definition('someFactory', someFactory, type: 'factory')
    catch
      errorRaised = true

    expect(errorRaised).to.be.true
# coffeelint: enable=cyclomatic_complexity