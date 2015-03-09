


exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'tamarind.js': (path) -> /^app/.test(path)
        'tamarind.tests.js': (path) -> /^test/.test(path)
        'vendor.js': (path) -> /^vendor/.test(path)
      order:
        before: 'app/shared.coffee'

    stylesheets:
      joinTo: 'tamarind.css'

  modules:
    definition: false
    wrapper: false

  paths:
    public: 'build'

  overrides:
    production:
      sourceMaps: true

  plugins:
    coffeelint:
      pattern:
        test: (path) -> /^app\/.*\.coffee$/.test(path) && path.indexOf('.tests.coffee') == -1
      options:
        no_unnecessary_double_quotes:
          level: 'error'
        no_interpolation_in_single_quotes:
          level: 'error'
        prefer_english_operator:
          level: 'error'
        space_operators:
          level: 'error'
        spacing_after_comma:
          level: 'error'
        no_implicit_returns:
          module: 'coffeelint-no-implicit-returns'
        max_line_length:
          value: 200
