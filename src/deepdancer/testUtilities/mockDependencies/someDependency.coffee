helloImADependencyFactory = (aCountToInject) ->

  helloImADependency = ->
    'That\'s my message: ' + aCountToInject

  helloImADependency


helloImADependencyFactory.__dependencies = ['aCountToInject']
helloImADependencyFactory.__type = 'factory'

module.exports = helloImADependencyFactory