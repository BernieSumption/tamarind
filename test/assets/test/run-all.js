// Generated by CoffeeScript 1.7.1
(function() {
  var TEST_FINDER, mod, _i, _len, _ref, _results;
  TEST_FINDER = /-test$/;
  _ref = window.require.list();
  _results = [];
  for (_i = 0, _len = _ref.length; _i < _len; _i++) {
    mod = _ref[_i];
    if (TEST_FINDER.test(mod)) {
      _results.push(require(mod));
    }
  }
  return _results;
})();