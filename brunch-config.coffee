

exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo:
        'tamarind.tests.js': (path) -> /^app/.test(path) && path.indexOf(".tests.coffee") != -1
        'tamarind.js': (path) -> /^app/.test(path) && path.indexOf(".tests.coffee") == -1
      order:
        before: 'app/shared.coffee'

  modules:
    definition: false
    wrapper: false

  paths:
    public: "debug"

  overrides:
    production:
      sourceMaps: true
      paths:
        public: "dist"
