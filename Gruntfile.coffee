module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-release'
  grunt.loadNpmTasks 'grunt-contrib-watch'
  grunt.loadNpmTasks 'grunt-shell'
  grunt.loadNpmTasks 'grunt-contrib-coffee'

  grunt.initConfig
    watch:
      coffee:
        files: [
          '**/*.coffee'   # Watch everything
          '!node_modules' # ...except dependencies
        ]
        tasks: ['coffee']

    shell:
      test:
        command: 'npm test'
        options:
          stdout: true
          stderr: true

    coffee:
      options:
        bare: true
      index:
        files:
          'src/oscar.js': 'src/oscar.coffee'
      classes:
        expand: true
        cwd: 'src'
        src: ['*.coffee']
        dest: 'src'
        ext: '.js'
      helper:
        expand: true
        cwd: 'src/helper'
        src: ['*.coffee']
        dest: 'src/helper'
        ext: '.js'

  grunt.registerTask 'prepublish', ['coffee']
