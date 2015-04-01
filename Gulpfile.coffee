beefy_cli    = require 'beefy/lib/cli'
browserify   = require 'browserify'
buffer       = require 'vinyl-buffer'
concat       = require 'gulp-concat'
del          = require 'del'
glob         = require 'glob'
gulp         = require 'gulp'
gutil        = require 'gulp-util'
karma        = require 'gulp-karma'
rename       = require 'gulp-rename'
runSequence  = require 'run-sequence'
server       = require 'gulp-server-livereload'
source       = require 'vinyl-source-stream'
sourcemaps   = require 'gulp-sourcemaps'
transform    = require 'vinyl-transform'
uglify       = require 'gulp-uglify'
watch        = require 'gulp-watch'
watchify     = require 'watchify'




APP_ENTRY_POINT = './app/tamarind/Tamarind.coffee'
APP_SCRIPT_NAME = 'tamarind.js'
TEST_ENTRY_POINT = './app/**/*.tests.coffee'
TEST_SCRIPT_NAME = 'tamarind.tests.js'
BUILD_DIR = './build'




gulp.task 'default', ['clean', 'build-scripts', 'copy-assets']


gulp.task 'clean', ->
  del.sync(BUILD_DIR, force: true)


# based on: https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-uglify-sourcemap.md
gulp.task 'build-scripts', ->
  browserified = transform((filename) ->
    return browserify(entries: filename, standalone: 'Tamarind').bundle()
  )
  gulp.src(APP_ENTRY_POINT)
    .pipe(browserified)
    .pipe(rename APP_SCRIPT_NAME)
    .pipe(gulp.dest BUILD_DIR)
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(rename extname: '.min.js')
    .pipe(uglify())
    .pipe(sourcemaps.write './')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'build-test-scripts', ->
  return browserify(entries: glob.sync(TEST_ENTRY_POINT), debug: true)
    .bundle()
    .pipe(source TEST_SCRIPT_NAME)
    .pipe(buffer())
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(sourcemaps.write './')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'copy-assets', ->
  gulp.src('app/assets/**')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'beefy', ->

  onready = (err) ->
    if err
      throw err
  beefy_cli(
    ["#{APP_ENTRY_POINT}:#{APP_SCRIPT_NAME}", '--live', '--index', 'app/assets/test/Tamarind-demo.html', '--', '--standalone', 'Tamarind']
    process.cwd()
    process.stdout
    process.stderr
    onready
  )


gulp.task 'test', ->
  runSequence [
    'clean'
    'build-test-scripts'
    'copy-assets'
    'karma-once'
  ]






doKarma = (action) ->
  return gulp.src('build/tamarind.tests.js')
  .pipe(karma(
      configFile: 'karma.conf.coffee'
      action: action))
  .on 'error', (err) ->
    throw err

gulp.task 'karma-continuous', ->
  return doKarma 'start'

gulp.task 'karma-once', ->
  return doKarma 'run'

do ->

  # based on: https://github.com/gulpjs/gulp/blob/master/docs/recipes/fast-browserify-builds-with-watchify.md
  watchifyBundler = watchify(browserify(watchify.args, {debug: true}))
  runWatchifyBundler = ->
    watchifyBundler
    .bundle()
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source TEST_SCRIPT_NAME)
    .pipe(buffer())
    .pipe(sourcemaps.init(loadMaps: true))
    .pipe(sourcemaps.write('./'))
    .pipe(gulp.dest BUILD_DIR)

  for file in glob.sync(TEST_ENTRY_POINT)
    watchifyBundler.add file
  watchifyBundler.on 'update', runWatchifyBundler
  watchifyBundler.on 'log', gutil.log
  gulp.task 'watch-test-scripts', runWatchifyBundler


gulp.task 'watch-assets', ->
  return gulp.src('app/assets/**')
    .pipe(watch 'app/assets/**')
    .pipe(gulp.dest BUILD_DIR)


gulp.task 'test:live', ->
  runSequence(
    'clean'
    'watch-test-scripts'
    'copy-assets'
    ['watch-assets', 'karma-continuous']
  )