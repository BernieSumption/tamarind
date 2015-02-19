exports.config =
  # See http://brunch.io/#documentation for docs.
  files:
    javascripts:
      joinTo: 'tamarind.js'
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
