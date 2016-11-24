{expect} = require 'chai'
sinon = require 'sinon'

Container = require 'deepdancer/Container'

describe 'deepdancer/Container', ->

  it 'should correctly tell if it has a dependency available', ->
    container = new Container()
    container.register('foo', 'the foo string')
    container._instances['roger'] =
      'value': 'some content'

    expect(container.has('roger')).to.be.true
    expect(container.has('foo')).to.be.true
    expect(container.has('bar')).to.be.false


  it 'should correctly retrieve an instance that already exists', ->
    container = new Container()
    expect(container.has('foo')).to.be.false

    container._instances['foo'] = 123
    expect(container.get('foo')).to.be.equal 123


  it 'should correctly load definition from module', ->
    container = new Container()

    container.registerFromModule('deepdancer/Container', type: 'class')
    expect(container._definitions).to.have.property 'deepdancer/Container'

    someContainer = container.get('deepdancer/Container')
    expect(someContainer).to.have.property 'registerFromModule'


  it 'should correctly load autoregistered modules', ->
    container = new Container()

    container.register('aCountToInject', 47)
    container.setModulesAsAutoregistered('deepdancer/testUtilities')
    myDependency = container.get(
      'deepdancer/testUtilities/mockDependencies/someDependency')
    expect(myDependency()).to.include '47'


  it 'shoud correctly manage the three lifespan: '+
      "'container', 'object' and 'call'", ->
    container = new Container()

    counterFactory = (subCounter1, subCounter2) ->
      oneMoreCounter =
        # coffeelint: disable=missing_fat_arrows
        oneMore: ->
          @counter()
          @subCounter1()
          @subCounter2()
        # coffeelint: enable=missing_fat_arrows

      oneMoreCounter.counter = sinon.spy()
      oneMoreCounter.subCounter1 = subCounter1
      oneMoreCounter.subCounter2 = subCounter2

      oneMoreCounter


    container.register('subCounterFromFactory',
      ->
        sinon.spy()
      , type: 'factory')
    container.register('subCounterValue', sinon.spy())
    container.register('counter', counterFactory, {
      type: 'factory'
      dependencies: ['subCounterFromFactory', 'subCounterValue']
    })

    counter = container.get('counter')
    counter.oneMore()
    counter.oneMore()
    # gunter.oneMore() ?
    # tEsPasDrole() ?

    subCounterFromFactory = container.get('subCounterFromFactory')
    subCounterValue = container.get('subCounterValue')

    # Testing the default 'container' level
    expect(counter.counter.callCount).to.be.equal 2
    expect(subCounterFromFactory.callCount).to.be.equal 2
    expect(subCounterValue.callCount).to.be.equal 2

    counterForCall = container.get('counter', 'call')
    counterForCall.oneMore()
    counterForCall.oneMore()
    counterForCall.oneMore()

    expect(counterForCall.counter.callCount).to.be.equal 3
    expect(counterForCall.subCounter1.callCount).to.be.equal 3,
      "The counter coming from a factory are reseted"
    expect(counterForCall.subCounter2.callCount).to.be.equal 5,
      "The counter coming from a value is persisted"
    expect(counter.counter.callCount).to.be.equal 2
    expect(subCounterFromFactory.callCount).to.be.equal 2
    expect(subCounterValue.callCount).to.be.equal 5

    counterForObject = container.get('counter', 'object')
    counterForObject.oneMore()

    expect(counterForObject.counter.callCount).to.be.equal 1
    expect(counterForObject.subCounter1.callCount).to.be.equal 3,
      "The counter coming from a hierarchy lower is reused"
    expect(counterForObject.subCounter2.callCount).to.be.equal 6
    expect(counter.counter.callCount).to.be.equal 2
    expect(subCounterFromFactory.callCount).to.be.equal 3
    expect(subCounterValue.callCount).to.be.equal 6

