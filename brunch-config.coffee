


exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'tamarind.tests.js': (path) -> /^app/.test(path) && path.indexOf(".tests.coffee") != -1
        'tamarind.js': (path) -> /^app/.test(path) && path.indexOf(".tests.coffee") == -1
      order:
        before: 'app/shared.coffee'

    stylesheets:
      joinTo: 'tamarind.css'

  modules:
    definition: false
    wrapper: false

  paths:
    public: "build"

  overrides:
    production:
      sourceMaps: true

  plugins:
    coffeelint:
      pattern:
        test: (path) -> /^app\/.*\.coffee$/.test(path) && path.indexOf(".tests.coffee") == -1
      options:
        no_implicit_returns:
          module: "coffeelint-no-implicit-returns"
        max_line_length:
          value: 200