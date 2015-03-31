gulp = require('gulp')
gutil = require('gulp-util')
sourcemaps = require('gulp-sourcemaps')
source = require('vinyl-source-stream')
buffer = require('vinyl-buffer')
watchify = require('watchify')
browserify = require('browserify')
bundler = watchify(browserify(watchify.args))
# add the file to bundle
# output build logs to terminal

bundle = ->
  bundler.bundle()
    .on('error', gutil.log.bind(gutil, 'Browserify Error'))
    .pipe(source 'bundle.js')
    .pipe(buffer())
    .pipe(sourcemaps.init loadMaps: true)
    .pipe(sourcemaps.write './')
    .pipe(gulp.dest './dist')

bundler.add './src/index.js'
gulp.task 'js', bundle
# so you can run `gulp js` to build the file
bundler.on 'update', bundle
# on any dep update, runs the bundler
bundler.on 'log', gutil.log
