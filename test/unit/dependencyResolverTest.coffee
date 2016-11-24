{expect} = require 'chai'

Container = require 'deepdancer/Container'

container = new Container()


describe 'deepdancer/dependencyResolver', ->

  it 'should lookup for value dependencies', ->
    container.register('config.port', 123)
    container.register('mockName', 'charles')

    port = container.get('config.port')
    expect(port).to.be.equal 123

    port = container.get('mockName')
    expect(port).to.be.equal 'charles'


  it 'should lookup for factory dependencies', ->
    appFactory = (port, extraObject, descriptionObject) ->
      app =
        description: 'A nice app'
        port: port
        extra: extraObject
        descriptionObject: descriptionObject
      app
    container.register('descriptionObject', ( -> field1: 'value1'),
      type: 'factory')
    container.get('descriptionObject').field1 = 'something tweaked'
    container.register('app', appFactory, {
      type: 'factory',
      dependencies: ['config.port', 'key1': 'value1', 'descriptionObject']
    })

    container.register('app-alias', 'app', type: 'alias')

    app = container.get('app')
    expect(app.description).to.be.equal 'A nice app'
    expect(app.port).to.be.equal 123
    expect(app.extra.key1).to.be.equal 'value1'
    expect(app.descriptionObject.field1).to.be.equal 'something tweaked'

    app.port = 122
    app = container.get('app')
    expect(app.port).to.be.equal 122

    app.port = 122
    app = container.get('app', 'call')
    expect(app.port).to.be.equal 123
    expect(app.descriptionObject.field1).to.be.equal 'value1'

    app = container.get('app', 'call', {'config.port': 42})
    expect(app.port).to.be.equal 42


  it 'should lookup for class dependencies', ->
    mockInstanceCount = 0
    class MockClass
      constructor: (@name) ->
        mockInstanceCount += 1
        @flickCount = 0

      getName: =>
        'Mock ' + @name

      flick: (increment = 1) =>
        @flickCount += increment
    setupCall1 =
      method: 'flick'
      args: []
    setupCall2 =
      method: 'flick'
      args: [3]
    setupCalls = [setupCall1, setupCall2]
    container.register('mock', MockClass, {
      type: 'class',
      lifespan: 'call',
      dependencies: ['mockName'],
      setupCalls: setupCalls
    })

    retrievedMock = container.get('mock')
    retrievedMock.flickCount += 1
    expect(retrievedMock.flickCount).to.be.equal 5

    retrievedMock = container.get('mock')
    expect(retrievedMock.flickCount).to.be.equal 4
    expect(retrievedMock.getName()).to.be.equal 'Mock charles'


  it 'should lookup for alias dependencies', ->
    container.register('christmas', tree: true)
    container.register('forest', 'christmas', type: 'alias')

    expect(container.get('forest').tree).to.be.true

    container.get('christmas').tree = false
    expect(container.get('forest').tree).to.be.false

    container.get('forest').tree = true
    expect(container.get('forest').tree).to.be.true


  it 'should lookup in the normal modules if needed', ->
    dictEmitter = (someThing) ->
      myDict =
        myThing: someThing
      myDict
    container.register('dict', dictEmitter, {
      type: 'factory'
      dependencies: ['chai']
    })

    dict = container.get('dict')
    expect(dict.myThing).to.include.property('expect')
    expect(dict.myThing).to.not.include.property('zorro')


  testDescription = 'should properly load setup type, lifespan, calls and '+
      'dependencies from the values'
  it testDescription, ->
    container.register('config.port', 123)
    class TestClass
      @__dependencies: [12]
      @__type = 'class'
      @__lifespan =  'call'

      constructor: (@someValue) ->
        @port = undefined

      setPort: (port) =>
        @port = port

    TestClass.__setupCalls = [{method: 'setPort', args: ['config.port']}]
    container.register('testObject', TestClass)

    testObject = container.get('testObject')
    expect(testObject.port).to.be.equal 123
    expect(testObject.someValue).to.be.equal 12