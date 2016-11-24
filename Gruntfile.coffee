module.exports = (grunt) ->
  grunt.initConfig

    watch:
      coffeelint:
        files: ['src/**/*.coffee', 'test/**/*.coffee', 'Gruntfile.coffee']
        tasks: ['coffeelint']

      test:
        files: ['src/**/*.coffee', 'test/**/*.coffee', 'Gruntfile.coffee']
        tasks: ['mochaTest']

    coffeelint:
      app: ['src/**/*.coffee', 'test/**/*.coffee', 'Gruntfile.coffee']
      options:
        configFile: 'coffeelint.json'

    mochaTest:
      test:
        options:
          reporter: 'spec',
          require: 'coffee-script/register'
          bail: true
        src: ['test/**/*.coffee']

    shell:
      coffee:
        command: 'node_modules/.bin/coffee --output lib src'

      publish:
        command: 'cp package.json lib/deepdancer; ' +
          'cp README.md lib/deepdancer; (cd lib/deepdancer; npm publish);'


  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.loadNpmTasks 'grunt-shell'
