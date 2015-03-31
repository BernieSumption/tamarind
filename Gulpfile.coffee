gulp         = require 'gulp'
gutil        = require 'gulp-util'
sourcemaps   = require 'gulp-sourcemaps'
source       = require 'vinyl-source-stream'
buffer       = require 'vinyl-buffer'
transform    = require 'vinyl-transform'
browserify   = require 'browserify'
uglify       = require 'gulp-uglify'
rename       = require 'gulp-rename'
del          = require 'del'
watch        = require 'gulp-watch'
runSequence  = require 'run-sequence'
server       = require 'gulp-server-livereload'
beefy_cli    = require 'beefy/lib/cli'



ENTRY_POINT = './app/tamarind/Tamarind.coffee'
OUT_FILE_NAME = 'tamarind.js'
BUILD_DIR = './build'


gulp.task 'default', ['clean', 'build-scripts', 'copy-assets']


gulp.task 'clean', ->
  del.sync(BUILD_DIR, force: true)


# based on: https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-uglify-sourcemap.md
gulp.task 'build-scripts', ->
  browserified = transform((filename) ->
    return browserify(entries: filename, standalone: 'Tamarind').bundle()
  )
  gulp.src(ENTRY_POINT)
    .pipe(browserified)
    .pipe(rename OUT_FILE_NAME)
    .pipe(gulp.dest BUILD_DIR)
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(rename extname: '.min.js')
    .pipe(uglify())
    .pipe(sourcemaps.write './')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'copy-assets', ->
  gulp.src('app/assets/**')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'live', ->

  onready = (err) ->
    if err
      throw err
  beefy_cli(
    ["#{ENTRY_POINT}:#{OUT_FILE_NAME}", '--live', '--index', 'app/assets/test/Tamarind-demo.html', '--', '--standalone', 'Tamarind']
    process.cwd()
    process.stdout
    process.stderr
    onready
  )

